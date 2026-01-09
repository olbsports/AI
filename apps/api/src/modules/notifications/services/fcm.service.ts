import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { PrismaService } from '../../../prisma/prisma.service';
import { NotificationCategoryMap, NotificationType } from '../dto/push-notification.dto';

interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
  imageUrl?: string;
  actionUrl?: string;
  badge?: number;
  sound?: string;
}

interface SendResult {
  success: boolean;
  successCount: number;
  failureCount: number;
  failedTokens: string[];
}

@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger(FcmService.name);
  private isInitialized = false;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  onModuleInit() {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    try {
      const serviceAccountPath = this.configService.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH');
      const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');

      if (serviceAccountPath) {
        // Initialize with service account file
        const serviceAccount = require(serviceAccountPath);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: projectId || serviceAccount.project_id,
        });
        this.isInitialized = true;
        this.logger.log('Firebase Admin initialized with service account');
      } else if (projectId) {
        // Initialize with environment credentials (for Cloud Run, etc.)
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
          projectId,
        });
        this.isInitialized = true;
        this.logger.log('Firebase Admin initialized with default credentials');
      } else {
        this.logger.warn('Firebase not configured - push notifications disabled');
      }
    } catch (error) {
      this.logger.error('Failed to initialize Firebase:', error);
    }
  }

  async sendToUser(userId: string, payload: PushPayload, notificationType?: NotificationType): Promise<SendResult> {
    if (!this.isInitialized) {
      this.logger.warn('Firebase not initialized, skipping push notification');
      return { success: false, successCount: 0, failureCount: 0, failedTokens: [] };
    }

    // Check user preferences
    const canSend = await this.checkUserPreferences(userId, notificationType);
    if (!canSend) {
      this.logger.debug(`Push blocked by user preferences for user ${userId}`);
      return { success: true, successCount: 0, failureCount: 0, failedTokens: [] };
    }

    // Get active push subscriptions for user
    const subscriptions = await this.prisma.pushSubscription.findMany({
      where: { userId, isActive: true },
    });

    if (subscriptions.length === 0) {
      this.logger.debug(`No active push subscriptions for user ${userId}`);
      return { success: true, successCount: 0, failureCount: 0, failedTokens: [] };
    }

    const tokens = subscriptions.map((s) => s.token);
    return this.sendToTokens(tokens, payload);
  }

  async sendToTokens(tokens: string[], payload: PushPayload): Promise<SendResult> {
    if (!this.isInitialized) {
      return { success: false, successCount: 0, failureCount: 0, failedTokens: [] };
    }

    if (tokens.length === 0) {
      return { success: true, successCount: 0, failureCount: 0, failedTokens: [] };
    }

    try {
      const message: admin.messaging.MulticastMessage = {
        tokens,
        notification: {
          title: payload.title,
          body: payload.body,
          imageUrl: payload.imageUrl,
        },
        data: {
          ...payload.data,
          actionUrl: payload.actionUrl || '',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            sound: payload.sound || 'default',
            channelId: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: payload.sound || 'default',
              badge: payload.badge,
              contentAvailable: true,
            },
          },
        },
        webpush: {
          notification: {
            icon: '/icons/icon-192x192.png',
            badge: '/icons/badge-72x72.png',
          },
          fcmOptions: {
            link: payload.actionUrl,
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      // Track failed tokens for cleanup
      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const error = resp.error;
          if (
            error?.code === 'messaging/invalid-registration-token' ||
            error?.code === 'messaging/registration-token-not-registered'
          ) {
            failedTokens.push(tokens[idx]);
          }
          this.logger.debug(`Push to token ${idx} failed: ${error?.code}`);
        }
      });

      // Clean up invalid tokens
      if (failedTokens.length > 0) {
        await this.cleanupInvalidTokens(failedTokens);
      }

      this.logger.debug(`Push sent: ${response.successCount}/${tokens.length} successful`);

      return {
        success: response.successCount > 0,
        successCount: response.successCount,
        failureCount: response.failureCount,
        failedTokens,
      };
    } catch (error) {
      this.logger.error('Failed to send push notifications:', error);
      return { success: false, successCount: 0, failureCount: tokens.length, failedTokens: [] };
    }
  }

  async sendToTopic(topic: string, payload: PushPayload): Promise<boolean> {
    if (!this.isInitialized) {
      return false;
    }

    try {
      const message: admin.messaging.Message = {
        topic,
        notification: {
          title: payload.title,
          body: payload.body,
          imageUrl: payload.imageUrl,
        },
        data: {
          ...payload.data,
          actionUrl: payload.actionUrl || '',
        },
        android: {
          priority: 'high',
          notification: { sound: payload.sound || 'default' },
        },
        apns: {
          payload: {
            aps: { sound: payload.sound || 'default' },
          },
        },
      };

      await admin.messaging().send(message);
      this.logger.debug(`Push sent to topic: ${topic}`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to send push to topic ${topic}:`, error);
      return false;
    }
  }

  async subscribeToTopic(tokens: string[], topic: string): Promise<boolean> {
    if (!this.isInitialized || tokens.length === 0) {
      return false;
    }

    try {
      await admin.messaging().subscribeToTopic(tokens, topic);
      return true;
    } catch (error) {
      this.logger.error(`Failed to subscribe to topic ${topic}:`, error);
      return false;
    }
  }

  async unsubscribeFromTopic(tokens: string[], topic: string): Promise<boolean> {
    if (!this.isInitialized || tokens.length === 0) {
      return false;
    }

    try {
      await admin.messaging().unsubscribeFromTopic(tokens, topic);
      return true;
    } catch (error) {
      this.logger.error(`Failed to unsubscribe from topic ${topic}:`, error);
      return false;
    }
  }

  private async checkUserPreferences(userId: string, notificationType?: NotificationType): Promise<boolean> {
    const prefs = await this.prisma.notificationPreference.findUnique({
      where: { userId },
    });

    // Default to enabled if no preferences set
    if (!prefs) {
      return true;
    }

    // Check if push is globally disabled
    if (!prefs.pushEnabled) {
      return false;
    }

    // Check quiet hours
    if (prefs.quietHoursEnabled) {
      const isQuietHours = this.isInQuietHours(
        prefs.quietHoursStart,
        prefs.quietHoursEnd,
        prefs.timezone,
      );
      if (isQuietHours) {
        return false;
      }
    }

    // Check category-specific settings
    if (notificationType) {
      const category = NotificationCategoryMap[notificationType];
      const categorySettings = prefs.categorySettings as Record<string, any>;

      if (categorySettings && categorySettings[category]?.push === false) {
        return false;
      }
    }

    return true;
  }

  private isInQuietHours(start: string, end: string, timezone: string): boolean {
    try {
      const now = new Date();
      const userTime = new Date(now.toLocaleString('en-US', { timeZone: timezone }));
      const hours = userTime.getHours();
      const minutes = userTime.getMinutes();
      const currentMinutes = hours * 60 + minutes;

      const [startHours, startMins] = start.split(':').map(Number);
      const [endHours, endMins] = end.split(':').map(Number);
      const startMinutes = startHours * 60 + startMins;
      const endMinutes = endHours * 60 + endMins;

      // Handle overnight quiet hours (e.g., 22:00 to 07:00)
      if (startMinutes > endMinutes) {
        return currentMinutes >= startMinutes || currentMinutes < endMinutes;
      }

      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } catch {
      return false;
    }
  }

  private async cleanupInvalidTokens(tokens: string[]): Promise<void> {
    try {
      await this.prisma.pushSubscription.updateMany({
        where: { token: { in: tokens } },
        data: { isActive: false },
      });
      this.logger.debug(`Deactivated ${tokens.length} invalid push tokens`);
    } catch (error) {
      this.logger.error('Failed to cleanup invalid tokens:', error);
    }
  }

  // ==================== PUSH SUBSCRIPTION MANAGEMENT ====================

  async registerToken(
    userId: string,
    data: {
      token: string;
      platform: string;
      deviceId: string;
      deviceName?: string;
      appVersion?: string;
    },
  ) {
    // Upsert subscription
    const subscription = await this.prisma.pushSubscription.upsert({
      where: {
        userId_deviceId: {
          userId,
          deviceId: data.deviceId,
        },
      },
      update: {
        token: data.token,
        platform: data.platform,
        deviceName: data.deviceName,
        appVersion: data.appVersion,
        isActive: true,
        lastUsedAt: new Date(),
      },
      create: {
        userId,
        token: data.token,
        platform: data.platform,
        deviceId: data.deviceId,
        deviceName: data.deviceName,
        appVersion: data.appVersion,
      },
    });

    return subscription;
  }

  async unregisterToken(userId: string, deviceId: string) {
    await this.prisma.pushSubscription.updateMany({
      where: { userId, deviceId },
      data: { isActive: false },
    });
    return { success: true };
  }

  async getSubscriptions(userId: string) {
    return this.prisma.pushSubscription.findMany({
      where: { userId },
      orderBy: { lastUsedAt: 'desc' },
      select: {
        id: true,
        platform: true,
        deviceId: true,
        deviceName: true,
        isActive: true,
        lastUsedAt: true,
        createdAt: true,
      },
    });
  }

  // ==================== NOTIFICATION PREFERENCES ====================

  async getPreferences(userId: string) {
    let prefs = await this.prisma.notificationPreference.findUnique({
      where: { userId },
    });

    if (!prefs) {
      // Create default preferences
      prefs = await this.prisma.notificationPreference.create({
        data: { userId },
      });
    }

    return prefs;
  }

  async updatePreferences(userId: string, data: Partial<{
    pushEnabled: boolean;
    emailEnabled: boolean;
    inAppEnabled: boolean;
    quietHoursEnabled: boolean;
    quietHoursStart: string;
    quietHoursEnd: string;
    timezone: string;
    categorySettings: Record<string, any>;
    digestEnabled: boolean;
    digestFrequency: string;
    digestTime: string;
  }>) {
    return this.prisma.notificationPreference.upsert({
      where: { userId },
      update: data,
      create: { userId, ...data },
    });
  }
}
