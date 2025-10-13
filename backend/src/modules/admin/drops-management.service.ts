import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Dropoff } from '../dropoffs/schemas/dropoff.schema';
import { CollectionAttempt } from '../dropoffs/schemas/collection-attempt.schema';
import { User } from '../users/schemas/user.schema';

@Injectable()
export class DropsManagementService {
  constructor(
    @InjectModel('Dropoff') private dropModel: Model<Dropoff>,
    @InjectModel('CollectionAttempt') private collectionAttemptModel: Model<CollectionAttempt>,
    @InjectModel('User') private userModel: Model<User>,
  ) {}

  /**
   * Get drops overview statistics
   */
  async getDropsStats() {
    const now = new Date();
    const threeDaysAgo = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    // Total drops
    const totalDrops = await this.dropModel.countDocuments();

    // Active drops (pending, accepted)
    const activeDrops = await this.dropModel.countDocuments({
      status: { $in: ['pending', 'accepted'] },
    });

    // Completed drops
    const completedDrops = await this.dropModel.countDocuments({
      status: 'collected',
    });

    // Flagged/Suspicious drops
    const flaggedDrops = await this.dropModel.countDocuments({
      isSuspicious: true,
    });

    // Old drops (>3 days, not collected)
    const oldDrops = await this.dropModel.countDocuments({
      createdAt: { $lt: threeDaysAgo },
      status: { $ne: 'collected' },
    });

    // Drops by status
    const dropsByStatus = await this.dropModel.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
        },
      },
    ]);

    // Drops created in last 7 days
    const dropsLast7Days = await this.dropModel.countDocuments({
      createdAt: { $gte: sevenDaysAgo },
    });

    // Drops created in last 30 days
    const dropsLast30Days = await this.dropModel.countDocuments({
      createdAt: { $gte: thirtyDaysAgo },
    });

    return {
      totalDrops,
      activeDrops,
      completedDrops,
      flaggedDrops,
      oldDrops,
      dropsByStatus: dropsByStatus.reduce((acc, item) => {
        acc[item._id] = item.count;
        return acc;
      }, {}),
      dropsLast7Days,
      dropsLast30Days,
    };
  }

  /**
   * Get drops list with advanced filters
   */
  async getDropsList(filters: {
    status?: string;
    startDate?: Date;
    endDate?: Date;
    userId?: string;
    isSuspicious?: boolean;
    isOld?: boolean;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const {
      status,
      startDate,
      endDate,
      userId,
      isSuspicious,
      isOld,
      search,
      page = 1,
      limit = 20,
    } = filters;

    const query: any = {};

    // Status filter
    if (status) {
      query.status = status;
    }

    // Date range filter
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    // User filter
    if (userId) {
      query.userId = userId;
    }

    // Suspicious filter
    if (isSuspicious !== undefined) {
      query.isSuspicious = isSuspicious;
    }

    // Old drops filter (>3 days, not collected)
    if (isOld) {
      const threeDaysAgo = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000);
      query.createdAt = { $lt: threeDaysAgo };
      query.status = { $ne: 'collected' };
    }

    // Search filter (by ID or notes)
    if (search) {
      query.$or = [
        { notes: { $regex: search, $options: 'i' } },
        { _id: search.match(/^[0-9a-fA-F]{24}$/) ? search : null },
      ].filter(Boolean);
    }

    const skip = (page - 1) * limit;

    const [drops, total] = await Promise.all([
      this.dropModel
        .find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.dropModel.countDocuments(query),
    ]);

    // Manually populate user data since userId is a string, not a reference
    const userIds = drops.map(drop => drop.userId);
    const users = await this.userModel.find({ _id: { $in: userIds } }).exec();
    
    const dropsWithUsers = drops.map(drop => {
      const user = users.find(u => u._id.toString() === drop.userId);
      return {
        ...drop.toObject(),
        userId: user ? { name: user.name, email: user.email } : { name: 'Unknown', email: 'N/A' },
      };
    });

    return {
      drops: dropsWithUsers,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Analyze old drops (>3 days, not collected)
   */
  async analyzeOldDrops() {
    const threeDaysAgo = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000);

    const oldDrops = await this.dropModel
      .find({
        createdAt: { $lt: threeDaysAgo },
        status: { $ne: 'collected' },
        isSuspicious: { $ne: true }, // Don't include already flagged drops
      })
      .sort({ createdAt: 1 })
      .exec();

    // Manually populate user data
    const userIds = oldDrops.map(drop => drop.userId);
    const users = await this.userModel.find({ _id: { $in: userIds } }).exec();

    // Calculate age in days for each drop
    const dropsWithAge = oldDrops.map(drop => {
      const createdAt = drop.createdAt ? new Date(drop.createdAt) : new Date();
      const ageInDays = Math.floor(
        (Date.now() - createdAt.getTime()) / (1000 * 60 * 60 * 24),
      );
      const user = users.find(u => u._id.toString() === drop.userId);
      return {
        ...drop.toObject(),
        userId: user ? { name: user.name, email: user.email } : { name: 'Unknown', email: 'N/A' },
        ageInDays,
        reason: `Drop is ${ageInDays} days old and has not been collected`,
      };
    });

    return dropsWithAge;
  }

  /**
   * Hide old drops and send notifications
   */
  async hideOldDrops(dropIds: string[]) {
    const drops = await this.dropModel.find({ _id: { $in: dropIds } }).exec();

    // Mark drops as suspicious (hidden)
    await this.dropModel.updateMany(
      { _id: { $in: dropIds } },
      { isSuspicious: true, suspiciousReason: 'Drop older than 3 days and not collected' },
    );

    // Return user IDs for notification
    const userIds = [...new Set(drops.map(drop => drop.userId.toString()))];

    return {
      hiddenCount: drops.length,
      userIds,
      drops,
    };
  }

  /**
   * Get flagged/suspicious drops
   */
  async getFlaggedDrops() {
    const flaggedDrops = await this.dropModel
      .find({ isSuspicious: true })
      .sort({ createdAt: -1 })
      .exec();

    // Manually populate user data
    const userIds = flaggedDrops.map(drop => drop.userId);
    const users = await this.userModel.find({ _id: { $in: userIds } }).exec();
    
    const dropsWithUsers = flaggedDrops.map(drop => {
      const user = users.find(u => u._id.toString() === drop.userId);
      return {
        ...drop.toObject(),
        userId: user ? { name: user.name, email: user.email } : { name: 'Unknown', email: 'N/A' },
      };
    });

    return dropsWithUsers;
  }

  /**
   * Get detailed drop information
   */
  async getDropDetails(dropId: string) {
    // Get the drop
    const drop = await this.dropModel.findById(dropId).exec();
    if (!drop) {
      throw new Error('Drop not found');
    }

    // Get user who created the drop
    const user = await this.userModel.findById(drop.userId).exec();

    // Get all collection attempts for this drop
    const collectionAttempts = await this.collectionAttemptModel
      .find({ dropoffId: dropId })
      .sort({ acceptedAt: -1 })
      .exec();

    // Get collector details for all attempts
    const collectorIds = collectionAttempts.map(attempt => attempt.collectorId).filter(Boolean);
    const collectors = await this.userModel.find({ _id: { $in: collectorIds } }).exec();

    // Enrich attempts with collector info
    const enrichedAttempts = collectionAttempts.map(attempt => {
      const collector = collectors.find(c => c._id.toString() === attempt.collectorId);
      return {
        ...attempt.toObject(),
        collector: collector ? { name: collector.name, email: collector.email } : null,
      };
    });

    return {
      drop: {
        ...drop.toObject(),
        user: user ? { 
          id: user._id,
          name: user.name, 
          email: user.email,
          phoneNumber: user.phoneNumber,
          address: user.address,
        } : null,
      },
      collectionAttempts: enrichedAttempts,
      totalAttempts: enrichedAttempts.length,
      successfulCollections: enrichedAttempts.filter(a => a.outcome === 'collected').length,
      cancelledAttempts: enrichedAttempts.filter(a => a.outcome === 'cancelled').length,
      expiredAttempts: enrichedAttempts.filter(a => a.outcome === 'expired').length,
    };
  }

  /**
   * Remove flag from drop
   */
  async unflagDrop(dropId: string) {
    const drop = await this.dropModel.findByIdAndUpdate(
      dropId,
      { isSuspicious: false, suspiciousReason: null },
      { new: true },
    );

    return drop;
  }

  /**
   * Flag drop as suspicious
   */
  async flagDrop(dropId: string, reason: string) {
    const drop = await this.dropModel.findByIdAndUpdate(
      dropId,
      { isSuspicious: true, suspiciousReason: reason },
      { new: true },
    );

    return drop;
  }

  /**
   * Delete drop permanently
   */
  async deleteDrop(dropId: string) {
    const drop = await this.dropModel.findByIdAndDelete(dropId).exec();
    return drop;
  }

  /**
   * Analytics: Drop Success Rate
   */
  async getDropSuccessRate(startDate?: Date, endDate?: Date) {
    const query: any = {};
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    const stats = await this.dropModel.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
        },
      },
    ]);

    const total = stats.reduce((sum, item) => sum + item.count, 0);
    const collected = stats.find(item => item._id === 'collected')?.count || 0;
    const cancelled = stats.find(item => item._id === 'cancelled')?.count || 0;
    const expired = stats.find(item => item._id === 'expired')?.count || 0;

    return {
      total,
      collected,
      cancelled,
      expired,
      successRate: total > 0 ? (collected / total) * 100 : 0,
      cancellationRate: total > 0 ? (cancelled / total) * 100 : 0,
      expirationRate: total > 0 ? (expired / total) * 100 : 0,
    };
  }

  /**
   * Analytics: Average Collection Time
   */
  async getAverageCollectionTime(startDate?: Date, endDate?: Date) {
    const query: any = { status: 'collected' };
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    const collectedDrops = await this.dropModel.find(query).exec();

    if (collectedDrops.length === 0) {
      return {
        averageMinutes: 0,
        averageHours: 0,
        totalDrops: 0,
      };
    }

    // Calculate average collection time
    const totalMinutes = collectedDrops.reduce((sum, drop) => {
      // Simple calculation: time from creation to last update (collected)
      const createdAt = drop.createdAt ? new Date(drop.createdAt) : new Date();
      const updatedAt = drop.updatedAt ? new Date(drop.updatedAt) : new Date();
      const minutes = (updatedAt.getTime() - createdAt.getTime()) / (1000 * 60);
      return sum + minutes;
    }, 0);

    const averageMinutes = totalMinutes / collectedDrops.length;

    return {
      averageMinutes: Math.round(averageMinutes),
      averageHours: Math.round((averageMinutes / 60) * 10) / 10,
      totalDrops: collectedDrops.length,
    };
  }

  /**
   * Analytics: Popular Locations
   */
  async getPopularLocations(limit = 10) {
    const locations = await this.dropModel.aggregate([
      {
        $group: {
          _id: {
            lat: { $round: ['$location.latitude', 2] }, // Round to 2 decimals for grouping
            lng: { $round: ['$location.longitude', 2] },
          },
          count: { $sum: 1 },
          drops: { $push: '$$ROOT' },
        },
      },
      { $sort: { count: -1 } },
      { $limit: limit },
    ]);

    return locations.map(loc => ({
      location: loc._id,
      count: loc.count,
      exactLocation: {
        latitude: loc.drops[0].location.latitude,
        longitude: loc.drops[0].location.longitude,
      },
    }));
  }

  /**
   * Analytics: Peak Times
   */
  async getPeakTimes() {
    const dropsByHour = await this.dropModel.aggregate([
      {
        $group: {
          _id: { $hour: '$createdAt' },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    const dropsByDayOfWeek = await this.dropModel.aggregate([
      {
        $group: {
          _id: { $dayOfWeek: '$createdAt' },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    return {
      byHour: dropsByHour,
      byDayOfWeek: dropsByDayOfWeek,
    };
  }

  /**
   * Performance: Collector Leaderboard
   */
  async getCollectorLeaderboard(limit = 10, startDate?: Date, endDate?: Date) {
    const matchStage: any = { outcome: 'collected' };
    if (startDate || endDate) {
      matchStage.completedAt = {};
      if (startDate) matchStage.completedAt.$gte = new Date(startDate);
      if (endDate) matchStage.completedAt.$lte = new Date(endDate);
    }

    const leaderboard = await this.collectionAttemptModel.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: '$collectorId',
          totalCollections: { $sum: 1 },
          totalDuration: { $sum: '$durationMinutes' },
        },
      },
      { $sort: { totalCollections: -1 } },
      { $limit: limit },
    ]);

    // Populate user details
    const collectorIds = leaderboard.map(item => item._id);
    const users = await this.userModel.find({ _id: { $in: collectorIds } }).exec();

    return leaderboard.map(item => {
      const user = users.find(u => (u as any)._id.toString() === item._id.toString());
      return {
        collectorId: item._id,
        collectorName: user?.name || 'Unknown',
        collectorEmail: user?.email || 'Unknown',
        totalCollections: item.totalCollections,
        averageDuration: item.totalDuration > 0 ? Math.round(item.totalDuration / item.totalCollections) : 0,
      };
    });
  }

  /**
   * Performance: Household Rankings
   */
  async getHouseholdRankings(limit = 10, startDate?: Date, endDate?: Date) {
    const matchStage: any = {};
    if (startDate || endDate) {
      matchStage.createdAt = {};
      if (startDate) matchStage.createdAt.$gte = new Date(startDate);
      if (endDate) matchStage.createdAt.$lte = new Date(endDate);
    }

    const rankings = await this.dropModel.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: '$userId',
          totalDrops: { $sum: 1 },
          collectedDrops: {
            $sum: { $cond: [{ $eq: ['$status', 'collected'] }, 1, 0] },
          },
        },
      },
      { $sort: { totalDrops: -1 } },
      { $limit: limit },
    ]);

    // Populate user details
    const userIds = rankings.map(item => item._id);
    const users = await this.userModel.find({ _id: { $in: userIds } }).exec();

    return rankings.map(item => {
      const user = users.find(u => (u as any)._id.toString() === item._id.toString());
      const successRate = item.totalDrops > 0 ? (item.collectedDrops / item.totalDrops) * 100 : 0;
      return {
        userId: item._id,
        userName: user?.name || 'Unknown',
        userEmail: user?.email || 'Unknown',
        totalDrops: item.totalDrops,
        collectedDrops: item.collectedDrops,
        successRate: Math.round(successRate * 10) / 10,
      };
    });
  }

  /**
   * Time-based Analytics: Compare periods
   */
  async getTimeBasedAnalytics() {
    const now = new Date();
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const twoWeeksAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);
    const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const twoMonthsAgo = new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000);

    // This week vs last week
    const [thisWeek, lastWeek] = await Promise.all([
      this.dropModel.countDocuments({ createdAt: { $gte: weekAgo } }),
      this.dropModel.countDocuments({
        createdAt: { $gte: twoWeeksAgo, $lt: weekAgo },
      }),
    ]);

    // This month vs last month
    const [thisMonth, lastMonth] = await Promise.all([
      this.dropModel.countDocuments({ createdAt: { $gte: monthAgo } }),
      this.dropModel.countDocuments({
        createdAt: { $gte: twoMonthsAgo, $lt: monthAgo },
      }),
    ]);

    const weekChange = lastWeek > 0 ? ((thisWeek - lastWeek) / lastWeek) * 100 : 0;
    const monthChange = lastMonth > 0 ? ((thisMonth - lastMonth) / lastMonth) * 100 : 0;

    return {
      thisWeek,
      lastWeek,
      weekChange: Math.round(weekChange * 10) / 10,
      thisMonth,
      lastMonth,
      monthChange: Math.round(monthChange * 10) / 10,
    };
  }
}

