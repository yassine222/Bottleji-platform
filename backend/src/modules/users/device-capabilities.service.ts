import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { DeviceCapabilities, DeviceCapabilitiesDocument } from './schemas/device-capabilities.schema';

export interface DeviceCapabilitiesInput {
  userId: string;
  fcmToken: string;
  platform: 'ios' | 'android';
  // iOS
  liveActivitySupported?: boolean;
  dynamicIslandSupported?: boolean;
  iosVersion?: string;
  // Android
  supportsOngoingNotification?: boolean;
  supportsForegroundService?: boolean;
  androidVersion?: string;
  // Common
  appVersion: string;
}

@Injectable()
export class DeviceCapabilitiesService {
  private readonly logger = new Logger(DeviceCapabilitiesService.name);

  constructor(
    @InjectModel(DeviceCapabilities.name)
    private deviceCapabilitiesModel: Model<DeviceCapabilitiesDocument>,
  ) {}

  /**
   * Store or update device capabilities
   * Called when app launches or capabilities change
   */
  async storeCapabilities(input: DeviceCapabilitiesInput): Promise<DeviceCapabilities> {
    const userIdObjectId = typeof input.userId === 'string' ? new Types.ObjectId(input.userId) : input.userId;

    const capabilities = await this.deviceCapabilitiesModel.findOneAndUpdate(
      { userId: userIdObjectId, fcmToken: input.fcmToken },
      {
        userId: userIdObjectId,
        fcmToken: input.fcmToken,
        platform: input.platform,
        liveActivitySupported: input.liveActivitySupported ?? false,
        dynamicIslandSupported: input.dynamicIslandSupported ?? false,
        iosVersion: input.iosVersion,
        supportsOngoingNotification: input.supportsOngoingNotification ?? false,
        supportsForegroundService: input.supportsForegroundService ?? false,
        androidVersion: input.androidVersion,
        appVersion: input.appVersion,
        lastUpdatedAt: new Date(),
        isActive: true,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    ).exec();

    this.logger.log(`✅ Device capabilities stored for user ${input.userId}, platform: ${input.platform}, FCM token: ${input.fcmToken.substring(0, 20)}...`);
    
    if (input.platform === 'ios') {
      this.logger.log(`   iOS - Live Activity: ${input.liveActivitySupported}, Dynamic Island: ${input.dynamicIslandSupported}, iOS: ${input.iosVersion}`);
    } else {
      this.logger.log(`   Android - Ongoing Notification: ${input.supportsOngoingNotification}, Foreground Service: ${input.supportsForegroundService}, Android: ${input.androidVersion}`);
    }

    return capabilities;
  }

  /**
   * Get device capabilities for a user by FCM token
   */
  async getCapabilitiesByToken(userId: string, fcmToken: string): Promise<DeviceCapabilities | null> {
    const userIdObjectId = typeof userId === 'string' ? new Types.ObjectId(userId) : userId;
    
    const capabilities = await this.deviceCapabilitiesModel.findOne({
      userId: userIdObjectId,
      fcmToken,
      isActive: true,
    }).exec();

    return capabilities;
  }

  /**
   * Get all active device capabilities for a user
   */
  async getUserCapabilities(userId: string): Promise<DeviceCapabilities[]> {
    const userIdObjectId = typeof userId === 'string' ? new Types.ObjectId(userId) : userId;
    
    const capabilities = await this.deviceCapabilitiesModel.find({
      userId: userIdObjectId,
      isActive: true,
    }).exec();

    return capabilities;
  }

  /**
   * Check if user has Live Activity support (iOS only)
   * Used for notification routing decisions
   */
  async hasLiveActivitySupport(userId: string, fcmToken: string): Promise<boolean> {
    const capabilities = await this.getCapabilitiesByToken(userId, fcmToken);
    
    if (!capabilities) {
      this.logger.warn(`⚠️ No capabilities found for user ${userId}, token ${fcmToken.substring(0, 20)}... - defaulting to false`);
      return false;
    }

    // Only iOS supports Live Activities
    if (capabilities.platform !== 'ios') {
      return false;
    }

    return capabilities.liveActivitySupported === true;
  }

  /**
   * Mark device as inactive (user logged out)
   */
  async deactivateDevice(userId: string, fcmToken: string): Promise<void> {
    const userIdObjectId = typeof userId === 'string' ? new Types.ObjectId(userId) : userId;
    
    await this.deviceCapabilitiesModel.updateOne(
      { userId: userIdObjectId, fcmToken },
      { isActive: false },
    ).exec();

    this.logger.log(`✅ Device deactivated for user ${userId}, token ${fcmToken.substring(0, 20)}...`);
  }

  /**
   * Mark all devices for a user as inactive
   */
  async deactivateAllUserDevices(userId: string): Promise<void> {
    const userIdObjectId = typeof userId === 'string' ? new Types.ObjectId(userId) : userId;
    
    await this.deviceCapabilitiesModel.updateMany(
      { userId: userIdObjectId },
      { isActive: false },
    ).exec();

    this.logger.log(`✅ All devices deactivated for user ${userId}`);
  }

  /**
   * Update push-to-start token for a device
   * This token allows the backend to start Live Activities remotely
   */
  async updatePushToStartToken(userId: string, fcmToken: string, pushToStartToken: string): Promise<DeviceCapabilities> {
    const userIdObjectId = typeof userId === 'string' ? new Types.ObjectId(userId) : userId;
    
    // Validate token format (should be 128 hex characters = 64 bytes)
    const cleanToken = pushToStartToken.replace(/\s/g, '').trim();
    if (cleanToken.length !== 128 || !/^[0-9a-fA-F]+$/.test(cleanToken)) {
      throw new Error('Invalid push-to-start token format: must be 128 hex characters');
    }

    const capabilities = await this.deviceCapabilitiesModel.findOneAndUpdate(
      { userId: userIdObjectId, fcmToken },
      {
        pushToStartToken: cleanToken,
        lastUpdatedAt: new Date(),
      },
      { upsert: false, new: true },
    ).exec();

    if (!capabilities) {
      throw new Error(`Device capabilities not found for user ${userId} with FCM token ${fcmToken.substring(0, 20)}...`);
    }

    this.logger.log(`✅ Push-to-start token updated for user ${userId}, token ${fcmToken.substring(0, 20)}...`);
    return capabilities;
  }

  /**
   * Get push-to-start token for a user/device
   */
  async getPushToStartToken(userId: string, fcmToken: string): Promise<string | null> {
    const capabilities = await this.getCapabilitiesByToken(userId, fcmToken);
    return capabilities?.pushToStartToken || null;
  }
}

