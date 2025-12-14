import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import * as apn from 'apn';

@Injectable()
export class APNsService implements OnModuleInit {
  private readonly logger = new Logger(APNsService.name);
  private apnProvider: apn.Provider | null = null;

  onModuleInit() {
    this.initializeAPNs();
  }

  private initializeAPNs() {
    try {
      // Get APNs configuration from environment variables
      const keyId = process.env.APNS_KEY_ID;
      const teamId = process.env.APNS_TEAM_ID;
      const bundleId = process.env.APNS_BUNDLE_ID || 'com.example.botleji';
      const keyPath = process.env.APNS_KEY_PATH;
      const keyContent = process.env.APNS_KEY_CONTENT;
      const isProduction = process.env.NODE_ENV === 'production';

      if (!keyId || !teamId) {
        this.logger.warn('⚠️ APNs configuration missing. Live Activity updates will be disabled.');
        this.logger.warn('⚠️ Required: APNS_KEY_ID, APNS_TEAM_ID');
        this.logger.warn('⚠️ Optional: APNS_BUNDLE_ID, APNS_KEY_PATH, APNS_KEY_CONTENT');
        return;
      }

      // Get key content first
      let key: string | undefined;
      
      if (keyContent) {
        key = keyContent.replace(/\\n/g, '\n');
        this.logger.log('✅ Using APNs key from APNS_KEY_CONTENT environment variable');
      } else if (keyPath) {
        const fs = require('fs');
        const path = require('path');
        const fullKeyPath = path.isAbsolute(keyPath) 
          ? keyPath 
          : path.join(process.cwd(), keyPath);
        
        if (fs.existsSync(fullKeyPath)) {
          key = fs.readFileSync(fullKeyPath, 'utf8');
          this.logger.log(`✅ Using APNs key from file: ${fullKeyPath}`);
        } else {
          this.logger.error(`❌ APNs key file not found: ${fullKeyPath}`);
          return;
        }
      } else {
        this.logger.error('❌ APNs key not provided. Set APNS_KEY_PATH or APNS_KEY_CONTENT');
        return;
      }

      if (!key) {
        this.logger.error('❌ APNs key is empty');
        return;
      }

      // Configure APNs provider options
      const options: apn.ProviderOptions = {
        token: {
          keyId: keyId,
          teamId: teamId,
          key: key, // Required property
        },
        production: isProduction,
      };

      // Initialize APNs provider
      this.apnProvider = new apn.Provider(options);
      this.logger.log('✅ APNs provider initialized successfully');
      this.logger.log(`✅ APNs environment: ${isProduction ? 'Production' : 'Development'}`);
      this.logger.log(`✅ Bundle ID: ${bundleId}`);
      this.logger.log(`✅ Key ID: ${keyId}`);
      this.logger.log(`✅ Team ID: ${teamId}`);
    } catch (error) {
      this.logger.error('❌ Failed to initialize APNs provider:', error);
    }
  }

  async sendLiveActivityUpdate(
    pushToken: string,
    contentState: {
      status: string;
      statusText: string;
      collectorName?: string;
      timeAgo: string;
      distanceRemaining?: number;
    },
    event: 'update' | 'end' = 'update',
    widgetExtensionBundleId?: string
  ): Promise<boolean> {
    if (!this.apnProvider) {
      this.logger.warn('⚠️ APNs provider not initialized. Cannot send Live Activity update.');
      return false;
    }

    try {
      const bundleId = widgetExtensionBundleId || process.env.APNS_TOPIC || process.env.APNS_BUNDLE_ID || 'com.example.botleji.LiveActivityWidgetExtension';

      // Build the Live Activity content state
      const liveActivityContentState = {
        status: contentState.status,
        statusText: contentState.statusText,
        collectorName: contentState.collectorName || null,
        timeAgo: contentState.timeAgo,
        distanceRemaining: contentState.distanceRemaining || null,
      };

      // Create APNs notification
      const notification = new apn.Notification();

      // Set Live Activity specific properties
      notification.topic = bundleId; // Widget extension bundle ID
      // Use type assertion for pushType (may not be in type definitions but required for Live Activities)
      (notification as any).pushType = 'liveactivity'; // Required for Live Activities
      notification.priority = 10; // High priority
      notification.expiry = Math.floor(Date.now() / 1000) + 3600; // 1 hour expiry

      // Build payload for Live Activities
      // IMPORTANT: For Live Activities, 'content-state' must be at ROOT level, not inside 'aps'
      // The apn package merges payload with aps, so we need to structure it carefully
      const timestamp = Math.floor(Date.now() / 1000);
      
      // Set aps properties directly on notification
      (notification as any).aps = {
        timestamp: timestamp,
        event: event,
      };
      
      // Set content-state at root level (custom payload property)
      notification.payload = {
        'content-state': liveActivityContentState,
      };

      // Clean and validate hex string token
      // Live Activity push tokens are 64-byte hex strings (128 hex characters)
      const cleanToken = pushToken.replace(/\s/g, '');
      
      // Validate token format (should be valid hex and 128 chars = 64 bytes)
      if (!/^[0-9a-fA-F]+$/.test(cleanToken)) {
        this.logger.error(`❌ [sendLiveActivityUpdate] Invalid token format: not a valid hex string`);
        this.logger.error(`❌ [sendLiveActivityUpdate] Token (first 50 chars): ${pushToken.substring(0, 50)}...`);
        return false;
      }
      
      if (cleanToken.length !== 128) {
        this.logger.error(`❌ [sendLiveActivityUpdate] Invalid token length: ${cleanToken.length} chars (expected 128 hex chars = 64 bytes)`);
        this.logger.error(`❌ [sendLiveActivityUpdate] Token (first 50 chars): ${pushToken.substring(0, 50)}...`);
        return false;
      }

      this.logger.log(`📤 [sendLiveActivityUpdate] Sending via direct APNs`);
      this.logger.log(`📤 [sendLiveActivityUpdate] Topic: ${bundleId}`);
      this.logger.log(`📤 [sendLiveActivityUpdate] Event: ${event}`);
      this.logger.log(`📤 [sendLiveActivityUpdate] Token (first 20 chars): ${pushToken.substring(0, 20)}...`);
      this.logger.log(`📤 [sendLiveActivityUpdate] Token length: ${cleanToken.length} hex chars (${cleanToken.length / 2} bytes)`);
      this.logger.log(`📤 [sendLiveActivityUpdate] Content state:`, JSON.stringify(liveActivityContentState, null, 2));

      // Convert hex string to Buffer for apn package (it accepts Buffer, string, or string[])
      // Buffer.from(hex, 'hex') creates the proper binary representation
      const tokenBuffer = Buffer.from(cleanToken, 'hex');
      
      // Send notification - apn package accepts Buffer for hex tokens
      const result = await this.apnProvider.send(notification, tokenBuffer as any);

      if (result.sent.length > 0) {
        this.logger.log(`✅ [sendLiveActivityUpdate] Live Activity ${event} sent successfully`);
        this.logger.log(`✅ [sendLiveActivityUpdate] Sent to token: ${pushToken.substring(0, 20)}...`);
        return true;
      }

      if (result.failed.length > 0) {
        const failure = result.failed[0];
        this.logger.error(`❌ [sendLiveActivityUpdate] Failed to send Live Activity update`);
        
        // Access response properties safely
        const response = failure.response as any;
        const reason = response?.reason || 'Unknown error';
        const status = response?.status || 'Unknown';
        
        this.logger.error(`❌ [sendLiveActivityUpdate] Error: ${reason}`);
        this.logger.error(`❌ [sendLiveActivityUpdate] Status: ${status}`);

        // Handle invalid token errors
        if (status === 400 && reason === 'BadDeviceToken') {
          this.logger.warn(`⚠️ [sendLiveActivityUpdate] Invalid Live Activity push token: ${pushToken.substring(0, 20)}...`);
          this.logger.warn(`⚠️ [sendLiveActivityUpdate] Token should be marked as inactive in the database`);
        }

        return false;
      }

      return false;
    } catch (error: any) {
      this.logger.error(`❌ [sendLiveActivityUpdate] Error sending Live Activity update: ${error}`);
      this.logger.error(`❌ [sendLiveActivityUpdate] Error message: ${error.message || 'Unknown error'}`);
      this.logger.error(`❌ [sendLiveActivityUpdate] Full error:`, JSON.stringify(error, null, 2));
      return false;
    }
  }

  async shutdown() {
    if (this.apnProvider) {
      this.apnProvider.shutdown();
      this.logger.log('✅ APNs provider shut down');
    }
  }
}

