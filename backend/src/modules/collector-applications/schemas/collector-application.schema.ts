import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum CollectorApplicationStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
}

@Schema({ timestamps: true })
export class CollectorApplication extends Document {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ type: String, enum: CollectorApplicationStatus, default: CollectorApplicationStatus.PENDING })
  status: CollectorApplicationStatus;

  // ID Card Information
  @Prop({ required: true })
  idCardPhoto: string;

  @Prop({ required: true })
  selfieWithIdPhoto: string;

  @Prop()
  idCardNumber?: string;

  @Prop()
  idCardType?: string; // e.g., "National ID", "Passport", "Driver's License"

  @Prop()
  idCardExpiryDate?: Date;

  @Prop()
  idCardIssuingAuthority?: string;

  // Additional photo fields
  @Prop()
  idCardBackPhoto?: string;

  // Passport specific fields
  @Prop()
  passportIssueDate?: Date;

  @Prop()
  passportExpiryDate?: Date;

  @Prop()
  passportMainPagePhoto?: string;

  // Additional verification fields
  @Prop()
  rejectionReason?: string;

  @Prop({ type: Date, default: Date.now })
  appliedAt: Date;

  @Prop()
  reviewedAt?: Date;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  reviewedBy?: Types.ObjectId; // Admin who reviewed the application

  @Prop()
  reviewNotes?: string;

  @Prop({ default: Date.now })
  createdAt: Date;

  @Prop({ default: Date.now })
  updatedAt: Date;
}

export const CollectorApplicationSchema = SchemaFactory.createForClass(CollectorApplication);

// Create indexes for better query performance
CollectorApplicationSchema.index({ userId: 1 });
CollectorApplicationSchema.index({ status: 1 });
CollectorApplicationSchema.index({ createdAt: -1 });

// Add virtual id field to convert _id to id
CollectorApplicationSchema.virtual('id').get(function(this: any) {
  return this._id.toHexString();
});

// Ensure virtual fields are serialized
CollectorApplicationSchema.set('toJSON', {
  virtuals: true,
  transform: function(doc: any, ret: any) {
    ret.id = ret._id;
    delete ret._id;
    delete ret.__v;
    return ret;
  }
}); 