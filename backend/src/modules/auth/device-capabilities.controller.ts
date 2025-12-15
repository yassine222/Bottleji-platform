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
}

