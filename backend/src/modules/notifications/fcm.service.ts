import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { UsersService } from '../users/users.service';

@Injectable()
export class FCMService implements OnModuleInit {
  private readonly logger = new Logger(FCMService.name);
  private firebaseApp: admin.app.App | null = null;

  constructor(private readonly usersService: UsersService) {
    this.logger.log('🔔 FCMService: Constructor called');
  }

  onModuleInit() {
    this.logger.log('🔔 FCMService: onModuleInit called - initializing Firebase...');
    this.initializeFirebase();
  }

  private initializeFirebase() {
    try {
      this.logger.log('🔔 FCMService: Starting Firebase initialization...');
      this.logger.log(`🔔 FCMService: Current working directory: ${process.cwd()}`);
      this.logger.log(`🔔 FCMService: Admin apps count: ${admin.apps.length}`);
      
      // Initialize Firebase Admin SDK
      // Priority: 1. Environment variable, 2. Service account file, 3. Default credentials
      if (!admin.apps.length) {
        let serviceAccount: any = null;

        // Option 1: Try environment variable first
        if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
          this.logger.log('🔔 FCMService: Found FIREBASE_SERVICE_ACCOUNT_KEY in environment');
          this.logger.log(`🔔 FCMService: Key length: ${process.env.FIREBASE_SERVICE_ACCOUNT_KEY.length} characters`);
          try {
            serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
            // Validate service account has required fields
            if (!serviceAccount.project_id || !serviceAccount.private_key || !serviceAccount.client_email) {
              this.logger.error('❌ FIREBASE_SERVICE_ACCOUNT_KEY is missing required fields!');
              this.logger.error(`❌ Has project_id: ${!!serviceAccount.project_id}`);
              this.logger.error(`❌ Has private_key: ${!!serviceAccount.private_key}`);
              this.logger.error(`❌ Has client_email: ${!!serviceAccount.client_email}`);
              serviceAccount = null; // Reset to try file
            } else {
            this.logger.log('✅ Using FIREBASE_SERVICE_ACCOUNT_KEY from environment variable');
              this.logger.log(`✅ Project ID: ${serviceAccount.project_id}`);
              this.logger.log(`✅ Client Email: ${serviceAccount.client_email}`);
            }
          } catch (error) {
            this.logger.error('❌ Failed to parse FIREBASE_SERVICE_ACCOUNT_KEY from environment variable:', error);
            serviceAccount = null; // Reset to try file
          }
        } else {
          this.logger.log('ℹ️ FCMService: No FIREBASE_SERVICE_ACCOUNT_KEY in environment, trying file...');
        }

        // Option 2: Try service account file (for development)
        if (!serviceAccount) {
          try {
            const fs = require('fs');
            const path = require('path');
            const serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');
            this.logger.log(`🔔 FCMService: Looking for file at: ${serviceAccountPath}`);
            
            if (fs.existsSync(serviceAccountPath)) {
              this.logger.log('✅ FCMService: File found, reading...');
              serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
              this.logger.log('✅ Using firebase-service-account.json file');
              this.logger.log(`✅ Project ID: ${serviceAccount.project_id}`);
              this.logger.log(`✅ Client Email: ${serviceAccount.client_email}`);
            } else {
              this.logger.warn(`❌ FCMService: File not found at: ${serviceAccountPath}`);
            }
          } catch (error) {
            this.logger.error('❌ FCMService: Error reading service account file:', error);
          }
        }

        // Initialize with service account if found
        if (serviceAccount) {
          try {
            this.logger.log('🔔 FCMService: Initializing Firebase Admin SDK with service account...');
            this.logger.log(`🔔 FCMService: Project ID: ${serviceAccount.project_id}`);
            this.logger.log(`🔔 FCMService: Client Email: ${serviceAccount.client_email}`);
            
            // Create credential first to validate it
            const credential = admin.credential.cert(serviceAccount);
            this.logger.log('✅ Credential created successfully');
            
            // Initialize Firebase with explicit project ID
            this.firebaseApp = admin.initializeApp({
              credential: credential,
              projectId: serviceAccount.project_id, // Explicitly set project ID
            });
            
            this.logger.log('✅ Firebase Admin SDK initialized successfully with service account');
            this.logger.log(`✅ Firebase App Name: ${this.firebaseApp.name}`);
            this.logger.log(`✅ Firebase Project ID: ${this.firebaseApp.options.projectId}`);
            
            // Verify project ID is actually set
            if (!this.firebaseApp.options.projectId) {
              this.logger.error('❌ CRITICAL: Firebase app initialized but project ID is still missing!');
              this.logger.error('❌ Firebase options:', JSON.stringify(this.firebaseApp.options, null, 2));
            }
          } catch (error) {
            this.logger.error('❌ FCMService: Error initializing Firebase Admin SDK:', error);
            if (error instanceof Error) {
              this.logger.error('❌ Error message:', error.message);
              this.logger.error('❌ Error stack:', error.stack);
            }
            throw error;
          }
        } else {
          // Option 3: Try default credentials (for Google Cloud environments)
          // NOTE: This usually doesn't work on Render unless Google Cloud credentials are configured
          this.logger.log('ℹ️ FCMService: No service account found, trying default credentials...');
          this.logger.warn('⚠️ WARNING: Default credentials may not work on Render!');
          this.logger.warn('⚠️ FCM notifications will likely fail without proper service account.');
          try {
            this.firebaseApp = admin.initializeApp({
              credential: admin.credential.applicationDefault(),
            });
            this.logger.log('✅ Firebase Admin SDK initialized with default credentials');
            // Verify project ID is set
            if (!this.firebaseApp.options.projectId) {
              this.logger.error('❌ CRITICAL: Default credentials initialized but project ID is missing!');
              this.logger.error('❌ This usually means FIREBASE_SERVICE_ACCOUNT_KEY is not set in Render environment variables');
              this.logger.error('❌ FCM notifications will NOT work until service account is configured');
            }
          } catch (error) {
            this.logger.error('❌ Firebase Admin SDK not initialized. FCM notifications will not work.');
            this.logger.error('To enable FCM:');
            this.logger.error('  1. Set FIREBASE_SERVICE_ACCOUNT_KEY environment variable in Render dashboard, OR');
            this.logger.error('  2. Place firebase-service-account.json in the backend root directory');
            this.logger.error('Error details:', error);
          }
        }
      } else {
        this.firebaseApp = admin.app();
        this.logger.log('ℹ️ Firebase Admin SDK already initialized (reusing existing instance)');
      }
    } catch (error) {
      this.logger.error('❌ FCMService: Critical error initializing Firebase Admin SDK:', error);
      if (error instanceof Error) {
        this.logger.error('Error message:', error.message);
        this.logger.error('Error stack:', error.stack);
      }
    }
  }

  async sendNotificationToUser(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, any>,
  ): Promise<boolean> {
    if (!this.firebaseApp) {
      this.logger.warn('Firebase Admin SDK not initialized. Cannot send FCM notification.');
      return false;
    }

    // Verify Firebase app has project ID
    if (!this.firebaseApp.options.projectId) {
      this.logger.error('Firebase Admin SDK initialized but project ID is missing!');
      this.logger.error('Firebase options:', JSON.stringify(this.firebaseApp.options, null, 2));
      return false;
    }

    try {
      // Get user's FCM token
      const user = await this.usersService.findOne(userId);
      if (!user || !user.fcmToken) {
        this.logger.warn(`User ${userId} does not have an FCM token`);
        return false;
      }

      const message: admin.messaging.Message = {
        token: user.fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: data
          ? Object.entries(data).reduce((acc, [key, value]) => {
              acc[key] = String(value);
              return acc;
            }, {} as Record<string, string>)
          : undefined,
        android: {
          priority: 'high' as const,
          notification: {
            channelId: 'bottleji_notifications',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Use the initialized Firebase app (not the default app)
      const response = await this.firebaseApp.messaging().send(message);
      this.logger.log(`FCM notification sent successfully to user ${userId}: ${response}`);
      return true;
    } catch (error) {
      this.logger.error(`Error sending FCM notification to user ${userId}:`, error);
      
      // If token is invalid, remove it from user
      if (error.code === 'messaging/invalid-registration-token' || 
          error.code === 'messaging/registration-token-not-registered') {
        this.logger.warn(`Invalid FCM token for user ${userId}, removing token`);
        await this.usersService.update(userId, { fcmToken: undefined });
      }
      
      return false;
    }
  }

  async sendNotificationToMultipleUsers(
    userIds: string[],
    title: string,
    body: string,
    data?: Record<string, any>,
  ): Promise<{ success: number; failed: number }> {
    if (!this.firebaseApp) {
      this.logger.warn('Firebase Admin SDK not initialized. Cannot send FCM notifications.');
      return { success: 0, failed: userIds.length };
    }

    let success = 0;
    let failed = 0;

    for (const userId of userIds) {
      const result = await this.sendNotificationToUser(userId, title, body, data);
      if (result) {
        success++;
      } else {
        failed++;
      }
    }

    return { success, failed };
  }

  /**
   * Send Live Activity push update via APNs
   * This sends a push notification specifically for Live Activities with content-state updates
   * 
   * APNs Live Activity payload format:
   * {
   *   "aps": {
   *     "timestamp": <unix_timestamp>,
   *     "event": "update" | "end",
   *     "content-state": {
   *       "activityType": "dropTimeline",
   *       "status": "...",
   *       "statusText": "...",
   *       "collectorName": "...",
   *       "timeAgo": "..."
   *     }
   *   }
   * }
   */
  async sendLiveActivityUpdate(
    pushToken: string,
    contentState: {
      status: string;
      statusText: string;
      collectorName?: string;
      timeAgo: string;
      distanceRemaining?: number; // Distance in meters for collector pin position
    },
    event: 'update' | 'end' = 'update'
  ): Promise<boolean> {
    if (!this.firebaseApp) {
      this.logger.warn('Firebase Admin SDK not initialized. Cannot send Live Activity update.');
      return false;
    }

    try {
      // Build the Live Activity content state payload
      // The package expects activityType to be included
      const liveActivityContentState = {
        activityType: 'dropTimeline',
        status: contentState.status,
        statusText: contentState.statusText,
        collectorName: contentState.collectorName || '',
        timeAgo: contentState.timeAgo,
        distanceRemaining: contentState.distanceRemaining, // Include distance for collector pin
      };

      // Build APNs payload for Live Activity
      const apnsPayload = {
        aps: {
          timestamp: Math.floor(Date.now() / 1000), // Unix timestamp in seconds
          event: event,
          'content-state': liveActivityContentState,
        },
      };

      // Create Firebase message with APNs-specific configuration
      const message: admin.messaging.Message = {
        token: pushToken, // APNs push token (hex string)
        apns: {
          headers: {
            'apns-priority': '10', // High priority for Live Activity updates
            'apns-push-type': 'liveactivity', // Required for Live Activities
            'apns-topic': process.env.APNS_TOPIC || 'com.example.botleji.LiveActivityWidgetExtension', // Widget extension bundle ID
          },
          payload: apnsPayload,
        },
      };

      // Log the full message structure for debugging
      this.logger.log(`📤 [sendLiveActivityUpdate] Sending push notification via Firebase Admin SDK`);
      this.logger.log(`📤 [sendLiveActivityUpdate] APNs Topic: ${process.env.APNS_TOPIC || 'com.example.botleji.LiveActivityWidgetExtension'}`);
      this.logger.log(`📤 [sendLiveActivityUpdate] Event: ${event}`);
      this.logger.log(`📤 [sendLiveActivityUpdate] Token (first 20 chars): ${pushToken.substring(0, 20)}...`);
      this.logger.log(`📤 [sendLiveActivityUpdate] Full payload:`, JSON.stringify(apnsPayload, null, 2));
      
      // Send via Firebase Admin SDK (which handles APNs communication)
      const response = await this.firebaseApp.messaging().send(message);
      
      this.logger.log(`✅ [sendLiveActivityUpdate] Live Activity ${event} sent successfully: ${response}`);
      this.logger.log(`✅ [sendLiveActivityUpdate] Token: ${pushToken.substring(0, 20)}...`);
      this.logger.log(`✅ [sendLiveActivityUpdate] Content state:`, JSON.stringify(liveActivityContentState, null, 2));
      
      return true;
    } catch (error: any) {
      this.logger.error(`❌ [sendLiveActivityUpdate] Error sending Live Activity update: ${error}`);
      this.logger.error(`❌ [sendLiveActivityUpdate] Error code: ${error.code || 'unknown'}`);
      this.logger.error(`❌ [sendLiveActivityUpdate] Error message: ${error.message || 'unknown'}`);
      this.logger.error(`❌ [sendLiveActivityUpdate] Full error:`, JSON.stringify(error, null, 2));
      
      // Handle specific error cases
      if (error.code === 'messaging/invalid-registration-token' || 
          error.code === 'messaging/registration-token-not-registered') {
        this.logger.warn(`⚠️ [sendLiveActivityUpdate] Invalid Live Activity push token: ${pushToken.substring(0, 20)}...`);
        this.logger.warn(`⚠️ [sendLiveActivityUpdate] Token should be marked as inactive in the database`);
      }
      
      // Check for APNs-specific errors
      if (error.code === 'messaging/invalid-argument') {
        this.logger.error(`❌ [sendLiveActivityUpdate] Invalid argument - check APNs topic and payload structure`);
      }
      
      return false;
    }
  }
}

