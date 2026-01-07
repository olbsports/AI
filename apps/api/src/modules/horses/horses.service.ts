import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { CreateHorseDto } from './dto/create-horse.dto';
import { UpdateHorseDto } from './dto/update-horse.dto';
import { calculatePagination, calculateOffset } from '@horse-vision/types';

@Injectable()
export class HorsesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploadService: UploadService
  ) {}

  async findAll(
    organizationId: string,
    params: {
      page?: number;
      pageSize?: number;
      search?: string;
      status?: string;
      gender?: string;
    }
  ) {
    const page = params.page ?? 1;
    const pageSize = params.pageSize ?? 20;
    const offset = calculateOffset(page, pageSize);

    const where: any = { organizationId };

    if (params.search) {
      where.OR = [
        { name: { contains: params.search, mode: 'insensitive' } },
        { sireId: { contains: params.search, mode: 'insensitive' } },
      ];
    }

    if (params.status) {
      where.status = params.status;
    }

    if (params.gender) {
      where.gender = params.gender;
    }

    const [items, totalItems] = await Promise.all([
      this.prisma.horse.findMany({
        where,
        skip: offset,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
        include: {
          rider: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
            },
          },
          _count: {
            select: {
              analysisSessions: true,
              reports: true,
            },
          },
        },
      }),
      this.prisma.horse.count({ where }),
    ]);

    return {
      items,
      pagination: calculatePagination(totalItems, page, pageSize),
    };
  }

  async findById(id: string, organizationId: string) {
    const horse = await this.prisma.horse.findFirst({
      where: { id, organizationId },
      include: {
        rider: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        _count: {
          select: {
            analysisSessions: true,
            reports: true,
          },
        },
      },
    });

    if (!horse) {
      throw new NotFoundException('Horse not found');
    }

    return horse;
  }

  async create(organizationId: string, data: CreateHorseDto) {
    return this.prisma.horse.create({
      data: {
        ...data,
        organizationId,
      },
    });
  }

  async update(id: string, organizationId: string, data: UpdateHorseDto) {
    await this.findById(id, organizationId);

    return this.prisma.horse.update({
      where: { id },
      data,
    });
  }

  async delete(id: string, organizationId: string) {
    await this.findById(id, organizationId);

    return this.prisma.horse.delete({
      where: { id },
    });
  }

  async archive(id: string, organizationId: string) {
    await this.findById(id, organizationId);

    return this.prisma.horse.update({
      where: { id },
      data: { status: 'retired' },
    });
  }

  async uploadPhoto(id: string, organizationId: string, file: any) {
    const horse = await this.findById(id, organizationId);

    // Delete old photo if exists
    if (horse.photoUrl) {
      try {
        // Extract key from URL
        const urlParts = horse.photoUrl.split('/');
        const key = urlParts.slice(3).join('/');
        await this.uploadService.deleteFile(key);
      } catch {
        // Ignore delete errors
      }
    }

    // Upload new photo
    const { url } = await this.uploadService.uploadFile(
      organizationId,
      'avatars', // Use avatars category for horse photos
      file
    );

    // Update horse with new photo URL
    return this.prisma.horse.update({
      where: { id },
      data: { photoUrl: url },
    });
  }

  async deletePhoto(id: string, organizationId: string) {
    const horse = await this.findById(id, organizationId);

    if (horse.photoUrl) {
      try {
        const urlParts = horse.photoUrl.split('/');
        const key = urlParts.slice(3).join('/');
        await this.uploadService.deleteFile(key);
      } catch {
        // Ignore delete errors
      }
    }

    return this.prisma.horse.update({
      where: { id },
      data: { photoUrl: null },
    });
  }

  // ========== HEALTH RECORDS ==========

  async getHealthRecords(horseId: string, organizationId: string) {
    await this.findById(horseId, organizationId);

    return this.prisma.healthRecord.findMany({
      where: { horseId },
      orderBy: { date: 'desc' },
    });
  }

  async getHealthSummary(horseId: string, organizationId: string) {
    const horse = await this.findById(horseId, organizationId);

    const records = await this.prisma.healthRecord.findMany({
      where: { horseId },
      orderBy: { date: 'desc' },
      take: 5,
    });

    const upcomingReminders = await this.prisma.healthRecord.findMany({
      where: {
        horseId,
        nextDueDate: { gte: new Date() },
      },
      orderBy: { nextDueDate: 'asc' },
      take: 3,
    });

    return {
      healthStatus: horse.healthStatus,
      lastVetCheck: horse.lastVetCheck,
      vaccinations: horse.vaccinations,
      recentRecords: records,
      upcomingReminders,
    };
  }

  async addHealthRecord(horseId: string, organizationId: string, data: any) {
    await this.findById(horseId, organizationId);

    return this.prisma.healthRecord.create({
      data: {
        horseId,
        type: data.type,
        date: new Date(data.date),
        title: data.title,
        description: data.description,
        vetName: data.vetName,
        cost: data.cost,
        nextDueDate: data.nextDueDate ? new Date(data.nextDueDate) : null,
      },
    });
  }

  async updateHealthRecord(horseId: string, recordId: string, organizationId: string, data: any) {
    await this.findById(horseId, organizationId);

    return this.prisma.healthRecord.update({
      where: { id: recordId },
      data: {
        ...data,
        date: data.date ? new Date(data.date) : undefined,
        nextDueDate: data.nextDueDate ? new Date(data.nextDueDate) : undefined,
      },
    });
  }

  async deleteHealthRecord(horseId: string, recordId: string, organizationId: string) {
    await this.findById(horseId, organizationId);

    return this.prisma.healthRecord.delete({
      where: { id: recordId },
    });
  }

  // ========== WEIGHT & BODY CONDITION ==========

  async getWeightRecords(horseId: string, organizationId: string) {
    await this.findById(horseId, organizationId);

    // Return mock data - in production you'd have a weight_records table
    return [
      { id: 'w1', weight: 550, date: new Date(), notes: null },
      {
        id: 'w2',
        weight: 545,
        date: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        notes: 'Après entraînement intensif',
      },
      { id: 'w3', weight: 540, date: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000), notes: null },
    ];
  }

  async addWeightRecord(horseId: string, organizationId: string, data: any) {
    await this.findById(horseId, organizationId);

    // Update horse weight
    await this.prisma.horse.update({
      where: { id: horseId },
      data: { weightKg: data.weight },
    });

    return {
      id: `weight-${Date.now()}`,
      horseId,
      ...data,
      date: new Date(data.date),
    };
  }

  async getBodyConditionRecords(horseId: string, organizationId: string) {
    await this.findById(horseId, organizationId);

    return [
      { id: 'bc1', score: 5, date: new Date(), notes: 'Condition optimale' },
      { id: 'bc2', score: 4.5, date: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), notes: null },
    ];
  }

  async addBodyConditionRecord(horseId: string, organizationId: string, data: any) {
    await this.findById(horseId, organizationId);

    return {
      id: `bc-${Date.now()}`,
      horseId,
      ...data,
      date: new Date(data.date),
    };
  }

  // ========== NUTRITION ==========

  async getNutritionPlans(horseId: string, organizationId: string) {
    await this.findById(horseId, organizationId);

    return [
      {
        id: 'np1',
        name: 'Plan standard',
        isActive: true,
        dailyRation: {
          hay: '10 kg',
          concentrate: '3 kg',
          supplements: ['Vitamines', 'Minéraux'],
        },
        createdAt: new Date(),
      },
    ];
  }

  async getActiveNutritionPlan(horseId: string, organizationId: string) {
    await this.findById(horseId, organizationId);

    return {
      id: 'np1',
      name: 'Plan standard',
      isActive: true,
      dailyRation: {
        hay: '10 kg',
        concentrate: '3 kg',
        supplements: ['Vitamines', 'Minéraux'],
      },
      schedule: [
        { time: '07:00', meal: 'Foin + Concentré' },
        { time: '12:00', meal: 'Foin' },
        { time: '18:00', meal: 'Foin + Concentré' },
      ],
      createdAt: new Date(),
    };
  }

  async createNutritionPlan(horseId: string, organizationId: string, data: any) {
    await this.findById(horseId, organizationId);

    return {
      id: `np-${Date.now()}`,
      horseId,
      ...data,
      isActive: true,
      createdAt: new Date(),
    };
  }

  // ========== GESTATIONS ==========

  async getGestations(horseId: string, organizationId: string) {
    await this.findById(horseId, organizationId);

    return this.prisma.gestation.findMany({
      where: { horseId },
      orderBy: { breedingDate: 'desc' },
    });
  }

  // ========== EVENTS ==========

  async getHorseEvents(horseId: string, organizationId: string) {
    const horse = await this.findById(horseId, organizationId);

    // Return mock events for this horse
    return [
      {
        id: 'e1',
        title: `Entraînement - ${horse.name}`,
        type: 'training',
        date: new Date(Date.now() + 24 * 60 * 60 * 1000),
        horseId,
      },
      {
        id: 'e2',
        title: `Visite vétérinaire - ${horse.name}`,
        type: 'vet',
        date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        horseId,
      },
    ];
  }

  // ========== HEALTH REMINDERS ==========

  async getHealthReminders(organizationId: string) {
    // Get all horses for this organization
    const horses = await this.prisma.horse.findMany({
      where: { organizationId },
      select: {
        id: true,
        name: true,
        photoUrl: true,
      },
    });

    const horseIds = horses.map((h) => h.id);

    // Get all health records with upcoming reminders (not dismissed)
    const now = new Date();
    const thirtyDaysFromNow = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    const reminders = await this.prisma.healthRecord.findMany({
      where: {
        horseId: { in: horseIds },
        nextDueDate: {
          gte: now,
          lte: thirtyDaysFromNow,
        },
        reminderSent: false, // Only show non-dismissed reminders
      },
      orderBy: { nextDueDate: 'asc' },
      include: {
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
    });

    // Add additional info for each reminder
    return reminders.map((reminder) => {
      const daysUntilDue = Math.ceil(
        (reminder.nextDueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
      );

      return {
        id: reminder.id,
        horseId: reminder.horseId,
        horseName: reminder.horse.name,
        horsePhotoUrl: reminder.horse.photoUrl,
        type: reminder.type,
        title: reminder.title,
        description: reminder.description,
        date: reminder.date,
        nextDueDate: reminder.nextDueDate,
        daysUntilDue,
        priority: daysUntilDue <= 7 ? 'high' : daysUntilDue <= 14 ? 'medium' : 'low',
        vetName: reminder.vetName,
        cost: reminder.cost,
        currency: reminder.currency,
      };
    });
  }

  async dismissReminder(id: string, organizationId: string) {
    // First verify that the reminder belongs to a horse in this organization
    const reminder = await this.prisma.healthRecord.findFirst({
      where: {
        id,
        horse: {
          organizationId,
        },
      },
    });

    if (!reminder) {
      throw new NotFoundException('Health reminder not found');
    }

    // Mark as dismissed by setting reminderSent to true
    return this.prisma.healthRecord.update({
      where: { id },
      data: { reminderSent: true },
    });
  }

  async completeReminder(id: string, organizationId: string) {
    // First verify that the reminder belongs to a horse in this organization
    const reminder = await this.prisma.healthRecord.findFirst({
      where: {
        id,
        horse: {
          organizationId,
        },
      },
    });

    if (!reminder) {
      throw new NotFoundException('Health reminder not found');
    }

    // Create a new health record for the completed action
    const newRecord = await this.prisma.healthRecord.create({
      data: {
        horseId: reminder.horseId,
        type: reminder.type,
        date: new Date(),
        title: reminder.title,
        description: `Completed: ${reminder.description || reminder.title}`,
        vetName: reminder.vetName,
        cost: reminder.cost,
        currency: reminder.currency,
        // Set next due date based on the type (example: vaccination every 12 months)
        nextDueDate: this.calculateNextDueDate(reminder.type, new Date()),
        reminderSent: false,
      },
    });

    // Mark the old reminder as sent/completed
    await this.prisma.healthRecord.update({
      where: { id },
      data: { reminderSent: true },
    });

    return newRecord;
  }

  private calculateNextDueDate(type: string, fromDate: Date): Date {
    const nextDate = new Date(fromDate);

    // Define intervals for different types of health records
    switch (type) {
      case 'vaccination':
        nextDate.setMonth(nextDate.getMonth() + 12); // Annual vaccination
        break;
      case 'deworming':
        nextDate.setMonth(nextDate.getMonth() + 3); // Quarterly deworming
        break;
      case 'dental':
        nextDate.setMonth(nextDate.getMonth() + 6); // Semi-annual dental
        break;
      case 'shoeing':
        nextDate.setMonth(nextDate.getMonth() + 2); // Every 2 months
        break;
      case 'vet_visit':
        nextDate.setMonth(nextDate.getMonth() + 6); // Semi-annual vet visit
        break;
      default:
        nextDate.setMonth(nextDate.getMonth() + 12); // Default to annual
        break;
    }

    return nextDate;
  }
}
