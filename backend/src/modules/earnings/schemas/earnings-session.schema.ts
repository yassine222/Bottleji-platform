import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type EarningsSessionDocument = EarningsSession & Document;

@Schema({ timestamps: true })
export class EarningsSession {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ required: true, type: Date })
  date: Date; // Session date (YYYY-MM-DD, start of day)

  @Prop({ type: Number, default: 0 })
  sessionEarnings: number; // Total earnings for this session/day

  @Prop({ type: Number, default: 0 })
  collectionCount: number; // Number of collections in this session

  @Prop({ type: [Types.ObjectId], default: [] })
  collectionAttemptIds: Types.ObjectId[]; // Array of CollectionAttempt IDs in this session

  @Prop({ type: Date, required: true })
  startTime: Date; // When first collection of session started

  @Prop({ type: Date, required: true })
  lastCollectionTime: Date; // When last collection of session completed

  @Prop({ type: Boolean, default: true })
  isActive: boolean; // Whether session is still active (last collection within 3 hours)

  @Prop()
  createdAt: Date;

  @Prop()
  updatedAt: Date;
}

export const EarningsSessionSchema = SchemaFactory.createForClass(EarningsSession);

// Indexes for performance
EarningsSessionSchema.index({ userId: 1, date: -1 });
EarningsSessionSchema.index({ userId: 1, isActive: 1 });
EarningsSessionSchema.index({ userId: 1, date: 1 }, { unique: true }); // One session per user per day

