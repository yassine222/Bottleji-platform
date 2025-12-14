import { Injectable, NotFoundException, BadRequestException, Inject, forwardRef } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Cron } from '@nestjs/schedule';
import { Model } from 'mongoose';
import { Dropoff } from './schemas/dropoff.schema';
import { CollectorInteraction } from './schemas/collector-interaction.schema';
import { CollectionAttempt } from './schemas/collection-attempt.schema';
import { DropReport, ReportStatus } from './schemas/drop-report.schema';
import { LiveActivityToken } from './schemas/live-activity-token.schema';
import { CreateDropoffDto } from './dto/create-dropoff.dto';
import { DropoffStatus, CancellationReason } from './schemas/dropoff.schema';
import { InteractionType } from './schemas/collector-interaction.schema';
import { User } from '../users/schemas/user.schema';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { FCMService } from '../notifications/fcm.service';
import { RewardsService } from '../rewards/rewards.service';
import { EarningsSessionService } from '../earnings/earnings-session.service';

@Injectable()
export class DropoffsService {
  constructor(
    @InjectModel(Dropoff.name) private dropoffModel: Model<Dropoff>,
    @InjectModel(CollectorInteraction.name) private interactionModel: Model<CollectorInteraction>,
    @InjectModel(CollectionAttempt.name) private collectionAttemptModel: Model<CollectionAttempt>,
    @InjectModel(DropReport.name) private dropReportModel: Model<DropReport>,
    @InjectModel(LiveActivityToken.name) private liveActivityTokenModel: Model<LiveActivityToken>,
    @InjectModel(User.name) private userModel: Model<User>,
    @Inject(forwardRef(() => NotificationsGateway))
    private notificationsGateway: NotificationsGateway,
    private readonly notificationsService: NotificationsService,
    private readonly fcmService: FCMService,
    private readonly rewardsService: RewardsService,
    @Inject(forwardRef(() => EarningsSessionService))
    private readonly earningsSessionService: EarningsSessionService,
  ) {
    this.migrateOldCancellationFields();
    // Disabled interaction migration - using original dropoff data instead
    // this.migrateCollectorDataToInteractions();
    this.migrateUserWarningFields(); // Call the new migration method
  }

  private async migrateOldCancellationFields() {
    try {
      console.log('Starting migration of old cancellation fields...');
      
      // Find documents that still have the old cancelledByCollectorId field
      const documentsToMigrate = await this.dropoffModel.find({
        cancelledByCollectorId: { $exists: true }
      }).exec();
      
      console.log(`Found ${documentsToMigrate.length} documents to migrate`);
      
      for (const doc of documentsToMigrate) {
        const oldCancelledByCollectorId = doc.get('cancelledByCollectorId');
        
        if (oldCancelledByCollectorId) {
          // Convert single ID to array
          const newCancelledByCollectorIds = [oldCancelledByCollectorId];
          
          // Create cancellation history entry
          const cancellationHistory = [{
            collectorId: oldCancelledByCollectorId,
            reason: 'other', // Default reason for migrated data
            cancelledAt: new Date(),
            notes: `Migrated from old cancellation field`,
          }];
          
          await this.dropoffModel.updateOne(
            { _id: doc._id },
            { 
              $set: { 
                cancelledByCollectorIds: newCancelledByCollectorIds,
                cancellationHistory: cancellationHistory,
              },
              $unset: { cancelledByCollectorId: 1 }
            }
          );
          
          console.log(`Migrated document ${doc._id}: ${oldCancelledByCollectorId} -> [${newCancelledByCollectorIds.join(', ')}]`);
        }
      }
      
      // Also migrate drops that have cancelledByCollectorIds but no cancellationHistory
      const dropsWithCancelledIds = await this.dropoffModel.find({
        cancelledByCollectorIds: { $exists: true, $ne: [] },
        cancellationHistory: { $exists: false }
      }).exec();
      
      console.log(`Found ${dropsWithCancelledIds.length} drops with cancelledByCollectorIds to migrate`);
      
      for (const doc of dropsWithCancelledIds) {
        const cancelledIds = doc.cancelledByCollectorIds || [];
        const cancellationHistory = cancelledIds.map(collectorId => ({
          collectorId,
          reason: 'other', // Default reason for migrated data
          cancelledAt: new Date(),
          notes: `Migrated from cancelledByCollectorIds array`,
        }));
        
        await this.dropoffModel.updateOne(
          { _id: doc._id },
          { 
            $set: { cancellationHistory: cancellationHistory }
          }
        );
        
        console.log(`Migrated cancellation history for document ${doc._id}: ${cancelledIds.length} entries`);
      }
      
      console.log('Migration completed successfully');
    } catch (error) {
      console.error('Error during migration:', error);
    }
  }

  async migrateUserWarningFields() {
    try {
      console.log('Starting migration of user warning fields...');
      
      // Find all users that don't have the new warning fields
      const usersToMigrate = await this.userModel.find({
        $or: [
          { warningCount: { $exists: false } },
          { isAccountLocked: { $exists: false } },
          { warnings: { $exists: false } }
        ]
      }).exec();
      
      console.log(`Found ${usersToMigrate.length} users to migrate warning fields`);
      
      for (const user of usersToMigrate) {
        await this.userModel.updateOne(
          { _id: user._id },
          {
            $set: {
              warningCount: 0,
              isAccountLocked: false,
              warnings: []
            }
          }
        );
        
        console.log(`Migrated user ${user._id} with warning fields`);
      }
      
      console.log('User warning fields migration completed successfully');
    } catch (error) {
      console.error('Error during user warning fields migration:', error);
    }
  }

  private async migrateCollectorDataToInteractions() {
    console.log('Starting migration of collector data to interactions...');
    
    // Find all dropoffs that have collectorId but no corresponding ACCEPTED interaction
    const dropoffsWithCollector = await this.dropoffModel.find({
      collectorId: { $exists: true, $ne: null },
      status: { $in: [DropoffStatus.ACCEPTED, DropoffStatus.COLLECTED] },
    }).exec();

    console.log(`Found ${dropoffsWithCollector.length} dropoffs with collector data to migrate`);

    for (const dropoff of dropoffsWithCollector) {
      // Check if there's already an ACCEPTED interaction for this dropoff
      const existingInteraction = await this.interactionModel.findOne({
        dropoffId: dropoff._id,
        interactionType: InteractionType.ACCEPTED,
      }).exec();

      if (!existingInteraction && (dropoff as any).collectorId) {
        // Create ACCEPTED interaction with the data from dropoff
        await this.createInteraction({
          collectorId: (dropoff as any).collectorId,
          dropoffId: dropoff._id?.toString() || '',
          interactionType: InteractionType.ACCEPTED,
          interactionTime: (dropoff as any).acceptedAt || new Date(),
          dropoffStatus: dropoff.status,
          numberOfItems: dropoff.numberOfBottles + dropoff.numberOfCans,
          bottleType: dropoff.bottleType,
          location: dropoff.location,
          notes: `Migrated: Accepted drop for collection`,
        });

        console.log(`Created ACCEPTED interaction for dropoff ${dropoff._id} with collector ${(dropoff as any).collectorId}`);
      }
    }

    console.log('Migration completed');
  }

  /**
   * Scheduled task to check for expiring and expired drops
   * Runs every 2 minutes to check for:
   * - Near expiring drops (70% time elapsed) - sends warning notification
   * - Expired drops - sends expiration notification and resets drop to PENDING
   * 
   * Cron expression: every 2 minutes
   */
  // Cleanup task disabled - can be called manually via endpoint if needed
  // @Cron('*/2 * * * *')
  // async handleExpiredDropsCleanup() {
  //   try {
  //     await this.cleanupExpiredAcceptedDrops();
  //   } catch (error) {
  //     console.error('❌ Error in scheduled cleanup task:', error);
  //   }
  // }

  async create(createDropoffDto: CreateDropoffDto) {
    // Check if user already has an active drop (pending or accepted)
    const activeDrops = await this.dropoffModel.find({
      userId: createDropoffDto.userId,
      status: { $in: [DropoffStatus.PENDING, DropoffStatus.ACCEPTED] },
    }).exec();

    if (activeDrops.length > 0) {
      throw new BadRequestException(
        'You already have an active drop. Please wait until it is collected or cancel it before creating a new one.'
      );
    }

    const now = new Date();
    
    const dropoff = new this.dropoffModel({
      ...createDropoffDto,
      location: {
        type: 'Point',
        coordinates: [createDropoffDto.location.longitude, createDropoffDto.location.latitude],
      },
      address: createDropoffDto.address,
      createdAt: now,
      updatedAt: now,
    });

    const savedDropoff = await dropoff.save();
    
    console.log('Drop created successfully:', {
      id: savedDropoff._id,
      userId: savedDropoff.userId,
      status: savedDropoff.status,
      createdAt: savedDropoff.createdAt,
      updatedAt: savedDropoff.updatedAt,
      location: savedDropoff.location,
      numberOfBottles: savedDropoff.numberOfBottles,
      numberOfCans: savedDropoff.numberOfCans,
      bottleType: savedDropoff.bottleType,
    });

    return savedDropoff;
  }

  async findAll() {
    return this.dropoffModel.find({
      isSuspicious: false, // Don't show suspicious drops
      cancellationCount: { $lt: 3 }, // Don't show drops cancelled 3+ times
    }).exec();
  }

  async findOne(id: string) {
    return this.dropoffModel.findById(id).exec();
  }

  async findByUser(userId: string) {
    try {
      console.log('findByUser called with userId:', userId);
      
      const result = await this.dropoffModel.find({
        userId: userId
      }).exec();
      
      console.log('findByUser result count:', result.length);
      return result;
    } catch (error) {
      console.error('Error in findByUser:', error);
      throw error;
    }
  }

  async findByStatus(status: string) {
    return this.dropoffModel.find({
      status,
      isSuspicious: false, // Don't show suspicious drops
      cancellationCount: { $lt: 3 }, // Don't show drops cancelled 3+ times
    }).exec();
  }

  async findAvailableForCollectors(excludeCollectorId?: string) {
    try {
      // Return only pending drops that:
      // 1. Have status PENDING (drops stay PENDING until 3+ cancellations)
      // 2. Aren't suspicious (cancelled 3+ times)
      // 3. Weren't cancelled by the requesting collector
      // 4. Weren't created by the requesting collector
      const query: any = {
        status: DropoffStatus.PENDING, // Only show PENDING drops
        isSuspicious: false,
        $or: [
          { isCensored: false },
          { isCensored: { $exists: false } }, // Handle old drops without this field
        ],
        cancellationCount: { $lt: 3 }, // Additional safety check
      };

      // If a collector ID is provided, exclude drops they cancelled AND drops they created
      if (excludeCollectorId) {
        query.$and = [
          {
            $or: [
              { cancelledByCollectorIds: { $nin: [excludeCollectorId] } },
              { cancelledByCollectorIds: { $exists: false } },
              { cancelledByCollectorIds: { $size: 0 } },
            ]
          },
          {
            userId: { $ne: excludeCollectorId }
          }
        ];
      }

      const result = await this.dropoffModel.find(query).exec();

      return result;
    } catch (error) {
      throw error;
    }
  }

  async findAcceptedByCollector(collectorId: string) {
    // Find all ACCEPTED interactions for this collector
    const acceptedInteractions = await this.interactionModel.find({
      collectorId,
      interactionType: InteractionType.ACCEPTED,
    }).sort({ interactionTime: -1 }).exec();

    // Get the dropoff IDs from these interactions
    // Handle both populated (document) and non-populated (ObjectId) cases
    const dropoffIds = acceptedInteractions.map(interaction => {
      const dropoffId = interaction.dropoffId as any;
      
      if (!dropoffId) {
        return null;
      }
      
      // Handle different cases:
      // 1. Populated document object - extract _id
      // 2. ObjectId instance - convert to string
      // 3. ObjectId string (24 hex chars) - use directly
      // 4. Invalid string (full document stringified) - skip with warning
      
      if (typeof dropoffId === 'object') {
        // Check if it's a populated document (has _id property)
        if ('_id' in dropoffId) {
          const id = (dropoffId as any)._id;
          // Extract the actual ObjectId value
          if (id && typeof id === 'object' && id.toString) {
            const idString = id.toString();
            // Validate it's a proper ObjectId string (24 hex characters)
            if (/^[0-9a-fA-F]{24}$/.test(idString)) {
              return idString;
            }
          } else if (typeof id === 'string' && /^[0-9a-fA-F]{24}$/.test(id)) {
            return id;
          }
        } else {
          // It's an ObjectId instance - convert to string
          try {
            const idString = dropoffId.toString();
            if (/^[0-9a-fA-F]{24}$/.test(idString)) {
              return idString;
            }
          } catch (e) {
            console.error(`⚠️ Error converting dropoffId to string: ${e}`);
          }
        }
      } else if (typeof dropoffId === 'string') {
        // If it's a string, validate it's a proper ObjectId
        // Check if it looks like a stringified document (contains newlines, etc.)
        if (dropoffId.includes('\n') || dropoffId.includes('location:') || dropoffId.length > 50) {
          console.error(`⚠️ Invalid dropoffId format (appears to be stringified document): ${dropoffId.substring(0, 100)}...`);
          return null; // Skip invalid entries
        }
        // Validate it's a proper ObjectId string (24 hex characters)
        if (/^[0-9a-fA-F]{24}$/.test(dropoffId)) {
          return dropoffId;
        } else {
          console.error(`⚠️ Invalid dropoffId format (not a valid ObjectId): ${dropoffId}`);
          return null;
        }
      }
      
      // If we get here, something is wrong
      console.error(`⚠️ Unexpected dropoffId type: ${typeof dropoffId}, value: ${dropoffId}`);
      return null;
    }).filter((id): id is string => id != null && typeof id === 'string'); // Filter out null/undefined and ensure strings

    if (dropoffIds.length === 0) {
      return [];
    }

    // Find the corresponding dropoffs that are still ACCEPTED
    const acceptedDropoffs = await this.dropoffModel.find({
      _id: { $in: dropoffIds },
      status: DropoffStatus.ACCEPTED,
    }).exec();

    return acceptedDropoffs;
  }

  async updateStatus(id: string, status: string) {
    const updateData: any = { status };
    
    // If status is being set to accepted, add acceptedAt timestamp
    if (status === DropoffStatus.ACCEPTED) {
      updateData.acceptedAt = new Date();
    }
    
    // If status is being set to cancelled, increment cancellation count
    if (status === DropoffStatus.CANCELLED) {
      const dropoff = await this.dropoffModel.findById(id);
      if (dropoff) {
        const newCancellationCount = (dropoff.cancellationCount || 0) + 1;
        updateData.cancellationCount = newCancellationCount;
        
        // If cancelled 3 or more times, mark as suspicious
        if (newCancellationCount >= 3) {
          updateData.isSuspicious = true;
        }
      }
    }

    return this.dropoffModel.findByIdAndUpdate(
      id,
      updateData,
      { new: true },
    ).exec();
  }

  async update(id: string, updateDropoffDto: any) {
    const dropoff = await this.dropoffModel.findById(id);
    if (!dropoff) {
      throw new NotFoundException('Dropoff not found');
    }

    // Only allow updates for pending drops
    if (dropoff.status !== DropoffStatus.PENDING) {
      throw new BadRequestException('Can only update pending drops');
    }

    const updateData: any = {
      // Mongoose will automatically set updatedAt when we use { new: true }
    };

    // Update fields
    if (updateDropoffDto.imageUrl !== undefined) {
      updateData.imageUrl = updateDropoffDto.imageUrl;
    }
    if (updateDropoffDto.numberOfBottles !== undefined) {
      updateData.numberOfBottles = updateDropoffDto.numberOfBottles;
    }
    if (updateDropoffDto.numberOfCans !== undefined) {
      updateData.numberOfCans = updateDropoffDto.numberOfCans;
    }
    if (updateDropoffDto.bottleType !== undefined) {
      updateData.bottleType = updateDropoffDto.bottleType;
    }
    if (updateDropoffDto.notes !== undefined) {
      updateData.notes = updateDropoffDto.notes;
    }
    if (updateDropoffDto.leaveOutside !== undefined) {
      updateData.leaveOutside = updateDropoffDto.leaveOutside;
    }
    if (updateDropoffDto.location !== undefined) {
      updateData.location = {
        type: 'Point',
        coordinates: [updateDropoffDto.location.longitude, updateDropoffDto.location.latitude],
      };
    }

    const updatedDropoff = await this.dropoffModel.findByIdAndUpdate(
      id,
      updateData,
      { new: true },
    ).exec();

    if (!updatedDropoff) {
      throw new NotFoundException('Dropoff not found after update');
    }

    console.log('Drop updated successfully:', {
      id: updatedDropoff._id,
      userId: updatedDropoff.userId,
      status: updatedDropoff.status,
      updatedAt: updatedDropoff.updatedAt,
      numberOfBottles: updatedDropoff.numberOfBottles,
      numberOfCans: updatedDropoff.numberOfCans,
      bottleType: updatedDropoff.bottleType,
    });

    return updatedDropoff;
  }

  async assignCollector(id: string, collectorId: string) {
    const dropoff = await this.dropoffModel.findById(id).exec();
    if (!dropoff) {
      throw new NotFoundException('Dropoff not found');
    }

    // Allow assignment if drop is PENDING (even if it has been cancelled before)
    if (dropoff.status !== DropoffStatus.PENDING) {
      throw new BadRequestException('Can only assign collectors to pending dropoffs');
    }

    // Check if this collector has already cancelled this drop
    const hasCancelled = dropoff.cancelledByCollectorIds?.includes(collectorId) || false;
    if (hasCancelled) {
      throw new BadRequestException('This collector has already cancelled this drop and cannot accept it again');
    }

    // Update dropoff status to ACCEPTED (but don't set collectorId or acceptedAt on dropoff)
    const updatedDropoff = await this.dropoffModel.findByIdAndUpdate(
      id,
      { 
        status: DropoffStatus.ACCEPTED,
        // Note: We don't set collectorId or acceptedAt on the dropoff anymore
        // This data will be tracked in the interaction collection
      },
      { new: true },
    ).exec();

    // Create interaction for acceptance
    const interaction = await this.createInteraction({
      collectorId,
      dropoffId: id,
      interactionType: InteractionType.ACCEPTED,
      interactionTime: new Date(), // This serves as acceptedAt
      dropoffStatus: DropoffStatus.ACCEPTED, // Set to ACCEPTED, not the old status
      numberOfItems: dropoff.numberOfBottles + dropoff.numberOfCans,
      bottleType: dropoff.bottleType,
      location: dropoff.location,
      notes: `Accepted drop for collection`,
    });

    console.log('Created ACCEPTED interaction:', {
      id: interaction.id,
      collectorId: interaction.collectorId,
      dropoffId: interaction.dropoffId,
      interactionType: interaction.interactionType,
      interactionTime: interaction.interactionTime, // This is the acceptedAt time
      notes: interaction.notes,
    });

    // Send notification to drop creator
    try {
      // Normalize userId to ensure it matches the format stored in connectedUsers
      // Handle both ObjectId and string formats
      const userId = dropoff.userId?.toString ? dropoff.userId.toString() : String(dropoff.userId);
      console.log(`📱 Preparing to send drop accepted notification to user: ${userId} (original: ${dropoff.userId}, type: ${typeof dropoff.userId})`);
      
      await this.notificationsGateway.sendNotificationToUser(userId, {
        type: 'drop_accepted',
        title: 'Drop Accepted',
        message: 'A collector has accepted your drop and is on their way',
        data: { 
          dropId: id, 
          collectorId,
          dropTitle: `Drop with ${dropoff.numberOfBottles + dropoff.numberOfCans} items`
        },
        timestamp: new Date(),
      });
      console.log(`📱 Drop accepted notification sent to user ${userId}`);
      
      // Send Live Activity update
      const collector = await this.userModel.findById(collectorId).exec();
      const collectorName = collector?.name || 'Collector';
      
      console.log(`📤 [assignCollector] Preparing to send Live Activity update for dropoff ${id}`);
      await this.sendLiveActivityUpdate(id, {
        status: 'accepted',
        statusText: 'Accepted',
        collectorName: collectorName,
        timeAgo: 'Just now',
      });
      console.log(`✅ [assignCollector] Live Activity update sent for dropoff ${id}`);
    } catch (error) {
      console.error(`❌ Error sending drop accepted notification: ${error}`);
      console.error(`❌ Error details:`, error);
    }

    return updatedDropoff;
  }

  async confirmCollection(id: string) {
    const dropoff = await this.dropoffModel.findById(id).exec();
    if (!dropoff) {
      throw new NotFoundException('Dropoff not found');
    }

    // Find the most recent ACCEPTED interaction for this dropoff to get the collectorId
    const acceptedInteraction = await this.interactionModel.findOne({
      dropoffId: id,
      interactionType: InteractionType.ACCEPTED,
    }).sort({ interactionTime: -1 }).exec();

    if (!acceptedInteraction) {
      throw new BadRequestException('No accepted interaction found for this dropoff');
    }

    const updatedDropoff = await this.dropoffModel.findByIdAndUpdate(
      id,
      { 
        status: DropoffStatus.COLLECTED,
        collectedBy: acceptedInteraction.collectorId,
        collectedAt: new Date(),
      },
      { new: true },
    ).exec();

    // Create interaction for collection
    const interaction = await this.createInteraction({
      collectorId: acceptedInteraction.collectorId,
      dropoffId: id,
      interactionType: InteractionType.COLLECTED,
      interactionTime: new Date(),
      dropoffStatus: DropoffStatus.COLLECTED,
      numberOfItems: dropoff.numberOfBottles + dropoff.numberOfCans,
      bottleType: dropoff.bottleType,
      location: dropoff.location,
      notes: `Successfully collected drop`,
    });

    console.log('Created COLLECTED interaction:', {
      id: interaction.id,
      collectorId: interaction.collectorId,
      dropoffId: interaction.dropoffId,
      interactionType: interaction.interactionType,
      notes: interaction.notes,
    });

    // Send Live Activity update (end event)
    try {
      console.log(`📤 [confirmCollection] Sending Live Activity end event for dropoff ${id}`);
      await this.sendLiveActivityUpdate(id, {
        status: 'collected',
        statusText: 'Collected',
        timeAgo: 'Just now',
      }); // Event type is determined automatically from status
      console.log(`✅ [confirmCollection] Live Activity end event sent for dropoff ${id}`);
    } catch (error) {
      console.error(`❌ [confirmCollection] Error sending Live Activity update for collected drop: ${error}`);
    }

    // Award points to collector for successful collection
    let rewardResult: any = null;
    try {
      rewardResult = await this.rewardsService.awardPointsForCollection(
        acceptedInteraction.collectorId.toString(),
        id
      );
           
      console.log('🎉 Collector reward - Points awarded:', {
        collectorId: acceptedInteraction.collectorId,
        pointsAwarded: rewardResult.pointsAwarded,
        newTier: rewardResult.newTier.name,
        tierUpgraded: rewardResult.tierUpgraded,
        totalPoints: rewardResult.totalPoints,
        totalDrops: rewardResult.totalDrops
      });

           // Send tier upgrade notification if applicable
           if (rewardResult.tierUpgraded) {
             const collectorUserId = String(acceptedInteraction.collectorId);
             this.notificationsGateway.sendNotificationToUser(collectorUserId, {
               type: 'tier_upgrade',
               title: '🎉 Tier Upgraded!',
               message: `Congratulations! You've reached ${rewardResult.newTier.name}! You now earn ${rewardResult.newTier.pointsPerDrop} points per drop.`,
               data: { 
                 newTier: rewardResult.newTier,
                 totalPoints: rewardResult.totalPoints,
                 totalDrops: rewardResult.totalDrops
               },
               timestamp: new Date(),
             });
           } else {
             // Send points earned notification
             const collectorUserId = String(acceptedInteraction.collectorId);
             this.notificationsGateway.sendNotificationToUser(collectorUserId, {
               type: 'points_earned',
               title: 'Points Earned!',
               message: `You earned ${rewardResult.pointsAwarded} points for collecting this drop!`,
               data: { 
                 pointsAwarded: rewardResult.pointsAwarded,
                 totalPoints: rewardResult.totalPoints,
                 currentTier: rewardResult.newTier.name
               },
               timestamp: new Date(),
             });
           }
         } catch (error) {
           console.error('❌ Error awarding collector points:', error);
           // Don't fail the collection if reward system fails
         }

         // Award points to household user for their drop being collected
         try {
           const householdRewardResult = await this.rewardsService.awardPointsForDropCollected(
             dropoff.userId.toString(),
             id
           );
           
           console.log('🏠 Household reward - Points awarded:', {
             householdUserId: dropoff.userId,
             pointsAwarded: householdRewardResult.pointsAwarded,
             newTier: householdRewardResult.newTier.name,
             tierUpgraded: householdRewardResult.tierUpgraded,
             totalPoints: householdRewardResult.totalPoints,
             totalDropsCreated: householdRewardResult.totalDropsCreated
           });

        // Send Live Activity update (end event) BEFORE sending notifications
        try {
          console.log(`📤 [confirmCollection] Sending Live Activity end event for dropoff ${id}`);
          await this.sendLiveActivityUpdate(id, {
            status: 'collected',
            statusText: 'Collected',
            timeAgo: 'Just now',
          }); // Event type is determined automatically from status
          console.log(`✅ [confirmCollection] Live Activity end event sent for dropoff ${id}`);
        } catch (error) {
          console.error(`❌ [confirmCollection] Error sending Live Activity update for collected drop: ${error}`);
        }

        // Send combined notification for drop collected + rewards
        if (householdRewardResult.tierUpgraded) {
          const householdUserId = dropoff.userId?.toString ? dropoff.userId.toString() : String(dropoff.userId);
           this.notificationsGateway.sendNotificationToUser(householdUserId, {
             type: 'drop_collected_with_tier_upgrade',
             title: '🏠 Drop Collected & Tier Upgraded!',
             message: `Your drop was collected! You earned ${householdRewardResult.pointsAwarded} points and reached ${householdRewardResult.newTier.name}!`,
             data: { 
                dropId: (dropoff._id as any).toString(),
               pointsAwarded: householdRewardResult.pointsAwarded,
               totalPoints: householdRewardResult.totalPoints,
               newTier: householdRewardResult.newTier,
               tierUpgraded: true
             },
             timestamp: new Date(),
           });
         } else {
           const householdUserId = dropoff.userId?.toString ? dropoff.userId.toString() : String(dropoff.userId);
           this.notificationsGateway.sendNotificationToUser(householdUserId, {
             type: 'drop_collected_with_rewards',
             title: '🏠 Drop Collected!',
             message: `Your drop was collected! You earned ${householdRewardResult.pointsAwarded} points for contributing to recycling.`,
             data: { 
                dropId: (dropoff._id as any).toString(),
               pointsAwarded: householdRewardResult.pointsAwarded,
               totalPoints: householdRewardResult.totalPoints,
               currentTier: householdRewardResult.newTier.name,
               tierUpgraded: false
             },
             timestamp: new Date(),
           });
         }
         } catch (error) {
           console.error('❌ Error awarding household points:', error);
           // Don't fail the collection if household reward system fails
         }
         
         // Send Live Activity update (end activity)
         await this.sendLiveActivityUpdate(id, {
           status: 'collected',
           statusText: 'Collected',
           timeAgo: 'Just now',
         });

    // Drop creator notification is now sent with rewards below (combined notification)

    console.log(`📱 Drop collected notification sent to user ${dropoff.userId}`);

    // Return both the updated dropoff and reward information for the collector
    return {
      ...(updatedDropoff?.toObject() || {}),
      rewardData: {
        pointsAwarded: rewardResult?.pointsAwarded || 0,
        currentTier: rewardResult?.newTier || { tier: 1, name: 'Bronze Collector', pointsPerDrop: 8 },
        totalPoints: rewardResult?.totalPoints || 0,
        tierUpgraded: rewardResult?.tierUpgraded || false,
        totalDrops: rewardResult?.totalDrops || 0
      }
    };
  }

  async cancelAcceptedDrop(id: string, reason?: string, cancelledByCollectorId?: string): Promise<Dropoff> {
    const dropoff = await this.dropoffModel.findById(id).exec();
    if (!dropoff) {
      throw new NotFoundException(`Dropoff with ID ${id} not found`);
    }

    if (dropoff.status !== DropoffStatus.ACCEPTED) {
      throw new BadRequestException('Only accepted dropoffs can be cancelled');
    }

    // Increment total cancellation count (historical counter)
    const newCancellationCount = (dropoff.cancellationCount || 0) + 1;

    // Build unique set of collectors who cancelled this drop
    const currentCancelledIds = dropoff.cancelledByCollectorIds || [];
    const updatedCancelledIds = cancelledByCollectorId
      ? Array.from(new Set([...currentCancelledIds, cancelledByCollectorId]))
      : currentCancelledIds;

    const distinctCancellingCollectors = new Set(updatedCancelledIds).size;

    // Flag as suspicious only if cancelled by 3 or more DISTINCT collectors
    const isSuspicious = distinctCancellingCollectors >= 3;

    // Determine the new status based on DISTINCT cancellations
    let newStatus = DropoffStatus.PENDING; // Default to PENDING
    if (isSuspicious) {
      newStatus = DropoffStatus.CANCELLED; // Only set to CANCELLED if 3+ distinct cancellations
    }

    // Add detailed cancellation history
    const currentCancellationHistory = dropoff.cancellationHistory || [];
    const newCancellationEntry = cancelledByCollectorId ? {
      collectorId: cancelledByCollectorId,
      reason: reason as any,
      cancelledAt: new Date(),
      notes: `Cancelled by collector ${cancelledByCollectorId}`,
    } : null;

    const updatedCancellationHistory = newCancellationEntry 
      ? [...currentCancellationHistory, newCancellationEntry]
      : currentCancellationHistory;

    console.log('Cancellation details:', {
      currentCancellationCount: dropoff.cancellationCount,
      newCancellationCount,
      isSuspicious,
      newStatus,
      reason,
      cancelledByCollectorId,
      currentCancelledIds,
      updatedCancelledIds,
      distinctCancellingCollectors,
      cancellationHistoryLength: updatedCancellationHistory.length,
    });

    // Prepare update data
    const updateData: any = {
      cancellationCount: newCancellationCount,
      isSuspicious: isSuspicious,
      cancelledByCollectorIds: updatedCancelledIds,
      cancellationHistory: updatedCancellationHistory,
    };

    // When marking suspicious, set a clear reason
    if (isSuspicious) {
      updateData.suspiciousReason = 'Cancelled by 3 different collectors';
    }

    // Only update status if we're setting to CANCELLED
    // Note: We don't clear collectorId or acceptedAt from dropoff since they're in interactions
    if (newStatus === DropoffStatus.CANCELLED) {
      updateData.status = newStatus;
    } else {
      // If staying as PENDING, just update the status
      updateData.status = newStatus;
    }

    const updatedDropoff = await this.dropoffModel.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    ).exec();

    if (!updatedDropoff) {
      throw new NotFoundException(`Dropoff with ID ${id} not found`);
    }

    console.log('Drop cancellation processed:', {
      id: updatedDropoff._id,
      status: updatedDropoff.status,
      cancellationCount: updatedDropoff.cancellationCount,
      isSuspicious: updatedDropoff.isSuspicious,
      cancelledByCollectorIds: updatedDropoff.cancelledByCollectorIds,
    });

    // Send Live Activity update if status changed to CANCELLED
    if (newStatus === DropoffStatus.CANCELLED) {
      try {
        await this.sendLiveActivityUpdate(id, {
          status: 'cancelled',
          statusText: 'Cancelled',
          timeAgo: 'Just now',
        }); // Event type is determined automatically from status
      } catch (error) {
        console.error(`❌ Error sending Live Activity update for cancelled drop: ${error}`);
      }
    }

    // Create interaction for cancellation
    if (cancelledByCollectorId) {
      const interaction = await this.createInteraction({
        collectorId: cancelledByCollectorId,
        dropoffId: id,
        interactionType: InteractionType.CANCELLED,
        cancellationReason: reason as any,
        interactionTime: new Date(),
        dropoffStatus: DropoffStatus.CANCELLED, // Always CANCELLED to match interactionType
        numberOfItems: dropoff.numberOfBottles + dropoff.numberOfCans,
        bottleType: dropoff.bottleType,
        notes: `Cancelled drop: ${reason}`,
        location: dropoff.location,
      });

      console.log('Created CANCELLED interaction:', {
        id: interaction.id,
        collectorId: interaction.collectorId,
        dropoffId: interaction.dropoffId,
        interactionType: interaction.interactionType,
        cancellationReason: interaction.cancellationReason,
        notes: interaction.notes,
      });
    }

    // Send notification to drop creator every time someone cancels
    if (cancelledByCollectorId) {
      const notificationMessage = newStatus === DropoffStatus.CANCELLED 
        ? 'Your drop was cancelled and flagged as suspicious due to multiple cancellations'
        : 'A collector cancelled your drop. It\'s now available for others.';
      
      const householdUserId = dropoff.userId?.toString ? dropoff.userId.toString() : String(dropoff.userId);
      this.notificationsGateway.sendNotificationToUser(householdUserId, {
        type: 'drop_cancelled',
        title: 'Drop Cancelled',
        message: notificationMessage,
        data: { 
          dropId: id, 
          reason: reason || 'No reason provided',
          dropTitle: `Drop with ${dropoff.numberOfBottles + dropoff.numberOfCans} items`,
          cancelledBy: cancelledByCollectorId,
          totalCancellations: distinctCancellingCollectors
        },
        timestamp: new Date(),
      });

      console.log(`📱 Drop cancelled notification sent to user ${dropoff.userId} (${distinctCancellingCollectors} total cancellations)`);
    }

    // If drop just became suspicious (flagged), notify creator once
    if (isSuspicious && !dropoff.isSuspicious) {
      try {
        const notificationsService = (this as any).notificationsService || null;
        const total = distinctCancellingCollectors;
        if (notificationsService && notificationsService.notifyDropFlagged) {
          notificationsService.notifyDropFlagged(
            dropoff.userId.toString(),
            id,
            total,
            'Cancelled by 3 different collectors',
            `Drop with ${dropoff.numberOfBottles + dropoff.numberOfCans} items`
          );
        } else {
          // Fallback: send via gateway directly without enum coupling
          const householdUserId = dropoff.userId?.toString ? dropoff.userId.toString() : String(dropoff.userId);
          this.notificationsGateway.sendNotificationToUser(householdUserId, {
            type: 'drop_flagged',
            title: 'Drop Flagged',
            message: 'Your drop was flagged due to multiple cancellations. It will be hidden from the map.',
            data: {
              dropId: id,
              totalCancellations: total,
              dropTitle: `Drop with ${dropoff.numberOfBottles + dropoff.numberOfCans} items`,
              reason: 'Cancelled by 3 different collectors',
            },
            timestamp: new Date(),
          });
        }
        console.log(`📱 Drop flagged notification sent to user ${dropoff.userId} (distinct cancellations: ${total})`);
      } catch (e) {
        console.error('Failed to send drop flagged notification', e);
      }
    }

    return updatedDropoff;
  }

  async cleanupExpiredAcceptedDrops() {
    console.log('🧹 Starting cleanup of expired accepted drops...');
    console.log('🔍 Method called at:', new Date().toISOString());
    
    // Simple test to verify method is working
    const testCount = await this.interactionModel.countDocuments({ interactionType: InteractionType.ACCEPTED });
    console.log(`📊 Total accepted interactions in database: ${testCount}`);
    
    // Find all ACCEPTED interactions that need timeout checking
    const acceptedInteractions = await this.interactionModel.find({
      interactionType: InteractionType.ACCEPTED,
    }).populate('dropoffId').exec();

    console.log(`📊 Found ${acceptedInteractions.length} accepted interactions to check`);

    const now = new Date();
    let cleanedCount = 0;

    for (const interaction of acceptedInteractions) {
      const dropoff = interaction.dropoffId as any;
      if (!dropoff) {
        console.log(`⚠️ No dropoff found for interaction ${interaction._id}`);
        continue;
      }

      console.log(`🔍 Checking interaction ${interaction._id} for drop ${dropoff._id}`);
      console.log(`⏰ Interaction time: ${interaction.interactionTime}`);
      console.log(`⏰ Current time: ${now}`);

      // Calculate dynamic timeout based on route duration
      // Use Google Maps API to get actual route duration
      const routeDurationMinutes = await this.calculateRouteDuration(
        interaction.location ? {
          lat: interaction.location.coordinates[1],
          lng: interaction.location.coordinates[0]
        } : { lat: 0, lng: 0 },
        dropoff.location
      );
      
      // Fixed buffer based on route duration
      let bufferMinutes = 10; // 10 minutes buffer for unexpected delays
      if (routeDurationMinutes > 30) {
        bufferMinutes = 20; // 20 minutes buffer for longer routes
      }
      
      const totalTimeoutMinutes = routeDurationMinutes + bufferMinutes;
      
      const timeoutThreshold = new Date(interaction.interactionTime.getTime() + (totalTimeoutMinutes * 60 * 1000));
      
      // Calculate time remaining
      const timeRemainingMs = timeoutThreshold.getTime() - now.getTime();
      const timeRemainingMinutes = Math.floor(timeRemainingMs / (60 * 1000));
      const timeElapsedMs = now.getTime() - interaction.interactionTime.getTime();
      const timeElapsedMinutes = Math.floor(timeElapsedMs / (60 * 1000));
      const timeElapsedPercent = (timeElapsedMinutes / totalTimeoutMinutes) * 100;
      
      console.log(`⏰ Route duration: ${routeDurationMinutes}min, Buffer: ${bufferMinutes}min, Total timeout: ${totalTimeoutMinutes}min`);
      console.log(`⏰ Timeout threshold: ${timeoutThreshold}`);
      console.log(`⏰ Time remaining: ${timeRemainingMinutes}min (${(timeRemainingMinutes / totalTimeoutMinutes * 100).toFixed(1)}%)`);
      console.log(`⏰ Time elapsed: ${timeElapsedMinutes}min (${timeElapsedPercent.toFixed(1)}%)`);
      console.log(`⏰ Should expire: ${now > timeoutThreshold}`);
      
      // Check if drop is near expiring (70% of time elapsed = 30% remaining)
      const nearExpiringThreshold = totalTimeoutMinutes * 0.7; // 70% of total time
      
      if (timeElapsedMinutes >= nearExpiringThreshold && timeRemainingMinutes > 0) {
        // Check if near-expiring notification was already sent for this drop (for collector only)
        const existingNearExpiringNotificationCollector = await this.notificationsService.getUserNotifications(
          interaction.collectorId.toString(),
          { type: 'drop_near_expiring' as any, limit: 1 }
        );
        
        // Check if there's a recent near-expiring notification for this drop (within last hour) for collector
        const recentNearExpiringCollector = existingNearExpiringNotificationCollector.notifications.find((n: any) => {
          const notificationData = n.data || {};
          return notificationData.dropId === (dropoff._id as any).toString() &&
                 new Date(n.createdAt).getTime() > (now.getTime() - 60 * 60 * 1000); // Within last hour
        });
        
        if (!recentNearExpiringCollector) {
          console.log(`⚠️ Drop ${dropoff._id} is near expiring (${timeElapsedPercent.toFixed(1)}% elapsed, ${timeRemainingMinutes}min remaining)`);
          
          // Send near-expiring notification to collector only
          try {
            const collectorUserId = String(interaction.collectorId);
            await this.notificationsGateway.sendNotificationToUser(collectorUserId, {
              type: 'drop_near_expiring',
              title: 'Collection Time Running Low',
              message: `You have ${timeRemainingMinutes} minute${timeRemainingMinutes !== 1 ? 's' : ''} remaining to collect this drop.`,
              data: { 
                dropId: (dropoff._id as any).toString(),
                collectorId: interaction.collectorId,
                dropTitle: `Drop with ${dropoff.numberOfBottles + dropoff.numberOfCans} items`,
                timeRemainingMinutes: timeRemainingMinutes,
              },
              timestamp: new Date(),
            });
            console.log(`📱 Near-expiring notification sent to collector ${interaction.collectorId}`);
          } catch (error) {
            console.error(`❌ Error sending near-expiring notification to collector: ${error}`);
          }
        } else {
          console.log(`ℹ️ Near-expiring notification already sent to collector for drop ${dropoff._id} recently, skipping`);
        }
      }
      
      if (now > timeoutThreshold) {
        console.log(`🔄 Processing expired drop ${dropoff._id} for collector ${interaction.collectorId}`);
        
        // Check if EXPIRED interaction already exists for this drop
        const existingExpiredInteraction = await this.interactionModel.findOne({
          dropoffId: interaction.dropoffId,
          interactionType: InteractionType.EXPIRED,
          collectorId: interaction.collectorId,
        }).exec();

        if (existingExpiredInteraction) {
          console.log(`⚠️ EXPIRED interaction already exists for drop ${dropoff._id} and collector ${interaction.collectorId}, skipping`);
          continue;
        }

        // Additional check: see if drop is already PENDING (might have been processed by another cleanup run)
        const currentDrop = await this.dropoffModel.findById(dropoff._id).exec();
        if (currentDrop && currentDrop.status === DropoffStatus.PENDING) {
          console.log(`⚠️ Drop ${dropoff._id} is already PENDING, skipping expired processing`);
          continue;
        }

        console.log(`🔄 Processing expired drop ${dropoff._id} for collector ${interaction.collectorId}`);

        // Timeout reached - set drop back to PENDING
        await this.dropoffModel.findByIdAndUpdate(
          dropoff._id,
          { 
            status: DropoffStatus.PENDING,
            updatedAt: now,
          },
          { new: true }
        ).exec();

        // Create interaction for expiration (penalty is now added automatically inside createInteraction)
        try {
          // Send Live Activity update (end activity)
          try {
            await this.sendLiveActivityUpdate(dropoff._id.toString(), {
              status: 'expired',
              statusText: 'Expired',
              timeAgo: 'Just now',
            }); // Event type is determined automatically from status
          } catch (error) {
            console.error(`❌ Error sending Live Activity update for expired drop: ${error}`);
          }

          // Create EXPIRED interaction (this will automatically add the penalty)
          await this.createInteraction({
            collectorId: interaction.collectorId,
            dropoffId: interaction.dropoffId,
            interactionType: InteractionType.EXPIRED,
            interactionTime: now,
            expiredAt: now,
            notes: `Collection expired after ${totalTimeoutMinutes} minutes`,
          });

          console.log(`✅ EXPIRED interaction created for drop ${dropoff._id} (penalty added automatically)`);
          
          // Send notification to drop creator (household user)
          try {
            const householdUserId = dropoff.userId?.toString ? dropoff.userId.toString() : String(dropoff.userId);
            await this.notificationsGateway.sendNotificationToUser(householdUserId, {
              type: 'drop_expired',
              title: 'Drop Expired',
              message: 'A collector\'s time expired on your drop. It\'s now available for others.',
              data: { 
                  dropId: (dropoff._id as any).toString(),
                collectorId: interaction.collectorId,
                dropTitle: `Drop with ${dropoff.numberOfBottles + dropoff.numberOfCans} items`
              },
              timestamp: new Date(),
            });
            console.log(`📱 Drop expired notification sent to household user ${dropoff.userId}`);
          } catch (error) {
            console.error(`❌ Error sending drop expired notification to household user: ${error}`);
          }
          
          // Send notification to collector
          try {
            const collectorUserId = String(interaction.collectorId);
            await this.notificationsGateway.sendNotificationToUser(collectorUserId, {
              type: 'drop_expired',
              title: 'Collection Time Expired',
              message: `Your time to collect this drop has expired. The drop is now available for other collectors.`,
              data: { 
                dropId: (dropoff._id as any).toString(),
                collectorId: interaction.collectorId,
                dropTitle: `Drop with ${dropoff.numberOfBottles + dropoff.numberOfCans} items`
              },
              timestamp: new Date(),
            });
            console.log(`📱 Drop expired notification sent to collector ${interaction.collectorId}`);
          } catch (error) {
            console.error(`❌ Error sending drop expired notification to collector: ${error}`);
          }
          
          cleanedCount++;
          console.log(`✅ Drop ${dropoff._id} timed out after ${totalTimeoutMinutes} minutes, set back to PENDING`);
        } catch (error: any) {
          if (error.code === 11000) { // MongoDB duplicate key error
            console.log(`⚠️ Duplicate EXPIRED interaction detected for drop ${dropoff._id}, skipping`);
            continue;
          } else {
            console.error(`❌ Error creating EXPIRED interaction for drop ${dropoff._id}:`, error);
            continue;
          }
        }
      } else {
        console.log(`✅ Drop ${dropoff._id} is still within timeout period`);
      }
    }

    console.log(`🧹 Cleanup completed. Processed ${cleanedCount} expired drops`);
    return cleanedCount;
  }

  async cleanupDuplicateExpiredInteractions() {
    try {
      console.log('🧹 Starting cleanup of duplicate EXPIRED interactions...');
      
      // Find all EXPIRED interactions
      const expiredInteractions = await this.interactionModel.find({
        interactionType: InteractionType.EXPIRED,
      }).exec();

      const duplicates = new Map();
      const toDelete: any[] = [];

      // Group by dropoffId and collectorId
      for (const interaction of expiredInteractions) {
        const key = `${interaction.dropoffId}_${interaction.collectorId}`;
        if (duplicates.has(key)) {
          toDelete.push(interaction._id);
        } else {
          duplicates.set(key, interaction._id);
        }
      }

      if (toDelete.length > 0) {
        await this.interactionModel.deleteMany({
          _id: { $in: toDelete }
        });
        console.log(`🧹 Cleaned up ${toDelete.length} duplicate EXPIRED interactions`);
      } else {
        console.log('✅ No duplicate EXPIRED interactions found');
      }
    } catch (error) {
      console.error('❌ Error cleaning up duplicate EXPIRED interactions:', error);
    }
  }

  async addCollectorPenalty(collectorId: string, penaltyType: string) {
    try {
      // Import User model
      const UserModel = this.userModel;
      
      // Find the collector
      const collector = await UserModel.findById(collectorId);
      if (!collector) {
        console.log(`Collector ${collectorId} not found for penalty`);
        return;
      }

      console.log(`\n🔍 PENALTY CHECK - Collector: ${collector.email}`);
      console.log(`   Current warningCount: ${collector.warningCount}`);
      console.log(`   Current isAccountLocked: ${collector.isAccountLocked}`);
      console.log(`   Current accountLockedUntil: ${collector.accountLockedUntil}`);

      // Add warning
      const warning = {
        type: penaltyType,
        reason: 'Collection timeout - did not complete drop within allocated time',
        timestamp: new Date(),
      };

      // Calculate new warning count
      const newWarningCount = collector.warningCount + 1;
      console.log(`   New warningCount will be: ${newWarningCount}`);
      
      // Determine lock duration based on warning count (incremental system)
      let lockDuration: number | null = null;
      let shouldLock = false;
      
      if (newWarningCount >= 25) {
        // 5th lock: Permanent until admin review
        shouldLock = true;
        lockDuration = null; // null means permanent
        console.log(`🔒 PERMANENT LOCK - User has ${newWarningCount} warnings (25+)`);
      } else if (newWarningCount >= 20 && newWarningCount % 5 === 0) {
        // 4th lock: 1 month (30 days)
        shouldLock = true;
        lockDuration = 30 * 24 * 60 * 60 * 1000;
        console.log(`🔒 1 MONTH LOCK - User has ${newWarningCount} warnings`);
      } else if (newWarningCount >= 15 && newWarningCount % 5 === 0) {
        // 3rd lock: 1 week (7 days)
        shouldLock = true;
        lockDuration = 7 * 24 * 60 * 60 * 1000;
        console.log(`🔒 1 WEEK LOCK - User has ${newWarningCount} warnings`);
      } else if (newWarningCount >= 10 && newWarningCount % 5 === 0) {
        // 2nd lock: 3 days
        shouldLock = true;
        lockDuration = 3 * 24 * 60 * 60 * 1000;
        console.log(`🔒 3 DAYS LOCK - User has ${newWarningCount} warnings`);
      } else if (newWarningCount >= 5 && newWarningCount % 5 === 0) {
        // 1st lock: 24 hours
        shouldLock = true;
        lockDuration = 24 * 60 * 60 * 1000;
        console.log(`🔒 24 HOURS LOCK - User has ${newWarningCount} warnings`);
      }
      
      // Prepare update fields
      const updateFields: any = {
        $inc: { warningCount: 1 },
        $push: { warnings: warning },
      };
      
      // Apply lock if user should be locked
      // Only skip lock update if user is CURRENTLY locked (not expired)
      const isCurrentlyLocked = collector.isAccountLocked && 
                                collector.accountLockedUntil && 
                                new Date(collector.accountLockedUntil) > new Date();
      
      console.log(`   Should lock at this count? ${shouldLock}`);
      console.log(`   Is currently locked? ${isCurrentlyLocked}`);
      
      if (shouldLock && !isCurrentlyLocked) {
        // Apply new lock
        updateFields.$set = {
          isAccountLocked: true,
          accountLockedUntil: lockDuration ? new Date(Date.now() + lockDuration) : null,
        };
        console.log(`🔒 APPLYING NEW LOCK: duration=${lockDuration ? lockDuration / (24 * 60 * 60 * 1000) + ' days' : 'PERMANENT'}`);
      } else if (isCurrentlyLocked) {
        console.log(`⏳ User already locked until ${collector.accountLockedUntil}, NOT resetting timer`);
      } else if (!shouldLock && collector.isAccountLocked && !isCurrentlyLocked) {
        // User was locked but lock expired and this warning doesn't trigger a new lock
        // Explicitly unlock them
        updateFields.$set = {
          isAccountLocked: false,
          accountLockedUntil: null,
        };
        console.log(`🔓 UNLOCKING - Lock expired and warning ${newWarningCount} doesn't trigger new lock`);
      } else {
        console.log(`✅ No lock needed - warning count ${newWarningCount} is not a lock threshold`);
      }
      
      // Update user with new warning
      const updatedUser = await UserModel.findByIdAndUpdate(
        collectorId,
        updateFields,
        { new: true }
      );

      if (updatedUser) {
        console.log(`Penalty added to collector ${collectorId}: ${penaltyType}`);
        console.log(`Warning count: ${updatedUser.warningCount}/5`);
        
        if (updatedUser.isAccountLocked) {
          console.log(`🔒 Account ${collectorId} locked until ${updatedUser.accountLockedUntil}`);
          
          // Determine lock message based on warning count
          let lockMessage = '';
          if (updatedUser.warningCount >= 25) {
            lockMessage = 'Your account has been permanently locked due to repeated violations. Please contact admin for review.';
          } else if (updatedUser.warningCount >= 20) {
            lockMessage = 'Your account has been locked for 1 month due to 20 warnings.';
          } else if (updatedUser.warningCount >= 15) {
            lockMessage = 'Your account has been locked for 1 week due to 15 warnings.';
          } else if (updatedUser.warningCount >= 10) {
            lockMessage = 'Your account has been locked for 3 days due to 10 warnings.';
          } else {
            lockMessage = 'Your account has been locked for 24 hours due to 5 warnings.';
          }
          
          // Emit WebSocket event for real-time lock notification
          // Ensure accountLockedUntil is properly serialized (null for permanent locks, ISO string for temporary)
          const accountLockedUntilValue = updatedUser.accountLockedUntil 
            ? updatedUser.accountLockedUntil.toISOString() 
            : null;
          
          console.log(`📤 Sending account_locked notification - isPermanent: ${accountLockedUntilValue === null}, accountLockedUntil: ${accountLockedUntilValue}`);
          
          this.notificationsGateway.sendNotificationToUser(collectorId, {
            type: 'account_locked',
            title: 'Account Locked',
            message: lockMessage,
            data: {
              isAccountLocked: true,
              accountLockedUntil: accountLockedUntilValue, // null for permanent, ISO string for temporary
              warningCount: updatedUser.warningCount,
            },
            timestamp: new Date(),
          });
        }
      } else {
        console.log(`Failed to update collector ${collectorId} with penalty`);
      }
    } catch (error) {
      console.error('Error adding penalty to collector:', error);
    }
  }

  async remove(id: string) {
    const dropoff = await this.dropoffModel.findById(id).exec();
    if (!dropoff) {
      throw new NotFoundException('Dropoff not found');
    }

    // Only allow deletion of pending drops
    if (dropoff.status !== DropoffStatus.PENDING) {
      throw new BadRequestException('Can only delete pending dropoffs');
    }

    return this.dropoffModel.findByIdAndDelete(id).exec();
  }

  // Collector Interaction Tracking Methods
  async createInteraction(createInteractionDto: any) {
    const now = new Date();
    const interactionData: any = {
      ...createInteractionDto,
      interactionTime: createInteractionDto.interactionTime || now,
    };

    // For EXPIRED, CANCELLED, or COLLECTED interactions, check if ACCEPTED exists
    // If not, create it automatically to maintain complete timeline
    if ([InteractionType.EXPIRED, InteractionType.CANCELLED, InteractionType.COLLECTED].includes(createInteractionDto.interactionType)) {
      const existingAccepted = await this.interactionModel.findOne({
        dropoffId: createInteractionDto.dropoffId,
        collectorId: createInteractionDto.collectorId,
        interactionType: InteractionType.ACCEPTED,
      }).exec();

      if (!existingAccepted) {
        console.log(`⚠️ Creating ${createInteractionDto.interactionType} without ACCEPTED - auto-creating ACCEPTED interaction first`);
        
        // Create the ACCEPTED interaction with earlier timestamp
        const acceptedTime = new Date(now.getTime() - 60 * 1000); // 1 minute before current interaction
        const acceptedInteraction = new this.interactionModel({
          collectorId: createInteractionDto.collectorId,
          dropoffId: createInteractionDto.dropoffId,
          interactionType: InteractionType.ACCEPTED,
          interactionTime: acceptedTime,
          acceptedAt: acceptedTime,
          dropoffStatus: 'accepted',
          numberOfItems: createInteractionDto.numberOfItems,
          bottleType: createInteractionDto.bottleType,
          location: createInteractionDto.location,
          notes: 'Auto-created: Accepted drop for collection (reconstructed for timeline)',
        });
        
        await acceptedInteraction.save();
        console.log(`✅ Auto-created ACCEPTED interaction for complete timeline`);
      }
    }

    // Set specific timestamp fields based on interaction type
    switch (createInteractionDto.interactionType) {
      case InteractionType.ACCEPTED:
        interactionData.acceptedAt = now;
        break;
      case InteractionType.CANCELLED:
        interactionData.cancelledAt = now;
        break;
      case InteractionType.COLLECTED:
        interactionData.collectedAt = now;
        break;
      case InteractionType.EXPIRED:
        interactionData.expiredAt = now;
        // Immediately add penalty warning when EXPIRED interaction is created
        try {
          await this.addCollectorPenalty(createInteractionDto.collectorId, 'TIMEOUT_WARNING');
          console.log(`✅ Warning instantly added to collector ${createInteractionDto.collectorId} for expired drop`);
        } catch (penaltyError) {
          console.error(`❌ Error adding instant penalty:`, penaltyError);
        }
        break;
    }

    const interaction = new this.interactionModel(interactionData);
    return interaction.save();
  }

  // Collection Attempt Tracking Methods (New System)

  async getCollectorStats(collectorId: string, timeRange?: string) {
    const now = new Date();
    let startDate: Date;

    switch (timeRange) {
      case 'today':
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        break;
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case 'month':
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
      case 'year':
        startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
        break;
      default:
        startDate = new Date(0); // All time
    }

    // Get all collection attempts for this collector
    const attempts = await this.collectionAttemptModel.find({
      collectorId,
      acceptedAt: { $gte: startDate }
    }).exec();

    // Count attempts by outcome
    let acceptedCount = 0; // Active attempts (not completed yet)
    let collectedCount = 0;
    let cancelledCount = 0;
    let expiredCount = 0;

    attempts.forEach(attempt => {
      if (attempt.status === 'active') {
        acceptedCount++; // Still in progress
      } else if (attempt.status === 'completed') {
        switch (attempt.outcome) {
          case 'collected':
            collectedCount++;
            break;
          case 'cancelled':
            cancelledCount++;
            break;
          case 'expired':
            expiredCount++;
            break;
        }
      }
    });

    // Debug logging
    console.log('🔍 Stats from CollectionAttempts for collector:', collectorId);
    console.log('📊 Total attempts:', attempts.length);
    console.log('📊 Counts - Active:', acceptedCount, 'Collected:', collectedCount, 'Cancelled:', cancelledCount, 'Expired:', expiredCount);

    const stats = {
      accepted: acceptedCount,
      collected: collectedCount,
      cancelled: cancelledCount,
      expired: expiredCount,
      collectionRate: 0,
      averageCollectionTime: 0,
      cancellationReasons: {},
      timeRange,
    };

    // Calculate collection rate (collected / total completed attempts)
    const totalCompleted = collectedCount + cancelledCount + expiredCount;
    if (totalCompleted > 0) {
      stats.collectionRate = (collectedCount / totalCompleted) * 100;
    }

    // Calculate average collection time from completed attempts
    if (collectedCount > 0) {
      const collectedAttempts = attempts.filter(a => a.outcome === 'collected' && a.durationMinutes);
      const totalMinutes = collectedAttempts.reduce((sum, a) => sum + (a.durationMinutes || 0), 0);
      stats.averageCollectionTime = totalMinutes > 0 ? (totalMinutes / collectedAttempts.length) * 60 * 1000 : 0; // Convert to milliseconds
    }

    // Calculate cancellation reasons from timeline events
    const cancelledAttempts = attempts.filter(a => a.outcome === 'cancelled');
    cancelledAttempts.forEach(attempt => {
      // Find the cancelled event in timeline
      const cancelledEvent = attempt.timeline.find(e => e.event === 'cancelled');
      const reason = cancelledEvent?.details?.reason || 'unknown';
      stats.cancellationReasons[reason] = (stats.cancellationReasons[reason] || 0) + 1;
    });

    return stats;
  }

  private async calculateRouteDuration(
    collectorLocation: { lat: number; lng: number },
    dropoffLocation: { lat: number; lng: number }
  ): Promise<number> {
    try {
      // Use Google Maps Distance Matrix API to get route duration
      const apiKey = process.env.GOOGLE_MAPS_API_KEY;
      if (!apiKey) {
        console.warn('⚠️ Google Maps API key not found, using default 20 minutes');
        return 20; // Default fallback
      }

      const origin = `${collectorLocation.lat},${collectorLocation.lng}`;
      const destination = `${dropoffLocation.lat},${dropoffLocation.lng}`;
      
      const url = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${origin}&destinations=${destination}&mode=driving&key=${apiKey}`;
      
      const response = await fetch(url);
      const data = await response.json();
      
      if (data.status === 'OK' && data.rows[0]?.elements[0]?.duration) {
        const durationSeconds = data.rows[0].elements[0].duration.value;
        const durationMinutes = Math.ceil(durationSeconds / 60); // Round up to next minute
        console.log(`🗺️ Route duration calculated: ${durationMinutes} minutes`);
        return durationMinutes;
      } else {
        console.warn('⚠️ Failed to get route duration from Google Maps API, using default 20 minutes');
        return 20; // Default fallback
      }
    } catch (error) {
      console.error('❌ Error calculating route duration:', error);
      return 20; // Default fallback
    }
  }

  private getStatusPriority(status: string): number {
    switch (status) {
      case InteractionType.COLLECTED:
        return 4; // Highest priority
      case InteractionType.CANCELLED:
        return 3;
      case InteractionType.EXPIRED:
        return 2;
      case InteractionType.ACCEPTED:
        return 1; // Lowest priority
      default:
        return 0;
    }
  }

  async getUserDropStats(userId: string, timeRange?: string) {
    const now = new Date();
    let startDate: Date;

    switch (timeRange) {
      case 'today':
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        break;
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case 'month':
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
      case 'year':
        startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
        break;
      case 'all':
      default:
        // Default to all time to match the drops list behavior
        startDate = new Date(0); // All time
    }

    // Get all drops created by this user
    // For collected drops, filter by collectedAt date (when it was collected)
    // For other statuses (pending, accepted, cancelled, expired), filter by updatedAt date (when status last changed)
    let userDrops: any[] = [];
    
    if (timeRange && timeRange !== 'all' && timeRange !== '') {
      // Get collected drops filtered by collectedAt date
      const collectedDropsQuery: any = {
        userId,
        status: DropoffStatus.COLLECTED,
        collectedAt: { $gte: startDate, $exists: true },
      };
      const collectedDrops = await this.dropoffModel.find(collectedDropsQuery).exec();
      
      // Get non-collected drops filtered by updatedAt date (when status last changed)
      // This captures when the drop was last active/modified in the time range
      // updatedAt is better than createdAt because:
      // - For accepted drops: shows when they were accepted
      // - For cancelled/expired drops: shows when they were cancelled/expired
      // - For pending drops: shows when they were last modified (e.g., after cancellation)
      const nonCollectedDropsQuery: any = {
        userId,
        status: { $ne: DropoffStatus.COLLECTED },
        updatedAt: { $gte: startDate },
      };
      const nonCollectedDrops = await this.dropoffModel.find(nonCollectedDropsQuery).exec();
      
      // Combine both sets
      userDrops = [...collectedDrops, ...nonCollectedDrops];
    } else {
      // All time - get all drops
      const query: any = { userId };
      userDrops = await this.dropoffModel.find(query).exec();
    }

    // Count drops by their current status and flags
    let pendingCount = 0;
    let collectedCount = 0;
    let flaggedCount = 0;
    let staleCount = 0;
    let censoredCount = 0;

    userDrops.forEach(drop => {
      // Check for flagged drops (suspicious or 3+ cancellations)
      if (drop.isSuspicious || drop.cancellationCount >= 3) {
        flaggedCount++;
      }
      // Check for censored drops
      else if (drop.isCensored) {
        censoredCount++;
      }
      // Check for stale drops
      else if (drop.status === DropoffStatus.STALE) {
        staleCount++;
      }
      // Check for pending drops
      else if (drop.status === DropoffStatus.PENDING) {
        pendingCount++;
      }
      // Check for collected drops
      else if (drop.status === DropoffStatus.COLLECTED) {
        collectedCount++;
      }
    });

    // Debug logging
    console.log('🔍 User Drop Stats Debug for user:', userId);
    console.log('📅 Time range:', timeRange);
    console.log('📅 Start date:', startDate);
    console.log('📊 Total drops found:', userDrops.length);
    console.log('📊 Status counts - Pending:', pendingCount, 'Collected:', collectedCount, 'Flagged:', flaggedCount, 'Stale:', staleCount, 'Censored:', censoredCount);
    
    // Log sample collected drops for debugging
    const sampleCollected = userDrops.filter(d => d.status === DropoffStatus.COLLECTED).slice(0, 3);
    if (sampleCollected.length > 0) {
      console.log('📦 Sample collected drops:');
      sampleCollected.forEach(drop => {
        console.log(`  - Drop ${drop._id}: collectedAt=${drop.collectedAt}, createdAt=${drop.createdAt}`);
      });
    }

    const stats = {
      total: userDrops.length,
      pending: pendingCount,
      collected: collectedCount,
      flagged: flaggedCount,
      stale: staleCount,
      censored: censoredCount,
      timeRange,
    };

    return stats;
  }

  async getCollectorHistory(collectorId: string, status?: string, timeRange?: string, page: number = 1, limit: number = 20) {
    const now = new Date();
    let startDate: Date;

    switch (timeRange) {
      case 'today':
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        break;
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case 'month':
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
      case 'year':
        startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
        break;
      default:
        startDate = new Date(0); // All time
    }

    const query: any = {
      collectorId,
      interactionTime: { $gte: startDate }
    };

    if (status) {
      query.interactionType = status;
    }

    const skip = (page - 1) * limit;
    
    const interactions = await this.interactionModel.find(query)
      .sort({ interactionTime: -1 })
      .skip(skip)
      .limit(limit)
      .populate('dropoffId')
      .exec();

    const total = await this.interactionModel.countDocuments(query);

    // Debug: Log the interactions being returned
    console.log('getCollectorHistory - Query:', query);
    console.log('getCollectorHistory - Total interactions found:', interactions.length);
    interactions.forEach((interaction, index) => {
      console.log(`Interaction ${index + 1}:`, {
        id: interaction.id,
        collectorId: interaction.collectorId,
        dropoffId: interaction.dropoffId,
        interactionType: interaction.interactionType,
        notes: interaction.notes,
        interactionTime: interaction.interactionTime,
      });
    });

    return {
      interactions,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    };
  }

  async debugDropoffInteractions(dropoffId: string) {
    const interactions = await this.interactionModel.find({ dropoffId })
      .sort({ interactionTime: -1 })
      .exec();

    console.log(`Debug: All interactions for dropoff ${dropoffId}:`);
    interactions.forEach((interaction, index) => {
      console.log(`  ${index + 1}. ${interaction.interactionType} - ${interaction.notes} (${interaction.interactionTime})`);
    });

    return interactions;
  }

  async getDropInteractionTimeline(dropoffId: string) {
    console.log('🔍 Dropoffs Service: Fetching interactions for dropoffId:', dropoffId);
    
    const interactions = await this.interactionModel.find({ dropoffId })
      .populate('collectorId', 'name email')
      .sort({ interactionTime: 1 }) // Sort chronologically (oldest first)
      .exec();
  
    console.log('🔍 Dropoffs Service: Found', interactions.length, 'interactions for dropoffId:', dropoffId);
    
    if (interactions.length > 0) {
      console.log('🔍 Dropoffs Service: First interaction:', {
        id: interactions[0]._id,
        type: interactions[0].interactionType,
        collectorId: interactions[0].collectorId,
        timestamp: interactions[0].interactionTime
      });
    }
  
    // Format interactions for timeline display
    const timeline = interactions.map(interaction => ({
      id: (interaction._id as any).toString(),
      type: interaction.interactionType,
      collectorId: interaction.collectorId,
      collectorName: (interaction.collectorId as any)?.name || 'Unknown Collector',
      timestamp: interaction.interactionTime,
      notes: interaction.notes,
      cancellationReason: interaction.cancellationReason,
      location: interaction.location,
      dropoffStatus: interaction.dropoffStatus,
      numberOfItems: interaction.numberOfItems,
      bottleType: interaction.bottleType,
      acceptedAt: interaction.acceptedAt,
      cancelledAt: interaction.cancelledAt,
      collectedAt: interaction.collectedAt,
      expiredAt: interaction.expiredAt,
    }));
  
    console.log('🔍 Dropoffs Service: Returning timeline with', timeline.length, 'formatted interactions');
    return timeline;
  }

  async getCollectionInteractionTimeline(collectionId: string) {
    console.log('🔍 Dropoffs Service: Fetching collection interactions for collectionId:', collectionId);
    
    // First, try to find if this collectionId is actually an interaction ID
    const specificInteraction = await this.interactionModel.findById(collectionId)
      .populate('collectorId', 'name email')
      .populate('dropoffId', 'numberOfBottles numberOfCans bottleType notes location status')
      .exec();
    
    if (specificInteraction) {
      console.log('🔍 Dropoffs Service: Found specific interaction:', {
        id: specificInteraction._id,
        type: specificInteraction.interactionType,
        collectorId: specificInteraction.collectorId,
        dropoffId: specificInteraction.dropoffId,
        timestamp: specificInteraction.interactionTime
      });
      
      // If we found a specific interaction, get all interactions for that dropoff
      // Extract the _id from the populated dropoff object
      let dropoffId: string;
      if (typeof specificInteraction.dropoffId === 'object' && (specificInteraction.dropoffId as any)._id) {
        dropoffId = (specificInteraction.dropoffId as any)._id.toString();
      } else if (typeof specificInteraction.dropoffId === 'string') {
        dropoffId = specificInteraction.dropoffId;
      } else {
        // If it's an ObjectId, convert it to string
        dropoffId = (specificInteraction.dropoffId as any).toString();
      }
      
      console.log('🔍 Dropoffs Service: Extracted dropoffId for collection timeline:', dropoffId);
      console.log('🔍 Dropoffs Service: Original dropoffId type:', typeof specificInteraction.dropoffId);
      console.log('🔍 Dropoffs Service: Original dropoffId value:', specificInteraction.dropoffId);
      
      const allInteractions = await this.interactionModel.find({ dropoffId })
        .populate('collectorId', 'name email')
        .sort({ interactionTime: 1 })
        .exec();
      
      console.log('🔍 Dropoffs Service: Found', allInteractions.length, 'interactions for related dropoff:', dropoffId);
      
      // Format interactions for timeline display
      const timeline = allInteractions.map(interaction => ({
        id: (interaction._id as any).toString(),
        type: interaction.interactionType,
        collectorId: interaction.collectorId,
        collectorName: (interaction.collectorId as any)?.name || 'Unknown Collector',
        timestamp: interaction.interactionTime,
        notes: interaction.notes,
        cancellationReason: interaction.cancellationReason,
        location: interaction.location,
        dropoffStatus: interaction.dropoffStatus,
        numberOfItems: interaction.numberOfItems,
        bottleType: interaction.bottleType,
        acceptedAt: interaction.acceptedAt,
        cancelledAt: interaction.cancelledAt,
        collectedAt: interaction.collectedAt,
        expiredAt: interaction.expiredAt,
        dropoffInfo: interaction.dropoffId ? {
          id: (interaction.dropoffId as any)._id?.toString() || (interaction.dropoffId as any).toString(),
          numberOfBottles: (interaction.dropoffId as any).numberOfBottles,
          numberOfCans: (interaction.dropoffId as any).numberOfCans,
          bottleType: (interaction.dropoffId as any).bottleType,
          status: (interaction.dropoffId as any).status,
        } : null,
      }));
      
      console.log('🔍 Dropoffs Service: Returning collection timeline with', timeline.length, 'formatted interactions');
      return timeline;
    }
    
    // If not found as interaction ID, try to find interactions by collector or other criteria
    console.log('🔍 Dropoffs Service: Collection ID not found as interaction ID, returning empty timeline');
    return [];
  }

  async debugCollectorInteractions(collectorId: string) {
    const interactions = await this.interactionModel.find({ collectorId })
      .sort({ interactionTime: -1 })
      .exec();

    console.log(`Debug: All interactions for collector ${collectorId}:`);
    interactions.forEach((interaction, index) => {
      console.log(`  ${index + 1}. ${interaction.interactionType} - Dropoff: ${interaction.dropoffId} - ${interaction.notes} (${interaction.interactionTime})`);
    });

    return interactions;
  }

  async verifyNoCollectorDataInDropoffs() {
    console.log('Verifying no collector data in dropoffs...');
    
    // Check for dropoffs that still have collectorId
    const dropoffsWithCollectorId = await this.dropoffModel.find({
      'collectorId': { $exists: true, $ne: null }
    } as any).exec();
    
    // Check for dropoffs that still have acceptedAt
    const dropoffsWithAcceptedAt = await this.dropoffModel.find({
      'acceptedAt': { $exists: true, $ne: null }
    } as any).exec();
    
    console.log('Verification results:');
    console.log(`- Dropoffs with collectorId: ${dropoffsWithCollectorId.length}`);
    console.log(`- Dropoffs with acceptedAt: ${dropoffsWithAcceptedAt.length}`);
    
    if (dropoffsWithCollectorId.length > 0) {
      console.log('⚠️  Found dropoffs with collectorId:');
      dropoffsWithCollectorId.forEach(drop => {
        console.log(`  - Dropoff ${drop._id}: collectorId = ${(drop as any).collectorId}`);
      });
    }
    
    if (dropoffsWithAcceptedAt.length > 0) {
      console.log('⚠️  Found dropoffs with acceptedAt:');
      dropoffsWithAcceptedAt.forEach(drop => {
        console.log(`  - Dropoff ${drop._id}: acceptedAt = ${(drop as any).acceptedAt}`);
      });
    }
    
    if (dropoffsWithCollectorId.length === 0 && dropoffsWithAcceptedAt.length === 0) {
      console.log('✅ All dropoffs are clean - no collector data found');
    }
    
    return {
      dropoffsWithCollectorId: dropoffsWithCollectorId.length,
      dropoffsWithAcceptedAt: dropoffsWithAcceptedAt.length,
      totalIssues: dropoffsWithCollectorId.length + dropoffsWithAcceptedAt.length
    };
  }

  async debugAllDrops() {
    console.log('Debugging all drops...');
    
    // Get ALL drops without any filters
    const allDrops = await this.dropoffModel.find({}).exec();
    
    console.log(`Total drops in database: ${allDrops.length}`);
    
    const dropsWithDetails = allDrops.map(drop => ({
      id: drop._id,
      userId: drop.userId,
      status: drop.status,
      isSuspicious: drop.isSuspicious,
      cancellationCount: drop.cancellationCount,
      cancelledByCollectorIds: drop.cancelledByCollectorIds,
      createdAt: drop.createdAt,
      updatedAt: drop.updatedAt,
      numberOfBottles: drop.numberOfBottles,
      numberOfCans: drop.numberOfCans,
      bottleType: drop.bottleType,
    }));
    
    console.log('All drops details:', dropsWithDetails);
    
    // Check which drops would be filtered out by findAll()
    const filteredOutDrops = allDrops.filter(drop => 
      drop.isSuspicious === true || drop.cancellationCount >= 3
    );
    
    console.log(`Drops filtered out by findAll(): ${filteredOutDrops.length}`);
    if (filteredOutDrops.length > 0) {
      console.log('Filtered out drops:', filteredOutDrops.map(drop => ({
        id: drop._id,
        status: drop.status,
        isSuspicious: drop.isSuspicious,
        cancellationCount: drop.cancellationCount,
      })));
    }
    
    return {
      totalDrops: allDrops.length,
      drops: dropsWithDetails,
      filteredOutCount: filteredOutDrops.length,
      filteredOutDrops: filteredOutDrops.map(drop => ({
        id: drop._id,
        status: drop.status,
        isSuspicious: drop.isSuspicious,
        cancellationCount: drop.cancellationCount,
      }))
    };
  }

  async cleanupDuplicateExpired() {
    try {
      await this.cleanupDuplicateExpiredInteractions();
      return { message: 'Duplicate EXPIRED interactions cleanup completed successfully' };
    } catch (error) {
      throw new BadRequestException('Cleanup failed: ' + error.message);
    }
  }

  async dropExpiredConstraint() {
    try {
      // Drop the unique constraint for expired interactions
      const db = this.interactionModel.db;
      const collection = db.collection('collectorinteractions');
      
      // Drop the unique index
      await collection.dropIndex('dropoffId_1_interactionType_1_collectorId_1');
      
      console.log('✅ Unique constraint for EXPIRED interactions dropped successfully');
      return { message: 'Unique constraint for EXPIRED interactions dropped successfully' };
    } catch (error) {
      console.log('⚠️ Error dropping constraint (might not exist):', error.message);
      return { message: 'Constraint drop attempted (might not exist)', error: error.message };
    }
  }

  // =============================================================================
  // NEW COLLECTION ATTEMPT METHODS
  // =============================================================================

  async createCollectionAttempt(dropoffId: string, collectorId: string) {
    try {
      // Get dropoff details
      const dropoff = await this.dropoffModel.findById(dropoffId).populate('userId', 'name email').exec();
      if (!dropoff) {
        throw new NotFoundException('Dropoff not found');
      }

      // Get collector details
      const collector = await this.userModel.findById(collectorId, 'name email').exec();
      if (!collector) {
        throw new NotFoundException('Collector not found');
      }

      // Check if there's already an active attempt for this dropoff
      const existingAttempt = await this.collectionAttemptModel.findOne({
        dropoffId,
        status: 'active'
      }).exec();

      if (existingAttempt) {
        throw new BadRequestException('An active collection attempt already exists for this dropoff');
      }

      // Get attempt number (count previous attempts for this dropoff)
      const attemptNumber = await this.collectionAttemptModel.countDocuments({
        dropoffId
      }) + 1;

      // Get cancellation count for this dropoff
      const cancellationCount = await this.collectionAttemptModel.countDocuments({
        dropoffId,
        outcome: 'cancelled'
      });

      const now = new Date();

      // Create collection attempt
      const collectionAttempt = new this.collectionAttemptModel({
        dropoffId,
        collectorId,
        status: 'active',
        outcome: null,
        acceptedAt: now,
        completedAt: null,
        durationMinutes: null,
        attemptNumber,
        cancellationCount,
        dropSnapshot: {
          imageUrl: dropoff.imageUrl,
          numberOfBottles: dropoff.numberOfBottles,
          numberOfCans: dropoff.numberOfCans,
          bottleType: dropoff.bottleType,
          location: {
            lat: dropoff.location.coordinates[1],
            lng: dropoff.location.coordinates[0]
          },
          address: dropoff.address,
          notes: dropoff.notes,
          leaveOutside: dropoff.leaveOutside,
          createdBy: {
            id: (dropoff as any).userId._id,
            name: (dropoff as any).userId.name,
            email: (dropoff as any).userId.email
          },
          createdAt: dropoff.createdAt
        },
        timeline: [{
          event: 'accepted',
          timestamp: now,
          collector: {
            id: collector._id,
            name: collector.name,
            email: collector.email
          },
          details: {
            notes: 'Accepted drop for collection',
            location: {
              lat: dropoff.location.coordinates[1],
              lng: dropoff.location.coordinates[0]
            }
          }
        }],
        // Initialize location tracking fields
        currentCollectorLocation: null
      });

      const savedAttempt = await collectionAttempt.save();

      console.log('✅ Collection attempt created:', {
        id: savedAttempt._id,
        dropoffId: savedAttempt.dropoffId,
        collectorId: savedAttempt.collectorId,
        attemptNumber: savedAttempt.attemptNumber
      });

      return savedAttempt;
    } catch (error) {
      console.error('❌ Error creating collection attempt:', error);
      throw error;
    }
  }

  async completeCollectionAttempt(attemptId: string, outcome: 'expired' | 'cancelled' | 'collected', details: any) {
    try {
      console.log(`🔄 Completing collection attempt: ${attemptId} with outcome: ${outcome}`);
      const attempt = await this.collectionAttemptModel.findById(attemptId).exec();
      if (!attempt) {
        console.log(`❌ Collection attempt not found: ${attemptId}`);
        throw new NotFoundException('Collection attempt not found');
      }

      console.log(`📋 Current attempt status: ${attempt.status}, current timeline length: ${attempt.timeline.length}`);

      if (attempt.status === 'completed') {
        console.log(`⚠️ Collection attempt already completed with outcome: ${attempt.outcome}`);
        throw new BadRequestException('Collection attempt already completed');
      }

      const now = new Date();
      const durationMinutes = Math.round((now.getTime() - attempt.acceptedAt.getTime()) / (1000 * 60));

      console.log(`⏱️ Duration: ${durationMinutes} minutes`);

      // Add outcome event to timeline
      const outcomeEvent = {
        event: outcome,
        timestamp: now,
        collector: attempt.timeline[0].collector, // Use same collector as accepted event
        details: {
          reason: details.reason || null,
          notes: details.notes || null,
          location: details.location || attempt.dropSnapshot.location
        }
      };

      console.log(`📝 Creating outcome event: ${JSON.stringify(outcomeEvent)}`);

      // Calculate earnings if collected
      let earnings = 0;
      if (outcome === 'collected') {
        // Formula: (numberOfBottles * 0.025) + (numberOfCans * 0.06)
        const bottles = attempt.dropSnapshot.numberOfBottles || 0;
        const cans = attempt.dropSnapshot.numberOfCans || 0;
        earnings = (bottles * 0.025) + (cans * 0.06);
        earnings = Math.round(earnings * 100) / 100; // Round to 2 decimal places
        console.log(`💰 Calculated earnings: ${earnings} TND (${bottles} bottles, ${cans} cans)`);
      }

      // Update attempt
      const updatedAttempt = await this.collectionAttemptModel.findByIdAndUpdate(
        attemptId,
        {
          status: 'completed',
          outcome,
          completedAt: now,
          durationMinutes,
          earnings,
          currentCollectorLocation: null, // Clear location when collection ends
          $push: { timeline: outcomeEvent }  // Use $push instead of spreading array
        },
        { new: true }
      ).exec();

      if (!updatedAttempt) {
        console.log(`❌ Collection attempt not found after update`);
        throw new NotFoundException('Collection attempt not found after update');
      }

      console.log(`✅ Collection attempt updated! New timeline length: ${updatedAttempt.timeline.length}`);
      console.log(`📋 Timeline events: ${updatedAttempt.timeline.map(e => e.event).join(' → ')}`);

      // Add warning if expired
      if (outcome === 'expired') {
        try {
          await this.addCollectorPenalty(attempt.collectorId.toString(), 'TIMEOUT_WARNING');
          console.log(`✅ Warning added to collector ${attempt.collectorId} for expired attempt`);
        } catch (penaltyError) {
          console.error(`❌ Error adding penalty:`, penaltyError);
        }
      }

      // Update user's total earnings and session if collected
      if (outcome === 'collected' && earnings > 0) {
        console.log(`💰 Starting earnings update for collector ${attempt.collectorId}, earnings: ${earnings} TND`);
        try {
          // Add to earnings session (this creates/updates the daily session)
          const session = await this.earningsSessionService.addCollectionToSession(
            attempt.collectorId.toString(),
            attemptId,
            earnings,
            now,
          );
          console.log(`💰 Earnings session updated: sessionEarnings=${session.sessionEarnings}, collectionCount=${session.collectionCount}`);

          // Update user's total earnings
          await this.userModel.findByIdAndUpdate(
            attempt.collectorId,
            { $inc: { totalEarnings: earnings } },
            { new: true }
          ).exec();
          console.log(`✅ Updated total earnings for collector ${attempt.collectorId}: +${earnings} TND`);

          // Update or create earnings history entry for today (similar to rewardHistory)
          // Use UTC to ensure consistent date comparison regardless of server timezone
          const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
          console.log(`💰 Today's date for earnings history (UTC): ${today.toISOString()}`);
          console.log(`💰 Current time (UTC): ${now.toISOString()}`);
          console.log(`💰 Current time (local): ${now.toString()}`);
          
          // Ensure earningsHistory array exists and find/update today's entry
          const user = await this.userModel.findById(attempt.collectorId).exec();
          if (user) {
            console.log(`💰 User found, current earningsHistory: ${JSON.stringify(user.earningsHistory)}`);
            console.log(`💰 earningsHistory is array: ${Array.isArray(user.earningsHistory)}`);
            
            // Initialize earningsHistory if it doesn't exist
            if (!user.earningsHistory || !Array.isArray(user.earningsHistory)) {
              console.log(`💰 Initializing earningsHistory array for user ${attempt.collectorId}`);
              await this.userModel.findByIdAndUpdate(
                attempt.collectorId,
                { $set: { earningsHistory: [] } }
              ).exec();
              // Re-fetch user after initialization
              const updatedUser = await this.userModel.findById(attempt.collectorId).exec();
              console.log(`💰 After initialization, earningsHistory: ${JSON.stringify(updatedUser?.earningsHistory)}`);
            }
            
            // Re-fetch user to get latest earningsHistory
            const latestUser = await this.userModel.findById(attempt.collectorId).exec();
            const earningsHistory = latestUser?.earningsHistory || [];
            console.log(`💰 Current earningsHistory length: ${earningsHistory.length}`);
            
            const existingEntryIndex = earningsHistory.findIndex((entry: any) => {
              if (!entry || !entry.date) {
                console.log(`💰 Entry has no date: ${JSON.stringify(entry)}`);
                return false;
              }
              // Parse entry date and normalize to UTC start of day
              const entryDate = new Date(entry.date);
              const entryDateUTC = new Date(Date.UTC(
                entryDate.getUTCFullYear(),
                entryDate.getUTCMonth(),
                entryDate.getUTCDate(),
                0, 0, 0, 0
              ));
              const matches = entryDateUTC.getTime() === today.getTime();
              console.log(`💰 Comparing entry date ${entryDateUTC.toISOString()} (from ${entryDate.toISOString()}) with today ${today.toISOString()}: ${matches}`);
              return matches;
            });

            if (existingEntryIndex >= 0) {
              console.log(`💰 Found existing entry at index ${existingEntryIndex}, updating...`);
              // Update existing entry
              await this.userModel.findByIdAndUpdate(
                attempt.collectorId,
                {
                  $set: {
                    [`earningsHistory.${existingEntryIndex}.earnings`]: session.sessionEarnings,
                    [`earningsHistory.${existingEntryIndex}.collectionCount`]: session.collectionCount,
                    [`earningsHistory.${existingEntryIndex}.lastCollectionTime`]: session.lastCollectionTime,
                    [`earningsHistory.${existingEntryIndex}.isActive`]: session.isActive,
                  }
                }
              ).exec();
              console.log(`✅ Updated existing earnings history entry for collector ${attempt.collectorId}`);
            } else {
              console.log(`💰 No existing entry found, creating new one...`);
              // Create new entry for today
              const newEntry = {
                date: today,
                earnings: session.sessionEarnings,
                collectionCount: session.collectionCount,
                startTime: session.startTime,
                lastCollectionTime: session.lastCollectionTime,
                isActive: session.isActive,
              };
              console.log(`💰 New entry to push: ${JSON.stringify(newEntry)}`);
              
              await this.userModel.findByIdAndUpdate(
                attempt.collectorId,
                {
                  $push: {
                    earningsHistory: newEntry
                  }
                }
              ).exec();
              console.log(`✅ Created new earnings history entry for collector ${attempt.collectorId}`);
            }
            
            // Verify the update
            const verifyUser = await this.userModel.findById(attempt.collectorId).exec();
            console.log(`💰 After update, earningsHistory: ${JSON.stringify(verifyUser?.earningsHistory)}`);
            console.log(`✅ Updated earnings history for collector ${attempt.collectorId}`);
          } else {
            console.error(`❌ User ${attempt.collectorId} not found when updating earnings history`);
          }
        } catch (earningsError) {
          console.error(`❌ Error updating earnings:`, earningsError);
          console.error(`❌ Error stack:`, earningsError.stack);
        }
      } else {
        console.log(`💰 Skipping earnings update: outcome=${outcome}, earnings=${earnings}`);
      }

      console.log('✅ Collection attempt completed:', {
        id: updatedAttempt._id,
        outcome: updatedAttempt.outcome,
        durationMinutes: updatedAttempt.durationMinutes,
        timelineLength: updatedAttempt.timeline.length,
        earnings: updatedAttempt.earnings || 0
      });

      return updatedAttempt;
    } catch (error) {
      console.error('❌ Error completing collection attempt:', error);
      throw error;
    }
  }

  async getCollectorAttempts(collectorId: string, page = 1, limit = 20) {
    try {
      const skip = (page - 1) * limit;

      const [attempts, total] = await Promise.all([
        this.collectionAttemptModel.find({ collectorId })
          .sort({ acceptedAt: -1 })
          .skip(skip)
          .limit(limit)
          .exec(),
        this.collectionAttemptModel.countDocuments({ collectorId })
      ]);

      // Debug: Check if imageUrl exists in snapshots
      if (attempts.length > 0) {
        console.log('🔍 Sample attempt dropSnapshot:', {
          hasImageUrl: 'imageUrl' in (attempts[0].dropSnapshot || {}),
          imageUrl: attempts[0].dropSnapshot?.imageUrl,
          snapshotKeys: Object.keys(attempts[0].dropSnapshot || {}),
        });
      }

      return {
        attempts,
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      };
    } catch (error) {
      console.error('❌ Error getting collector attempts:', error);
      throw error;
    }
  }

  async getDropoffAttempts(dropoffId: string) {
    try {
      const attempts = await this.collectionAttemptModel.find({ dropoffId })
        .sort({ acceptedAt: 1 }) // Chronological order
        .exec();

      return attempts;
    } catch (error) {
      console.error('❌ Error getting dropoff attempts:', error);
      throw error;
    }
  }

  async getCollectionAttemptStats(collectorId: string) {
    try {
      const stats = await this.collectionAttemptModel.aggregate([
        { $match: { collectorId: new (require('mongoose').Types.ObjectId)(collectorId) } },
        {
          $group: {
            _id: null,
            totalAttempts: { $sum: 1 },
            successfulCollections: { $sum: { $cond: [{ $eq: ['$outcome', 'collected'] }, 1, 0] } },
            cancelledAttempts: { $sum: { $cond: [{ $eq: ['$outcome', 'cancelled'] }, 1, 0] } },
            expiredAttempts: { $sum: { $cond: [{ $eq: ['$outcome', 'expired'] }, 1, 0] } },
            activeAttempts: { $sum: { $cond: [{ $eq: ['$status', 'active'] }, 1, 0] } },
            averageDuration: { $avg: '$durationMinutes' }
          }
        }
      ]);

      const result = stats[0] || {
        totalAttempts: 0,
        successfulCollections: 0,
        cancelledAttempts: 0,
        expiredAttempts: 0,
        activeAttempts: 0,
        averageDuration: 0
      };

      result.successRate = result.totalAttempts > 0 
        ? Math.round((result.successfulCollections / result.totalAttempts) * 100) 
        : 0;

      return result;
    } catch (error) {
      console.error('❌ Error getting collection attempt stats:', error);
      throw error;
    }
  }

  private async checkAndUnlockExpiredAccounts() {
    try {
      const now = new Date();
      
      // Find all locked accounts where the lock has expired
      // Exclude permanently locked accounts (accountLockedUntil is null)
      const expiredLocks = await this.userModel.find({
        isAccountLocked: true,
        accountLockedUntil: { $ne: null, $lte: now }
      }).exec();
      
      if (expiredLocks.length === 0) {
        return;
      }
      
      console.log(`🔓 Found ${expiredLocks.length} expired account locks to unlock`);
      
      for (const user of expiredLocks) {
        // Unlock the account
        await this.userModel.updateOne(
          { _id: user._id },
          {
            isAccountLocked: false,
            accountLockedUntil: null,
          }
        ).exec();
        
        console.log(`✅ Auto-unlocked account: ${user._id} (${user.email})`);
        
        // Emit WebSocket event for real-time unlock notification
        const userId = String((user as any)._id);
        this.notificationsGateway.sendNotificationToUser(userId, {
          type: 'account_unlocked',
          title: 'Account Unlocked',
          message: 'Your account has been unlocked. You can start collecting again!',
          data: {
            isAccountLocked: false,
            accountLockedUntil: null,
            warningCount: user.warningCount,
          },
          timestamp: new Date(),
        });
        
        console.log(`📱 WebSocket unlock notification sent to ${user.email}`);
      }
    } catch (error) {
      console.error('❌ Error checking expired account locks:', error);
    }
  }

  /**
   * Report a drop (by collector)
   */
  async reportDrop(dropId: string, collectorId: string, reason: string, details?: string) {
    const report = await this.dropReportModel.create({
      dropId,
      reportedBy: collectorId,
      reason,
      details,
      status: ReportStatus.PENDING,
    });

    console.log(`📢 Drop ${dropId} reported by collector ${collectorId} for: ${reason}`);
    
    return report;
  }

  /**
   * Get all reports for a drop
   */
  async getDropReports(dropId: string) {
    return await this.dropReportModel.find({ dropId }).sort({ createdAt: -1 }).exec();
  }

  /**
   * Get all pending reports
   */
  async getPendingReports() {
    const reports = await this.dropReportModel
      .find({ status: 'pending' })
      .sort({ createdAt: -1 })
      .exec();
    
    return reports;
  }

  /**
   * Update collector's current location for an active collection attempt
   * @param attemptId - Collection attempt ID
   * @param location - Location data (latitude, longitude, accuracy, speed, heading)
   * @returns Updated collection attempt
   */
  async updateCollectorLocation(
    attemptId: string,
    location: {
      latitude: number;
      longitude: number;
      accuracy?: number;
      speed?: number;
      heading?: number;
    }
  ) {
    console.log(`📍 updateCollectorLocation called for attempt ${attemptId}:`, location);
    try {
      console.log(`📍 Updating collector location for attempt: ${attemptId}`);
      
      // Find the collection attempt
      const attempt = await this.collectionAttemptModel.findById(attemptId).exec();
      if (!attempt) {
        throw new NotFoundException('Collection attempt not found');
      }

      // Only allow updates for active attempts
      if (attempt.status !== 'active') {
        throw new BadRequestException('Cannot update location for completed collection attempt');
      }

      // Validate location coordinates
      if (location.latitude < -90 || location.latitude > 90) {
        throw new BadRequestException('Invalid latitude (must be between -90 and 90)');
      }
      if (location.longitude < -180 || location.longitude > 180) {
        throw new BadRequestException('Invalid longitude (must be between -180 and 180)');
      }

      // Update current collector location
      const now = new Date();
      const updatedAttempt = await this.collectionAttemptModel.findByIdAndUpdate(
        attemptId,
        {
          currentCollectorLocation: {
            latitude: location.latitude,
            longitude: location.longitude,
            accuracy: location.accuracy,
            timestamp: now,
            speed: location.speed,
            heading: location.heading,
          }
        },
        { new: true }
      ).exec();

      if (!updatedAttempt) {
        throw new NotFoundException('Collection attempt not found after update');
      }

      console.log(`✅ Collector location updated in database: ${location.latitude}, ${location.longitude}`);
      console.log(`📋 Updated attempt document:`, {
        attemptId: updatedAttempt._id.toString(),
        status: updatedAttempt.status,
        hasLocation: !!updatedAttempt.currentCollectorLocation,
        location: updatedAttempt.currentCollectorLocation,
      });

      // Get dropoff to find household user
      const dropoff = await this.dropoffModel.findById(attempt.dropoffId).exec();
      if (dropoff) {
        console.log(`📡 Broadcasting location to household user for dropoff: ${(dropoff as any)._id.toString()}`);
        // Broadcast location to household user via WebSocket
        await this.broadcastLocationToHousehold(
          (dropoff as any)._id.toString(),
          attempt._id.toString(),
          updatedAttempt.currentCollectorLocation!
        );
      } else {
        console.log(`⚠️ Dropoff not found for attempt: ${attempt.dropoffId}`);
      }

      return updatedAttempt;
    } catch (error) {
      console.error('❌ Error updating collector location:', error);
      throw error;
    }
  }

  /**
   * Get collector's current location for a collection attempt
   * @param attemptId - Collection attempt ID
   * @returns Current collector location or null
   */
  async getCollectorLocation(attemptId: string) {
    try {
      const attempt = await this.collectionAttemptModel.findById(attemptId).exec();
      if (!attempt) {
        throw new NotFoundException('Collection attempt not found');
      }

      return attempt.currentCollectorLocation || null;
    } catch (error) {
      console.error('❌ Error getting collector location:', error);
      throw error;
    }
  }

  /**
   * Broadcast collector location to household user via WebSocket
   * @param dropoffId - Dropoff ID
   * @param attemptId - Collection attempt ID
   * @param location - Current collector location
   */
  private async broadcastLocationToHousehold(
    dropoffId: string,
    attemptId: string,
    location: {
      latitude: number;
      longitude: number;
      accuracy?: number;
      timestamp: Date;
      speed?: number;
      heading?: number;
    }
  ) {
    try {
      // Get dropoff to find household user
      const dropoff = await this.dropoffModel.findById(dropoffId).populate('userId', '_id').exec();
      if (!dropoff) {
        console.log(`⚠️ Dropoff not found: ${dropoffId}`);
        return;
      }

      const dropoffDoc = dropoff as any;
      const householdUserId = dropoffDoc.userId?._id?.toString() || dropoffDoc.userId?.toString();
      if (!householdUserId) {
        console.log(`⚠️ Household user not found for dropoff: ${dropoffId}`);
        return;
      }

      // Calculate distance and ETA (optional - can be calculated on frontend)
      const dropLocation = dropoff.location.coordinates;
      const distanceRemaining = this.calculateDistance(
        location.latitude,
        location.longitude,
        dropLocation[1], // lat
        dropLocation[0]  // lng
      );

      // Broadcast to household user's WebSocket room
      this.notificationsGateway.server
        .to(`user:${householdUserId}`)
        .emit('collector_location_received', {
          dropoffId,
          attemptId,
          location: {
            latitude: location.latitude,
            longitude: location.longitude,
            accuracy: location.accuracy,
            timestamp: location.timestamp,
            speed: location.speed,
            heading: location.heading,
          },
          distanceRemaining, // meters
        });

      console.log(`📡 Broadcasted collector location to household user: ${householdUserId}`);
      
      // Also send Live Activity update with distance remaining
      try {
        const dropoffStatus = dropoff.status;
        console.log(`📤 [broadcastLocationToHousehold] Dropoff status: ${dropoffStatus}, checking if should send Live Activity update`);
        
        if (dropoffStatus === DropoffStatus.ACCEPTED) {
          // Get collector ID from the active CollectionAttempt
          const activeAttempt = await this.collectionAttemptModel.findOne({
            dropoffId: dropoffId,
            status: 'active'
          }).exec();
          
          let collectorName = 'Collector';
          if (activeAttempt) {
            const collector = await this.userModel.findById(activeAttempt.collectorId).exec();
            collectorName = collector?.name || 'Collector';
          }
          
          const statusKey = dropoffStatus.toLowerCase();
          const statusText = 'Accepted';
          
          console.log(`📤 [broadcastLocationToHousehold] Sending Live Activity update for dropoff ${dropoffId}`);
          console.log(`📤 [broadcastLocationToHousehold] Status: ${statusKey}, Distance: ${distanceRemaining.toFixed(2)}m, Collector: ${collectorName}`);
          
          await this.sendLiveActivityUpdate(dropoffId, {
            status: statusKey,
            statusText: statusText,
            collectorName: collectorName,
            timeAgo: 'Just now',
            distanceRemaining: distanceRemaining, // Include distance for pin position
          });
          console.log(`✅ [broadcastLocationToHousehold] Live Activity update sent with distance: ${distanceRemaining.toFixed(2)}m`);
        } else {
          console.log(`⏭️ [broadcastLocationToHousehold] Skipping Live Activity update - dropoff status is ${dropoffStatus}`);
        }
      } catch (error) {
        console.error('❌ [broadcastLocationToHousehold] Error sending Live Activity update with distance:', error);
        // Don't throw - this is a non-critical operation
      }
    } catch (error) {
      console.error('❌ Error broadcasting location to household:', error);
      // Don't throw - this is a non-critical operation
    }
  }

  /**
   * Calculate distance between two coordinates (Haversine formula)
   * @param lat1 - Latitude of first point
   * @param lon1 - Longitude of first point
   * @param lat2 - Latitude of second point
   * @param lon2 - Longitude of second point
   * @returns Distance in meters
   */
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371000; // Earth's radius in meters
    const dLat = this.toRadians(lat2 - lat1);
    const dLon = this.toRadians(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRadians(lat1)) *
        Math.cos(this.toRadians(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  /**
   * Convert degrees to radians
   */
  private toRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
  }

  /**
   * Store Live Activity push token
   */
  async storeLiveActivityToken(dropoffId: string, activityId: string, pushToken: string) {
    const dropoff = await this.dropoffModel.findById(dropoffId).exec();
    if (!dropoff) {
      throw new NotFoundException('Dropoff not found');
    }

    // Upsert the token (update if exists, create if not)
    const token = await this.liveActivityTokenModel.findOneAndUpdate(
      { dropoffId, activityId },
      {
        dropoffId,
        activityId,
        pushToken,
        userId: dropoff.userId,
        updatedAt: new Date(),
      },
      { upsert: true, new: true }
    ).exec();

    console.log(`✅ Live Activity push token stored: dropoffId=${dropoffId}, activityId=${activityId}`);
    return token;
  }

  /**
   * Send Live Activity push update
   * Determines if this is an update or end event based on status
   */
  private async sendLiveActivityUpdate(
    dropoffId: string,
    contentState: {
      status: string;
      statusText: string;
      collectorName?: string;
      timeAgo: string;
      distanceRemaining?: number; // Distance in meters
    }
  ) {
    try {
      // Find all active Live Activity tokens for this dropoff
      const tokens = await this.liveActivityTokenModel.find({ 
        dropoffId,
        isActive: { $ne: false } // Only active tokens
      }).exec();

      if (tokens.length === 0) {
        console.log(`⚠️ [sendLiveActivityUpdate] No active Live Activity tokens found for dropoff ${dropoffId}`);
        console.log(`⚠️ [sendLiveActivityUpdate] This means either:`);
        console.log(`   - No Live Activity was started for this dropoff`);
        console.log(`   - Push token was not sent from Flutter app`);
        console.log(`   - All tokens were marked as inactive`);
        return;
      }

      // Determine if this is an end event (collected, expired, cancelled)
      const isEndEvent = 
        contentState.status === 'collected' || 
        contentState.status === 'expired' || 
        contentState.status === 'cancelled';

      const event: 'update' | 'end' = isEndEvent ? 'end' : 'update';

      console.log(`📤 [sendLiveActivityUpdate] Sending Live Activity ${event} to ${tokens.length} token(s) for dropoff ${dropoffId}`);
      console.log(`📤 [sendLiveActivityUpdate] Content state:`, JSON.stringify(contentState, null, 2));

      // Send update/end to each Live Activity token
      for (const token of tokens) {
        try {
          console.log(`📤 [sendLiveActivityUpdate] Sending to token: ${token.pushToken.substring(0, 20)}... (activityId: ${token.activityId})`);
          const success = await this.fcmService.sendLiveActivityUpdate(
            token.pushToken, 
            contentState,
            event
          );
          console.log(`✅ [sendLiveActivityUpdate] Push notification ${success ? 'sent successfully' : 'failed'} for token ${token.activityId}`);

          // If it's an end event and successful, mark token as inactive
          if (isEndEvent && success) {
            await this.liveActivityTokenModel.findByIdAndUpdate(
              token._id,
              { isActive: false },
              { new: true }
            ).exec();
            console.log(`✅ Marked Live Activity token as inactive: ${token.activityId}`);
          }

          // If token is invalid, mark as inactive
          if (!success) {
            // Check if it's an invalid token error (handled in FCMService)
            // Mark as inactive to prevent future attempts
            await this.liveActivityTokenModel.findByIdAndUpdate(
              token._id,
              { isActive: false },
              { new: true }
            ).exec();
          }
        } catch (error) {
          console.error(`❌ Error sending Live Activity update to token ${token.pushToken.substring(0, 20)}...: ${error}`);
          // Mark token as inactive on error
          try {
            await this.liveActivityTokenModel.findByIdAndUpdate(
              token._id,
              { isActive: false },
              { new: true }
            ).exec();
          } catch (updateError) {
            console.error(`❌ Error marking token as inactive: ${updateError}`);
          }
        }
      }
    } catch (error) {
      console.error(`❌ Error sending Live Activity update: ${error}`);
    }
  }
} 