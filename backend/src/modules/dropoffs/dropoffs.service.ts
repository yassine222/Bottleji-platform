import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Dropoff } from './schemas/dropoff.schema';
import { CollectorInteraction } from './schemas/collector-interaction.schema';
import { CreateDropoffDto } from './dto/create-dropoff.dto';
import { DropoffStatus, CancellationReason } from './schemas/dropoff.schema';
import { InteractionType } from './schemas/collector-interaction.schema';
import { User } from '../users/schemas/user.schema';

@Injectable()
export class DropoffsService {
  constructor(
    @InjectModel(Dropoff.name) private dropoffModel: Model<Dropoff>,
    @InjectModel(CollectorInteraction.name) private interactionModel: Model<CollectorInteraction>,
    @InjectModel(User.name) private userModel: Model<User>,
  ) {
    this.startCleanupTask();
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

  private startCleanupTask() {
    console.log('🚀 Starting cleanup task - will run every 1 minute (TESTING MODE)');
    
    // TESTING: Run cleanup every 1 minute (was 10 minutes)
    // TODO: Change back to 10 minutes for production
    setInterval(async () => {
      try {
        console.log('⏰ Cleanup task triggered at:', new Date().toISOString());
        const cleanedCount = await this.cleanupExpiredAcceptedDrops();
        if (cleanedCount > 0) {
          console.log(`🧹 Cleaned up ${cleanedCount} expired accepted drops`);
        } else {
          console.log('🧹 No expired drops found to clean up');
        }
      } catch (error) {
        console.error('❌ Error during cleanup task:', error);
      }
    }, 1 * 60 * 1000); // TESTING: 1 minute (was 10 * 60 * 1000)
    
    // Also run cleanup immediately on startup
    setTimeout(async () => {
      try {
        console.log('🚀 Running initial cleanup check...');
        const cleanedCount = await this.cleanupExpiredAcceptedDrops();
        if (cleanedCount > 0) {
          console.log(`🧹 Initial cleanup: ${cleanedCount} expired drops processed`);
        } else {
          console.log('🧹 Initial cleanup: No expired drops found');
        }
      } catch (error) {
        console.error('❌ Error during initial cleanup:', error);
      }
    }, 5000); // Run after 5 seconds
  }

  async create(createDropoffDto: CreateDropoffDto) {
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

      console.log('findAvailableForCollectors query:', JSON.stringify(query, null, 2));
      console.log('excludeCollectorId:', excludeCollectorId);

      const result = await this.dropoffModel.find(query).exec();
      
      console.log('findAvailableForCollectors result count:', result.length);
      console.log('findAvailableForCollectors result:', result.map(d => ({
        id: d._id,
        status: d.status,
        userId: d.userId,
        cancelledByCollectorIds: d.cancelledByCollectorIds,
        isSuspicious: d.isSuspicious,
        cancellationCount: d.cancellationCount,
      })));

      return result;
    } catch (error) {
      console.error('Error in findAvailableForCollectors:', error);
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
    const dropoffIds = acceptedInteractions.map(interaction => interaction.dropoffId);

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
      { status: DropoffStatus.COLLECTED },
      { new: true },
    ).exec();

    // Create interaction for collection
    const interaction = await this.createInteraction({
      collectorId: acceptedInteraction.collectorId,
      dropoffId: id,
      interactionType: InteractionType.COLLECTED,
      interactionTime: new Date(),
      dropoffStatus: DropoffStatus.COLLECTED, // Set to COLLECTED, not the old status
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

    return updatedDropoff;
  }

  async cancelAcceptedDrop(id: string, reason?: string, cancelledByCollectorId?: string): Promise<Dropoff> {
    const dropoff = await this.dropoffModel.findById(id).exec();
    if (!dropoff) {
      throw new NotFoundException(`Dropoff with ID ${id} not found`);
    }

    if (dropoff.status !== DropoffStatus.ACCEPTED) {
      throw new BadRequestException('Only accepted dropoffs can be cancelled');
    }

    // Increment cancellation count
    const newCancellationCount = (dropoff.cancellationCount || 0) + 1;
    
    // Check if this drop should be marked as suspicious (3 or more cancellations)
    const isSuspicious = newCancellationCount >= 3;
    
    // Determine the new status based on cancellation count
    let newStatus = DropoffStatus.PENDING; // Default to PENDING
    if (newCancellationCount >= 3) {
      newStatus = DropoffStatus.CANCELLED; // Only set to CANCELLED if 3+ cancellations
    }

    // Add the collector ID to the cancelledByCollectorIds array
    const currentCancelledIds = dropoff.cancelledByCollectorIds || [];
    const updatedCancelledIds = cancelledByCollectorId 
      ? [...currentCancelledIds, cancelledByCollectorId]
      : currentCancelledIds;

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
      cancellationHistoryLength: updatedCancellationHistory.length,
    });

    // Prepare update data
    const updateData: any = {
      cancellationCount: newCancellationCount,
      isSuspicious: isSuspicious,
      cancelledByCollectorIds: updatedCancelledIds,
      cancellationHistory: updatedCancellationHistory,
    };

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
      // FOR TESTING: Using 1 minute timeout
      // TODO: Change back to dynamic calculation for production
      const routeDurationMinutes = 1; // TESTING: 1 minute (was 20 minutes)
      
      // Fixed buffer based on route duration
      let bufferMinutes = 0; // TESTING: No buffer (was 10-20 minutes)
      
      const totalTimeoutMinutes = routeDurationMinutes + bufferMinutes; // TESTING: 1 minute total
      
      const timeoutThreshold = new Date(interaction.interactionTime.getTime() + (totalTimeoutMinutes * 60 * 1000));
      
      console.log(`⏰ Route duration: ${routeDurationMinutes}min, Buffer: ${bufferMinutes}min, Total timeout: ${totalTimeoutMinutes}min`);
      console.log(`⏰ Timeout threshold: ${timeoutThreshold}`);
      console.log(`⏰ Should expire: ${now > timeoutThreshold}`);
      
      if (now > timeoutThreshold) {
        console.log(`🔄 Processing expired drop ${dropoff._id} for collector ${interaction.collectorId}`);
        
        // Check if EXPIRED interaction already exists for this drop
        const existingExpiredInteraction = await this.interactionModel.findOne({
          dropoffId: interaction.dropoffId,
          interactionType: InteractionType.EXPIRED,
          collectorId: interaction.collectorId,
        }).exec();

        if (existingExpiredInteraction) {
          console.log(`⚠️ EXPIRED interaction already exists for drop ${dropoff._id} and collector ${interaction.collectorId}`);
          // Delete the orphaned ACCEPTED interaction since we already have the EXPIRED one
          await this.interactionModel.findByIdAndDelete(interaction._id).exec();
          console.log(`🗑️ Deleted orphaned ACCEPTED interaction ${interaction._id}`);
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
          
          // Delete the old ACCEPTED interaction now that we've created the EXPIRED one
          await this.interactionModel.findByIdAndDelete(interaction._id).exec();
          console.log(`🗑️ Deleted old ACCEPTED interaction ${interaction._id}`);
          
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

      // Add warning
      const warning = {
        type: penaltyType,
        reason: 'Collection timeout - did not complete drop within allocated time',
        timestamp: new Date(),
      };

      // Update user with new warning
      const updatedUser = await UserModel.findByIdAndUpdate(
        collectorId,
        {
          $inc: { warningCount: 1 },
          $push: { warnings: warning },
          $set: {
            isAccountLocked: collector.warningCount + 1 >= 5,
            accountLockedUntil: collector.warningCount + 1 >= 5 ? new Date(Date.now() + 24 * 60 * 60 * 1000) : undefined, // 24 hours lock
          }
        },
        { new: true }
      );

      if (updatedUser) {
        console.log(`Penalty added to collector ${collectorId}: ${penaltyType}`);
        console.log(`Warning count: ${updatedUser.warningCount}/5`);
        
        if (updatedUser.isAccountLocked) {
          console.log(`Account ${collectorId} locked until ${updatedUser.accountLockedUntil}`);
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

    // Get all interactions for this collector
    const interactions = await this.interactionModel.find({
      collectorId,
      interactionTime: { $gte: startDate }
    }).populate('dropoffId').exec();

    // Group interactions by dropoffId to determine final status
    const dropoffStatusMap = new Map();

    interactions.forEach(interaction => {
      const dropoffId = interaction.dropoffId.toString();
      const currentStatus = dropoffStatusMap.get(dropoffId);
      
      // Priority: COLLECTED > CANCELLED > EXPIRED > ACCEPTED
      // Only update if the new status has higher priority
      if (!currentStatus || this.getStatusPriority(interaction.interactionType) > this.getStatusPriority(currentStatus)) {
        dropoffStatusMap.set(dropoffId, interaction.interactionType);
      }
    });

    // Count drops by their final status
    let acceptedCount = 0;
    let collectedCount = 0;
    let cancelledCount = 0;
    let expiredCount = 0;

    dropoffStatusMap.forEach((finalStatus) => {
      switch (finalStatus) {
        case InteractionType.ACCEPTED:
          acceptedCount++;
          break;
        case InteractionType.COLLECTED:
          collectedCount++;
          break;
        case InteractionType.CANCELLED:
          cancelledCount++;
          break;
        case InteractionType.EXPIRED:
          expiredCount++;
          break;
      }
    });

    // Debug logging
    console.log('🔍 Enhanced Stats Debug for collector:', collectorId);
    console.log('📊 Total unique drops:', dropoffStatusMap.size);
    console.log('📊 Final status counts - Accepted:', acceptedCount, 'Collected:', collectedCount, 'Cancelled:', cancelledCount, 'Expired:', expiredCount);
    console.log('📊 Dropoff status map:', Object.fromEntries(dropoffStatusMap));

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

    // Calculate collection rate (collected / accepted)
    if (acceptedCount > 0) {
      stats.collectionRate = (collectedCount / acceptedCount) * 100;
    }

    // Calculate average collection time
    if (collectedCount > 0) {
      const totalTime: number = Array.from(dropoffStatusMap.entries())
        .filter(([_, status]) => status === InteractionType.COLLECTED)
        .reduce<number>((sum: number, [dropoffId, _]) => {
          const collectedInteraction = interactions.find(i => 
            i.dropoffId.toString() === dropoffId && i.interactionType === InteractionType.COLLECTED
          );
          const acceptedInteraction = interactions.find(i => 
            i.dropoffId.toString() === dropoffId && i.interactionType === InteractionType.ACCEPTED
          );
          if (collectedInteraction && acceptedInteraction) {
            return sum + (collectedInteraction.interactionTime.getTime() - acceptedInteraction.interactionTime.getTime());
          }
          return sum;
        }, 0);
      stats.averageCollectionTime = totalTime / collectedCount;
    }

    // Calculate cancellation reasons
    const cancelledInteractions = interactions.filter(i => i.interactionType === InteractionType.CANCELLED);
    cancelledInteractions.forEach(interaction => {
      const reason = interaction.cancellationReason || 'unknown';
      stats.cancellationReasons[reason] = (stats.cancellationReasons[reason] || 0) + 1;
    });

    return stats;
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

    // Get all drops created by this user (same query as findByUser but with optional date filter)
    const query: any = { userId };
    
    // Only add date filter if not "all time"
    if (timeRange && timeRange !== 'all' && timeRange !== '') {
      query.createdAt = { $gte: startDate };
    }
    
    const userDrops = await this.dropoffModel.find(query).exec();

    // Count drops by their current status
    let pendingCount = 0;
    let acceptedCount = 0;
    let collectedCount = 0;
    let cancelledCount = 0;
    let expiredCount = 0;

    userDrops.forEach(drop => {
      switch (drop.status) {
        case DropoffStatus.PENDING:
          pendingCount++;
          break;
        case DropoffStatus.ACCEPTED:
          acceptedCount++;
          break;
        case DropoffStatus.COLLECTED:
          collectedCount++;
          break;
        case DropoffStatus.CANCELLED:
          cancelledCount++;
          break;
        case DropoffStatus.EXPIRED:
          expiredCount++;
          break;
      }
    });

    // Debug logging
    console.log('🔍 User Drop Stats Debug for user:', userId);
    console.log('📊 Total drops created:', userDrops.length);
    console.log('📊 Status counts - Pending:', pendingCount, 'Accepted:', acceptedCount, 'Collected:', collectedCount, 'Cancelled:', cancelledCount, 'Expired:', expiredCount);

    const stats = {
      total: userDrops.length,
      pending: pendingCount,
      accepted: acceptedCount,
      collected: collectedCount,
      cancelled: cancelledCount,
      expired: expiredCount,
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
} 