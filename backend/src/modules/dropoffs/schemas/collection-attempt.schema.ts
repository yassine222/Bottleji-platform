import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type CollectionAttemptDocument = CollectionAttempt & Document;

@Schema({ timestamps: true })
export class TimelineEvent {
  @Prop({ type: String, enum: ['accepted', 'cancelled', 'expired', 'collected'], required: true })
  event: 'accepted' | 'cancelled' | 'expired' | 'collected';

  @Prop({ required: true })
  timestamp: Date;

  @Prop({ type: Object, required: true })
  collector: {
    id: Types.ObjectId;
    name: string;
    email: string;
  };

  @Prop({ type: Object, required: true })
  details: {
    reason?: string; // For cancelled/expired
    notes?: string;
    location?: {
      lat: number;
      lng: number;
    };
  };
}

@Schema({ _id: false })
export class DropSnapshot {
  @Prop({ required: true })
  imageUrl: string;

  @Prop({ required: true })
  numberOfBottles: number;

  @Prop({ required: true })
  numberOfCans: number;

  @Prop({ required: true })
  bottleType: string;

  @Prop({ type: Object, required: true })
  location: {
    lat: number;
    lng: number;
  };

  @Prop()
  address?: string;

  @Prop()
  notes?: string;

  @Prop()
  leaveOutside?: boolean;

  @Prop({ type: Object, required: true })
  createdBy: {
    id: Types.ObjectId;
    name: string;
    email: string;
  };

  @Prop({ required: true })
  createdAt: Date;
}

@Schema({ timestamps: true })
export class CollectionAttempt {
  @Prop({ type: Types.ObjectId, ref: 'Dropoff', required: true })
  dropoffId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  collectorId: Types.ObjectId;

  // Core status
  @Prop({ type: String, enum: ['active', 'completed'], default: 'active' })
  status: 'active' | 'completed';

  @Prop({ type: String, enum: ['expired', 'cancelled', 'collected'], default: null })
  outcome: 'expired' | 'cancelled' | 'collected' | null;

  // Timeline events (for UI display)
  @Prop({ type: [TimelineEvent], default: [] })
  timeline: TimelineEvent[];

  // Quick access fields (for performance)
  @Prop({ required: true })
  acceptedAt: Date;

  @Prop({ type: Date, default: null })
  completedAt: Date | null;

  @Prop({ type: Number, default: null })
  durationMinutes: number | null;

  // Drop snapshot (for history display)
  @Prop({ type: DropSnapshot, required: true })
  dropSnapshot: DropSnapshot;

  // Metadata
  @Prop({ default: 1 })
  attemptNumber: number; // 1, 2, 3... (for retries)

  @Prop({ default: 0 })
  cancellationCount: number; // Track how many times this drop was cancelled

  // Timestamps
  @Prop()
  createdAt: Date;

  @Prop()
  updatedAt: Date;
}

export const CollectionAttemptSchema = SchemaFactory.createForClass(CollectionAttempt);

// Indexes for performance
CollectionAttemptSchema.index({ dropoffId: 1 });
CollectionAttemptSchema.index({ collectorId: 1 });
CollectionAttemptSchema.index({ status: 1 });
CollectionAttemptSchema.index({ outcome: 1 });
CollectionAttemptSchema.index({ acceptedAt: -1 });
CollectionAttemptSchema.index({ completedAt: -1 });
