import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type DeviceCapabilitiesDocument = DeviceCapabilities & Document;

@Schema({ timestamps: true })
export class DeviceCapabilities {
  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  userId: Types.ObjectId;

  @Prop({ required: true })
  fcmToken: string; // FCM token for this device (used as device identifier)

  @Prop({ required: true, enum: ['ios', 'android'] })
  platform: string;

  // iOS-specific capabilities
  @Prop({ type: Boolean, default: false })
  liveActivitySupported?: boolean; // iOS 16.2+

  @Prop({ type: Boolean, default: false })
  dynamicIslandSupported?: boolean; // iPhone 14 Pro+

  @Prop({ type: String })
  iosVersion?: string;

  // Push tokens for remote Live Activity control
  @Prop({ type: String })
  pushToStartToken?: string; // Token for starting Live Activities remotely (iOS 17.2+)

  // Android-specific capabilities
  @Prop({ type: Boolean, default: false })
  supportsOngoingNotification?: boolean; // Android 8.0+

  @Prop({ type: Boolean, default: false })
  supportsForegroundService?: boolean; // Android 8.0+

  @Prop({ type: String })
  androidVersion?: string;

  // Common fields
  @Prop({ required: true })
  appVersion: string;

  @Prop({ default: Date.now })
  lastUpdatedAt?: Date;

  @Prop({ default: true })
  isActive: boolean; // Device is currently active (not logged out)
}

export const DeviceCapabilitiesSchema = SchemaFactory.createForClass(DeviceCapabilities);

// Create compound index for efficient lookups
DeviceCapabilitiesSchema.index({ userId: 1, fcmToken: 1 }, { unique: true });
DeviceCapabilitiesSchema.index({ userId: 1, isActive: 1 });

