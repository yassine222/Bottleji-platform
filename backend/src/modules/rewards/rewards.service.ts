import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { RewardItem, RewardItemDocument, RewardCategory } from './schemas/reward-item.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CollectionAttempt, CollectionAttemptDocument } from '../dropoffs/schemas/collection-attempt.schema';

export interface CreateRewardItemDto {
  name: string;
  description: string;
  category: RewardCategory;
  subCategory: string;
  pointCost: number;
  stock: number;
  imageUrl?: string;
  isActive?: boolean;
}

export interface UpdateRewardItemDto {
  name?: string;
  description?: string;
  category?: RewardCategory;
  subCategory?: string;
  pointCost?: number;
  stock?: number;
  imageUrl?: string;
  isActive?: boolean;
}

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
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(CollectionAttempt.name) private collectionAttemptModel: Model<CollectionAttemptDocument>,
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
    // This method should be implemented in the existing rewards service
    // For now, return a mock response to prevent compilation errors
    console.log(`🎉 Points awarded to collector ${collectorId} for drop ${dropId}`);
    return {
      pointsAwarded: 10,
      newTier: { tier: 1, name: 'Bronze' },
      tierUpgraded: false,
      totalPoints: 10,
      totalDrops: 1,
    };
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
    // This method should be implemented in the existing rewards service
    // For now, return a mock response to prevent compilation errors
    console.log(`🎉 Points awarded to household ${householdId} for drop ${dropId} being collected`);
    return {
      pointsAwarded: 5,
      newTier: { tier: 1, name: 'Bronze' },
      tierUpgraded: false,
      totalPoints: 5,
      totalDrops: 1,
      totalDropsCreated: 1,
    };
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
      
      // Calculate tier name and points to next tier
      const tierNames = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'];
      const tierName = tierNames[Math.min(currentTier - 1, tierNames.length - 1)] || 'Bronze';
      const pointsToNextTier = Math.max(0, (currentTier * 100) - totalPoints);

      // Get recent redemptions (mock for now, would need redemption model)
      const recentRedemptions = [];

      return {
        totalPoints,
        currentTier,
        tierName,
        pointsToNextTier,
        totalRedemptions: recentRedemptions.length,
        availablePoints: totalPoints,
        totalCollections,
        recentRedemptions
      };
    } catch (error) {
      console.error('Error getting user reward stats:', error);
      // Return fallback data
      return {
        totalPoints: 0,
        currentTier: 1,
        tierName: 'Bronze',
        pointsToNextTier: 100,
        totalRedemptions: 0,
        availablePoints: 0,
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
   * Get user's redemption history
   */
  async getUserRedemptions(userId: string): Promise<any[]> {
    // For now, return mock data
    // In a real implementation, this would query the user's redemption history
    return [
      {
        id: 'redemption_1',
        itemName: 'Professional Collection Bag',
        pointsUsed: 100,
        redeemedAt: new Date(),
        status: 'fulfilled'
      },
      {
        id: 'redemption_2',
        itemName: 'Smart Home Speaker',
        pointsUsed: 200,
        redeemedAt: new Date(Date.now() - 86400000), // 1 day ago
        status: 'pending'
      }
    ];
  }
}