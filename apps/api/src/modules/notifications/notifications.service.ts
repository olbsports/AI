import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { FcmService } from './services/fcm.service';
import { NotificationType } from './dto/push-notification.dto';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private prisma: PrismaService,
    private fcmService: FcmService,
  ) {}

  async getNotifications(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });
  }

  async getUnreadCount(userId: string) {
    const count = await this.prisma.notification.count({
      where: { userId, isRead: false },
    });
    return { count };
  }

  async markAsRead(notificationId: string, userId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    return this.prisma.notification.update({
      where: { id: notificationId },
      data: { isRead: true, readAt: new Date() },
    });
  }

  async markManyAsRead(notificationIds: string[], userId: string) {
    await this.prisma.notification.updateMany({
      where: {
        id: { in: notificationIds },
        userId,
      },
      data: { isRead: true, readAt: new Date() },
    });
    return { success: true };
  }

  async markAllAsRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true, readAt: new Date() },
    });
    return { success: true };
  }

  async deleteNotification(notificationId: string, userId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    return this.prisma.notification.delete({
      where: { id: notificationId },
    });
  }

  async createNotification(
    userId: string,
    organizationId: string,
    data: {
      type: string;
      title: string;
      body: string;
      data?: any;
      actionUrl?: string;
      sendPush?: boolean;
    }
  ) {
    const notification = await this.prisma.notification.create({
      data: {
        type: data.type,
        title: data.title,
        body: data.body,
        data: data.data,
        actionUrl: data.actionUrl,
        userId,
        organizationId,
      },
    });

    // Send push notification if requested
    if (data.sendPush !== false) {
      try {
        const result = await this.fcmService.sendToUser(
          userId,
          {
            title: data.title,
            body: data.body,
            data: data.data ? Object.fromEntries(
              Object.entries(data.data).map(([k, v]) => [k, String(v)])
            ) : undefined,
            actionUrl: data.actionUrl,
          },
          data.type as NotificationType,
        );

        if (result.successCount > 0) {
          await this.prisma.notification.update({
            where: { id: notification.id },
            data: { pushSent: true, pushSentAt: new Date() },
          });
        }
      } catch (error) {
        this.logger.error(`Failed to send push for notification ${notification.id}:`, error);
      }
    }

    return notification;
  }

  // ==================== BATCH NOTIFICATIONS ====================

  async createBatchNotifications(
    notifications: Array<{
      userId: string;
      organizationId: string;
      type: string;
      title: string;
      body: string;
      data?: any;
      actionUrl?: string;
    }>,
    sendPush = true,
  ) {
    // Create all notifications in database
    const created = await this.prisma.notification.createMany({
      data: notifications.map((n) => ({
        type: n.type,
        title: n.title,
        body: n.body,
        data: n.data,
        actionUrl: n.actionUrl,
        userId: n.userId,
        organizationId: n.organizationId,
      })),
    });

    // Send push notifications
    if (sendPush) {
      for (const notif of notifications) {
        try {
          await this.fcmService.sendToUser(
            notif.userId,
            {
              title: notif.title,
              body: notif.body,
              data: notif.data ? Object.fromEntries(
                Object.entries(notif.data).map(([k, v]) => [k, String(v)])
              ) : undefined,
              actionUrl: notif.actionUrl,
            },
            notif.type as NotificationType,
          );
        } catch (error) {
          this.logger.error(`Failed to send batch push to user ${notif.userId}:`, error);
        }
      }
    }

    return { count: created.count };
  }

  // ==================== TOPIC NOTIFICATIONS ====================

  async sendToTopic(topic: string, data: { title: string; body: string; data?: Record<string, string> }) {
    return this.fcmService.sendToTopic(topic, data);
  }

  // ==================== PUSH MANAGEMENT ====================

  async registerPushToken(
    userId: string,
    data: {
      token: string;
      platform: string;
      deviceId: string;
      deviceName?: string;
      appVersion?: string;
    },
  ) {
    return this.fcmService.registerToken(userId, data);
  }

  async unregisterPushToken(userId: string, deviceId: string) {
    return this.fcmService.unregisterToken(userId, deviceId);
  }

  async getPushSubscriptions(userId: string) {
    return this.fcmService.getSubscriptions(userId);
  }

  // ==================== PREFERENCES ====================

  async getPreferences(userId: string) {
    return this.fcmService.getPreferences(userId);
  }

  async updatePreferences(userId: string, data: any) {
    return this.fcmService.updatePreferences(userId, data);
  }
}
