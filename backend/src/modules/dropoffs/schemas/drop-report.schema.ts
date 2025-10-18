import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum ReportReason {
  INAPPROPRIATE_IMAGE = 'inappropriate_image',
  FAKE_DROP = 'fake_drop',
  AMOUNT_MISMATCH = 'amount_mismatch',
  WRONG_LOCATION = 'wrong_location',
  ALREADY_COLLECTED = 'already_collected',
  DANGEROUS_LOCATION = 'dangerous_location',
  OTHER = 'other',
}

export enum ReportStatus {
  PENDING = 'pending',
  REVIEWED = 'reviewed',
  DISMISSED = 'dismissed',
  ACTION_TAKEN = 'action_taken',
}

@Schema({ timestamps: true })
export class DropReport extends Document {
  @Prop({ required: true })
  dropId: string;

  @Prop({ required: true })
  reportedBy: string; // Collector ID

  @Prop({ required: true, enum: ReportReason })
  reason: ReportReason;

  @Prop()
  details?: string; // Additional details from reporter

  @Prop({ required: true, enum: ReportStatus, default: ReportStatus.PENDING })
  status: ReportStatus;

  @Prop()
  reviewedBy?: string; // Admin ID

  @Prop()
  reviewedAt?: Date;

  @Prop()
  actionTaken?: string; // What action admin took (censored, deleted, dismissed, etc.)

  @Prop()
  adminNotes?: string;

  @Prop()
  createdAt?: Date;

  @Prop()
  updatedAt?: Date;
}

export const DropReportSchema = SchemaFactory.createForClass(DropReport);

