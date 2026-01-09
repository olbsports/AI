import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

export type HealthReminderType =
  | 'vaccination_due'
  | 'deworming_due'
  | 'vet_checkup_due'
  | 'dental_due'
  | 'farrier_due';

interface HealthReminderConfig {
  type: HealthReminderType;
  intervalDays: number; // Days between treatments
  reminderDaysBefore: number; // Days before due date to send reminder
  title: string;
  messageTemplate: string;
}

const HEALTH_REMINDER_CONFIGS: HealthReminderConfig[] = [
  {
    type: 'vaccination_due',
    intervalDays: 365, // Annual vaccination
    reminderDaysBefore: 14,
    title: 'Vaccination a prevoir',
    messageTemplate: 'Le vaccin de {horseName} arrive a echeance le {dueDate}',
  },
  {
    type: 'deworming_due',
    intervalDays: 90, // Every 3 months
    reminderDaysBefore: 7,
    title: 'Vermifuge a prevoir',
    messageTemplate: 'Le vermifuge de {horseName} est prevu pour le {dueDate}',
  },
  {
    type: 'vet_checkup_due',
    intervalDays: 180, // Every 6 months
    reminderDaysBefore: 14,
    title: 'Visite veterinaire a prevoir',
    messageTemplate: 'La visite de controle de {horseName} est prevue pour le {dueDate}',
  },
  {
    type: 'dental_due',
    intervalDays: 365, // Annual dental check
    reminderDaysBefore: 14,
    title: 'Soins dentaires a prevoir',
    messageTemplate: 'Le controle dentaire de {horseName} est prevu pour le {dueDate}',
  },
  {
    type: 'farrier_due',
    intervalDays: 42, // Every 6 weeks
    reminderDaysBefore: 7,
    title: 'Marechal-ferrant a prevoir',
    messageTemplate: 'La visite du marechal pour {horseName} est prevue pour le {dueDate}',
  },
];

@Injectable()
export class HealthReminderService {
  private readonly logger = new Logger(HealthReminderService.name);

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Generate health reminders based on health records
   * Called daily to create reminders for upcoming health events
   */
  @Cron(CronExpression.EVERY_DAY_AT_6AM)
  async generateHealthReminders() {
    this.logger.log('Generating health reminders...');

    // Get all active horses
    const horses = await this.prisma.horse.findMany({
      where: {
        status: 'active',
      },
      include: {
        healthRecords: {
          orderBy: { date: 'desc' },
        },
        organization: {
          include: {
            users: {
              where: { isActive: true },
              select: { id: true, organizationId: true },
            },
          },
        },
      },
    });

    let createdCount = 0;

    for (const horse of horses) {
      for (const config of HEALTH_REMINDER_CONFIGS) {
        const reminder = await this.createHealthReminderIfNeeded(horse, config);
        if (reminder) {
          createdCount++;
        }
      }
    }

    this.logger.log(`Generated ${createdCount} health reminders`);
    return { created: createdCount };
  }

  /**
   * Create a health reminder if one is needed
   */
  private async createHealthReminderIfNeeded(
    horse: any,
    config: HealthReminderConfig,
  ): Promise<any> {
    // Map reminder type to health record type
    const healthRecordType = this.getHealthRecordType(config.type);

    // Find the last health record of this type
    const lastRecord = horse.healthRecords.find(
      (r: any) => r.type === healthRecordType,
    );

    // Calculate due date
    let dueDate: Date;

    if (lastRecord) {
      dueDate = new Date(lastRecord.date);
      dueDate.setDate(dueDate.getDate() + config.intervalDays);
    } else {
      // If no record exists, set due date to today (overdue)
      dueDate = new Date();
    }

    // Calculate reminder date
    const reminderDate = new Date(dueDate);
    reminderDate.setDate(reminderDate.getDate() - config.reminderDaysBefore);

    const now = new Date();

    // Only create reminder if reminder date is in the future or today
    if (reminderDate < now) {
      // Check if due date is still in the future (but reminder would be today)
      if (dueDate < now) {
        // Overdue - create reminder for today
        reminderDate.setTime(now.getTime());
      }
    }

    // Check if a reminder already exists for this horse and type
    const existingReminder = await this.prisma.healthReminder.findFirst({
      where: {
        horseId: horse.id,
        type: config.type,
        status: { in: ['pending', 'sent'] },
        dueDate: {
          gte: new Date(dueDate.getTime() - 7 * 24 * 60 * 60 * 1000), // Within 7 days of this due date
          lte: new Date(dueDate.getTime() + 7 * 24 * 60 * 60 * 1000),
        },
      },
    });

    if (existingReminder) {
      return null; // Reminder already exists
    }

    // Create the reminder
    const formattedDueDate = dueDate.toLocaleDateString('fr-FR', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });

    const message = config.messageTemplate
      .replace('{horseName}', horse.name)
      .replace('{dueDate}', formattedDueDate);

    return this.prisma.healthReminder.create({
      data: {
        type: config.type,
        dueDate,
        reminderDate,
        title: config.title,
        message,
        horseId: horse.id,
        organizationId: horse.organizationId,
        healthRecordId: lastRecord?.id,
      },
    });
  }

  /**
   * Get health reminders for an organization
   */
  async getHealthReminders(
    organizationId: string,
    filters?: {
      horseId?: string;
      type?: HealthReminderType;
      status?: string;
      startDate?: Date;
      endDate?: Date;
    },
  ) {
    const where: any = {
      organizationId,
    };

    if (filters?.horseId) {
      where.horseId = filters.horseId;
    }

    if (filters?.type) {
      where.type = filters.type;
    }

    if (filters?.status) {
      where.status = filters.status;
    } else {
      // By default, only show pending and sent reminders
      where.status = { in: ['pending', 'sent'] };
    }

    if (filters?.startDate || filters?.endDate) {
      where.dueDate = {};
      if (filters.startDate) {
        where.dueDate.gte = filters.startDate;
      }
      if (filters.endDate) {
        where.dueDate.lte = filters.endDate;
      }
    }

    return this.prisma.healthReminder.findMany({
      where,
      include: {
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
        healthRecord: {
          select: {
            id: true,
            type: true,
            date: true,
            title: true,
          },
        },
      },
      orderBy: { dueDate: 'asc' },
    });
  }

  /**
   * Process pending health reminders and send notifications
   */
  @Cron(CronExpression.EVERY_HOUR)
  async processHealthReminders() {
    this.logger.debug('Processing health reminders...');

    const now = new Date();

    // Get reminders that should be sent now
    const pendingReminders = await this.prisma.healthReminder.findMany({
      where: {
        status: 'pending',
        reminderDate: { lte: now },
      },
      include: {
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
        organization: {
          include: {
            users: {
              where: { isActive: true },
              select: { id: true },
            },
          },
        },
      },
    });

    if (pendingReminders.length === 0) {
      return { processed: 0 };
    }

    this.logger.log(`Processing ${pendingReminders.length} health reminders`);

    let sentCount = 0;

    for (const reminder of pendingReminders) {
      try {
        // Send notification to all users in the organization
        for (const user of reminder.organization.users) {
          await this.notificationsService.createNotification(
            user.id,
            reminder.organizationId,
            {
              type: 'health_reminder',
              title: reminder.title,
              body: reminder.message || `Rappel sante pour ${reminder.horse.name}`,
              data: {
                reminderId: reminder.id,
                horseId: reminder.horseId,
                reminderType: reminder.type,
              },
              actionUrl: `/horses/${reminder.horseId}/health`,
              sendPush: true,
            },
          );
        }

        // Mark reminder as sent
        await this.prisma.healthReminder.update({
          where: { id: reminder.id },
          data: {
            status: 'sent',
            sentAt: new Date(),
          },
        });

        sentCount++;
      } catch (error) {
        this.logger.error(`Failed to send health reminder ${reminder.id}:`, error);
      }
    }

    this.logger.log(`Sent ${sentCount} health reminders`);
    return { processed: pendingReminders.length, sent: sentCount };
  }

  /**
   * Dismiss a health reminder
   */
  async dismissReminder(reminderId: string, organizationId: string) {
    const reminder = await this.prisma.healthReminder.findFirst({
      where: { id: reminderId, organizationId },
    });

    if (!reminder) {
      return null;
    }

    return this.prisma.healthReminder.update({
      where: { id: reminderId },
      data: { status: 'dismissed' },
    });
  }

  /**
   * Mark a health reminder as completed (action taken)
   */
  async completeReminder(reminderId: string, organizationId: string) {
    const reminder = await this.prisma.healthReminder.findFirst({
      where: { id: reminderId, organizationId },
    });

    if (!reminder) {
      return null;
    }

    return this.prisma.healthReminder.update({
      where: { id: reminderId },
      data: { status: 'completed' },
    });
  }

  /**
   * Get upcoming health events summary for a horse
   */
  async getHorseHealthSummary(horseId: string) {
    const now = new Date();
    const thirtyDaysFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const reminders = await this.prisma.healthReminder.findMany({
      where: {
        horseId,
        status: { in: ['pending', 'sent'] },
        dueDate: { lte: thirtyDaysFromNow },
      },
      orderBy: { dueDate: 'asc' },
    });

    const overdueCount = reminders.filter((r) => r.dueDate < now).length;
    const upcomingCount = reminders.filter((r) => r.dueDate >= now).length;

    return {
      horseId,
      overdueCount,
      upcomingCount,
      totalCount: reminders.length,
      reminders: reminders.map((r) => ({
        id: r.id,
        type: r.type,
        title: r.title,
        dueDate: r.dueDate,
        isOverdue: r.dueDate < now,
      })),
    };
  }

  /**
   * Map health reminder type to health record type
   */
  private getHealthRecordType(reminderType: HealthReminderType): string {
    const mapping: Record<HealthReminderType, string> = {
      vaccination_due: 'vaccination',
      deworming_due: 'deworming',
      vet_checkup_due: 'vet_visit',
      dental_due: 'dental',
      farrier_due: 'shoeing',
    };

    return mapping[reminderType];
  }

  /**
   * Get reminder type label in French
   */
  getReminderTypeLabel(type: HealthReminderType): string {
    const labels: Record<HealthReminderType, string> = {
      vaccination_due: 'Vaccination',
      deworming_due: 'Vermifuge',
      vet_checkup_due: 'Visite veterinaire',
      dental_due: 'Soins dentaires',
      farrier_due: 'Marechal-ferrant',
    };

    return labels[type] || type;
  }
}
