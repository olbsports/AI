import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery, ApiParam } from '@nestjs/swagger';

import { CalendarService } from './calendar.service';
import { ReminderService } from './reminder.service';
import { HealthReminderService, HealthReminderType } from './health-reminder.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('calendar')
@Controller('calendar')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class CalendarController {
  constructor(
    private readonly calendarService: CalendarService,
    private readonly reminderService: ReminderService,
    private readonly healthReminderService: HealthReminderService,
  ) {}

  // ========== EVENTS ==========

  @Get('events')
  @ApiOperation({ summary: 'Get calendar events' })
  @ApiQuery({ name: 'startDate', required: false, description: 'Start date for filtering' })
  @ApiQuery({ name: 'endDate', required: false, description: 'End date for filtering' })
  @ApiQuery({ name: 'type', required: false, description: 'Event type filter' })
  @ApiQuery({ name: 'horseId', required: false, description: 'Filter by horse ID' })
  @ApiQuery({ name: 'includeRecurrences', required: false, type: Boolean })
  async getEvents(
    @CurrentUser() user: any,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('type') type?: string,
    @Query('horseId') horseId?: string,
    @Query('includeRecurrences') includeRecurrences?: string,
  ) {
    return this.calendarService.getEvents(user.organizationId, {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      type,
      horseId,
      includeRecurrences: includeRecurrences === 'true',
    });
  }

  @Get('events/:id')
  @ApiOperation({ summary: 'Get single event by ID' })
  @ApiParam({ name: 'id', description: 'Event ID' })
  async getEventById(@CurrentUser() user: any, @Param('id') id: string) {
    return this.calendarService.getEventById(id, user.organizationId);
  }

  @Post('events')
  @ApiOperation({ summary: 'Create calendar event' })
  async createEvent(
    @CurrentUser() user: any,
    @Body()
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
      reminderTimes?: number[];
      recurrenceRule?: string;
      recurrenceEndDate?: string;
    },
  ) {
    return this.calendarService.createEvent(user.organizationId, user.id, data);
  }

  @Put('events/:id')
  @ApiOperation({ summary: 'Update calendar event' })
  async updateEvent(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body()
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
    },
  ) {
    return this.calendarService.updateEvent(id, user.organizationId, data);
  }

  @Delete('events/:id')
  @ApiOperation({ summary: 'Delete calendar event' })
  @ApiQuery({ name: 'deleteOccurrences', required: false, type: Boolean })
  async deleteEvent(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Query('deleteOccurrences') deleteOccurrences?: string,
  ) {
    return this.calendarService.deleteEvent(
      id,
      user.organizationId,
      deleteOccurrences === 'true',
    );
  }

  // ========== RECURRENCE ==========

  @Post('events/:id/recurrence')
  @ApiOperation({ summary: 'Set recurrence rule for an event' })
  @ApiParam({ name: 'id', description: 'Event ID' })
  async setEventRecurrence(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body()
    data: {
      recurrenceRule: string;
      recurrenceEndDate?: string;
      generateOccurrences?: boolean;
      generateUntil?: string;
    },
  ) {
    return this.calendarService.setEventRecurrence(id, user.organizationId, data);
  }

  // ========== REMINDERS ==========

  @Get('reminders')
  @ApiOperation({ summary: 'Get user reminders' })
  async getUserReminders(@CurrentUser() user: any) {
    return this.reminderService.getUserReminders(user.id);
  }

  @Post('events/:eventId/reminders')
  @ApiOperation({ summary: 'Create reminder for an event' })
  async createReminder(
    @CurrentUser() user: any,
    @Param('eventId') eventId: string,
    @Body()
    data: {
      reminderType: 'email' | 'push' | 'both';
      reminderTime: number;
    },
  ) {
    return this.reminderService.createReminder({
      eventId,
      userId: user.id,
      reminderType: data.reminderType,
      reminderTime: data.reminderTime,
    });
  }

  // ========== HEALTH REMINDERS ==========

  @Get('health-reminders')
  @ApiOperation({ summary: 'Get health reminders for organization' })
  @ApiQuery({ name: 'horseId', required: false })
  @ApiQuery({ name: 'type', required: false })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'startDate', required: false })
  @ApiQuery({ name: 'endDate', required: false })
  async getHealthReminders(
    @CurrentUser() user: any,
    @Query('horseId') horseId?: string,
    @Query('type') type?: string,
    @Query('status') status?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.healthReminderService.getHealthReminders(user.organizationId, {
      horseId,
      type: type as HealthReminderType,
      status,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
    });
  }

  @Get('health-reminders/horse/:horseId')
  @ApiOperation({ summary: 'Get health summary for a horse' })
  async getHorseHealthSummary(
    @CurrentUser() user: any,
    @Param('horseId') horseId: string,
  ) {
    return this.healthReminderService.getHorseHealthSummary(horseId);
  }

  @Post('health-reminders/:id/dismiss')
  @ApiOperation({ summary: 'Dismiss a health reminder' })
  async dismissHealthReminder(
    @CurrentUser() user: any,
    @Param('id') id: string,
  ) {
    return this.healthReminderService.dismissReminder(id, user.organizationId);
  }

  @Post('health-reminders/:id/complete')
  @ApiOperation({ summary: 'Mark health reminder as completed' })
  async completeHealthReminder(
    @CurrentUser() user: any,
    @Param('id') id: string,
  ) {
    return this.healthReminderService.completeReminder(id, user.organizationId);
  }

  @Post('health-reminders/generate')
  @ApiOperation({ summary: 'Manually trigger health reminder generation' })
  async generateHealthReminders(@CurrentUser() user: any) {
    return this.healthReminderService.generateHealthReminders();
  }

  // ========== INTELLIGENT PLANNING ==========

  @Get('planning')
  @ApiOperation({ summary: 'Get intelligent planning for a horse' })
  @ApiQuery({ name: 'horseId', required: true, description: 'Horse ID for planning' })
  @ApiQuery({ name: 'startDate', required: false })
  @ApiQuery({ name: 'endDate', required: false })
  async getHorsePlanning(
    @CurrentUser() user: any,
    @Query('horseId') horseId: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.calendarService.getHorsePlanning(user.organizationId, horseId, {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
    });
  }

  // ========== GOALS ==========

  @Get('goals')
  @ApiOperation({ summary: 'Get goals' })
  async getGoals(
    @CurrentUser() user: any,
    @Query('status') status?: string,
    @Query('horseId') horseId?: string,
  ) {
    return this.calendarService.getGoals(user.organizationId, { status, horseId });
  }

  @Post('goals')
  @ApiOperation({ summary: 'Create goal' })
  async createGoal(
    @CurrentUser() user: any,
    @Body()
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
    return this.calendarService.createGoal(user.organizationId, data);
  }

  @Put('goals/:id')
  @ApiOperation({ summary: 'Update goal' })
  async updateGoal(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body()
    data: {
      title?: string;
      description?: string;
      currentValue?: number;
      targetValue?: number;
      targetDate?: string;
      status?: string;
    },
  ) {
    return this.calendarService.updateGoal(id, user.organizationId, data);
  }

  @Post('goals/:id/complete')
  @ApiOperation({ summary: 'Mark goal as complete' })
  async completeGoal(@CurrentUser() user: any, @Param('id') id: string) {
    return this.calendarService.completeGoal(id, user.organizationId);
  }

  // ========== TRAINING ==========

  @Get('training/plans')
  @ApiOperation({ summary: 'Get training plans' })
  async getTrainingPlans(@CurrentUser() user: any) {
    return this.calendarService.getTrainingPlans(user.organizationId);
  }

  @Get('training/plans/active')
  @ApiOperation({ summary: 'Get active training plan' })
  async getActiveTrainingPlan(@CurrentUser() user: any) {
    return this.calendarService.getActiveTrainingPlan(user.organizationId);
  }

  @Get('training/recommendations')
  @ApiOperation({ summary: 'Get training recommendations' })
  async getTrainingRecommendations(@CurrentUser() user: any) {
    return this.calendarService.getTrainingRecommendations(user.organizationId);
  }

  @Post('training/plans')
  @ApiOperation({ summary: 'Create training plan' })
  async createTrainingPlan(
    @CurrentUser() user: any,
    @Body()
    data: {
      name: string;
      description?: string;
      duration: number;
      difficulty: string;
      horseId?: string;
      sessions: any[];
    },
  ) {
    return this.calendarService.createTrainingPlan(user.organizationId, data);
  }

  @Post('training/plans/generate')
  @ApiOperation({ summary: 'Generate AI training plan' })
  async generateTrainingPlan(
    @CurrentUser() user: any,
    @Body()
    data: {
      horseId: string;
      goalType: string;
      duration: number;
      currentLevel: string;
      targetLevel: string;
      preferences?: any;
    },
  ) {
    return this.calendarService.generateTrainingPlan(user.organizationId, data);
  }

  @Post('training/plans/:planId/sessions/:sessionId/complete')
  @ApiOperation({ summary: 'Complete training session' })
  async completeTrainingSession(
    @CurrentUser() user: any,
    @Param('planId') planId: string,
    @Param('sessionId') sessionId: string,
    @Body()
    data?: {
      notes?: string;
      rating?: number;
      duration?: number;
    },
  ) {
    return this.calendarService.completeTrainingSession(
      planId,
      sessionId,
      user.organizationId,
      data,
    );
  }

  @Post('training/recommendations/:id/dismiss')
  @ApiOperation({ summary: 'Dismiss training recommendation' })
  async dismissTrainingRecommendation(@CurrentUser() user: any, @Param('id') id: string) {
    return this.calendarService.dismissTrainingRecommendation(id, user.organizationId);
  }

  @Get('planning/summary')
  @ApiOperation({ summary: 'Get planning summary' })
  async getPlanningSummary(@CurrentUser() user: any) {
    return this.calendarService.getPlanningSummary(user.organizationId);
  }
}
