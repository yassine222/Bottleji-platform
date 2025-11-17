import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type NotificationDocument = Notification & Document;

export enum NotificationType {
  ORDER_APPROVED = 'order_approved',
  ORDER_REJECTED = 'order_rejected',
  ORDER_SHIPPED = 'order_shipped',
  ORDER_DELIVERED = 'order_delivered',
  POINTS_EARNED = 'points_earned',
  SYSTEM_ANNOUNCEMENT = 'system_announcement',
  USER_DELETED = 'user_deleted',
  APPLICATION_APPROVED = 'application_approved',
  APPLICATION_REJECTED = 'application_rejected',
  APPLICATION_REVERSED = 'application_reversed',
  // Drop-related notifications
  DROP_ACCEPTED = 'drop_accepted',
  DROP_COLLECTED = 'drop_collected',
  DROP_COLLECTED_WITH_REWARDS = 'drop_collected_with_rewards',
  DROP_COLLECTED_WITH_TIER_UPGRADE = 'drop_collected_with_tier_upgrade',
  DROP_CANCELLED = 'drop_cancelled',
  DROP_EXPIRED = 'drop_expired',
  DROP_NEAR_EXPIRING = 'drop_near_expiring',
  DROP_CENSORED = 'drop_censored',
  // Support ticket notifications
  TICKET_MESSAGE = 'ticket_message',
  // Account notifications
  ACCOUNT_LOCKED = 'account_locked',
  ACCOUNT_UNLOCKED = 'account_unlocked',
  // Other
  TEST = 'test',
}

export enum NotificationPriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  URGENT = 'urgent',
}

@Schema({ timestamps: true })
export class Notification extends Document {
  @Prop({ required: true, ref: 'User' })
  userId: string;

  @Prop({ required: true, enum: NotificationType })
  type: NotificationType;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  message: string;

  @Prop({ enum: NotificationPriority, default: NotificationPriority.MEDIUM })
  priority: NotificationPriority;

  @Prop({ default: false })
  isRead: boolean;

  @Prop()
  readAt?: Date;

  // Additional data for specific notification types
  @Prop({ type: Object })
  data?: {
    orderId?: string;
    pointsAmount?: number;
    trackingNumber?: string;
    rejectionReason?: string;
    [key: string]: any;
  };

  // Action buttons for notifications
  @Prop({ type: [Object] })
  actions?: Array<{
    label: string;
    action: string;
    url?: string;
  }>;

  // Expiration date (optional)
  @Prop()
  expiresAt?: Date;

  // Metadata
  @Prop({ default: Date.now })
  createdAt: Date;

  @Prop({ default: Date.now })
  updatedAt: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);

// Index for efficient queries
NotificationSchema.index({ userId: 1, createdAt: -1 });
NotificationSchema.index({ userId: 1, isRead: 1 });
NotificationSchema.index({ type: 1 });
