import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

export type ReminderType = 'email' | 'push' | 'both';

@Injectable()
export class ReminderService {
  private readonly logger = new Logger(ReminderService.name);

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Create a reminder for an event
   */
  async createReminder(data: {
    eventId: string;
    userId: string;
    reminderType: ReminderType;
    reminderTime: number; // minutes before event
  }) {
    return this.prisma.eventReminder.create({
      data: {
        eventId: data.eventId,
        userId: data.userId,
        reminderType: data.reminderType,
        reminderTime: data.reminderTime,
      },
    });
  }

  /**
   * Create multiple reminders for an event
   */
  async createReminders(
    eventId: string,
    userId: string,
    reminderTimes: number[],
    reminderType: ReminderType = 'push',
  ) {
    const reminders = reminderTimes.map((time) => ({
      eventId,
      userId,
      reminderType,
      reminderTime: time,
    }));

    return this.prisma.eventReminder.createMany({
      data: reminders,
      skipDuplicates: true,
    });
  }

  /**
   * Delete all reminders for an event
   */
  async deleteEventReminders(eventId: string) {
    return this.prisma.eventReminder.deleteMany({
      where: { eventId },
    });
  }

  /**
   * Get reminders for a user
   */
  async getUserReminders(userId: string) {
    return this.prisma.eventReminder.findMany({
      where: { userId, sent: false },
      include: {
        event: {
          include: {
            horse: { select: { id: true, name: true } },
          },
        },
      },
      orderBy: { event: { startDate: 'asc' } },
    });
  }

  /**
   * Get pending reminders that need to be sent
   * Called by the cron job
   */
  async getPendingReminders() {
    const now = new Date();

    // Get all unsent reminders for upcoming events
    const reminders = await this.prisma.eventReminder.findMany({
      where: {
        sent: false,
        event: {
          status: { in: ['scheduled', 'confirmed'] },
          startDate: { gte: now },
        },
      },
      include: {
        event: {
          include: {
            horse: { select: { id: true, name: true } },
            organization: { select: { id: true, name: true } },
          },
        },
        user: {
          select: {
            id: true,
            email: true,
            firstName: true,
            organizationId: true,
          },
        },
      },
    });

    // Filter reminders that should be sent now
    return reminders.filter((reminder) => {
      const eventTime = new Date(reminder.event.startDate).getTime();
      const reminderTime = eventTime - reminder.reminderTime * 60 * 1000;
      return reminderTime <= now.getTime();
    });
  }

  /**
   * Send a single reminder
   */
  async sendReminder(reminderId: string) {
    const reminder = await this.prisma.eventReminder.findUnique({
      where: { id: reminderId },
      include: {
        event: {
          include: {
            horse: { select: { id: true, name: true } },
          },
        },
        user: {
          select: {
            id: true,
            email: true,
            firstName: true,
            organizationId: true,
          },
        },
      },
    });

    if (!reminder || reminder.sent) {
      return null;
    }

    const event = reminder.event;
    const user = reminder.user;

    // Build notification content
    const title = this.buildReminderTitle(event, reminder.reminderTime);
    const body = this.buildReminderBody(event, reminder.reminderTime);

    try {
      // Send push notification
      if (reminder.reminderType === 'push' || reminder.reminderType === 'both') {
        await this.notificationsService.createNotification(user.id, user.organizationId, {
          type: 'reminder',
          title,
          body,
          data: {
            eventId: event.id,
            eventType: event.type,
            horseId: event.horseId,
          },
          actionUrl: `/calendar/events/${event.id}`,
          sendPush: true,
        });
      }

      // TODO: Send email notification if needed
      if (reminder.reminderType === 'email' || reminder.reminderType === 'both') {
        // Email sending would be implemented here
        this.logger.log(`Email reminder would be sent to ${user.email}`);
      }

      // Mark reminder as sent
      await this.prisma.eventReminder.update({
        where: { id: reminderId },
        data: {
          sent: true,
          sentAt: new Date(),
        },
      });

      this.logger.log(`Reminder sent for event ${event.id} to user ${user.id}`);
      return { success: true, reminderId };
    } catch (error) {
      // Mark reminder as failed
      await this.prisma.eventReminder.update({
        where: { id: reminderId },
        data: {
          failedAt: new Date(),
          failureReason: error.message,
        },
      });

      this.logger.error(`Failed to send reminder ${reminderId}:`, error);
      return { success: false, reminderId, error: error.message };
    }
  }

  /**
   * Process all pending reminders
   * Called by the cron job every minute
   */
  @Cron(CronExpression.EVERY_MINUTE)
  async processReminders() {
    this.logger.debug('Processing pending reminders...');

    const pendingReminders = await this.getPendingReminders();

    if (pendingReminders.length === 0) {
      return { processed: 0 };
    }

    this.logger.log(`Found ${pendingReminders.length} pending reminders to send`);

    const results = await Promise.all(
      pendingReminders.map((reminder) => this.sendReminder(reminder.id)),
    );

    const successful = results.filter((r) => r?.success).length;
    const failed = results.filter((r) => r && !r.success).length;

    this.logger.log(`Processed ${results.length} reminders: ${successful} sent, ${failed} failed`);

    return { processed: results.length, successful, failed };
  }

  /**
   * Build the reminder notification title
   */
  private buildReminderTitle(event: any, minutesBefore: number): string {
    const timeString = this.formatTimeRemaining(minutesBefore);

    const typeLabels: Record<string, string> = {
      training: 'Entrainement',
      vet: 'Rendez-vous veterinaire',
      competition: 'Competition',
      farrier: 'Marechal-ferrant',
      dental: 'Soins dentaires',
      vaccination: 'Vaccination',
      deworming: 'Vermifuge',
      other: 'Evenement',
    };

    const typeLabel = typeLabels[event.type] || 'Evenement';
    return `${typeLabel} ${timeString}`;
  }

  /**
   * Build the reminder notification body
   */
  private buildReminderBody(event: any, minutesBefore: number): string {
    const parts: string[] = [event.title];

    if (event.horse?.name) {
      parts.push(`Cheval: ${event.horse.name}`);
    }

    if (event.location) {
      parts.push(`Lieu: ${event.location}`);
    }

    const startTime = new Date(event.startDate).toLocaleTimeString('fr-FR', {
      hour: '2-digit',
      minute: '2-digit',
    });
    parts.push(`Heure: ${startTime}`);

    return parts.join(' - ');
  }

  /**
   * Format time remaining in a human-readable format
   */
  private formatTimeRemaining(minutes: number): string {
    if (minutes < 60) {
      return `dans ${minutes} min`;
    }

    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;

    if (hours < 24) {
      if (remainingMinutes === 0) {
        return `dans ${hours}h`;
      }
      return `dans ${hours}h${remainingMinutes}min`;
    }

    const days = Math.floor(hours / 24);
    const remainingHours = hours % 24;

    if (remainingHours === 0) {
      return `dans ${days} jour${days > 1 ? 's' : ''}`;
    }
    return `dans ${days}j ${remainingHours}h`;
  }

  /**
   * Get default reminder times based on event type
   */
  getDefaultReminderTimes(eventType: string): number[] {
    const defaults: Record<string, number[]> = {
      training: [30, 60], // 30 min and 1 hour before
      vet: [60, 1440], // 1 hour and 1 day before
      competition: [60, 1440, 10080], // 1 hour, 1 day, and 1 week before
      farrier: [1440], // 1 day before
      dental: [1440], // 1 day before
      vaccination: [1440, 10080], // 1 day and 1 week before
      deworming: [1440], // 1 day before
      other: [60], // 1 hour before
    };

    return defaults[eventType] || defaults.other;
  }
}
