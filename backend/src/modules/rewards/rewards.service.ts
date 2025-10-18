import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from '../users/schemas/user.schema';

export interface TierInfo {
  tier: number;
  name: string;
  minDrops: number;
  maxDrops: number;
  pointsPerDrop: number;
  color: string;
  description: string;
}

@Injectable()
export class RewardsService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
  ) {}

  // Tier configuration
  private readonly TIERS: TierInfo[] = [
    {
      tier: 1,
      name: 'Bronze Collector',
      minDrops: 0,
      maxDrops: 999,
      pointsPerDrop: 10,
      color: '#CD7F32',
      description: 'Just getting started!'
    },
    {
      tier: 2,
      name: 'Silver Collector',
      minDrops: 1000,
      maxDrops: 1999,
      pointsPerDrop: 20,
      color: '#C0C0C0',
      description: 'Making a difference!'
    },
    {
      tier: 3,
      name: 'Gold Collector',
      minDrops: 2000,
      maxDrops: 2999,
      pointsPerDrop: 30,
      color: '#FFD700',
      description: 'Environmental champion!'
    },
    {
      tier: 4,
      name: 'Platinum Collector',
      minDrops: 3000,
      maxDrops: 3999,
      pointsPerDrop: 40,
      color: '#E5E4E2',
      description: 'Elite collector!'
    },
    {
      tier: 5,
      name: 'Diamond Collector',
      minDrops: 4000,
      maxDrops: Infinity,
      pointsPerDrop: 50,
      color: '#B9F2FF',
      description: 'Legendary collector!'
    }
  ];

  /**
   * Calculate tier based on number of drops collected
   */
  calculateTier(dropsCollected: number): TierInfo {
    for (const tier of this.TIERS) {
      if (dropsCollected >= tier.minDrops && dropsCollected <= tier.maxDrops) {
        return tier;
      }
    }
    // Fallback to highest tier
    return this.TIERS[this.TIERS.length - 1];
  }

  /**
   * Calculate points earned for a drop collection
   */
  calculatePointsForDrop(dropsCollected: number): number {
    const tier = this.calculateTier(dropsCollected);
    return tier.pointsPerDrop;
  }

  /**
   * Award points for a successful drop collection (Collector role)
   */
  async awardPointsForCollection(collectorId: string, dropId: string): Promise<{
    pointsAwarded: number;
    newTier: TierInfo;
    tierUpgraded: boolean;
    totalPoints: number;
    totalDrops: number;
  }> {
    const user = await this.userModel.findById(collectorId).exec();
    if (!user) {
      throw new Error('Collector not found');
    }

    // Get current stats
    const currentDrops = user.totalDropsCollected || 0;
    const currentPoints = user.currentPoints || 0;
    const currentTier = user.currentTier || 1;

    // Calculate new stats
    const newDrops = currentDrops + 1;
    const pointsForThisDrop = this.calculatePointsForDrop(currentDrops); // Use current drops count for tier calculation
    const newTotalPoints = currentPoints + pointsForThisDrop;
    const newTier = this.calculateTier(newDrops);
    const tierUpgraded = newTier.tier > currentTier;

    // Update user
    await this.userModel.findByIdAndUpdate(collectorId, {
      totalDropsCollected: newDrops,
      totalPointsEarned: (user.totalPointsEarned || 0) + pointsForThisDrop,
      currentPoints: newTotalPoints,
      currentTier: newTier.tier,
      lastDropCollectedAt: new Date(),
      $push: {
        rewardHistory: {
          dropId,
          pointsAwarded: pointsForThisDrop,
          tier: newTier.tier,
          tierUpgraded,
          collectedAt: new Date(),
        }
      }
    }).exec();

    console.log(`🎉 Points awarded to collector ${collectorId}:`);
    console.log(`   - Points awarded: ${pointsForThisDrop}`);
    console.log(`   - New tier: ${newTier.name} (Tier ${newTier.tier})`);
    console.log(`   - Tier upgraded: ${tierUpgraded}`);
    console.log(`   - Total drops: ${newDrops}`);
    console.log(`   - Total points: ${newTotalPoints}`);

    return {
      pointsAwarded: pointsForThisDrop,
      newTier,
      tierUpgraded,
      totalPoints: newTotalPoints,
      totalDrops: newDrops,
    };
  }

  /**
   * Get collector's reward stats
   */
  async getCollectorStats(collectorId: string): Promise<{
    currentTier: TierInfo;
    totalDrops: number;
    totalPoints: number;
    currentPoints: number;
    nextTier?: TierInfo;
    dropsToNextTier: number;
    rewardHistory: any[];
  }> {
    const user = await this.userModel.findById(collectorId).exec();
    if (!user) {
      throw new Error('Collector not found');
    }

    const totalDrops = user.totalDropsCollected || 0;
    const currentTier = this.calculateTier(totalDrops);
    const nextTier = this.TIERS.find(tier => tier.tier === currentTier.tier + 1);
    const dropsToNextTier = nextTier ? nextTier.minDrops - totalDrops : 0;

    return {
      currentTier,
      totalDrops,
      totalPoints: user.totalPointsEarned || 0,
      currentPoints: user.currentPoints || 0,
      nextTier,
      dropsToNextTier,
      rewardHistory: user.rewardHistory || [],
    };
  }

  /**
   * Get all tiers information
   */
  getAllTiers(): TierInfo[] {
    return this.TIERS;
  }

  /**
   * Spend points (for future reward shop)
   */
  async spendPoints(collectorId: string, pointsToSpend: number, reason: string): Promise<{
    success: boolean;
    remainingPoints: number;
    pointsSpent: number;
  }> {
    const user = await this.userModel.findById(collectorId).exec();
    if (!user) {
      throw new Error('Collector not found');
    }

    const currentPoints = user.currentPoints || 0;
    if (currentPoints < pointsToSpend) {
      return {
        success: false,
        remainingPoints: currentPoints,
        pointsSpent: 0,
      };
    }

    const newPoints = currentPoints - pointsToSpend;
    await this.userModel.findByIdAndUpdate(collectorId, {
      currentPoints: newPoints,
      $push: {
        rewardHistory: {
          pointsSpent: pointsToSpend,
          reason,
          spentAt: new Date(),
          type: 'spent'
        }
      }
    }).exec();

    return {
      success: true,
      remainingPoints: newPoints,
      pointsSpent: pointsToSpend,
    };
  }

  /**
   * Award points to household user when their drop is successfully collected
   */
  async awardPointsForDropCollected(householdUserId: string, dropId: string): Promise<{
    pointsAwarded: number;
    newTier: TierInfo;
    tierUpgraded: boolean;
    totalPoints: number;
    totalDropsCreated: number;
  }> {
    const user = await this.userModel.findById(householdUserId).exec();
    if (!user) {
      throw new Error('Household user not found');
    }

    // Get current stats
    const currentDropsCreated = user.totalDropsCreated || 0;
    const currentPoints = user.currentPoints || 0;
    const currentTier = user.currentTier || 1;

    // Calculate new stats
    const newDropsCreated = currentDropsCreated + 1;
    const pointsForThisDrop = this.calculatePointsForHouseholdDrop(currentDropsCreated);
    const newTotalPoints = currentPoints + pointsForThisDrop;
    const newTier = this.calculateTier(newDropsCreated);
    const tierUpgraded = newTier.tier > currentTier;

    // Update user
    await this.userModel.findByIdAndUpdate(householdUserId, {
      totalDropsCreated: newDropsCreated,
      totalPointsEarned: (user.totalPointsEarned || 0) + pointsForThisDrop,
      currentPoints: newTotalPoints,
      currentTier: newTier.tier,
      lastDropCreatedAt: new Date(),
      $push: {
        rewardHistory: {
          dropId,
          pointsAwarded: pointsForThisDrop,
          tier: newTier.tier,
          tierUpgraded,
          type: 'household_drop_collected',
          collectedAt: new Date(),
        }
      }
    }).exec();

    console.log(`🏠 Household reward - Points awarded to user ${householdUserId}:`);
    console.log(`   - Points awarded: ${pointsForThisDrop}`);
    console.log(`   - New tier: ${newTier.name} (Tier ${newTier.tier})`);
    console.log(`   - Tier upgraded: ${tierUpgraded}`);
    console.log(`   - Total drops created: ${newDropsCreated}`);
    console.log(`   - Total points: ${newTotalPoints}`);

    return {
      pointsAwarded: pointsForThisDrop,
      newTier,
      tierUpgraded,
      totalPoints: newTotalPoints,
      totalDropsCreated: newDropsCreated,
    };
  }

  /**
   * Calculate points for household drop collection (different from collector points)
   */
  calculatePointsForHouseholdDrop(dropsCreated: number): number {
    const tier = this.calculateTier(dropsCreated);
    // Household points are lower than collector points to reflect the effort difference
    return Math.floor(tier.pointsPerDrop * 0.5); // 50% of collector points
  }

  /**
   * Get all tiers information
   */
  getAllTiers(): TierInfo[] {
    return this.TIERS;
  }
}
