import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type RewardRedemptionDocument = RewardRedemption & Document;

export enum RedemptionStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  PROCESSING = 'processing',
  SHIPPED = 'shipped',
  DELIVERED = 'delivered',
  CANCELLED = 'cancelled',
  REJECTED = 'rejected',
}

@Schema({ timestamps: true })
export class RewardRedemption extends Document {
  @Prop({ required: true, ref: 'User' })
  userId: string;

  @Prop({ required: true, ref: 'RewardItem' })
  rewardItemId: string;

  @Prop({ required: true })
  rewardItemName: string;

  @Prop({ required: true, min: 0 })
  pointsSpent: number;

  @Prop({ required: true, enum: RedemptionStatus, default: RedemptionStatus.PENDING })
  status: RedemptionStatus;

  // Delivery information
  @Prop({ 
    required: true,
    type: {
      street: { type: String, required: true },
      city: { type: String, required: true },
      state: { type: String, required: true },
      zipCode: { type: String, required: true },
      country: { type: String, required: true },
      phoneNumber: { type: String, required: true },
      additionalNotes: { type: String, required: false }
    }
  })
  deliveryAddress: {
    street: string;
    city: string;
    state: string;
    zipCode: string;
    country: string;
    phoneNumber: string;
    additionalNotes?: string;
  };

  // Size selection (for wearable items)
  @Prop()
  selectedSize?: string;

  @Prop()
  sizeType?: string; // 'footwear', 'jacket', 'bottoms'

  // Order tracking
  @Prop()
  trackingNumber?: string;

  @Prop()
  estimatedDelivery?: Date;

  // Admin notes
  @Prop()
  adminNotes?: string;

  @Prop()
  rejectionReason?: string;

  // Timestamps for status changes
  @Prop()
  approvedAt?: Date;

  @Prop()
  processingAt?: Date;

  @Prop()
  shippedAt?: Date;

  @Prop()
  deliveredAt?: Date;

  @Prop()
  rejectedAt?: Date;

  @Prop()
  cancelledAt?: Date;

  // Metadata
  @Prop({ default: Date.now })
  createdAt: Date;

  @Prop({ default: Date.now })
  updatedAt: Date;
}

export const RewardRedemptionSchema = SchemaFactory.createForClass(RewardRedemption);
