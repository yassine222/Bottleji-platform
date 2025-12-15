import { Injectable, Logger } from '@nestjs/common';
import { DeviceCapabilitiesService } from '../users/device-capabilities.service';
import { FCMService } from './fcm.service';
import { APNsService } from './apns.service';
import { NotificationsGateway } from './notifications.gateway';
import { DropoffsService } from '../dropoffs/dropoffs.service';

/**
 * Unified Notification Service
 * 
 * SINGLE SOURCE OF TRUTH for notification routing decisions.
 * 
 * Problem Solved:
 * - Prevents duplicate notifications (FCM + Live Activity) for the same event
 * - Duplicate notifications cause delays because:
 *   1. Both compete for delivery resources
 *   2. System throttles when it sees duplicate content
 *   3. Live Activity updates get queued behind notifications
 *   4. Dynamic Island expansion is blocked by notification interference
 * 
 * Decision Logic:
 * - If device supports Live Activities → Send Live Activity update ONLY
 * - If device does NOT support Live Activities → Send FCM notification
 * - Terminal events (completed, error) → Always send notification (Live Activity ends first)
 */
@Injectable()
export class UnifiedNotificationService {
  private readonly logger = new Logger(UnifiedNotificationService.name);

  constructor(
    private readonly deviceCapabilitiesService: DeviceCapabilitiesService,
    private readonly fcmService: FCMService,
    private readonly apnsService: APNsService,
    private readonly notificationsGateway: NotificationsGateway,
  ) {}

  /**
   * Send unified notification for drop status updates
   * 
   * @param userId - User ID to notify
   * @param fcmToken - FCM token (used to identify device and check capabilities)
   * @param dropoffId - Dropoff ID
   * @param updateType - Type of update (ongoing vs terminal)
   * @param notificationPayload - FCM notification payload (used if Live Activity not supported)
   * @param liveActivityContentState - Live Activity content state (used if supported)
   * @param isTerminalEvent - Whether this is a terminal event (collected, cancelled, expired)
   */
  async sendDropStatusUpdate(
    userId: string,
    fcmToken: string,
    dropoffId: string,
    updateType: 'accepted' | 'on_way' | 'location_update' | 'collected' | 'cancelled' | 'expired',
    notificationPayload: {
      type: string;
      title: string;
      message: string;
      data?: Record<string, any>;
    },
    liveActivityContentState?: {
      status: string;
      statusText: string;
      collectorName?: string;
      timeAgo: string;
      distanceRemaining?: number;
    },
    isTerminalEvent: boolean = false,
  ): Promise<{ sent: 'live_activity' | 'notification' | 'none'; reason?: string }> {
    try {
      // Check device capabilities
      const hasLiveActivity = await this.deviceCapabilitiesService.hasLiveActivitySupport(userId, fcmToken);
      const capabilities = await this.deviceCapabilitiesService.getCapabilitiesByToken(userId, fcmToken);

      // TERMINAL EVENTS: Always send notification (Live Activity ends first)
      if (isTerminalEvent) {
        this.logger.log(`📤 [sendDropStatusUpdate] Terminal event (${updateType}) - sending notification only (Live Activity will end)`);
        
        // Note: Live Activity should be ended BEFORE calling this method
        // We send notification for terminal events to inform user
        
        await this.notificationsGateway.sendNotificationToUser(userId, {
          ...notificationPayload,
          timestamp: new Date(),
        });

        return { sent: 'notification' };
      }

      // ONGOING EVENTS: Route based on capabilities
      if (hasLiveActivity && capabilities?.platform === 'ios') {
        // iOS WITH Live Activity support → Send Live Activity update ONLY
        // DO NOT send FCM notification to avoid duplication and delays
        
        if (!liveActivityContentState) {
          this.logger.warn(`⚠️ [sendDropStatusUpdate] Live Activity supported but no content state provided - falling back to notification`);
          await this.notificationsGateway.sendNotificationToUser(userId, {
            ...notificationPayload,
            timestamp: new Date(),
          });
          return { sent: 'notification', reason: 'No Live Activity content state' };
        }

        // Check if there's an active Live Activity token for this dropoff
        // Note: This check is done in DropoffsService.sendLiveActivityUpdate
        // We return 'live_activity' to indicate the decision was made
        // The actual sending is handled by DropoffsService
        
        this.logger.log(`✅ [sendDropStatusUpdate] iOS with Live Activity - sending Live Activity update ONLY (no FCM notification to prevent delay)`);
        this.logger.log(`   User: ${userId}, Dropoff: ${dropoffId}, Update: ${updateType}`);
        
        // Return indication that Live Activity should be sent
        // The caller (DropoffsService) will handle the actual Live Activity update
        return { sent: 'live_activity', reason: 'iOS device with Live Activity support' };
      } else {
        // iOS WITHOUT Live Activity OR Android → Send FCM notification ONLY
        // DO NOT send Live Activity update (not supported or no token)
        
        this.logger.log(`✅ [sendDropStatusUpdate] No Live Activity support - sending FCM notification ONLY`);
        this.logger.log(`   User: ${userId}, Platform: ${capabilities?.platform || 'unknown'}, Dropoff: ${dropoffId}, Update: ${updateType}`);

        await this.notificationsGateway.sendNotificationToUser(userId, {
          ...notificationPayload,
          timestamp: new Date(),
        });

        return { sent: 'notification' };
      }
    } catch (error) {
      this.logger.error(`❌ [sendDropStatusUpdate] Error routing notification: ${error}`);
      return { sent: 'none', reason: `Error: ${error.message}` };
    }
  }

  /**
   * Check if device should receive Live Activity update
   * Helper method for DropoffsService
   */
  async shouldUseLiveActivity(userId: string, fcmToken: string): Promise<boolean> {
    return this.deviceCapabilitiesService.hasLiveActivitySupport(userId, fcmToken);
  }
}

