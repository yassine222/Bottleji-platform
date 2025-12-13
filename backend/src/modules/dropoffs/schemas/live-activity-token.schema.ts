import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type LiveActivityTokenDocument = LiveActivityToken & Document;

@Schema({ timestamps: true })
export class LiveActivityToken {
  @Prop({ required: true, type: Types.ObjectId, ref: 'Dropoff' })
  dropoffId: Types.ObjectId;

  @Prop({ required: true })
  activityId: string; // UUID from ActivityKit

  @Prop({ required: true })
  pushToken: string; // Hexadecimal push token from ActivityKit

  @Prop({ required: true, type: Types.ObjectId, ref: 'User' })
  userId: Types.ObjectId; // User who owns the Live Activity (household user)

  @Prop({ default: Date.now })
  createdAt?: Date;

  @Prop({ default: Date.now })
  updatedAt?: Date;
}

export const LiveActivityTokenSchema = SchemaFactory.createForClass(LiveActivityToken);

// Create index for efficient lookups
LiveActivityTokenSchema.index({ dropoffId: 1, activityId: 1 }, { unique: true });
LiveActivityTokenSchema.index({ dropoffId: 1 });

