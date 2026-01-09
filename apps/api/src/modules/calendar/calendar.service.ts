import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ReminderService } from './reminder.service';

// Simple RRULE parser for recurrence
interface RecurrenceRule {
  frequency: 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY';
  interval?: number;
  count?: number;
  until?: Date;
  byDay?: string[];
  byMonth?: number[];
  byMonthDay?: number[];
}

@Injectable()
export class CalendarService {
  constructor(
    private prisma: PrismaService,
    private reminderService: ReminderService
  ) {}

  // ========== EVENTS ==========

  async getEvents(
    organizationId: string,
    filters: {
      startDate?: Date;
      endDate?: Date;
      type?: string;
      horseId?: string;
      includeRecurrences?: boolean;
    }
  ) {
    const where: any = {
      organizationId,
      parentEventId: null, // Only get parent events, not occurrences
    };

    if (filters.startDate || filters.endDate) {
      where.startDate = {};
      if (filters.startDate) {
        where.startDate.gte = filters.startDate;
      }
      if (filters.endDate) {
        where.startDate.lte = filters.endDate;
      }
    }

    if (filters.type) {
      where.type = filters.type;
    }

    if (filters.horseId) {
      where.horseId = filters.horseId;
    }

    const events = await this.prisma.calendarEvent.findMany({
      where,
      include: {
        horse: {
          select: { id: true, name: true, photoUrl: true },
        },
        rider: {
          select: { id: true, firstName: true, lastName: true },
        },
        reminders: true,
        occurrences: filters.includeRecurrences
          ? {
              where: {
                startDate: {
                  gte: filters.startDate,
                  lte: filters.endDate,
                },
              },
            }
          : false,
      },
      orderBy: { startDate: 'asc' },
    });

    // If includeRecurrences and we have date range, generate virtual occurrences
    if (filters.includeRecurrences && filters.startDate && filters.endDate) {
      const allEvents = [];

      for (const event of events) {
        allEvents.push(event);

        // Generate occurrences for recurring events
        if (event.recurrenceRule) {
          const occurrences = this.generateOccurrences(event, filters.startDate, filters.endDate);
          allEvents.push(...occurrences);
        }
      }

      return allEvents.sort(
        (a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime()
      );
    }

    return events;
  }

  async getEventById(eventId: string, organizationId: string) {
    const event = await this.prisma.calendarEvent.findFirst({
      where: { id: eventId, organizationId },
      include: {
        horse: {
          select: { id: true, name: true, photoUrl: true },
        },
        rider: {
          select: { id: true, firstName: true, lastName: true },
        },
        reminders: {
          include: {
            user: {
              select: { id: true, firstName: true, lastName: true },
            },
          },
        },
        occurrences: true,
        parent: true,
      },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    return event;
  }

  async createEvent(
    organizationId: string,
    userId: string,
    data: {
      title: string;
      description?: string;
      type: string;
      startDate: string;
      endDate?: string;
      allDay?: boolean;
      horseId?: string;
      riderId?: string;
      location?: string;
      color?: string;
      priority?: string;
      notes?: string;
      reminderTimes?: number[]; // minutes before event
      recurrenceRule?: string;
      recurrenceEndDate?: string;
    }
  ) {
    const event = await this.prisma.calendarEvent.create({
      data: {
        title: data.title,
        description: data.description,
        type: data.type,
        startDate: new Date(data.startDate),
        endDate: data.endDate ? new Date(data.endDate) : null,
        allDay: data.allDay || false,
        horseId: data.horseId,
        riderId: data.riderId,
        location: data.location,
        color: data.color,
        priority: data.priority || 'normal',
        notes: data.notes,
        recurrenceRule: data.recurrenceRule,
        recurrenceEndDate: data.recurrenceEndDate ? new Date(data.recurrenceEndDate) : null,
        organizationId,
        createdById: userId,
      },
      include: {
        horse: {
          select: { id: true, name: true },
        },
      },
    });

    // Create reminders if specified
    if (data.reminderTimes && data.reminderTimes.length > 0) {
      await this.reminderService.createReminders(event.id, userId, data.reminderTimes, 'push');
    } else {
      // Create default reminders based on event type
      const defaultTimes = this.reminderService.getDefaultReminderTimes(data.type);
      await this.reminderService.createReminders(event.id, userId, defaultTimes, 'push');
    }

    return event;
  }

  async updateEvent(
    eventId: string,
    organizationId: string,
    data: {
      title?: string;
      description?: string;
      type?: string;
      startDate?: string;
      endDate?: string;
      allDay?: boolean;
      horseId?: string;
      riderId?: string;
      location?: string;
      color?: string;
      priority?: string;
      notes?: string;
      status?: string;
      recurrenceRule?: string;
      recurrenceEndDate?: string;
    }
  ) {
    const event = await this.prisma.calendarEvent.findFirst({
      where: { id: eventId, organizationId },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    return this.prisma.calendarEvent.update({
      where: { id: eventId },
      data: {
        title: data.title,
        description: data.description,
        type: data.type,
        startDate: data.startDate ? new Date(data.startDate) : undefined,
        endDate: data.endDate ? new Date(data.endDate) : undefined,
        allDay: data.allDay,
        horseId: data.horseId,
        riderId: data.riderId,
        location: data.location,
        color: data.color,
        priority: data.priority,
        notes: data.notes,
        status: data.status,
        recurrenceRule: data.recurrenceRule,
        recurrenceEndDate: data.recurrenceEndDate ? new Date(data.recurrenceEndDate) : undefined,
      },
      include: {
        horse: {
          select: { id: true, name: true },
        },
        reminders: true,
      },
    });
  }

  async deleteEvent(eventId: string, organizationId: string, deleteOccurrences = false) {
    const event = await this.prisma.calendarEvent.findFirst({
      where: { id: eventId, organizationId },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    // Delete reminders first
    await this.reminderService.deleteEventReminders(eventId);

    // If deleteOccurrences, delete all child events
    if (deleteOccurrences) {
      await this.prisma.calendarEvent.deleteMany({
        where: { parentEventId: eventId },
      });
    }

    await this.prisma.calendarEvent.delete({
      where: { id: eventId },
    });

    return { success: true, message: 'Event deleted' };
  }

  // ========== RECURRENCE ==========

  /**
   * Set recurrence rule for an event
   */
  async setEventRecurrence(
    eventId: string,
    organizationId: string,
    data: {
      recurrenceRule: string; // RRULE format
      recurrenceEndDate?: string;
      generateOccurrences?: boolean;
      generateUntil?: string;
    }
  ) {
    const event = await this.prisma.calendarEvent.findFirst({
      where: { id: eventId, organizationId },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    // Validate RRULE
    const rule = this.parseRRule(data.recurrenceRule);
    if (!rule) {
      throw new BadRequestException('Invalid recurrence rule format');
    }

    // Update event with recurrence rule
    const updatedEvent = await this.prisma.calendarEvent.update({
      where: { id: eventId },
      data: {
        recurrenceRule: data.recurrenceRule,
        recurrenceEndDate: data.recurrenceEndDate ? new Date(data.recurrenceEndDate) : null,
      },
    });

    // Generate actual occurrences in database if requested
    let occurrences = [];
    if (data.generateOccurrences) {
      const endDate = data.generateUntil
        ? new Date(data.generateUntil)
        : new Date(Date.now() + 90 * 24 * 60 * 60 * 1000); // 90 days default

      occurrences = await this.createOccurrences(event, endDate);
    }

    return {
      event: updatedEvent,
      occurrencesCreated: occurrences.length,
    };
  }

  /**
   * Generate virtual occurrences for display (not saved in DB)
   */
  private generateOccurrences(event: any, startDate: Date, endDate: Date): any[] {
    if (!event.recurrenceRule) {
      return [];
    }

    const rule = this.parseRRule(event.recurrenceRule);
    if (!rule) {
      return [];
    }

    const occurrences: any[] = [];
    const eventDuration =
      event.endDate && event.startDate
        ? new Date(event.endDate).getTime() - new Date(event.startDate).getTime()
        : 60 * 60 * 1000; // 1 hour default

    let currentDate = new Date(event.startDate);
    const recurrenceEnd = event.recurrenceEndDate ? new Date(event.recurrenceEndDate) : endDate;

    let count = 0;
    const maxCount = rule.count || 365; // Safety limit

    while (currentDate <= endDate && currentDate <= recurrenceEnd && count < maxCount) {
      if (currentDate >= startDate && currentDate > new Date(event.startDate)) {
        // Check if occurrence already exists in database
        const existingOccurrence = event.occurrences?.find(
          (o: any) => new Date(o.startDate).toDateString() === currentDate.toDateString()
        );

        if (!existingOccurrence) {
          occurrences.push({
            ...event,
            id: `${event.id}-${currentDate.getTime()}`,
            parentEventId: event.id,
            startDate: new Date(currentDate),
            endDate: new Date(currentDate.getTime() + eventDuration),
            isVirtual: true,
          });
        }
      }

      // Advance to next occurrence
      currentDate = this.getNextOccurrence(currentDate, rule);
      count++;
    }

    return occurrences;
  }

  /**
   * Create actual occurrences in database
   */
  private async createOccurrences(event: any, endDate: Date): Promise<any[]> {
    if (!event.recurrenceRule) {
      return [];
    }

    const rule = this.parseRRule(event.recurrenceRule);
    if (!rule) {
      return [];
    }

    const occurrences: any[] = [];
    const eventDuration =
      event.endDate && event.startDate
        ? new Date(event.endDate).getTime() - new Date(event.startDate).getTime()
        : 60 * 60 * 1000;

    let currentDate = new Date(event.startDate);
    const recurrenceEnd = event.recurrenceEndDate ? new Date(event.recurrenceEndDate) : endDate;

    let count = 0;
    const maxCount = rule.count || 100; // Safety limit

    while (currentDate <= endDate && currentDate <= recurrenceEnd && count < maxCount) {
      if (currentDate > new Date(event.startDate)) {
        const occurrence = await this.prisma.calendarEvent.create({
          data: {
            title: event.title,
            description: event.description,
            type: event.type,
            startDate: new Date(currentDate),
            endDate: new Date(currentDate.getTime() + eventDuration),
            allDay: event.allDay,
            location: event.location,
            color: event.color,
            priority: event.priority,
            notes: event.notes,
            horseId: event.horseId,
            riderId: event.riderId,
            organizationId: event.organizationId,
            createdById: event.createdById,
            parentEventId: event.id,
          },
        });
        occurrences.push(occurrence);
      }

      currentDate = this.getNextOccurrence(currentDate, rule);
      count++;
    }

    return occurrences;
  }

  /**
   * Parse RRULE string to RecurrenceRule object
   */
  private parseRRule(rrule: string): RecurrenceRule | null {
    try {
      // Remove RRULE: prefix if present
      const ruleStr = rrule.replace(/^RRULE:/i, '');
      const parts = ruleStr.split(';');
      const rule: RecurrenceRule = { frequency: 'DAILY' };

      for (const part of parts) {
        const [key, value] = part.split('=');

        switch (key.toUpperCase()) {
          case 'FREQ':
            rule.frequency = value.toUpperCase() as RecurrenceRule['frequency'];
            break;
          case 'INTERVAL':
            rule.interval = parseInt(value, 10);
            break;
          case 'COUNT':
            rule.count = parseInt(value, 10);
            break;
          case 'UNTIL':
            rule.until = new Date(value);
            break;
          case 'BYDAY':
            rule.byDay = value.split(',');
            break;
          case 'BYMONTH':
            rule.byMonth = value.split(',').map((v) => parseInt(v, 10));
            break;
          case 'BYMONTHDAY':
            rule.byMonthDay = value.split(',').map((v) => parseInt(v, 10));
            break;
        }
      }

      return rule;
    } catch {
      return null;
    }
  }

  /**
   * Get next occurrence date based on rule
   */
  private getNextOccurrence(currentDate: Date, rule: RecurrenceRule): Date {
    const interval = rule.interval || 1;
    const nextDate = new Date(currentDate);

    switch (rule.frequency) {
      case 'DAILY':
        nextDate.setDate(nextDate.getDate() + interval);
        break;
      case 'WEEKLY':
        nextDate.setDate(nextDate.getDate() + 7 * interval);
        break;
      case 'MONTHLY':
        nextDate.setMonth(nextDate.getMonth() + interval);
        break;
      case 'YEARLY':
        nextDate.setFullYear(nextDate.getFullYear() + interval);
        break;
    }

    return nextDate;
  }

  // ========== INTELLIGENT PLANNING ==========

  /**
   * Get intelligent planning for a horse
   */
  async getHorsePlanning(
    organizationId: string,
    horseId: string,
    options?: {
      startDate?: Date;
      endDate?: Date;
    }
  ) {
    const now = new Date();
    const startDate = options?.startDate || now;
    const endDate = options?.endDate || new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    // Get horse info
    const horse = await this.prisma.horse.findFirst({
      where: { id: horseId, organizationId },
      include: {
        healthRecords: {
          orderBy: { date: 'desc' },
          take: 10,
        },
      },
    });

    if (!horse) {
      throw new NotFoundException('Horse not found');
    }

    // Get upcoming events for this horse
    const events = await this.getEvents(organizationId, {
      horseId,
      startDate,
      endDate,
      includeRecurrences: true,
    });

    // Get health reminders
    const healthReminders = await this.prisma.healthReminder.findMany({
      where: {
        horseId,
        organizationId,
        status: { in: ['pending', 'sent'] },
        dueDate: { gte: now, lte: endDate },
      },
      orderBy: { dueDate: 'asc' },
    });

    // Get upcoming competitions
    const competitions = await this.prisma.competitionResult.findMany({
      where: {
        horseId,
        competitionDate: { gte: now, lte: endDate },
      },
      orderBy: { competitionDate: 'asc' },
    });

    // Generate training recommendations
    const trainingRecommendations = this.generateTrainingRecommendationsForHorse(
      horse,
      events,
      competitions
    );

    return {
      horse: {
        id: horse.id,
        name: horse.name,
        photoUrl: horse.photoUrl,
        healthStatus: horse.healthStatus,
      },
      period: {
        startDate,
        endDate,
      },
      upcomingEvents: events,
      healthReminders: healthReminders.map((r) => ({
        id: r.id,
        type: r.type,
        title: r.title,
        dueDate: r.dueDate,
        status: r.status,
      })),
      competitions: competitions.map((c) => ({
        id: c.id,
        name: c.competitionName,
        date: c.competitionDate,
        discipline: c.discipline,
        level: c.eventLevel,
      })),
      trainingRecommendations,
      summary: {
        totalEvents: events.length,
        trainingCount: events.filter((e: any) => e.type === 'training').length,
        vetAppointments: events.filter((e: any) => e.type === 'vet').length,
        healthRemindersCount: healthReminders.length,
        competitionsCount: competitions.length,
      },
    };
  }

  /**
   * Generate training recommendations based on horse's schedule
   */
  private generateTrainingRecommendationsForHorse(
    horse: any,
    events: any[],
    competitions: any[]
  ): any[] {
    const recommendations: any[] = [];

    // Check for upcoming competition
    if (competitions.length > 0) {
      const nextCompetition = competitions[0];
      const daysUntil = Math.ceil(
        (new Date(nextCompetition.competitionDate).getTime() - Date.now()) / (24 * 60 * 60 * 1000)
      );

      if (daysUntil <= 14) {
        recommendations.push({
          id: `rec-comp-${nextCompetition.id}`,
          type: 'competition_prep',
          priority: 'high',
          title: `Preparation competition: ${nextCompetition.competitionName}`,
          description: `Competition dans ${daysUntil} jours - ${nextCompetition.discipline}`,
          suggestedExercises: this.getSuggestedExercises(nextCompetition.discipline, daysUntil),
          dueDate: nextCompetition.competitionDate,
        });
      }
    }

    // Check training frequency
    const trainingEvents = events.filter((e: any) => e.type === 'training');
    const now = new Date();
    const lastWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const trainingsLastWeek = trainingEvents.filter(
      (e: any) => new Date(e.startDate) >= lastWeek && new Date(e.startDate) <= now
    ).length;

    if (trainingsLastWeek < 3) {
      recommendations.push({
        id: 'rec-training-frequency',
        type: 'training_frequency',
        priority: 'medium',
        title: "Augmenter la frequence d'entrainement",
        description: `Seulement ${trainingsLastWeek} entrainements la semaine derniere. Recommandation: 3-5 seances par semaine.`,
        suggestedSchedule: this.suggestTrainingSchedule(events),
      });
    }

    // Health-based recommendations
    if (horse.healthStatus === 'recovering') {
      recommendations.push({
        id: 'rec-recovery',
        type: 'recovery',
        priority: 'high',
        title: 'Programme de recuperation',
        description: 'Le cheval est en periode de recuperation. Privilegier les seances legeres.',
        suggestedExercises: [
          'Marche en main (20-30 min)',
          'Pas monte (15-20 min)',
          'Etirements doux',
        ],
      });
    }

    // Variety recommendation
    const eventTypes = events.map((e: any) => e.type);
    const uniqueTypes = new Set(eventTypes);
    if (uniqueTypes.size < 3 && events.length > 5) {
      recommendations.push({
        id: 'rec-variety',
        type: 'variety',
        priority: 'low',
        title: 'Varier les activites',
        description: "Diversifiez les types d'activites pour un developpement equilibre.",
        suggestedActivities: ['Travail sur le plat', 'Saut', 'Travail en exterieur', 'Longe'],
      });
    }

    return recommendations;
  }

  /**
   * Get suggested exercises based on discipline
   */
  private getSuggestedExercises(discipline: string, daysUntil: number): string[] {
    const baseExercises: Record<string, string[][]> = {
      CSO: [
        ['Gymnastique', 'Lignes de cavaletti', 'Travail sur le plat'],
        ['Parcours simplifie', 'Transitions', 'Enchaînements'],
        ['Detente', 'Quelques sauts', 'Relaxation'],
      ],
      Dressage: [
        ['Figures de manege', 'Travail lateral', 'Transitions'],
        ['Reprises simplifiees', 'Assouplissements', 'Impulsion'],
        ['Detente legere', 'Etirements', 'Relaxation'],
      ],
      CCE: [
        ['Travail mixte', 'Cross leger', 'Conditioning'],
        ['Parcours technique', 'Endurance', 'Saut'],
        ['Detente', 'Balade', 'Relaxation'],
      ],
    };

    const exercises = baseExercises[discipline] || baseExercises['CSO'];

    if (daysUntil <= 3) {
      return exercises[2]; // Light work
    } else if (daysUntil <= 7) {
      return exercises[1]; // Medium intensity
    } else {
      return exercises[0]; // Full training
    }
  }

  /**
   * Suggest training schedule
   */
  private suggestTrainingSchedule(existingEvents: any[]): any[] {
    const now = new Date();
    const suggestions = [];
    const daysOfWeek = ['Lundi', 'Mercredi', 'Vendredi'];

    for (let i = 0; i < 7; i++) {
      const day = new Date(now.getTime() + i * 24 * 60 * 60 * 1000);
      const dayName = day.toLocaleDateString('fr-FR', { weekday: 'long' });

      // Check if already has event
      const hasEvent = existingEvents.some(
        (e: any) =>
          new Date(e.startDate).toDateString() === day.toDateString() && e.type === 'training'
      );

      if (!hasEvent && daysOfWeek.some((d) => dayName.toLowerCase().includes(d.toLowerCase()))) {
        suggestions.push({
          date: day,
          dayName,
          suggested: true,
          reason: 'Jour optimal pour un entrainement',
        });
      }
    }

    return suggestions.slice(0, 3);
  }

  // ========== GOALS ==========

  async getGoals(organizationId: string, filters: { status?: string; horseId?: string }) {
    const where: any = {};

    if (filters.horseId) {
      where.horseId = filters.horseId;
    }
    if (filters.status) {
      where.status = filters.status;
    }

    const goals = await this.prisma.evolutionGoal.findMany({
      where,
      orderBy: { targetDate: 'asc' },
    });

    return goals;
  }

  async createGoal(
    organizationId: string,
    data: {
      title: string;
      description?: string;
      goalType: string;
      targetMetric: string;
      startValue: number;
      targetValue: number;
      targetDate: string;
      horseId?: string;
      riderId?: string;
    }
  ) {
    return this.prisma.evolutionGoal.create({
      data: {
        title: data.title,
        description: data.description,
        goalType: data.goalType,
        targetMetric: data.targetMetric,
        startValue: data.startValue,
        targetValue: data.targetValue,
        targetDate: new Date(data.targetDate),
        subjectType: data.horseId ? 'horse' : data.riderId ? 'rider' : 'pair',
        horseId: data.horseId,
        riderId: data.riderId,
        status: 'active',
        progress: 0,
      },
    });
  }

  async updateGoal(goalId: string, organizationId: string, data: any) {
    const goal = await this.prisma.evolutionGoal.findUnique({
      where: { id: goalId },
    });

    if (!goal) {
      throw new NotFoundException('Goal not found');
    }

    let progress = goal.progress;
    if (data.currentValue !== undefined) {
      const range = goal.targetValue - goal.startValue;
      const current = data.currentValue - goal.startValue;
      progress = Math.min(100, Math.max(0, (current / range) * 100));
    }

    return this.prisma.evolutionGoal.update({
      where: { id: goalId },
      data: {
        ...data,
        currentValue: data.currentValue,
        progress,
        targetDate: data.targetDate ? new Date(data.targetDate) : undefined,
      },
    });
  }

  async completeGoal(goalId: string, organizationId: string) {
    return this.prisma.evolutionGoal.update({
      where: { id: goalId },
      data: {
        status: 'achieved',
        progress: 100,
        completedDate: new Date(),
      },
    });
  }

  // ========== TRAINING PLANS ==========

  async getTrainingPlans(organizationId: string) {
    // Get horses for this organization first
    const horses = await this.prisma.horse.findMany({
      where: { organizationId },
      select: { id: true },
    });
    const horseIds = horses.map((h) => h.id);

    return this.prisma.trainingSession.findMany({
      where: {
        horseId: { in: horseIds },
      },
      take: 20,
      orderBy: { sessionDate: 'desc' },
    });
  }

  async getActiveTrainingPlan(organizationId: string) {
    // Get horses for this organization first
    const horses = await this.prisma.horse.findMany({
      where: { organizationId },
      select: { id: true },
    });
    const horseIds = horses.map((h) => h.id);

    const recentSessions = await this.prisma.trainingSession.findMany({
      where: {
        horseId: { in: horseIds },
        sessionDate: {
          gte: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
        },
      },
      orderBy: { sessionDate: 'asc' },
    });

    return {
      id: 'active-plan',
      name: 'Plan actuel',
      sessions: recentSessions,
      progress: Math.round((recentSessions.length / 10) * 100),
    };
  }

  async getTrainingRecommendations(organizationId: string) {
    return [
      {
        id: 'rec-1',
        title: "Ameliorer l'equilibre",
        description: "Travail sur l'equilibre du cheval",
        priority: 'high',
        exercises: ['Transitions', 'Cercles', 'Serpentines'],
      },
      {
        id: 'rec-2',
        title: "Renforcer l'impulsion",
        description: "Exercices pour ameliorer l'impulsion",
        priority: 'medium',
        exercises: ['Extensions', 'Allongements', 'Departs au galop'],
      },
    ];
  }

  async createTrainingPlan(
    organizationId: string,
    data: {
      name: string;
      description?: string;
      duration: number;
      difficulty: string;
      horseId?: string;
      sessions: any[];
    }
  ) {
    const planId = `plan-${Date.now()}`;
    return {
      id: planId,
      ...data,
      isActive: false,
      progress: 0,
      createdAt: new Date(),
      organizationId,
    };
  }

  async generateTrainingPlan(
    organizationId: string,
    data: {
      horseId: string;
      goalType: string;
      duration: number;
      currentLevel: string;
      targetLevel: string;
      preferences?: any;
    }
  ) {
    const planId = `plan-ai-${Date.now()}`;
    const sessions = [];
    const sessionsPerWeek = 5;
    const totalSessions = Math.floor((data.duration / 7) * sessionsPerWeek);
    const sessionTypes = ['Dressage', "Saut d'obstacles", 'Cross', 'Detente', 'Travail au sol'];

    for (let i = 0; i < totalSessions; i++) {
      sessions.push({
        id: `session-${i + 1}`,
        day: i + 1,
        week: Math.floor(i / sessionsPerWeek) + 1,
        title: sessionTypes[i % sessionTypes.length],
        description: `Session ${i + 1} - ${sessionTypes[i % sessionTypes.length]}`,
        duration: 45 + Math.floor(Math.random() * 30),
        exercises: ['Echauffement', 'Exercice principal', 'Retour au calme'],
        completed: false,
      });
    }

    return {
      id: planId,
      name: `Programme ${data.goalType} - ${data.currentLevel} vers ${data.targetLevel}`,
      description: `Plan d'entrainement genere par IA pour atteindre le niveau ${data.targetLevel}`,
      duration: data.duration,
      difficulty:
        data.currentLevel === 'beginner'
          ? 'easy'
          : data.currentLevel === 'advanced'
            ? 'hard'
            : 'medium',
      horseId: data.horseId,
      goalType: data.goalType,
      currentLevel: data.currentLevel,
      targetLevel: data.targetLevel,
      isActive: false,
      progress: 0,
      sessions,
      generatedAt: new Date(),
      organizationId,
    };
  }

  async completeTrainingSession(
    planId: string,
    sessionId: string,
    organizationId: string,
    data?: {
      notes?: string;
      rating?: number;
      duration?: number;
    }
  ) {
    return {
      success: true,
      planId,
      sessionId,
      completed: true,
      completedAt: new Date(),
      notes: data?.notes || '',
      rating: data?.rating || 0,
      duration: data?.duration || 0,
      message: 'Session marquee comme completee',
    };
  }

  async dismissTrainingRecommendation(recommendationId: string, organizationId: string) {
    return {
      success: true,
      recommendationId,
      dismissed: true,
      dismissedAt: new Date(),
      message: 'Recommandation ignoree',
    };
  }

  async getPlanningSummary(organizationId: string) {
    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 7);

    const horses = await this.prisma.horse.count({
      where: { organizationId, status: 'active' },
    });

    const goals = await this.prisma.evolutionGoal.count({
      where: { status: 'active' },
    });

    const upcomingEvents = await this.prisma.calendarEvent.count({
      where: {
        organizationId,
        startDate: { gte: now, lte: endOfWeek },
        status: { in: ['scheduled', 'confirmed'] },
      },
    });

    const completedThisWeek = await this.prisma.calendarEvent.count({
      where: {
        organizationId,
        startDate: { gte: startOfWeek, lte: now },
        status: 'completed',
      },
    });

    return {
      totalHorses: horses,
      activeGoals: goals,
      upcomingEvents,
      completedThisWeek,
      plannedThisWeek: upcomingEvents + completedThisWeek,
      trainingProgress: 45,
    };
  }
}
