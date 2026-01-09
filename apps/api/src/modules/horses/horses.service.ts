import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { CreateHorseDto } from './dto/create-horse.dto';
import { UpdateHorseDto } from './dto/update-horse.dto';
import { PedigreeDto } from './dto/pedigree.dto';
import { CreatePerformanceDto, UpdatePerformanceDto } from './dto/performance.dto';
import { CreateBodyConditionDto, UpdateBodyConditionDto } from './dto/body-condition.dto';
import { calculatePagination, calculateOffset } from '@horse-tempo/types';

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
    const { riderId, sireId, ...rest } = data;
    return this.prisma.horse.create({
      data: {
        ...rest,
        organization: { connect: { id: organizationId } },
        ...(riderId && { rider: { connect: { id: riderId } } }),
        ...(sireId && { sire: { connect: { id: sireId } } }),
      },
    });
  }

  async update(id: string, organizationId: string, data: UpdateHorseDto) {
    await this.findById(id, organizationId);

    const { riderId, sireId, ...rest } = data;
    return this.prisma.horse.update({
      where: { id },
      data: {
        ...rest,
        ...(riderId !== undefined && (riderId ? { rider: { connect: { id: riderId } } } : { rider: { disconnect: true } })),
        ...(sireId !== undefined && (sireId ? { sire: { connect: { id: sireId } } } : { sire: { disconnect: true } })),
      },
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

  // ========== PEDIGREE / GENEALOGY ==========

  async getPedigree(horseId: string, organizationId: string, generations: number = 4) {
    const horse = await this.prisma.horse.findFirst({
      where: { id: horseId, organizationId },
      select: {
        id: true,
        name: true,
        ueln: true,
        sireId: true,
        sireName: true,
        sireUeln: true,
        damName: true,
        damUeln: true,
        siresSireName: true,
        siresDamName: true,
        damsSireName: true,
        damsDamName: true,
        pedigree: true,
        breed: true,
        studbook: true,
        color: true,
        birthDate: true,
      },
    });

    if (!horse) {
      throw new NotFoundException('Horse not found');
    }

    // Build pedigree tree from stored data
    const pedigreeData = horse.pedigree as any || {};

    return {
      horse: {
        id: horse.id,
        name: horse.name,
        ueln: horse.ueln,
        breed: horse.breed,
        studbook: horse.studbook,
        color: horse.color,
        birthYear: horse.birthDate ? horse.birthDate.getFullYear().toString() : null,
      },
      pedigree: {
        sire: pedigreeData.sire || { name: horse.sireName, ueln: horse.sireUeln },
        dam: pedigreeData.dam || { name: horse.damName, ueln: horse.damUeln },
        sireSire: pedigreeData.sireSire || { name: horse.siresSireName },
        sireDam: pedigreeData.sireDam || { name: horse.siresDamName },
        damSire: pedigreeData.damSire || { name: horse.damsSireName },
        damDam: pedigreeData.damDam || { name: horse.damsDamName },
        // Generation 3 (arriere-grands-parents)
        sireSireSire: pedigreeData.sireSireSire,
        sireSireDam: pedigreeData.sireSireDam,
        sireDamSire: pedigreeData.sireDamSire,
        sireDamDam: pedigreeData.sireDamDam,
        damSireSire: pedigreeData.damSireSire,
        damSireDam: pedigreeData.damSireDam,
        damDamSire: pedigreeData.damDamSire,
        damDamDam: pedigreeData.damDamDam,
      },
      generations,
    };
  }

  async updatePedigree(horseId: string, organizationId: string, pedigreeDto: PedigreeDto) {
    await this.findById(horseId, organizationId);

    // Update both the legacy fields and the JSON pedigree
    return this.prisma.horse.update({
      where: { id: horseId },
      data: {
        sireName: pedigreeDto.sire?.name,
        sireUeln: pedigreeDto.sire?.ueln,
        damName: pedigreeDto.dam?.name,
        damUeln: pedigreeDto.dam?.ueln,
        siresSireName: pedigreeDto.sireSire?.name,
        siresDamName: pedigreeDto.sireDam?.name,
        damsSireName: pedigreeDto.damSire?.name,
        damsDamName: pedigreeDto.damDam?.name,
        pedigree: pedigreeDto as any,
      },
    });
  }

  async getOffspring(horseId: string, organizationId: string) {
    const horse = await this.findById(horseId, organizationId);

    // Search for offspring by looking at breeding records where this horse was stallion or dam
    const breedingRecords = await this.prisma.breedingRecord.findMany({
      where: {
        horseId,
        foalBorn: true,
      },
      select: {
        id: true,
        year: true,
        foalName: true,
        foalGender: true,
        partnerName: true,
        partnerUeln: true,
        method: true,
      },
      orderBy: { year: 'desc' },
    });

    // Also check gestations for mares
    const gestations = await this.prisma.gestation.findMany({
      where: {
        horseId,
        status: 'born',
      },
      select: {
        id: true,
        actualBirthDate: true,
        foalName: true,
        foalGender: true,
        foalColor: true,
        stallionName: true,
        stallionUeln: true,
      },
      orderBy: { actualBirthDate: 'desc' },
    });

    const offspring = [
      ...breedingRecords.map((r) => ({
        id: r.id,
        type: 'breeding_record' as const,
        name: r.foalName,
        gender: r.foalGender,
        year: r.year,
        otherParent: { name: r.partnerName, ueln: r.partnerUeln },
        method: r.method,
      })),
      ...gestations.map((g) => ({
        id: g.id,
        type: 'gestation' as const,
        name: g.foalName,
        gender: g.foalGender,
        year: g.actualBirthDate?.getFullYear(),
        color: g.foalColor,
        otherParent: { name: g.stallionName, ueln: g.stallionUeln },
      })),
    ];

    return {
      horse: {
        id: horse.id,
        name: horse.name,
        gender: horse.gender,
      },
      offspring,
      totalOffspring: offspring.length,
    };
  }

  // ========== PERFORMANCE TRACKING ==========

  async getPerformances(
    horseId: string,
    organizationId: string,
    params?: {
      discipline?: string;
      level?: string;
      year?: number;
      page?: number;
      pageSize?: number;
    }
  ) {
    await this.findById(horseId, organizationId);

    const page = params?.page ?? 1;
    const pageSize = params?.pageSize ?? 20;
    const offset = calculateOffset(page, pageSize);

    const where: any = { horseId };

    if (params?.discipline) {
      where.discipline = params.discipline;
    }
    if (params?.level) {
      where.level = params.level;
    }
    if (params?.year) {
      where.date = {
        gte: new Date(`${params.year}-01-01`),
        lt: new Date(`${params.year + 1}-01-01`),
      };
    }

    const [items, totalItems] = await Promise.all([
      this.prisma.horsePerformance.findMany({
        where,
        skip: offset,
        take: pageSize,
        orderBy: { date: 'desc' },
      }),
      this.prisma.horsePerformance.count({ where }),
    ]);

    return {
      items,
      pagination: calculatePagination(totalItems, page, pageSize),
    };
  }

  async createPerformance(horseId: string, organizationId: string, data: CreatePerformanceDto) {
    await this.findById(horseId, organizationId);

    return this.prisma.horsePerformance.create({
      data: {
        ...data,
        horseId,
      },
    });
  }

  async updatePerformance(
    horseId: string,
    performanceId: string,
    organizationId: string,
    data: UpdatePerformanceDto
  ) {
    await this.findById(horseId, organizationId);

    const performance = await this.prisma.horsePerformance.findFirst({
      where: { id: performanceId, horseId },
    });

    if (!performance) {
      throw new NotFoundException('Performance record not found');
    }

    return this.prisma.horsePerformance.update({
      where: { id: performanceId },
      data,
    });
  }

  async deletePerformance(horseId: string, performanceId: string, organizationId: string) {
    await this.findById(horseId, organizationId);

    const performance = await this.prisma.horsePerformance.findFirst({
      where: { id: performanceId, horseId },
    });

    if (!performance) {
      throw new NotFoundException('Performance record not found');
    }

    return this.prisma.horsePerformance.delete({
      where: { id: performanceId },
    });
  }

  async getPerformanceStats(horseId: string, organizationId: string) {
    await this.findById(horseId, organizationId);

    const performances = await this.prisma.horsePerformance.findMany({
      where: { horseId },
      orderBy: { date: 'desc' },
    });

    if (performances.length === 0) {
      return {
        totalPerformances: 0,
        bestRank: null,
        averageRank: null,
        wins: 0,
        podiums: 0,
        clearRoundRate: null,
        averagePenalties: null,
        bestTime: null,
        bestPercentage: null,
        byDiscipline: {},
        byLevel: {},
      };
    }

    const rankedPerformances = performances.filter((p) => p.rank !== null);
    const wins = rankedPerformances.filter((p) => p.rank === 1).length;
    const podiums = rankedPerformances.filter((p) => p.rank && p.rank <= 3).length;

    const penaltiesPerformances = performances.filter((p) => p.penaltyPoints !== null);
    const clearRounds = penaltiesPerformances.filter((p) => p.penaltyPoints === 0).length;

    const timesPerformances = performances.filter((p) => p.timeSeconds !== null);
    const percentagePerformances = performances.filter((p) => p.percentage !== null);

    // Group by discipline and level
    const byDiscipline: Record<string, number> = {};
    const byLevel: Record<string, number> = {};

    for (const p of performances) {
      byDiscipline[p.discipline] = (byDiscipline[p.discipline] || 0) + 1;
      if (p.level) {
        byLevel[p.level] = (byLevel[p.level] || 0) + 1;
      }
    }

    return {
      totalPerformances: performances.length,
      bestRank: rankedPerformances.length > 0
        ? Math.min(...rankedPerformances.map((p) => p.rank!))
        : null,
      averageRank: rankedPerformances.length > 0
        ? rankedPerformances.reduce((sum, p) => sum + p.rank!, 0) / rankedPerformances.length
        : null,
      wins,
      podiums,
      clearRoundRate: penaltiesPerformances.length > 0
        ? (clearRounds / penaltiesPerformances.length) * 100
        : null,
      averagePenalties: penaltiesPerformances.length > 0
        ? penaltiesPerformances.reduce((sum, p) => sum + p.penaltyPoints!, 0) / penaltiesPerformances.length
        : null,
      bestTime: timesPerformances.length > 0
        ? Math.min(...timesPerformances.map((p) => p.timeSeconds!))
        : null,
      bestPercentage: percentagePerformances.length > 0
        ? Math.max(...percentagePerformances.map((p) => p.percentage!))
        : null,
      byDiscipline,
      byLevel,
    };
  }

  // ========== BODY CONDITION SCORE (Database) ==========

  async getBodyConditionScores(horseId: string, organizationId: string) {
    await this.findById(horseId, organizationId);

    const scores = await this.prisma.bodyConditionScore.findMany({
      where: { horseId },
      orderBy: { date: 'desc' },
    });

    // Calculate trend and statistics
    const currentScore = scores.length > 0 ? scores[0].score : null;
    let trend: string | null = null;

    if (scores.length >= 2) {
      const recentAvg = scores.slice(0, 3).reduce((sum, s) => sum + s.score, 0) / Math.min(3, scores.length);
      const olderAvg = scores.slice(3, 6).reduce((sum, s) => sum + s.score, 0) / Math.max(1, scores.slice(3, 6).length);

      if (scores.length >= 4 && recentAvg > olderAvg + 0.3) {
        trend = 'improving';
      } else if (scores.length >= 4 && recentAvg < olderAvg - 0.3) {
        trend = 'declining';
      } else {
        trend = 'stable';
      }
    }

    // Calculate 6-month average
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    const recentScores = scores.filter((s) => s.date >= sixMonthsAgo);
    const averageScore = recentScores.length > 0
      ? recentScores.reduce((sum, s) => sum + s.score, 0) / recentScores.length
      : null;

    return {
      history: scores.map((s) => ({
        id: s.id,
        score: s.score,
        scaleType: s.scaleType,
        date: s.date,
        weightKg: s.weightKg,
        evaluatedBy: s.evaluatedBy,
        notes: s.notes,
      })),
      currentScore,
      trend,
      averageScore,
      recommendedScore: { min: 4.5, max: 6 }, // Ideal range on Henneke scale
    };
  }

  async createBodyConditionScore(horseId: string, organizationId: string, data: CreateBodyConditionDto) {
    await this.findById(horseId, organizationId);

    // If weight is provided, also update the horse's weight
    if (data.weightKg) {
      await this.prisma.horse.update({
        where: { id: horseId },
        data: { weightKg: Math.round(data.weightKg) },
      });
    }

    return this.prisma.bodyConditionScore.create({
      data: {
        ...data,
        photoUrls: data.photoUrls || [],
        horseId,
      },
    });
  }

  async updateBodyConditionScore(
    horseId: string,
    scoreId: string,
    organizationId: string,
    data: UpdateBodyConditionDto
  ) {
    await this.findById(horseId, organizationId);

    const score = await this.prisma.bodyConditionScore.findFirst({
      where: { id: scoreId, horseId },
    });

    if (!score) {
      throw new NotFoundException('Body condition score not found');
    }

    return this.prisma.bodyConditionScore.update({
      where: { id: scoreId },
      data,
    });
  }

  async deleteBodyConditionScore(horseId: string, scoreId: string, organizationId: string) {
    await this.findById(horseId, organizationId);

    const score = await this.prisma.bodyConditionScore.findFirst({
      where: { id: scoreId, horseId },
    });

    if (!score) {
      throw new NotFoundException('Body condition score not found');
    }

    return this.prisma.bodyConditionScore.delete({
      where: { id: scoreId },
    });
  }
}
