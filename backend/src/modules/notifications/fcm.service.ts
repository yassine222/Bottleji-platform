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
          try {
            serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
            this.logger.log('✅ Using FIREBASE_SERVICE_ACCOUNT_KEY from environment variable');
          } catch (error) {
            this.logger.warn('❌ Failed to parse FIREBASE_SERVICE_ACCOUNT_KEY from environment variable:', error);
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
            this.firebaseApp = admin.initializeApp({
              credential: admin.credential.cert(serviceAccount),
              projectId: serviceAccount.project_id, // Explicitly set project ID
            });
            this.logger.log('✅ Firebase Admin SDK initialized successfully with service account');
            this.logger.log(`✅ Firebase App Name: ${this.firebaseApp.name}`);
            this.logger.log(`✅ Firebase Project ID: ${this.firebaseApp.options.projectId}`);
          } catch (error) {
            this.logger.error('❌ FCMService: Error initializing Firebase Admin SDK:', error);
            throw error;
          }
        } else {
          // Option 3: Try default credentials (for Google Cloud environments)
          this.logger.log('ℹ️ FCMService: No service account found, trying default credentials...');
          try {
            this.firebaseApp = admin.initializeApp({
              credential: admin.credential.applicationDefault(),
            });
            this.logger.log('✅ Firebase Admin SDK initialized with default credentials');
          } catch (error) {
            this.logger.warn('❌ Firebase Admin SDK not initialized. FCM notifications will not work.');
            this.logger.warn('To enable FCM:');
            this.logger.warn('  1. Set FIREBASE_SERVICE_ACCOUNT_KEY environment variable, OR');
            this.logger.warn('  2. Place firebase-service-account.json in the backend root directory');
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
}

