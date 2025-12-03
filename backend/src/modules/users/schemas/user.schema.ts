import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum UserRole {
  HOUSEHOLD = 'household',
  COLLECTOR = 'collector',
  SUPPORT_AGENT = 'support_agent',
  MODERATOR = 'moderator',
  ADMIN = 'admin',
  SUPER_ADMIN = 'super_admin',
}

export enum CollectorApplicationStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
}

@Schema()
export class CollectorApplication {
  @Prop({ type: String, enum: CollectorApplicationStatus, default: CollectorApplicationStatus.PENDING })
  status: CollectorApplicationStatus;

  @Prop()
  idCardPhoto: string;

  @Prop()
  selfieWithIdPhoto: string;

  @Prop()
  rejectionReason?: string;

  @Prop({ default: Date.now })
  appliedAt: Date;

  @Prop()
  reviewedAt?: Date;
}

@Schema()
export class User extends Document {
  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  password: string;

  @Prop()
  name?: string;

  @Prop()
  phoneNumber?: string;

  @Prop({ default: false })
  isPhoneVerified: boolean;

  @Prop()
  phoneVerificationId?: string;

  @Prop({ default: false })
  registeredWithPhone: boolean; // Track if user originally registered with phone number

  @Prop()
  address?: string;

  @Prop()
  profilePhoto?: string;

  @Prop({ type: [String], enum: UserRole, default: [UserRole.HOUSEHOLD] })
  roles: UserRole[];

  @Prop({ type: CollectorApplication })
  collectorApplication?: CollectorApplication;

  // Collector application status fields (for real-time updates)
  @Prop({ type: String, enum: CollectorApplicationStatus })
  collectorApplicationStatus?: CollectorApplicationStatus;

  @Prop()
  collectorApplicationId?: string;

  @Prop()
  collectorApplicationAppliedAt?: Date;

  @Prop()
  collectorApplicationRejectionReason?: string;

  @Prop({ type: String, enum: ['basic', 'premium'], default: 'basic' })
  collectorSubscriptionType: string;

  @Prop({ default: false })
  isProfileComplete: boolean;

  // Verification fields
  @Prop()
  verificationOTP?: string;

  @Prop()
  otpExpiresAt?: Date;

  @Prop({ default: 0 })
  otpAttempts: number;

  @Prop({ default: false })
  isVerified: boolean;

  // Email verification fields (for phone users who add email later)
  @Prop({ default: false })
  isEmailVerified: boolean; // Track if email is verified (separate from account verification)

  @Prop()
  emailVerificationOTP?: string;

  @Prop()
  emailOtpExpiresAt?: Date;

  @Prop({ default: 0 })
  emailOtpAttempts: number;

  // Password reset fields
  @Prop()
  resetPasswordOtp?: string;

  @Prop()
  resetPasswordOtpExpiry?: Date;

  // Phone verification OTP fields
  @Prop()
  phoneVerificationOtp?: string;

  @Prop()
  phoneOtpExpiresAt?: Date;

  @Prop({ default: 0 })
  phoneOtpAttempts: number;

  // Admin password change requirement
  @Prop({ default: false })
  mustChangePassword: boolean;

  // Warning fields
  @Prop({ default: 0 })
  warningCount: number;

  @Prop({ default: false })
  isAccountLocked: boolean;

  @Prop()
  accountLockedUntil?: Date;

  @Prop({ type: [Object], default: [] })
  warnings: any[];

  // Soft delete fields
  @Prop({ default: false })
  isDeleted: boolean;

  @Prop()
  deletedAt?: Date;

  @Prop()
  deletedBy?: string;

  // Session invalidation field
  @Prop()
  sessionInvalidatedAt?: Date;

  // Reward System Fields (Unified for both Collector and Household roles)
  @Prop({ default: 0 })
  totalDropsCollected: number;

  @Prop({ default: 0 })
  totalDropsCreated: number;

  @Prop({ default: 0 })
  totalPointsEarned: number;

  @Prop({ default: 0 })
  currentPoints: number;

  @Prop({ default: 1 })
  currentTier: number;

  @Prop({ default: Date.now })
  lastDropCollectedAt?: Date;

  @Prop({ default: Date.now })
  lastDropCreatedAt?: Date;

  @Prop({ type: [Object], default: [] })
  rewardHistory: any[];

  // FCM token for push notifications
  @Prop()
  fcmToken?: string;

  // Earnings fields
  @Prop({ type: Number, default: 0 })
  totalEarnings: number; // Lifetime cumulative earnings across all sessions

  @Prop({ type: [Object], default: [] })
  earningsHistory: any[]; // Array of earnings sessions (similar to rewardHistory)

  @Prop({ default: Date.now })
  createdAt: Date;

  @Prop({ default: Date.now })
  updatedAt: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);

// Export the document type
export type UserDocument = User & Document;

// Add virtual id field to convert _id to id
UserSchema.virtual('id').get(function(this: any) {
  return this._id.toHexString();
});

// Ensure virtual fields are serialized
UserSchema.set('toJSON', {
  virtuals: true,
  transform: function(doc: any, ret: any) {
    ret.id = ret._id;
    delete ret._id;
    delete ret.__v;
    return ret;
  }
}); 