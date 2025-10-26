import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Notification, NotificationDocument, NotificationType, NotificationPriority } from './schemas/notification.schema';
import { CreateNotificationDto, UpdateNotificationDto, NotificationFiltersDto } from './dto/notification.dto';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectModel(Notification.name) private notificationModel: Model<NotificationDocument>,
  ) {}

  /**
   * Create a new notification
   */
  async create(createNotificationDto: CreateNotificationDto): Promise<Notification> {
    const notification = new this.notificationModel(createNotificationDto);
    return await notification.save();
  }

  /**
   * Get notifications for a user with filters
   */
  async getUserNotifications(
    userId: string,
    filters: NotificationFiltersDto = {}
  ): Promise<{ notifications: Notification[]; total: number; unreadCount: number }> {
    const query: any = { userId };

    if (filters.type) {
      query.type = filters.type;
    }

    if (filters.isRead !== undefined) {
      query.isRead = filters.isRead;
    }

    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const skip = (page - 1) * limit;

    const [notifications, total, unreadCount] = await Promise.all([
      this.notificationModel
        .find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.notificationModel.countDocuments(query).exec(),
      this.notificationModel.countDocuments({ userId, isRead: false }).exec(),
    ]);

    return { notifications, total, unreadCount };
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId: string, userId: string): Promise<Notification> {
    const notification = await this.notificationModel.findOneAndUpdate(
      { _id: notificationId, userId },
      { isRead: true, readAt: new Date() },
      { new: true }
    ).exec();

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    return notification;
  }

  /**
   * Mark all notifications as read for a user
   */
  async markAllAsRead(userId: string): Promise<{ modifiedCount: number }> {
    const result = await this.notificationModel.updateMany(
      { userId, isRead: false },
      { isRead: true, readAt: new Date() }
    ).exec();

    return { modifiedCount: result.modifiedCount };
  }

  /**
   * Delete notification
   */
  async delete(notificationId: string, userId: string): Promise<void> {
    const result = await this.notificationModel.deleteOne({
      _id: notificationId,
      userId
    }).exec();

    if (result.deletedCount === 0) {
      throw new NotFoundException('Notification not found');
    }
  }

  /**
   * Create order approval notification
   */
  async createOrderApprovedNotification(
    userId: string,
    orderId: string,
    trackingNumber: string,
    estimatedDelivery: Date
  ): Promise<Notification> {
    return this.create({
      userId,
      type: NotificationType.ORDER_APPROVED,
      title: 'Order Approved! 🎉',
      message: `Your order has been approved and is being prepared for shipment. Tracking: ${trackingNumber}`,
      priority: NotificationPriority.HIGH,
      data: {
        orderId,
        trackingNumber,
        estimatedDelivery: estimatedDelivery.toISOString(),
      },
      actions: [
        {
          label: 'Track Order',
          action: 'track_order',
          url: `/orders/${orderId}`,
        },
      ],
    });
  }

  /**
   * Create order rejection notification
   */
  async createOrderRejectedNotification(
    userId: string,
    orderId: string,
    reason: string,
    refundedPoints: number
  ): Promise<Notification> {
    return this.create({
      userId,
      type: NotificationType.ORDER_REJECTED,
      title: 'Order Rejected',
      message: `Your order was rejected: ${reason}. ${refundedPoints} points have been refunded to your account.`,
      priority: NotificationPriority.HIGH,
      data: {
        orderId,
        rejectionReason: reason,
        pointsAmount: refundedPoints,
      },
      actions: [
        {
          label: 'View Order',
          action: 'view_order',
          url: `/orders/${orderId}`,
        },
        {
          label: 'Shop Again',
          action: 'shop_again',
          url: '/rewards',
        },
      ],
    });
  }

  /**
   * Create points earned notification
   */
  async createPointsEarnedNotification(
    userId: string,
    pointsEarned: number,
    totalPoints: number,
    source: string
  ): Promise<Notification> {
    return this.create({
      userId,
      type: NotificationType.POINTS_EARNED,
      title: 'Points Earned! ⭐',
      message: `You earned ${pointsEarned} points for ${source}. Total: ${totalPoints} points.`,
      priority: NotificationPriority.MEDIUM,
      data: {
        pointsAmount: pointsEarned,
        totalPoints,
        source,
      },
      actions: [
        {
          label: 'View Rewards',
          action: 'view_rewards',
          url: '/rewards',
        },
      ],
    });
  }

  /**
   * Clean up expired notifications
   */
  async cleanupExpiredNotifications(): Promise<{ deletedCount: number }> {
    const result = await this.notificationModel.deleteMany({
      expiresAt: { $lt: new Date() }
    }).exec();

    return { deletedCount: result.deletedCount };
  }

  /**
   * Notify user deleted (for admin service)
   */
  async notifyUserDeleted(userId: string, deletedByAdminId: string): Promise<Notification> {
    return this.create({
      userId,
      type: NotificationType.USER_DELETED,
      title: 'Account Deleted',
      message: 'Your account has been deleted by an administrator.',
      priority: NotificationPriority.HIGH,
      data: {
        deletedByAdminId,
        deletedAt: new Date().toISOString(),
      },
    });
  }

  /**
   * Notify application approved (for admin service)
   */
  async notifyApplicationApproved(userId: string, adminId: string, applicationId: string): Promise<Notification> {
    return this.create({
      userId,
      type: NotificationType.APPLICATION_APPROVED,
      title: 'Application Approved! 🎉',
      message: 'Your collector application has been approved. You can now start collecting drops!',
      priority: NotificationPriority.HIGH,
      data: {
        applicationId,
        approvedByAdminId: adminId,
        approvedAt: new Date().toISOString(),
      },
      actions: [
        {
          label: 'Start Collecting',
          action: 'start_collecting',
          url: '/drops',
        },
      ],
    });
  }

  /**
   * Notify application rejected (for admin service)
   */
  async notifyApplicationRejected(userId: string, adminId: string, applicationId: string, reason: string): Promise<Notification> {
    return this.create({
      userId,
      type: NotificationType.APPLICATION_REJECTED,
      title: 'Application Rejected',
      message: `Your collector application was rejected: ${reason}`,
      priority: NotificationPriority.HIGH,
      data: {
        applicationId,
        rejectedByAdminId: adminId,
        rejectionReason: reason,
        rejectedAt: new Date().toISOString(),
      },
      actions: [
        {
          label: 'Apply Again',
          action: 'apply_again',
          url: '/collector-application',
        },
      ],
    });
  }

  /**
   * Notify application reversed (for admin service)
   */
  async notifyApplicationReversed(userId: string, adminId: string, applicationId: string): Promise<Notification> {
    return this.create({
      userId,
      type: NotificationType.APPLICATION_REVERSED,
      title: 'Application Status Reversed',
      message: 'Your collector application status has been reversed by an administrator.',
      priority: NotificationPriority.HIGH,
      data: {
        applicationId,
        reversedByAdminId: adminId,
        reversedAt: new Date().toISOString(),
      },
      actions: [
        {
          label: 'View Application',
          action: 'view_application',
          url: `/collector-application/${applicationId}`,
        },
      ],
    });
  }
}