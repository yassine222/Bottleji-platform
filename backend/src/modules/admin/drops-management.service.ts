import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Dropoff } from '../dropoffs/schemas/dropoff.schema';
import { CollectionAttempt } from '../dropoffs/schemas/collection-attempt.schema';
import { DropReport } from '../dropoffs/schemas/drop-report.schema';
import { User } from '../users/schemas/user.schema';

@Injectable()
export class DropsManagementService {
  constructor(
    @InjectModel(Dropoff.name) private dropoffModel: Model<Dropoff>,
    @InjectModel(CollectionAttempt.name) private collectionAttemptModel: Model<CollectionAttempt>,
    @InjectModel(DropReport.name) private dropReportModel: Model<DropReport>,
    @InjectModel(User.name) private userModel: Model<User>,
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
    const totalDrops = await this.dropoffModel.countDocuments();

    // Active drops (pending, accepted)
    const activeDrops = await this.dropoffModel.countDocuments({
      status: { $in: ['pending', 'accepted'] },
    });

    // Completed drops
    const completedDrops = await this.dropoffModel.countDocuments({
      status: 'collected',
    });

    // Flagged/Suspicious drops
    const flaggedDrops = await this.dropoffModel.countDocuments({
      isSuspicious: true,
    });

    // Old drops (>3 days, not collected, not stale)
    const oldDrops = await this.dropoffModel.countDocuments({
      createdAt: { $lt: threeDaysAgo },
      status: { $in: ['pending', 'accepted', 'cancelled', 'expired'] },
      isSuspicious: { $ne: true },
    });

    // Drops by status
    const dropsByStatus = await this.dropoffModel.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
        },
      },
    ]);

    // Drops created in last 7 days
    const dropsLast7Days = await this.dropoffModel.countDocuments({
      createdAt: { $gte: sevenDaysAgo },
    });

    // Drops created in last 30 days
    const dropsLast30Days = await this.dropoffModel.countDocuments({
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
    hasAttempts?: boolean;
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
      hasAttempts,
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
      const searchConditions: any[] = [
        { notes: { $regex: search, $options: 'i' } },
      ];
      
      // If search looks like a MongoDB ObjectId (24 hex chars), search by ID
      if (search.match(/^[0-9a-fA-F]{24}$/)) {
        searchConditions.push({ _id: search });
      }
      
      query.$or = searchConditions;
    }

    const skip = (page - 1) * limit;

    // If filtering by drops with attempts, first get all drop IDs that have collection attempts
    if (hasAttempts) {
      // Get unique drop IDs from CollectionAttempt collection
      const dropIdsWithAttempts = await this.collectionAttemptModel
        .distinct('dropoffId')
        .exec();
      
      console.log('🔍 Filtering by drops with attempts...');
      console.log('   - Found attempts for', dropIdsWithAttempts.length, 'unique drops');
      console.log('   - Sample dropoffId:', dropIdsWithAttempts[0]);
      console.log('   - Type:', typeof dropIdsWithAttempts[0]);
      
      // Convert to ObjectIds if they're strings
      const dropObjectIds = dropIdsWithAttempts.map(id => {
        if (typeof id === 'string') {
          return new Types.ObjectId(id);
        }
        return id;
      });
      
      // Add to query: only show drops whose ID is in the list of drops with attempts
      query._id = { $in: dropObjectIds };
    }

    const [drops, total] = await Promise.all([
      this.dropoffModel
        .find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.dropoffModel.countDocuments(query),
    ]);

    // Manually populate user data since userId and collectedBy are strings, not references
    const userIds = drops.map(drop => drop.userId);
    const collectedByIds = drops.map(drop => drop.collectedBy).filter(Boolean);
    const allUserIds = [...new Set([...userIds, ...collectedByIds])];
    const users = await this.userModel.find({ _id: { $in: allUserIds } }).exec();
    
    const dropsWithUsers = drops.map(drop => {
      const user = users.find(u => (u as any)._id.toString() === drop.userId);
      const collector = drop.collectedBy ? users.find(u => (u as any)._id.toString() === drop.collectedBy) : null;
      return {
        ...drop.toObject(),
        userId: user ? { name: user.name, email: user.email } : { name: 'Unknown', email: 'N/A' },
        collectedBy: collector ? { name: collector.name, email: collector.email } : null,
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

    const oldDrops = await this.dropoffModel
      .find({
        createdAt: { $lt: threeDaysAgo },
        status: { $in: ['pending', 'accepted', 'cancelled', 'expired'] }, // Only include drops that can be marked as stale
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
      const user = users.find(u => (u as any)._id.toString() === drop.userId);
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
    const drops = await this.dropoffModel.find({ _id: { $in: dropIds } }).exec();

    // Mark drops as stale (hidden from active view)
    await this.dropoffModel.updateMany(
      { _id: { $in: dropIds } },
      { 
        status: 'stale',
        modifiedAt: new Date()
      },
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
   * Get stale drops
   */
  async getStaleDrops(filters: { page: number; limit: number }) {
    const { page, limit } = filters;
    const skip = (page - 1) * limit;

    const staleDrops = await this.dropoffModel
      .find({ status: 'stale' })
      .populate('userId', 'name email')
      .sort({ modifiedAt: -1 })
      .skip(skip)
      .limit(limit)
      .exec();

    const total = await this.dropoffModel.countDocuments({ status: 'stale' });

    console.log('📋 Stale drops found:', staleDrops.length);
    if (staleDrops.length > 0) {
      console.log('📋 First drop userId:', staleDrops[0].userId);
      console.log('📋 First drop full data:', JSON.stringify(staleDrops[0], null, 2));
    }

    return {
      drops: staleDrops,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Get flagged/suspicious drops
   */
  async getFlaggedDrops() {
    const flaggedDrops = await this.dropoffModel
      .find({ isSuspicious: true })
      .sort({ createdAt: -1 })
      .exec();

    // Manually populate user data
    const userIds = flaggedDrops.map(drop => drop.userId);
    const users = await this.userModel.find({ _id: { $in: userIds } }).exec();
    
    const dropsWithUsers = flaggedDrops.map(drop => {
      const user = users.find(u => (u as any)._id.toString() === drop.userId);
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
    console.log('🔍 getDropDetails called with dropId:', dropId);
    
    // First try to find in dropoff collection (for collected drops)
    let drop = await this.dropoffModel.findById(dropId).exec();
    let isDropoffRecord = true;
    
    if (drop) {
      console.log('✅ Found in dropoff collection:', drop._id);
    } else {
      console.log('🔍 Drop not found in dropoff collection');
      isDropoffRecord = false;
    }
    
    if (!drop) {
      console.log('❌ Drop not found in either collection. This might be a deleted drop or invalid ID.');
      console.log('   - DropId:', dropId);
      console.log('   - This could happen if the drop was deleted but reports still reference it');
      throw new Error('Drop not found - this drop may have been deleted or the ID is invalid');
    }

    // Get user who created the drop
    const user = await this.userModel.findById(drop.userId).exec();
    console.log('🔍 User lookup for drop:', {
      dropId: drop._id,
      userId: drop.userId,
      userFound: !!user,
      userName: user?.name,
      userEmail: user?.email
    });

    // Get all collection attempts for this drop
    // IMPORTANT: dropoffId might be stored as ObjectId or String, so we need to check both
    const dropIdString = (drop as any)._id.toString();
    const dropIdObjectId = (drop as any)._id;
    console.log('🔍 Searching for collection attempts...');
    console.log('   - Is dropoff record:', isDropoffRecord);
    console.log('   - Querying with dropoffId (string):', dropIdString);
    console.log('   - Querying with dropoffId (ObjectId):', dropIdObjectId);
    
    // Query using both string and ObjectId to handle both cases
    const collectionAttempts = await this.collectionAttemptModel
      .find({ 
        $or: [
          { dropoffId: dropIdString },
          { dropoffId: dropIdObjectId }
        ]
      })
      .sort({ 
        // First sort by outcome: expired/cancelled first, then collected
        outcome: 1, // expired/cancelled will come first alphabetically
        acceptedAt: -1 // Then by date (newest first)
      })
      .exec();
    
    console.log('✅ Found collection attempts:', collectionAttempts.length);
    if (collectionAttempts.length > 0) {
      console.log('   - First attempt dropoffId:', collectionAttempts[0].dropoffId);
      console.log('   - First attempt dropoffId type:', typeof collectionAttempts[0].dropoffId);
      console.log('   - Match:', collectionAttempts[0].dropoffId === dropIdString);
      console.log('   - First attempt dropSnapshot:', collectionAttempts[0].dropSnapshot);
      console.log('   - First attempt imageUrl:', collectionAttempts[0].dropSnapshot?.imageUrl);
      console.log('   - Timeline order (outcome, acceptedAt):');
      collectionAttempts.forEach((attempt, index) => {
        console.log(`     ${index + 1}. Outcome: ${attempt.outcome}, Status: ${attempt.status}, Accepted: ${attempt.acceptedAt}`);
      });
    } else {
      console.log('   - No attempts found. Checking if any attempts exist in DB...');
      const anyAttempts = await this.collectionAttemptModel.countDocuments();
      console.log('   - Total attempts in DB:', anyAttempts);
    }

    // Get collector details for all attempts
    const collectorIds = collectionAttempts.map(attempt => attempt.collectorId).filter(Boolean);
    const collectors = await this.userModel.find({ _id: { $in: collectorIds } }).exec();

    // Enrich attempts with collector info
    const enrichedAttempts = collectionAttempts.map(attempt => {
      const collector = collectors.find(c => (c as any)._id.toString() === attempt.collectorId);
      return {
        ...attempt.toObject(),
        collector: collector ? { name: collector.name, email: collector.email } : null,
      };
    });

    const result = {
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

    console.log('🔍 Final result structure:');
    console.log('   - Drop imageUrl:', result.drop.imageUrl);
    console.log('   - Drop user:', result.drop.user?.name);
    console.log('   - Collection attempts count:', result.collectionAttempts.length);
    console.log('   - Is dropoff record:', isDropoffRecord);
    console.log('   - Drop status:', result.drop.status);
    console.log('   - Drop collectedBy:', result.drop.collectedBy);
    console.log('   - Drop collectedAt:', result.drop.collectedAt);
    
    if (result.collectionAttempts.length > 0) {
      console.log('   - First attempt dropSnapshot imageUrl:', result.collectionAttempts[0].dropSnapshot?.imageUrl);
      console.log('   - First attempt outcome:', result.collectionAttempts[0].outcome);
    } else {
      console.log('   - No collection attempts found - will use dropoff data directly');
    }
    
    return result;
  }

  /**
   * Remove flag from drop
   */
  async unflagDrop(dropId: string) {
    const drop = await this.dropoffModel.findByIdAndUpdate(
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
    const drop = await this.dropoffModel.findByIdAndUpdate(
      dropId,
      { isSuspicious: true, suspiciousReason: reason },
      { new: true },
    );

    return drop;
  }

  /**
   * Censor drop image and add warning to user
   */
  async censorDrop(dropId: string, reason: string, adminId?: string) {
    const drop = await this.dropoffModel.findByIdAndUpdate(
      dropId,
      { 
        isCensored: true, 
        censorReason: reason,
        censoredBy: adminId || 'Admin',
        censoredAt: new Date(),
      },
      { new: true },
    ).exec();

    if (!drop) {
      throw new Error('Drop not found');
    }

    // Add warning to user
    const user = await this.userModel.findById(drop.userId).exec();
    if (user) {
      const warning = {
        type: 'censored_image',
        reason: reason,
        date: new Date(),
        dropId: (drop as any)._id.toString(),
      };

      await this.userModel.findByIdAndUpdate(
        drop.userId,
        {
          $push: { warnings: warning },
          $inc: { warningCount: 1 },
        },
      ).exec();

      console.log(`⚠️ Warning added to user ${user.email} for censored drop image`);
    }

    return { drop, user };
  }

  /**
   * Delete drop permanently
   */
  async deleteDrop(dropId: string) {
    const drop = await this.dropoffModel.findByIdAndDelete(dropId).exec();
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

    const stats = await this.dropoffModel.aggregate([
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

    const collectedDrops = await this.dropoffModel.find(query).exec();

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
    const locations = await this.dropoffModel.aggregate([
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
    const dropsByHour = await this.dropoffModel.aggregate([
      {
        $group: {
          _id: { $hour: '$createdAt' },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    const dropsByDayOfWeek = await this.dropoffModel.aggregate([
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

    // Get all collectors with their points and sort by points
    const users = await this.userModel.find({ 
      roles: { $in: ['collector'] } 
    }).sort({ totalPointsEarned: -1 }).limit(limit).exec();

    const leaderboard = await Promise.all(users.map(async (user) => {
      // Get collection stats for this collector
      const stats = await this.collectionAttemptModel.aggregate([
        { $match: { ...matchStage, collectorId: user._id } },
        {
          $group: {
            _id: '$collectorId',
            totalCollections: { $sum: 1 },
            totalDuration: { $sum: '$durationMinutes' },
          },
        },
      ]);
      
      const collectionStats = stats[0] || { totalCollections: 0, totalDuration: 0 };
      
      return {
        collectorId: user._id,
        collectorName: user.name || 'Unknown',
        collectorEmail: user.email || 'Unknown',
        totalCollections: collectionStats.totalCollections,
        averageDuration: collectionStats.totalDuration > 0 ? Math.round(collectionStats.totalDuration / collectionStats.totalCollections) : 0,
        totalPointsEarned: user.totalPointsEarned || 0,
        currentPoints: user.currentPoints || 0,
        currentTier: user.currentTier || 1,
      };
    }));

    return leaderboard;
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

    // Get all households with their points and sort by points
    const users = await this.userModel.find({ 
      roles: { $in: ['household'] } 
    }).sort({ totalPointsEarned: -1 }).limit(limit).exec();

    const rankings = await Promise.all(users.map(async (user) => {
      // Get drop stats for this household
      const stats = await this.dropoffModel.aggregate([
        { $match: { ...matchStage, userId: user._id } },
        {
          $group: {
            _id: '$userId',
            totalDrops: { $sum: 1 },
            collectedDrops: {
              $sum: { $cond: [{ $eq: ['$status', 'collected'] }, 1, 0] },
            },
          },
        },
      ]);
      
      const dropStats = stats[0] || { totalDrops: 0, collectedDrops: 0 };
      const successRate = dropStats.totalDrops > 0 ? (dropStats.collectedDrops / dropStats.totalDrops) * 100 : 0;
      
      return {
        userId: user._id,
        userName: user.name || 'Unknown',
        userEmail: user.email || 'Unknown',
        totalDrops: dropStats.totalDrops,
        collectedDrops: dropStats.collectedDrops,
        successRate: Math.round(successRate * 10) / 10,
        totalPointsEarned: user.totalPointsEarned || 0,
        currentPoints: user.currentPoints || 0,
        currentTier: user.currentTier || 1,
      };
    }));

    return rankings;
  }

  /**
   * Get all reported drops with report details
   * Only shows reports for drops that haven't been censored or flagged (admin action taken)
   */
  async getReportedDrops() {
    const reports = await this.dropReportModel
      .find({ status: 'pending' })
      .sort({ createdAt: -1 })
      .exec();

    // Get drop and user details for each report
    const dropIds = reports.map(r => r.dropId);
    const collectorIds = reports.map(r => r.reportedBy);
    
    const [drops, collectors] = await Promise.all([
      this.dropoffModel.find({ _id: { $in: dropIds } }).exec(),
      this.userModel.find({ _id: { $in: collectorIds } }).exec(),
    ]);

    // Filter out reports for drops that have been censored or flagged (admin action taken)
    const reportsWithDetails = reports
      .map(report => {
        const drop = drops.find(d => (d as any)._id.toString() === report.dropId);
        const collector = collectors.find(c => (c as any)._id.toString() === report.reportedBy);
        
        return {
          ...report.toObject(),
          drop: drop ? {
            id: drop._id,
            imageUrl: drop.imageUrl,
            status: drop.status,
            numberOfBottles: drop.numberOfBottles,
            numberOfCans: drop.numberOfCans,
            bottleType: drop.bottleType,
            location: drop.location,
            address: drop.address,
            notes: drop.notes,
            createdAt: drop.createdAt,
            userId: drop.userId,
            isCensored: drop.isCensored,
            isSuspicious: drop.isSuspicious,
          } : null,
          reporter: collector ? {
            name: collector.name,
            email: collector.email,
          } : null,
        };
      })
      .filter(report => {
        // Only include reports for drops that haven't been censored or flagged
        if (!report.drop) return false; // Drop doesn't exist
        
        const hasAdminAction = report.drop.isCensored || report.drop.isSuspicious;
        return !hasAdminAction;
      });

    console.log(`📋 Reported drops: ${reportsWithDetails.length} reports found (filtered from ${reports.length} total)`);
    console.log(`   - Drops with valid data: ${reportsWithDetails.filter(r => r.drop).length}`);
    console.log(`   - Drops with admin action taken (censored/flagged): ${reports.filter(r => {
      const drop = drops.find(d => (d as any)._id.toString() === r.dropId);
      return drop && (drop.isCensored || drop.isSuspicious);
    }).length}`);

    return reportsWithDetails;
  }

  /**
   * Handle admin action on a reported drop
   */
  async handleReportedDropAction(reportId: string, dropId: string, action: 'approve' | 'censor' | 'delete', adminId: string, reason?: string) {
    console.log(`🔍 Admin action on reported drop: ${action} for drop ${dropId}, report ${reportId}`);
    
    // Update the report status
    await this.dropReportModel.findByIdAndUpdate(reportId, {
      status: 'reviewed',
      reviewedBy: adminId,
      reviewedAt: new Date(),
      adminAction: action,
      adminNotes: reason,
    }).exec();

    // Take action on the drop based on admin decision
    switch (action) {
      case 'approve':
        // Drop is approved - no action needed, just mark report as reviewed
        console.log(`✅ Drop ${dropId} approved - no changes needed`);
        break;
        
      case 'censor':
        // Censor the drop
        await this.censorDrop(dropId, reason || 'Censored due to report', adminId);
        console.log(`🚫 Drop ${dropId} censored due to report`);
        break;
        
      case 'delete':
        // Delete the drop
        await this.dropoffModel.findByIdAndDelete(dropId).exec();
        console.log(`🗑️ Drop ${dropId} deleted due to report`);
        break;
    }

    return { success: true, action, dropId, reportId };
  }

  /**
   * Review a report (mark as reviewed/dismissed/action taken)
   */
  async reviewReport(reportId: string, adminId: string, status: string, actionTaken?: string, adminNotes?: string) {
    const report = await this.dropReportModel.findByIdAndUpdate(
      reportId,
      {
        status,
        reviewedBy: adminId,
        reviewedAt: new Date(),
        actionTaken,
        adminNotes,
      },
      { new: true },
    ).exec();

    return report;
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
      this.dropoffModel.countDocuments({ createdAt: { $gte: weekAgo } }),
      this.dropoffModel.countDocuments({
        createdAt: { $gte: twoWeeksAgo, $lt: weekAgo },
      }),
    ]);

    // This month vs last month
    const [thisMonth, lastMonth] = await Promise.all([
      this.dropoffModel.countDocuments({ createdAt: { $gte: monthAgo } }),
      this.dropoffModel.countDocuments({
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

