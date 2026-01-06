import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CalendarService {
  constructor(private prisma: PrismaService) {}

  // ========== EVENTS ==========

  async getEvents(
    organizationId: string,
    filters: {
      startDate?: Date;
      endDate?: Date;
      type?: string;
      horseId?: string;
    },
  ) {
    // For now, return mock events since we don't have a CalendarEvent model
    // In production, you'd query from a calendar_events table
    const horses = await this.prisma.horse.findMany({
      where: { organizationId },
      select: { id: true, name: true },
      take: 5,
    });

    const mockEvents = [];
    const now = new Date();

    // Generate some sample events
    horses.forEach((horse, index) => {
      mockEvents.push({
        id: `event-${index}-1`,
        title: `Entraînement - ${horse.name}`,
        description: 'Session d\'entraînement quotidienne',
        type: 'training',
        startDate: new Date(now.getTime() + index * 24 * 60 * 60 * 1000),
        endDate: new Date(now.getTime() + index * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
        allDay: false,
        horseId: horse.id,
        horseName: horse.name,
        status: 'scheduled',
      });

      mockEvents.push({
        id: `event-${index}-2`,
        title: `Visite vétérinaire - ${horse.name}`,
        description: 'Contrôle de routine',
        type: 'vet',
        startDate: new Date(now.getTime() + (index + 7) * 24 * 60 * 60 * 1000),
        allDay: true,
        horseId: horse.id,
        horseName: horse.name,
        status: 'scheduled',
      });
    });

    // Filter by date range if provided
    let filtered = mockEvents;
    if (filters.startDate) {
      filtered = filtered.filter(e => new Date(e.startDate) >= filters.startDate!);
    }
    if (filters.endDate) {
      filtered = filtered.filter(e => new Date(e.startDate) <= filters.endDate!);
    }
    if (filters.type) {
      filtered = filtered.filter(e => e.type === filters.type);
    }
    if (filters.horseId) {
      filtered = filtered.filter(e => e.horseId === filters.horseId);
    }

    return filtered;
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
      reminder?: number;
      recurrence?: string;
    },
  ) {
    // In production, you'd create a CalendarEvent in the database
    return {
      id: `event-${Date.now()}`,
      ...data,
      startDate: new Date(data.startDate),
      endDate: data.endDate ? new Date(data.endDate) : null,
      organizationId,
      createdById: userId,
      status: 'scheduled',
      createdAt: new Date(),
    };
  }

  async updateEvent(
    eventId: string,
    organizationId: string,
    data: any,
  ) {
    // In production, you'd update the CalendarEvent in the database
    return {
      id: eventId,
      ...data,
      updatedAt: new Date(),
    };
  }

  async deleteEvent(eventId: string, organizationId: string) {
    // In production, you'd delete the CalendarEvent from the database
    return { success: true, message: 'Event deleted' };
  }

  // ========== GOALS ==========

  async getGoals(
    organizationId: string,
    filters: { status?: string; horseId?: string },
  ) {
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
    },
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

    // Calculate progress if currentValue is provided
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

  // ========== TRAINING ==========

  async getTrainingPlans(organizationId: string) {
    // Return mock training plans
    return [
      {
        id: 'plan-1',
        name: 'Programme débutant',
        description: 'Programme d\'entraînement pour débutants',
        duration: 30,
        difficulty: 'easy',
        isActive: false,
        progress: 0,
      },
      {
        id: 'plan-2',
        name: 'Programme intermédiaire',
        description: 'Programme pour cavaliers expérimentés',
        duration: 60,
        difficulty: 'medium',
        isActive: true,
        progress: 45,
      },
    ];
  }

  async getActiveTrainingPlan(organizationId: string) {
    return {
      id: 'plan-2',
      name: 'Programme intermédiaire',
      description: 'Programme pour cavaliers expérimentés',
      duration: 60,
      difficulty: 'medium',
      isActive: true,
      progress: 45,
      sessions: [
        { id: 's1', day: 1, title: 'Dressage', completed: true },
        { id: 's2', day: 2, title: 'Saut', completed: true },
        { id: 's3', day: 3, title: 'Repos', completed: true },
        { id: 's4', day: 4, title: 'Dressage', completed: false },
        { id: 's5', day: 5, title: 'Cross', completed: false },
      ],
      nextSession: { id: 's4', day: 4, title: 'Dressage' },
    };
  }

  async getTrainingRecommendations(organizationId: string) {
    return [
      {
        id: 'rec-1',
        title: 'Améliorer l\'équilibre',
        description: 'Travail sur l\'équilibre du cheval',
        priority: 'high',
        exercises: ['Transitions', 'Cercles', 'Serpentines'],
      },
      {
        id: 'rec-2',
        title: 'Renforcer l\'impulsion',
        description: 'Exercices pour améliorer l\'impulsion',
        priority: 'medium',
        exercises: ['Extensions', 'Allongements', 'Départs au galop'],
      },
    ];
  }

  async getPlanningSummary(organizationId: string) {
    const now = new Date();
    const endOfWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const horses = await this.prisma.horse.count({
      where: { organizationId, status: 'active' },
    });

    const goals = await this.prisma.evolutionGoal.count({
      where: { status: 'active' },
    });

    return {
      totalHorses: horses,
      activeGoals: goals,
      upcomingEvents: 5,
      completedThisWeek: 3,
      plannedThisWeek: 8,
      trainingProgress: 45,
    };
  }
}
