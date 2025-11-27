import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type TemporarySignupDocument = TemporarySignup & Document;

@Schema({ timestamps: true })
export class TemporarySignup {
  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  password: string; // Hashed password

  @Prop({ required: true })
  verificationOTP: string;

  @Prop({ required: true })
  otpExpiresAt: Date;

  @Prop({ default: 0 })
  otpAttempts: number;

  @Prop()
  createdAt?: Date;

  @Prop()
  updatedAt?: Date;
}

export const TemporarySignupSchema = SchemaFactory.createForClass(TemporarySignup);

// Note: Email index is automatically created by @Prop({ unique: true }) decorator above
// No need to manually create it again to avoid duplicate index warning

