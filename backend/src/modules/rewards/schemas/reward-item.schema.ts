import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type RewardItemDocument = RewardItem & Document;

export enum RewardCategory {
  COLLECTOR = 'collector',
  HOUSEHOLD = 'household',
}

@Schema({ timestamps: true })
export class RewardItem extends Document {
  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ required: true, trim: true })
  description: string;

  @Prop({ required: true, enum: RewardCategory })
  category: RewardCategory;

  @Prop({ required: true, trim: true })
  subCategory: string;

  @Prop({ required: true, min: 0 })
  pointCost: number;

  @Prop({ required: true, min: 0, default: 0 })
  stock: number;

  @Prop({ trim: true })
  imageUrl?: string;

  @Prop({ default: true })
  isActive: boolean;

  // Wearable type flags (only relevant for Equipment subcategory)
  @Prop({ default: false })
  isFootwear: boolean;

  @Prop({ default: false })
  isJacket: boolean;

  @Prop({ default: false })
  isBottoms: boolean;

  // Metadata
  @Prop({ default: 0 })
  totalRedemptions: number;

  @Prop({ default: Date.now })
  createdAt: Date;

  @Prop({ default: Date.now })
  updatedAt: Date;
}

export const RewardItemSchema = SchemaFactory.createForClass(RewardItem);

// Add indexes for better query performance
RewardItemSchema.index({ category: 1, isActive: 1 });
RewardItemSchema.index({ subCategory: 1 });
RewardItemSchema.index({ pointCost: 1 });
RewardItemSchema.index({ createdAt: -1 });
