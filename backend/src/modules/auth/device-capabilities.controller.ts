import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { DeviceCapabilitiesService } from '../users/device-capabilities.service';

@Controller('device-capabilities')
export class DeviceCapabilitiesController {
  constructor(private readonly deviceCapabilitiesService: DeviceCapabilitiesService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  async storeCapabilities(@Request() req, @Body() body: {
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
  }) {
    const userId = req.user.userId;

    return this.deviceCapabilitiesService.storeCapabilities({
      userId,
      ...body,
    });
  }

  @Post('push-to-start-token')
  @UseGuards(JwtAuthGuard)
  async storePushToStartToken(@Request() req, @Body() body: {
    pushToStartToken: string;
    fcmToken?: string; // Optional: can be passed in body or retrieved from user
  }) {
    const userId = req.user.id || req.user._id?.toString() || req.user.userId;
    // Get FCM token from body first, then from user object, then from capabilities
    const fcmToken = body.fcmToken || req.user.fcmToken;
    
    if (!fcmToken) {
      // Try to get the most recent active FCM token from capabilities
      const capabilities = await this.deviceCapabilitiesService.getUserCapabilities(userId);
      const activeCapability = capabilities.find(c => c.isActive);
      if (!activeCapability?.fcmToken) {
        throw new Error('FCM token is required. Please provide it in the request body or ensure your device capabilities are stored.');
      }
      return this.deviceCapabilitiesService.updatePushToStartToken(
        userId,
        activeCapability.fcmToken,
        body.pushToStartToken,
      );
    }

    return this.deviceCapabilitiesService.updatePushToStartToken(
      userId,
      fcmToken,
      body.pushToStartToken,
    );
  }
}

