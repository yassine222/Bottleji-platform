import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { User, UserRole, CollectorApplicationStatus } from '../users/schemas/user.schema';
import { CollectorApplication } from '../collector-applications/schemas/collector-application.schema';
import { Dropoff } from '../dropoffs/schemas/dropoff.schema';
import { CollectorInteraction } from '../dropoffs/schemas/collector-interaction.schema';
import { CollectionAttempt } from '../dropoffs/schemas/collection-attempt.schema';
import { SupportTicket } from '../support-tickets/schemas/support-ticket.schema';
import { NotificationsService } from '../notifications/notifications.service';
import { CollectorApplicationsService } from '../collector-applications/collector-applications.service';
import { UsersService } from '../users/users.service';
import { EmailService } from '../email/email.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AdminService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    @InjectModel(CollectorApplication.name) private collectorApplicationModel: Model<CollectorApplication>,
    @InjectModel(Dropoff.name) private dropoffModel: Model<Dropoff>,
    @InjectModel(CollectorInteraction.name) private interactionModel: Model<CollectorInteraction>,
    @InjectModel(CollectionAttempt.name) private collectionAttemptModel: Model<CollectionAttempt>,
    @InjectModel(SupportTicket.name) private supportTicketModel: Model<SupportTicket>,
    private notificationsService: NotificationsService,
    private collectorApplicationsService: CollectorApplicationsService,
    private usersService: UsersService,
    private emailService: EmailService,
  ) {}

  async getDashboardStats() {
    try {
      const now = new Date();
      const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

      const [
        totalUsers, 
        totalDrops, 
        totalApplications, 
        pendingApplications, 
        totalTickets, 
        pendingTickets,
        activeCollectors,
        dropsLast7Days,
        dropsLast30Days,
        usersLast7Days,
        usersLast30Days,
        dropsByStatus,
        applicationsByStatus,
        ticketsByStatus,
        ticketsByCategory,
        bottleTypeDistribution,
      ] = await Promise.all([
        // Basic counts
        this.userModel.countDocuments({ isDeleted: { $ne: true } }),
        this.dropoffModel.countDocuments(),
        this.collectorApplicationModel.countDocuments(),
        this.collectorApplicationModel.countDocuments({ status: 'pending' }),
        this.supportTicketModel.countDocuments({ isDeleted: false }),
        this.supportTicketModel.countDocuments({ 
          isDeleted: false, 
          status: { $in: ['open', 'in_progress'] } 
        }),
        
        // Active collectors (users with collector role)
        this.userModel.countDocuments({ 
          isDeleted: { $ne: true },
          roles: 'collector' 
        }),
        
        // Time-based counts
        this.dropoffModel.countDocuments({ createdAt: { $gte: sevenDaysAgo } }),
        this.dropoffModel.countDocuments({ createdAt: { $gte: thirtyDaysAgo } }),
        this.userModel.countDocuments({ 
          isDeleted: { $ne: true },
          createdAt: { $gte: sevenDaysAgo } 
        }),
        this.userModel.countDocuments({ 
          isDeleted: { $ne: true },
          createdAt: { $gte: thirtyDaysAgo } 
        }),
        
        // Drops by status
        this.dropoffModel.aggregate([
          { $group: { _id: '$status', count: { $sum: 1 } } }
        ]),
        
        // Applications by status
        this.collectorApplicationModel.aggregate([
          { $group: { _id: '$status', count: { $sum: 1 } } }
        ]),
        
        // Tickets by status
        this.supportTicketModel.aggregate([
          { $match: { isDeleted: false } },
          { $group: { _id: '$status', count: { $sum: 1 } } }
        ]),
        
        // Tickets by category
        this.supportTicketModel.aggregate([
          { $match: { isDeleted: false } },
          { $group: { _id: '$category', count: { $sum: 1 } } }
        ]),
        
        // Bottle type distribution
        this.dropoffModel.aggregate([
          { $group: { _id: '$bottleType', count: { $sum: 1 } } }
        ]),
      ]);

      // Get time series data for charts (last 30 days)
      const usersTimeSeries = await this.getUsersTimeSeries(30);
      const dropsTimeSeries = await this.getDropsTimeSeries(30);
      const interactionsTimeSeries = await this.getInteractionsTimeSeries(30);

      // Get recent activity
      const recentActivity = await this.getRecentActivity();

      return {
        // Basic stats
        totalUsers,
        totalDrops,
        totalApplications,
        pendingApplications,
        totalTickets,
        pendingTickets,
        activeCollectors,
        
        // Recent activity counts
        dropsLast7Days,
        dropsLast30Days,
        usersLast7Days,
        usersLast30Days,
        
        // Status breakdowns
        dropsByStatus: dropsByStatus.reduce((acc, item) => {
          acc[item._id] = item.count;
          return acc;
        }, {}),
        
        applicationsByStatus: applicationsByStatus.reduce((acc, item) => {
          acc[item._id] = item.count;
          return acc;
        }, {}),
        
        ticketsByStatus: ticketsByStatus.reduce((acc, item) => {
          acc[item._id] = item.count;
          return acc;
        }, {}),
        
        ticketsByCategory: ticketsByCategory.reduce((acc, item) => {
          acc[item._id] = item.count;
          return acc;
        }, {}),
        
        bottleTypeDistribution: bottleTypeDistribution.reduce((acc, item) => {
          acc[item._id] = item.count;
          return acc;
        }, {}),
        
        // Time series data for charts
        usersTimeSeries,
        dropsTimeSeries,
        interactionsTimeSeries,
        
        recentActivity,
      };
    } catch (error) {
      console.error('Error getting dashboard stats:', error);
      // Return default values if there's an error
      return {
        totalUsers: 0,
        totalDrops: 0,
        totalApplications: 0,
        pendingApplications: 0,
        totalTickets: 0,
        pendingTickets: 0,
        activeCollectors: 0,
        dropsLast7Days: 0,
        dropsLast30Days: 0,
        usersLast7Days: 0,
        usersLast30Days: 0,
        dropsByStatus: {},
        applicationsByStatus: {},
        ticketsByStatus: {},
        ticketsByCategory: {},
        bottleTypeDistribution: {},
        usersTimeSeries: [],
        dropsTimeSeries: [],
        interactionsTimeSeries: [],
        recentActivity: [],
      };
    }
  }

  private async getUsersTimeSeries(days: number) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const timeSeries = await this.userModel.aggregate([
      {
        $match: {
          isDeleted: { $ne: true },
          createdAt: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$createdAt' }
          },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    return this.fillMissingDates(timeSeries, days);
  }

  private async getDropsTimeSeries(days: number) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const timeSeries = await this.dropoffModel.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$createdAt' }
          },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    return this.fillMissingDates(timeSeries, days);
  }

  private async getInteractionsTimeSeries(days: number) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const timeSeries = await this.interactionModel.aggregate([
      {
        $match: {
          interactionTime: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: {
            date: { $dateToString: { format: '%Y-%m-%d', date: '$interactionTime' } },
            type: '$interactionType'
          },
          count: { $sum: 1 }
        }
      },
      { $sort: { '_id.date': 1 } }
    ]);

    // Group by date with all interaction types
    const groupedByDate = timeSeries.reduce((acc, item) => {
      const date = item._id.date;
      if (!acc[date]) {
        acc[date] = { date, accepted: 0, collected: 0, cancelled: 0, expired: 0 };
      }
      acc[date][item._id.type] = item.count;
      return acc;
    }, {});

    return this.fillMissingDatesWithTypes(Object.values(groupedByDate), days);
  }

  private fillMissingDates(timeSeries: any[], days: number): any[] {
    const result: any[] = [];
    const dataMap = new Map(timeSeries.map(item => [item._id, item.count]));
    
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      
      result.push({
        date: dateStr,
        count: dataMap.get(dateStr) || 0
      });
    }
    
    return result;
  }

  private fillMissingDatesWithTypes(timeSeries: any[], days: number): any[] {
    const result: any[] = [];
    const dataMap = new Map(timeSeries.map(item => [item.date, item]));
    
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      
      result.push(dataMap.get(dateStr) || {
        date: dateStr,
        accepted: 0,
        collected: 0,
        cancelled: 0,
        expired: 0
      });
    }
    
    return result;
  }

  async getAllUsers(page = 1, limit = 20, includeDeleted = false) {
    const skip = (page - 1) * limit;
    const filter = includeDeleted ? {} : { isDeleted: { $ne: true } };
    
    const [users, total] = await Promise.all([
      this.userModel.find(filter)
        .select('-password')
        .skip(skip)
        .limit(limit)
        .sort({ createdAt: -1 })
        .exec(),
      this.userModel.countDocuments(filter),
    ]);

    return {
      users,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getUserById(userId: string, includeDeleted = false) {
    const filter = includeDeleted ? { _id: userId } : { _id: userId, isDeleted: { $ne: true } };
    return await this.userModel.findOne(filter).select('-password');
  }

  async getAdminUsers() {
    // Get all users who have admin-level roles
    const adminUsers = await this.userModel.find({
      roles: { $in: ['super_admin', 'admin', 'moderator', 'support_agent'] },
      isDeleted: { $ne: true }
    })
    .select('-password')
    .sort({ createdAt: -1 })
    .exec();

    return adminUsers.map(user => ({
      id: user._id,
      name: user.name || user.email?.split('@')[0] || 'Unknown User',
      email: user.email,
      roles: user.roles,
      isVerified: user.isVerified || false,
      createdAt: user.createdAt,
      lastLogin: undefined, // TODO: Add lastLogin field to User schema if needed
    }));
  }

  async createAdminUser(createAdminDto: { email: string; name: string; role: string }) {
    // Check if user already exists
    const existingUser = await this.userModel.findOne({ email: createAdminDto.email });
    if (existingUser) {
      throw new Error('User with this email already exists');
    }

    // Generate a temporary password
    const tempPassword = Math.random().toString(36).slice(-8) + Math.random().toString(36).slice(-8);
    const hashedPassword = await bcrypt.hash(tempPassword, 10);

    // Create the admin user
    const newAdmin = new this.userModel({
      email: createAdminDto.email,
      name: createAdminDto.name,
      password: hashedPassword,
      roles: [createAdminDto.role],
      isVerified: true, // Admin users are pre-verified
      isProfileComplete: true,
      mustChangePassword: true, // Force password change on first login
    });

    await newAdmin.save();

    // Send invitation email with temporary password
    try {
      await this.emailService.sendAdminInvitation(
        createAdminDto.email,
        createAdminDto.name,
        createAdminDto.role,
        tempPassword
      );
      console.log(`Admin invitation sent to: ${createAdminDto.email}`);
    } catch (error) {
      console.error('Failed to send admin invitation email:', error);
      // Don't fail the user creation if email fails
    }

    return {
      id: newAdmin._id,
      email: newAdmin.email,
      name: newAdmin.name,
      roles: newAdmin.roles,
      isVerified: newAdmin.isVerified,
      createdAt: newAdmin.createdAt,
    };
  }

  async updateUserRole(userId: string, roles: string[]) {
    return await this.userModel.findByIdAndUpdate(
      userId,
      { roles },
      { new: true }
    ).select('-password');
  }

  async banUser(userId: string, reason: string) {
    return await this.userModel.findByIdAndUpdate(
      userId,
      { 
        isAccountLocked: true,
        accountLockedUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
        warnings: [{ reason, date: new Date() }],
      },
      { new: true }
    ).select('-password');
  }

  async unbanUser(userId: string) {
    return await this.userModel.findByIdAndUpdate(
      userId,
      { 
        isAccountLocked: false,
        accountLockedUntil: null,
      },
      { new: true }
    ).select('-password');
  }

  async deleteUser(userId: string, deletedByAdminId: string) {
    try {
      // 1. Soft delete the user
      const deletedUser = await this.userModel.findByIdAndUpdate(
        userId,
        {
          isDeleted: true,
          deletedAt: new Date(),
          deletedBy: deletedByAdminId,
        },
        { new: true }
      ).select('-password');

      if (!deletedUser) {
        throw new Error('User not found');
      }

      // 2. Keep all related data for analytics and statistics
      // - User's drops remain in database
      // - User's collector applications remain in database  
      // - User's interactions remain in database
      // - All data is preserved for analytics and reporting
      console.log(`✅ User ${userId} soft deleted. Related data preserved for analytics.`);

      // 3. Invalidate user sessions by updating a session invalidation timestamp
      await this.userModel.findByIdAndUpdate(userId, {
        sessionInvalidatedAt: new Date(),
      });

      // 4. Send real-time notification for immediate logout
      this.notificationsService.notifyUserDeleted(userId, deletedByAdminId);

      return deletedUser;
    } catch (error) {
      console.error('Error deleting user:', error);
      throw error;
    }
  }

  async restoreUser(userId: string, restoredByAdminId: string) {
    try {
      // 1. Restore the user (remove soft delete flags)
      const restoredUser = await this.userModel.findByIdAndUpdate(
        userId,
        {
          isDeleted: false,
          deletedAt: null,
          deletedBy: null,
          sessionInvalidatedAt: null, // Clear session invalidation
        },
        { new: true }
      ).select('-password');

      if (!restoredUser) {
        throw new Error('User not found');
      }

      console.log(`✅ User ${userId} restored by admin ${restoredByAdminId}`);

      return restoredUser;
    } catch (error) {
      console.error('Error restoring user:', error);
      throw error;
    }
  }

  async getUserActivities(userId: string) {
    try {
      const { Types } = require('mongoose');
      const userObjectId = new Types.ObjectId(userId);
      
      // Get user's drops
      const userDrops = await this.dropoffModel.find({ userId })
        .sort({ createdAt: -1 })
        .exec();

      // Get collection attempts where user is the collector (using new CollectionAttempt system)
      const collectionAttempts = await this.collectionAttemptModel.find({ 
        collectorId: userObjectId 
      })
        .sort({ acceptedAt: -1 })
        .exec();

      // Group activities by type and create timeline
      const activities: any[] = [];

      // Add drop creation activities
      userDrops.forEach(drop => {
        activities.push({
          id: drop._id?.toString(),
          type: 'drop_created',
          title: 'Drop Created',
          description: `Created a drop with ${drop.numberOfBottles} bottles and ${drop.numberOfCans} cans`,
          timestamp: drop.createdAt,
          status: drop.status,
          dropoffId: drop._id?.toString(),
          numberOfBottles: drop.numberOfBottles,
          numberOfCans: drop.numberOfCans,
          bottleType: drop.bottleType,
          location: drop.location,
          notes: drop.notes
        });
      });

      // Add collection attempt activities (using new CollectionAttempt system)
      collectionAttempts.forEach(attempt => {
        // Determine the status and icon based on outcome
        let finalStatus = attempt.outcome || 'accepted';
        let statusIcon = '📋';
        
        if (finalStatus === 'collected') {
          statusIcon = '✅';
        } else if (finalStatus === 'cancelled') {
          statusIcon = '❌';
        } else if (finalStatus === 'expired') {
          statusIcon = '⏰';
        }
        
        // Convert timeline events to interaction format for compatibility
        const interactionsList = attempt.timeline.map(event => ({
          type: event.event,
          time: event.timestamp,
          reason: event.details.reason,
          notes: event.details.notes,
        }));
        
        activities.push({
          id: attempt._id?.toString(),
          type: `collector_${finalStatus}`,
          title: `${statusIcon} Collection ${finalStatus.charAt(0).toUpperCase() + finalStatus.slice(1)}`,
          description: `${attempt.dropSnapshot.numberOfBottles} bottles, ${attempt.dropSnapshot.numberOfCans} cans - ${finalStatus}`,
          timestamp: attempt.completedAt || attempt.acceptedAt,
          dropoffId: attempt.dropoffId?.toString(),
          interactionType: finalStatus,
          interactions: interactionsList, // Include all timeline events
          numberOfBottles: attempt.dropSnapshot.numberOfBottles,
          numberOfCans: attempt.dropSnapshot.numberOfCans,
          bottleType: attempt.dropSnapshot.bottleType,
          location: attempt.dropSnapshot.location,
          userId: attempt.dropSnapshot.createdBy.id,
          attemptNumber: attempt.attemptNumber,
          durationMinutes: attempt.durationMinutes,
        });
      });

      // Sort all activities by timestamp (newest first)
      activities.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

      return activities;
    } catch (error) {
      console.error('Error getting user activities:', error);
      return [];
    }
  }

  async getAllDrops(page = 1, limit = 20, status?: string) {
    const skip = (page - 1) * limit;
    const filter = status ? { status } : {};
    
    const [drops, total] = await Promise.all([
      this.dropoffModel.find(filter)
        .populate('userId', 'name email')
        .skip(skip)
        .limit(limit)
        .sort({ createdAt: -1 })
        .exec(),
      this.dropoffModel.countDocuments(filter),
    ]);

    return {
      drops,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getDropById(dropId: string) {
    return await this.dropoffModel.findById(dropId).populate('userId', 'name email');
  }

  async updateDrop(dropId: string, updateData: any) {
    return await this.dropoffModel.findByIdAndUpdate(
      dropId,
      updateData,
      { new: true }
    ).populate('userId', 'name email');
  }

  async deleteDrop(dropId: string) {
    return await this.dropoffModel.findByIdAndDelete(dropId);
  }

  async getRecentActivity(limit = 10) {
    const activities: any[] = [];

    // Get recent user registrations
    const recentUsers = await this.userModel
      .find({})
      .sort({ createdAt: -1 })
      .limit(limit)
      .select('name email createdAt')
      .exec();

    recentUsers.forEach(user => {
      if (user && user._id && user.name) {
        activities.push({
          id: (user._id as any).toString(),
          type: 'user_registration',
          description: `New user registered: ${user.name}`,
          timestamp: user.createdAt,
          userId: (user._id as any).toString(),
          userName: user.name,
        });
      }
    });

    // Get recent drops
    const recentDrops = await this.dropoffModel
      .find({})
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('userId', 'name')
      .exec();

    recentDrops.forEach(drop => {
      const userId = drop.userId as any;
      if (drop && drop._id && userId && userId._id && userId.name) {
        activities.push({
          id: (drop._id as any).toString(),
          type: 'drop_created',
          description: `New drop created by ${userId.name}`,
          timestamp: drop.createdAt,
          userId: userId._id.toString(),
          userName: userId.name,
        });
      }
    });

    // Sort by timestamp and return top activities
    return activities
      .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
      .slice(0, limit);
  }

  // Collector Applications Management
  async getAllCollectorApplications(status?: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const filter = status ? { status } : {};
    
    // Get applications with pagination
    const applications = await this.collectorApplicationModel
      .find(filter)
      .populate('userId', 'email name')
      .populate('reviewedBy', 'email name')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .exec();

    // Get total count for pagination
    const total = await this.collectorApplicationModel.countDocuments(filter);

    return {
      success: true,
      applications,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getCollectorApplication(applicationId: string) {
    const application = await this.collectorApplicationsService.getApplicationById(applicationId);
    if (!application) {
      throw new Error('Application not found');
    }
    return { success: true, application };
  }

  async approveCollectorApplication(applicationId: string, adminId: string, notes?: string) {
    const application = await this.collectorApplicationsService.approveApplication(applicationId, adminId, notes);
    
    // Add collector role to user
    const user = await this.usersService.findOne(application.userId.toString());
    if (user && !user.roles.includes(UserRole.COLLECTOR)) {
      user.roles.push(UserRole.COLLECTOR);
      await user.save();
    }

    // Update user's application status in user collection
    await this.usersService.update(application.userId.toString(), {
      collectorApplicationStatus: CollectorApplicationStatus.APPROVED,
      collectorApplicationId: applicationId,
      collectorApplicationAppliedAt: application.appliedAt,
      collectorApplicationRejectionReason: undefined, // Clear rejection reason
    });

    // Send notification to user
    this.notificationsService.notifyApplicationApproved(application.userId.toString(), adminId, applicationId);

    return { success: true, application, message: 'Application approved successfully' };
  }

  async rejectCollectorApplication(applicationId: string, adminId: string, rejectionReason: string, notes?: string) {
    const application = await this.collectorApplicationsService.rejectApplication(
      applicationId,
      adminId,
      rejectionReason,
      notes,
    );

    // Update user's application status in user collection
    await this.usersService.update(application.userId.toString(), {
      collectorApplicationStatus: CollectorApplicationStatus.REJECTED,
      collectorApplicationId: applicationId,
      collectorApplicationAppliedAt: application.appliedAt,
      collectorApplicationRejectionReason: rejectionReason,
    });

    // Send notification to user
    this.notificationsService.notifyApplicationRejected(
      application.userId.toString(), 
      rejectionReason, 
      adminId,
      applicationId
    );

    return { success: true, application, message: 'Application rejected successfully' };
  }

  async reverseCollectorApplicationApproval(applicationId: string, adminId: string, notes?: string) {
    const application = await this.collectorApplicationsService.reverseApproval(applicationId, adminId, notes);
    
    // Remove collector role from user if they don't have other approved applications
    const user = await this.usersService.findOne(application.userId.toString());
    if (user) {
      // Check if user has other approved applications
      const otherApprovedApplications = await this.collectorApplicationModel.countDocuments({
        userId: application.userId,
        status: 'approved',
        _id: { $ne: application._id }
      });
      
      // Only remove collector role if no other approved applications exist
      if (otherApprovedApplications === 0 && user.roles.includes(UserRole.COLLECTOR)) {
        user.roles = user.roles.filter(role => role !== UserRole.COLLECTOR);
        await user.save();
        console.log(`🔴 Removed collector role from user ${user.email} - no other approved applications`);
      }
    }

    // Update user's application status in user collection
    await this.usersService.update(application.userId.toString(), {
      collectorApplicationStatus: CollectorApplicationStatus.PENDING,
      collectorApplicationId: applicationId,
      collectorApplicationAppliedAt: application.appliedAt,
      collectorApplicationRejectionReason: undefined, // Clear rejection reason
    });

    // Send notification to user
    this.notificationsService.notifyApplicationReversed(application.userId.toString(), adminId, applicationId);

    return { success: true, application, message: 'Application approval reversed successfully' };
  }

  async getCollectorApplicationStats() {
    try {
      const [total, pending, approved, rejected] = await Promise.all([
        this.collectorApplicationModel.countDocuments(),
        this.collectorApplicationModel.countDocuments({ status: 'pending' }),
        this.collectorApplicationModel.countDocuments({ status: 'approved' }),
        this.collectorApplicationModel.countDocuments({ status: 'rejected' }),
      ]);

      return { 
        success: true, 
        stats: { total, pending, approved, rejected } 
      };
    } catch (error) {
      console.error('Error getting collector application stats:', error);
      return { 
        success: true, 
        stats: { total: 0, pending: 0, approved: 0, rejected: 0 } 
      };
    }
  }

  async getDropInteractions(dropId: string, excludeUserId?: string) {
    try {
      console.log('🔍 Getting drop interactions for dropId:', dropId, 'excludeUserId:', excludeUserId);
      
      // Get all interactions for this drop
      const interactions = await this.interactionModel
        .find({ dropoffId: dropId })
        .populate('collectorId', 'name email')
        .sort({ interactionTime: 1 }) // Sort by oldest first (chronological order)
        .exec();
        
      console.log('🔍 Found interactions:', interactions.length);
      interactions.forEach((interaction, index) => {
        console.log(`Interaction ${index + 1}:`, {
          id: interaction._id?.toString(),
          collectorId: interaction.collectorId,
          collectorIdString: interaction.collectorId.toString(),
          collectorType: typeof interaction.collectorId,
          interactionType: interaction.interactionType,
          notes: interaction.notes
        });
      });

      // Filter out interactions by the excluded user
      // For household tickets: exclude the drop creator (household user)
      // For collector tickets: exclude the ticket creator (collector)
      const filteredInteractions = excludeUserId 
        ? interactions.filter(interaction => {
            const collectorIdStr = interaction.collectorId.toString();
            const shouldExclude = collectorIdStr === excludeUserId;
            console.log(`🔍 Filtering interaction: collectorId=${collectorIdStr}, excludeUserId=${excludeUserId}, shouldExclude=${shouldExclude}`);
            return !shouldExclude;
          })
        : interactions;
        
      console.log('🔍 Filtered interactions:', filteredInteractions.length);

      // Format the interactions for the frontend
      const formattedInteractions = filteredInteractions.map(interaction => {
        const collector = interaction.collectorId as any;
        
        // Handle cases where population failed or collector is null/undefined
        let actorName = 'Unknown User';
        let actorEmail = '';
        let actorId = '';
        
        if (collector && typeof collector === 'object') {
          actorId = collector._id?.toString() || collector.id?.toString() || '';
          actorName = collector.name || collector.email?.split('@')[0] || 'Unknown User';
          actorEmail = collector.email || '';
        } else if (typeof collector === 'string') {
          // If collectorId is still a string (population failed), use the ID directly
          actorId = collector;
          actorName = 'User (ID: ' + collector.substring(0, 8) + '...)';
        }
        
        return {
          id: interaction._id?.toString(),
          type: interaction.interactionType,
          actor: {
            id: actorId,
            name: actorName,
            email: actorEmail
          },
          at: interaction.interactionTime,
          note: interaction.notes,
          cancellationReason: interaction.cancellationReason,
          location: interaction.location
        };
      });

      return {
        success: true,
        interactions: formattedInteractions
      };
    } catch (error) {
      console.error('Error getting drop interactions:', error);
      return {
        success: false,
        interactions: [],
        error: error.message
      };
    }
  }
} 