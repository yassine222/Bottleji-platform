import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';

export enum BottleType {
  PLASTIC = 'plastic',
  CAN = 'can',
  MIXED = 'mixed',
}

export enum DropoffStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  COLLECTED = 'collected',
  CANCELLED = 'cancelled',
  EXPIRED = 'expired',
}

export enum CancellationReason {
  NO_ACCESS = 'noAccess',
  NOT_FOUND = 'notFound',
  ALREADY_COLLECTED = 'alreadyCollected',
  WRONG_LOCATION = 'wrongLocation',
  UNSAFE = 'unsafe',
  OTHER = 'other',
}

@Schema({ timestamps: true })
export class Dropoff extends Document {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  imageUrl: string;

  @Prop({ required: true, default: 0 })
  numberOfBottles: number;

  @Prop({ required: true, default: 0 })
  numberOfCans: number;

  @Prop({ required: true, enum: BottleType })
  bottleType: BottleType;

  @Prop()
  notes?: string;

  @Prop({ required: true, default: false })
  leaveOutside: boolean;

  @Prop({
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number],
      required: true,
    },
  })
  location: {
    type: string;
    coordinates: number[];
  };

  @Prop()
  address?: string;

  @Prop({ required: true, enum: DropoffStatus, default: DropoffStatus.PENDING })
  status: DropoffStatus;

  @Prop({ default: 0 })
  cancellationCount: number;

  @Prop({ default: false })
  isSuspicious: boolean;

  @Prop({ type: [String], default: [] })
  cancelledByCollectorIds: string[];

  // Timestamp fields (automatically managed by Mongoose)
  @Prop()
  createdAt?: Date;

  @Prop()
  updatedAt?: Date;

  // Enhanced cancellation tracking
  @Prop({
    type: [{
      collectorId: { type: String, required: true },
      reason: { type: String, enum: Object.values(CancellationReason), required: true },
      cancelledAt: { type: Date, required: true },
      notes: { type: String },
      location: {
        type: {
          type: String,
          enum: ['Point'],
          default: 'Point',
        },
        coordinates: {
          type: [Number],
        },
      },
    }],
    default: [],
  })
  cancellationHistory: Array<{
    collectorId: string;
    reason: CancellationReason;
    cancelledAt: Date;
    notes?: string;
    location?: {
      type: string;
      coordinates: number[];
    };
  }>;
}

export const DropoffSchema = SchemaFactory.createForClass(Dropoff);

// Add virtual id field to convert _id to id
DropoffSchema.virtual('id').get(function(this: any) {
  return this._id.toHexString();
});

// Ensure virtual fields are serialized
DropoffSchema.set('toJSON', {
  virtuals: true,
  transform: function(doc: any, ret: any) {
    ret.id = ret._id;
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

// Create a 2dsphere index for location queries
DropoffSchema.index({ location: '2dsphere' }); 