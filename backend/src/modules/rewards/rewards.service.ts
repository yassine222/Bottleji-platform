import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { RewardItem, RewardItemDocument, RewardCategory } from './schemas/reward-item.schema';
import { RewardRedemption, RewardRedemptionDocument, RedemptionStatus } from './schemas/reward-redemption.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CollectionAttempt, CollectionAttemptDocument } from '../dropoffs/schemas/collection-attempt.schema';
import { CreateRedemptionDto, UpdateRedemptionStatusDto } from './dto/reward-redemption.dto';
import { CreateRewardItemDto, UpdateRewardItemDto } from './dto/reward-item.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationsGateway } from '../notifications/notifications.gateway';

export interface RewardItemFilters {
  category?: RewardCategory;
  subCategory?: string;
  isActive?: boolean;
  minPointCost?: number;
  maxPointCost?: number;
  search?: string;
  page?: number;
  limit?: number;
}

@Injectable()
export class RewardsService {
  constructor(
    @InjectModel(RewardItem.name) private rewardItemModel: Model<RewardItemDocument>,
    @InjectModel(RewardRedemption.name) private redemptionModel: Model<RewardRedemptionDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(CollectionAttempt.name) private collectionAttemptModel: Model<CollectionAttemptDocument>,
    private notificationsService: NotificationsService,
    private notificationsGateway: NotificationsGateway,
  ) {}

  /**
   * Create a new reward item
   */
  async create(createRewardItemDto: CreateRewardItemDto): Promise<RewardItem> {
    try {
      const rewardItem = new this.rewardItemModel(createRewardItemDto);
      return await rewardItem.save();
    } catch (error) {
      throw new BadRequestException('Failed to create reward item: ' + error.message);
    }
  }

  /**
   * Get all reward items with optional filtering
   */
  async findAll(filters: RewardItemFilters = {}): Promise<{
    items: RewardItem[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }> {
    const {
      category,
      subCategory,
      isActive,
      minPointCost,
      maxPointCost,
      search,
      page = 1,
      limit = 10,
    } = filters;

    // Build query
    const query: any = {};

    if (category) query.category = category;
    if (subCategory) query.subCategory = subCategory;
    if (isActive !== undefined) query.isActive = isActive;
    if (minPointCost !== undefined || maxPointCost !== undefined) {
      query.pointCost = {};
      if (minPointCost !== undefined) query.pointCost.$gte = minPointCost;
      if (maxPointCost !== undefined) query.pointCost.$lte = maxPointCost;
    }
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }

    // Calculate pagination
    const skip = (page - 1) * limit;
    const total = await this.rewardItemModel.countDocuments(query);
    const totalPages = Math.ceil(total / limit);

    // Execute query
    const items = await this.rewardItemModel
      .find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .exec();

    return {
      items,
      total,
      page,
      limit,
      totalPages,
    };
  }

  /**
   * Get a single reward item by ID
   */
  async findOne(id: string): Promise<RewardItem> {
    const rewardItem = await this.rewardItemModel.findById(id).exec();
    if (!rewardItem) {
      throw new NotFoundException(`Reward item with ID ${id} not found`);
    }
    return rewardItem;
  }

  /**
   * Update a reward item
   */
  async update(id: string, updateRewardItemDto: UpdateRewardItemDto): Promise<RewardItem> {
    try {
      const rewardItem = await this.rewardItemModel
        .findByIdAndUpdate(id, updateRewardItemDto, { new: true })
        .exec();
      
      if (!rewardItem) {
        throw new NotFoundException(`Reward item with ID ${id} not found`);
      }
      
      return rewardItem;
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException('Failed to update reward item: ' + error.message);
    }
  }

  /**
   * Delete a reward item
   */
  async remove(id: string): Promise<void> {
    const result = await this.rewardItemModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException(`Reward item with ID ${id} not found`);
    }
  }

  /**
   * Toggle active status of a reward item
   */
  async toggleActive(id: string): Promise<RewardItem> {
    const rewardItem = await this.findOne(id);
    return await this.update(id, { isActive: !rewardItem.isActive });
  }

  /**
   * Update stock of a reward item
   */
  async updateStock(id: string, newStock: number): Promise<RewardItem> {
    if (newStock < 0) {
      throw new BadRequestException('Stock cannot be negative');
    }
    return await this.update(id, { stock: newStock });
  }

  /**
   * Get reward item statistics
   */
  async getStats(): Promise<{
    totalItems: number;
    activeItems: number;
    inactiveItems: number;
    totalStock: number;
    categories: { [key: string]: number };
    subCategories: { [key: string]: number };
  }> {
    const totalItems = await this.rewardItemModel.countDocuments();
    const activeItems = await this.rewardItemModel.countDocuments({ isActive: true });
    const inactiveItems = totalItems - activeItems;

    const stockAggregation = await this.rewardItemModel.aggregate([
      { $group: { _id: null, totalStock: { $sum: '$stock' } } }
    ]);
    const totalStock = stockAggregation[0]?.totalStock || 0;

    const categoryStats = await this.rewardItemModel.aggregate([
      { $group: { _id: '$category', count: { $sum: 1 } } }
    ]);
    const categories = categoryStats.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {});

    const subCategoryStats = await this.rewardItemModel.aggregate([
      { $group: { _id: '$subCategory', count: { $sum: 1 } } }
    ]);
    const subCategories = subCategoryStats.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {});

    return {
      totalItems,
      activeItems,
      inactiveItems,
      totalStock,
      categories,
      subCategories,
    };
  }

  /**
   * Get reward items by category
   */
  async findByCategory(category: RewardCategory): Promise<RewardItem[]> {
    return await this.rewardItemModel
      .find({ category, isActive: true })
      .sort({ pointCost: 1 })
      .exec();
  }

  /**
   * Get reward items by sub-category
   */
  async findBySubCategory(subCategory: string): Promise<RewardItem[]> {
    return await this.rewardItemModel
      .find({ subCategory, isActive: true })
      .sort({ pointCost: 1 })
      .exec();
  }

  /**
   * Award points for a successful drop collection (Collector role)
   * This method is called by the dropoffs service
   */
  async awardPointsForCollection(collectorId: string, dropId: string): Promise<{
    pointsAwarded: number;
    newTier: any;
    tierUpgraded: boolean;
    totalPoints: number;
    totalDrops: number;
  }> {
    try {
      console.log(`🎉 Awarding points to collector ${collectorId} for drop ${dropId}`);
      
      // Find the collector user
      const collector = await this.userModel.findById(collectorId).exec();
      if (!collector) {
        throw new Error(`Collector with ID ${collectorId} not found`);
      }

    // Calculate points to award based on current tier
    const tierInfo = this.calculateTier(collector.totalDropsCollected || 0);
    const pointsToAward = tierInfo.pointsPerDrop;
      
      // Update collector's points and stats
      const updatedCollector = await this.userModel.findByIdAndUpdate(
        collectorId,
        {
          $inc: {
            currentPoints: pointsToAward,
            totalPointsEarned: pointsToAward,
            totalDropsCollected: 1
          },
          $set: {
            lastDropCollectedAt: new Date()
          }
        },
        { new: true }
      ).exec();

      if (!updatedCollector) {
        throw new Error(`Failed to update collector ${collectorId}`);
      }

      // Calculate new tier based on total points
      const newTier = this.calculateTier(updatedCollector.totalPointsEarned);
      const tierUpgraded = newTier.tier > collector.currentTier;
      
      // Update tier if upgraded
      if (tierUpgraded) {
        await this.userModel.findByIdAndUpdate(
          collectorId,
          { currentTier: newTier.tier },
          { new: true }
        ).exec();
      }

      // Add to reward history (collector rewards don't have a type field, but have collectedAt)
      await this.userModel.findByIdAndUpdate(
        collectorId,
        {
          $push: {
            rewardHistory: {
              dropId: dropId,
              pointsAwarded: pointsToAward,
              tier: newTier.tier,
              tierUpgraded: tierUpgraded,
              collectedAt: new Date(),
              // No type field for collector rewards
            }
          }
        }
      ).exec();

      console.log(`✅ Points awarded successfully:`, {
        collectorId,
        pointsAwarded: pointsToAward,
        totalPoints: updatedCollector.currentPoints,
        newTier: newTier.name,
        tierUpgraded
      });

      return {
        pointsAwarded: pointsToAward,
        newTier: newTier,
        tierUpgraded: tierUpgraded,
        totalPoints: updatedCollector.currentPoints,
        totalDrops: updatedCollector.totalDropsCollected
      };
    } catch (error) {
      console.error('❌ Error awarding points to collector:', error);
      throw error;
    }
  }

  /**
   * Award points for a drop being collected (Household role)
   * This method is called by the dropoffs service
   */
  async awardPointsForDropCollected(householdId: string, dropId: string): Promise<{
    pointsAwarded: number;
    newTier: any;
    tierUpgraded: boolean;
    totalPoints: number;
    totalDrops: number;
    totalDropsCreated: number;
  }> {
    try {
      console.log(`🎉 Awarding points to household ${householdId} for drop ${dropId} being collected`);
      
      // Find the household user
      const household = await this.userModel.findById(householdId).exec();
      if (!household) {
        throw new Error(`Household user with ID ${householdId} not found`);
      }

      // Calculate points to award based on current tier (household users get half the collector points)
      const tierInfo = this.calculateTier(household.totalDropsCreated || 0);
      const pointsToAward = Math.floor(tierInfo.pointsPerDrop / 2);
      
      // Update household's points and stats
      const updatedHousehold = await this.userModel.findByIdAndUpdate(
        householdId,
        {
          $inc: {
            currentPoints: pointsToAward,
            totalPointsEarned: pointsToAward,
            totalDropsCreated: 1
          },
          $set: {
            lastDropCreatedAt: new Date()
          }
        },
        { new: true }
      ).exec();

      if (!updatedHousehold) {
        throw new Error(`Failed to update household user ${householdId}`);
      }

      // Calculate new tier based on total points
      const newTier = this.calculateTier(updatedHousehold.totalPointsEarned);
      const tierUpgraded = newTier.tier > household.currentTier;
      
      // Update tier if upgraded
      if (tierUpgraded) {
        await this.userModel.findByIdAndUpdate(
          householdId,
          { currentTier: newTier.tier },
          { new: true }
        ).exec();
      }

      // Add to reward history (household rewards have type: 'household_drop_collected')
      await this.userModel.findByIdAndUpdate(
        householdId,
        {
          $push: {
            rewardHistory: {
              dropId: dropId,
              pointsAwarded: pointsToAward,
              tier: newTier.tier,
              tierUpgraded: tierUpgraded,
              type: 'household_drop_collected',
              collectedAt: new Date(),
            }
          }
        }
      ).exec();

      console.log(`✅ Points awarded successfully to household:`, {
        householdId,
        pointsAwarded: pointsToAward,
        totalPoints: updatedHousehold.currentPoints,
        newTier: newTier.name,
        tierUpgraded
      });

      return {
        pointsAwarded: pointsToAward,
        newTier: newTier,
        tierUpgraded: tierUpgraded,
        totalPoints: updatedHousehold.currentPoints,
        totalDrops: updatedHousehold.totalDropsCollected,
        totalDropsCreated: updatedHousehold.totalDropsCreated
      };
    } catch (error) {
      console.error('❌ Error awarding points to household:', error);
      throw error;
    }
  }

  /**
   * Calculate tier based on total points earned
   */
  private calculateTier(totalDropsCollected: number): { tier: number; name: string; pointsPerDrop: number } {
    if (totalDropsCollected >= 4000) {
      return { tier: 5, name: 'Diamond Collector', pointsPerDrop: 50 };
    } else if (totalDropsCollected >= 3000) {
      return { tier: 4, name: 'Platinum Collector', pointsPerDrop: 40 };
    } else if (totalDropsCollected >= 2000) {
      return { tier: 3, name: 'Gold Collector', pointsPerDrop: 30 };
    } else if (totalDropsCollected >= 1000) {
      return { tier: 2, name: 'Silver Collector', pointsPerDrop: 20 };
    } else {
      return { tier: 1, name: 'Bronze Collector', pointsPerDrop: 10 };
    }
  }

  /**
   * Get user's reward stats
   */
  async getUserRewardStats(userId: string): Promise<any> {
    try {
      // Get user's actual points from their profile
      const user = await this.userModel.findById(userId).exec();
      if (!user) {
        throw new Error('User not found');
      }

      // Calculate points from collection history
      const collectionAttempts = await this.collectionAttemptModel.find({ collectorId: userId }).exec();
      const totalCollections = collectionAttempts.length;
      const totalPoints = user.totalPointsEarned || 0;
      const currentTier = user.currentTier || 1;
      
      // Calculate tier information using the calculateTier method
      const tierInfo = this.calculateTier(totalCollections);
      const pointsToNextTier = Math.max(0, (tierInfo.tier * 1000) - totalCollections);

      // Get recent redemptions (mock for now, would need redemption model)
      const recentRedemptions = [];

      return {
        totalPoints,
        currentTier: {
          tier: tierInfo.tier,
          name: tierInfo.name,
          pointsPerDrop: tierInfo.pointsPerDrop
        },
        tierName: tierInfo.name,
        pointsToNextTier,
        totalRedemptions: recentRedemptions.length,
        currentPoints: user.currentPoints || 0,
        totalCollections,
        recentRedemptions
      };
    } catch (error) {
      console.error('Error getting user reward stats:', error);
      // Return fallback data
      return {
        totalPoints: 0,
        currentTier: {
          tier: 1,
          name: 'Bronze Collector',
          pointsPerDrop: 8
        },
        tierName: 'Bronze Collector',
        pointsToNextTier: 100,
        totalRedemptions: 0,
        currentPoints: 0,
        totalCollections: 0,
        recentRedemptions: []
      };
    }
  }

  /**
   * Get available reward items for users
   */
  async findAvailableForUser(filters?: {
    category?: string;
    subCategory?: string;
    isActive?: boolean;
  }): Promise<RewardItem[]> {
    const query: any = {};
    
    if (filters?.isActive !== undefined) {
      query.isActive = filters.isActive;
    } else {
      query.isActive = true; // Default to active items only
    }
    
    if (filters?.category) {
      query.category = filters.category;
    }
    
    if (filters?.subCategory) {
      query.subCategory = filters.subCategory;
    }
    
    return await this.rewardItemModel.find(query).exec();
  }


  /**
   * Redeem a reward item
   */
  async redeemReward(createRedemptionDto: CreateRedemptionDto): Promise<RewardRedemption> {
    const { userId, rewardItemId, pointsSpent, deliveryAddress, selectedSize, sizeType } = createRedemptionDto;

    // Check if user exists and has enough points
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.currentPoints < pointsSpent) {
      throw new BadRequestException('Insufficient points');
    }

    // Check if reward item exists and is available
    const rewardItem = await this.rewardItemModel.findById(rewardItemId).exec();
    if (!rewardItem) {
      throw new NotFoundException('Reward item not found');
    }

    if (!rewardItem.isActive) {
      throw new BadRequestException('Reward item is not active');
    }

    if (rewardItem.stock <= 0) {
      throw new BadRequestException('Reward item is out of stock');
    }

    if (rewardItem.pointCost !== pointsSpent) {
      throw new BadRequestException('Point cost mismatch');
    }

    // Start a transaction to ensure atomicity
    const session = await this.rewardItemModel.db.startSession();
    session.startTransaction();

    try {
      // Deduct points from user
      await this.userModel.findByIdAndUpdate(
        userId,
        { $inc: { currentPoints: -pointsSpent } },
        { session }
      ).exec();

      // Reduce stock
      await this.rewardItemModel.findByIdAndUpdate(
        rewardItemId,
        { 
          $inc: { 
            stock: -1,
            totalRedemptions: 1
          } 
        },
        { session }
      ).exec();

      // Create redemption record
      const redemption = new this.redemptionModel({
        userId,
        rewardItemId,
        rewardItemName: rewardItem.name,
        pointsSpent,
        status: RedemptionStatus.PENDING,
        deliveryAddress,
        selectedSize,
        sizeType,
      });

      const savedRedemption = await redemption.save({ session });

      await session.commitTransaction();

      return savedRedemption;
    } catch (error) {
      // Abort transaction if it's still active
      if (session.inTransaction()) {
        try {
          await session.abortTransaction();
        } catch (abortError) {
          console.error('Error aborting transaction:', abortError);
        }
      }
      throw error;
    } finally {
      // Always end session, even if there's an error
      try {
        await session.endSession();
      } catch (endError) {
        console.error('Error ending session:', endError);
      }
    }
  }

  /**
   * Get user's redemption history
   */
  async getUserRedemptions(userId: string): Promise<RewardRedemption[]> {
    return this.redemptionModel
      .find({ userId })
      .populate('rewardItemId', 'name imageUrl')
      .sort({ createdAt: -1 })
      .exec();
  }

  /**
   * Get all redemptions (admin)
   */
  async getAllRedemptions(filters?: {
    status?: RedemptionStatus;
    userId?: string;
    page?: number;
    limit?: number;
  }): Promise<{ redemptions: RewardRedemption[]; total: number }> {
    try {
      console.log('🔍 getAllRedemptions called');
      console.log('🔍 redemptionModel exists:', !!this.redemptionModel);
      
      const query: any = {};
      
      if (filters?.status) {
        query.status = filters.status;
      }
      
      if (filters?.userId) {
        query.userId = filters.userId;
      }

      const page = filters?.page || 1;
      const limit = filters?.limit || 10;
      const skip = (page - 1) * limit;

      console.log('🔍 About to query database');
      const redemptions = await this.redemptionModel
        .find(query)
        .populate('userId', 'name email phoneNumber roles')
        .populate('rewardItemId', 'name imageUrl')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec();
      console.log('🔍 Found redemptions:', redemptions.length);
      
      const total = await this.redemptionModel.countDocuments(query).exec();
      console.log('🔍 Total count:', total);

      return { redemptions, total };
    } catch (error) {
      console.error('❌ Error in getAllRedemptions:', error);
      console.error('❌ Error stack:', error.stack);
      throw error;
    }
  }

  /**
   * Get redemption by ID (admin)
   */
  async getRedemptionById(redemptionId: string): Promise<RewardRedemption> {
    const redemption = await this.redemptionModel
      .findById(redemptionId)
      .populate('userId', 'email firstName lastName')
      .populate('rewardItemId', 'name imageUrl')
      .exec();

    if (!redemption) {
      throw new NotFoundException('Redemption not found');
    }

    return redemption;
  }

  /**
   * Update redemption status (admin)
   */
  async updateRedemptionStatus(
    redemptionId: string, 
    updateDto: UpdateRedemptionStatusDto
  ): Promise<RewardRedemption> {
    const redemption = await this.redemptionModel.findById(redemptionId).exec();
    if (!redemption) {
      throw new NotFoundException('Redemption not found');
    }

    const updateData: any = {
      status: updateDto.status,
      adminNotes: updateDto.adminNotes,
      rejectionReason: updateDto.rejectionReason,
      trackingNumber: updateDto.trackingNumber,
      estimatedDelivery: updateDto.estimatedDelivery,
    };

    // Set timestamp based on status
    const now = new Date();
    switch (updateDto.status) {
      case 'approved':
        updateData.approvedAt = now;
        break;
      case 'processing':
        updateData.processingAt = now;
        break;
      case 'shipped':
        updateData.shippedAt = now;
        break;
      case 'delivered':
        updateData.deliveredAt = now;
        break;
      case 'cancelled':
        updateData.cancelledAt = now;
        break;
      case 'rejected':
        updateData.rejectedAt = now;
        break;
    }

    const updatedRedemption = await this.redemptionModel
      .findByIdAndUpdate(redemptionId, updateData, { new: true })
      .populate('userId', 'email firstName lastName')
      .populate('rewardItemId', 'name imageUrl')
      .exec();

    if (!updatedRedemption) {
      throw new NotFoundException('Redemption not found');
    }

    return updatedRedemption;
  }

  /**
   * Cancel redemption (user)
   */
  async cancelRedemption(redemptionId: string, userId: string): Promise<RewardRedemption> {
    const redemption = await this.redemptionModel.findOne({
      _id: redemptionId,
      userId,
      status: { $in: [RedemptionStatus.PENDING, RedemptionStatus.APPROVED] }
    }).exec();

    if (!redemption) {
      throw new NotFoundException('Redemption not found or cannot be cancelled');
    }

    // Start transaction to refund points and restore stock
    const session = await this.rewardItemModel.db.startSession();
    session.startTransaction();

    try {
      // Refund points to user
      await this.userModel.findByIdAndUpdate(
        userId,
        { $inc: { currentPoints: redemption.pointsSpent } },
        { session }
      ).exec();

      // Restore stock
      await this.rewardItemModel.findByIdAndUpdate(
        redemption.rewardItemId,
        { 
          $inc: { 
            stock: 1,
            totalRedemptions: -1
          } 
        },
        { session }
      ).exec();

      // Update redemption status
      const updatedRedemption = await this.redemptionModel
        .findByIdAndUpdate(
          redemptionId,
          { 
            status: RedemptionStatus.CANCELLED,
            cancelledAt: new Date()
          },
          { new: true, session }
        )
        .populate('userId', 'email firstName lastName')
        .populate('rewardItemId', 'name imageUrl')
        .exec();

      if (!updatedRedemption) {
        throw new NotFoundException('Redemption not found');
      }

      await session.commitTransaction();
      return updatedRedemption;
    } catch (error) {
      // Abort transaction if it's still active
      if (session.inTransaction()) {
        try {
          await session.abortTransaction();
        } catch (abortError) {
          console.error('Error aborting transaction:', abortError);
        }
      }
      throw error;
    } finally {
      // Always end session, even if there's an error
      try {
        await session.endSession();
      } catch (endError) {
        console.error('Error ending session:', endError);
      }
    }
  }

  /**
   * Reject redemption with reason, refund points, restore stock, and send notification
   */
  async rejectRedemption(redemptionId: string, reason: string): Promise<RewardRedemption> {
    const session = await this.redemptionModel.db.startSession();
    
    try {
      await session.startTransaction();

      // Get the redemption with populated data
      const redemption = await this.redemptionModel
        .findById(redemptionId)
        .populate('userId', 'email name')
        .populate('rewardItemId', 'name stock')
        .session(session)
        .exec();

      if (!redemption) {
        throw new NotFoundException('Redemption not found');
      }

      if (redemption.status !== RedemptionStatus.PENDING) {
        throw new BadRequestException('Only pending redemptions can be rejected');
      }

      // Refund points to user
      await this.userModel.findByIdAndUpdate(
        redemption.userId,
        { $inc: { currentPoints: redemption.pointsSpent } },
        { session }
      );

      // Restore stock
      await this.rewardItemModel.findByIdAndUpdate(
        redemption.rewardItemId,
        { $inc: { stock: 1 } },
        { session }
      );

      // Update redemption status with reason
      const updatedRedemption = await this.redemptionModel
        .findByIdAndUpdate(
          redemptionId,
          { 
            status: RedemptionStatus.REJECTED,
            rejectionReason: reason,
            rejectedAt: new Date()
          },
          { new: true, session }
        )
        .populate('userId', 'email name')
        .populate('rewardItemId', 'name imageUrl')
        .exec();

      // Send real-time notification via WebSocket (just like account unlock)
      const normalizedUserId = String((redemption.userId as any)._id || redemption.userId);
      this.notificationsGateway.sendNotificationToUser(normalizedUserId, {
        type: 'order_rejected',
        title: 'Order Rejected',
        message: `Your order was rejected: ${reason}. ${redemption.pointsSpent} points have been refunded to your account.`,
        data: {
          orderId: redemptionId,
          rejectionReason: reason,
          pointsAmount: redemption.pointsSpent,
        },
        timestamp: new Date(),
      });

      await session.commitTransaction();
      return updatedRedemption!;
    } catch (error) {
      // Abort transaction if it's still active
      if (session.inTransaction()) {
        try {
          await session.abortTransaction();
        } catch (abortError) {
          console.error('Error aborting transaction:', abortError);
        }
      }
      throw error;
    } finally {
      // Always end session, even if there's an error
      try {
        await session.endSession();
      } catch (endError) {
        console.error('Error ending session:', endError);
      }
    }
  }

  /**
   * Approve redemption, generate shipping label, and mark as confirmed
   */
  async approveRedemption(redemptionId: string): Promise<RewardRedemption> {
    const session = await this.redemptionModel.db.startSession();
    
    try {
      await session.startTransaction();

      // Get the redemption with populated data
      const redemption = await this.redemptionModel
        .findById(redemptionId)
        .populate('userId', 'email name')
        .populate('rewardItemId', 'name imageUrl')
        .session(session)
        .exec();

      if (!redemption) {
        throw new NotFoundException('Redemption not found');
      }

      if (redemption.status !== RedemptionStatus.PENDING) {
        throw new BadRequestException('Only pending redemptions can be approved');
      }

      // Generate shipping label (mock implementation)
      const shippingLabel = this.generateShippingLabel(redemption);

      // Update redemption status to confirmed with shipping label
      const updatedRedemption = await this.redemptionModel
        .findByIdAndUpdate(
          redemptionId,
          { 
            status: RedemptionStatus.APPROVED,
            trackingNumber: shippingLabel.trackingNumber,
            estimatedDelivery: shippingLabel.estimatedDelivery,
            approvedAt: new Date()
          },
          { new: true, session }
        )
        .populate('userId', 'email name')
        .populate('rewardItemId', 'name imageUrl')
        .exec();

      // Send real-time notification via WebSocket (just like account unlock)
      const normalizedUserId = String((redemption.userId as any)._id || redemption.userId);
      this.notificationsGateway.sendNotificationToUser(normalizedUserId, {
        type: 'order_approved',
        title: 'Order Approved! 🎉',
        message: `Your order has been approved and is being prepared for shipment. Tracking: ${shippingLabel.trackingNumber}`,
        data: {
          orderId: redemptionId,
          trackingNumber: shippingLabel.trackingNumber,
          estimatedDelivery: shippingLabel.estimatedDelivery.toISOString(),
        },
        timestamp: new Date(),
      });

      await session.commitTransaction();
      return updatedRedemption!;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  /**
   * Generate shipping label for redemption
   */
  private generateShippingLabel(redemption: RewardRedemption): { trackingNumber: string; estimatedDelivery: Date } {
    // Generate a mock tracking number
    const trackingNumber = `TRK${Date.now().toString().slice(-8)}${Math.random().toString(36).substr(2, 4).toUpperCase()}`;
    
    // Calculate estimated delivery (3-7 business days)
    const estimatedDelivery = new Date();
    estimatedDelivery.setDate(estimatedDelivery.getDate() + Math.floor(Math.random() * 5) + 3);
    
    return {
      trackingNumber,
      estimatedDelivery
    };
  }
}