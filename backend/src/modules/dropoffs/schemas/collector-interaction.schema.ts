import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum InteractionType {
  ACCEPTED = 'accepted',
  COLLECTED = 'collected',
  CANCELLED = 'cancelled',
  EXPIRED = 'expired',
}

export enum CancellationReason {
  WRONG_LOCATION = 'wrongLocation',
  UNSAFE = 'unsafe',
  OTHER = 'other',
}

@Schema({ timestamps: true })
export class CollectorInteraction extends Document {
  @Prop({ required: true, type: String, ref: 'User' })
  collectorId: string;

  @Prop({ required: true, type: String, ref: 'Dropoff' })
  dropoffId: string;

  @Prop({ required: true, enum: InteractionType })
  interactionType: InteractionType;

  @Prop({ enum: CancellationReason })
  cancellationReason?: CancellationReason;

  @Prop()
  notes?: string;

  @Prop({
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number],
    },
  })
  location?: {
    type: string;
    coordinates: number[];
  };

  @Prop()
  interactionTime: Date;

  // Specific timestamp fields based on interaction type
  @Prop()
  acceptedAt?: Date;

  @Prop()
  cancelledAt?: Date;

  @Prop()
  collectedAt?: Date;

  @Prop()
  expiredAt?: Date;

  // Additional metadata for stats
  @Prop()
  dropoffStatus?: string;

  @Prop()
  numberOfItems?: number;

  @Prop()
  bottleType?: string;
}

export const CollectorInteractionSchema = SchemaFactory.createForClass(CollectorInteraction);

// Add virtual for id
CollectorInteractionSchema.virtual('id').get(function(this: any) {
  return this._id.toHexString();
});

// Ensure virtual fields are serialized
CollectorInteractionSchema.set('toJSON', {
  virtuals: true,
  transform: function(doc, ret) {
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

// Add indexes for performance
CollectorInteractionSchema.index({ collectorId: 1, interactionTime: -1 });
CollectorInteractionSchema.index({ dropoffId: 1 });
CollectorInteractionSchema.index({ interactionType: 1 });
CollectorInteractionSchema.index({ dropoffId: 1, interactionType: 1 }); // For duplicate EXPIRED check

