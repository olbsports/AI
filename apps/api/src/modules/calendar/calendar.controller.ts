import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { CalendarService } from './calendar.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('calendar')
@Controller('calendar')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class CalendarController {
  constructor(private readonly calendarService: CalendarService) {}

  @Get('events')
  @ApiOperation({ summary: 'Get calendar events' })
  async getEvents(
    @CurrentUser() user: any,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('type') type?: string,
    @Query('horseId') horseId?: string,
  ) {
    return this.calendarService.getEvents(user.organizationId, {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      type,
      horseId,
    });
  }

  @Post('events')
  @ApiOperation({ summary: 'Create calendar event' })
  async createEvent(
    @CurrentUser() user: any,
    @Body() data: {
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
    return this.calendarService.createEvent(user.organizationId, user.id, data);
  }

  @Put('events/:id')
  @ApiOperation({ summary: 'Update calendar event' })
  async updateEvent(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: {
      title?: string;
      description?: string;
      type?: string;
      startDate?: string;
      endDate?: string;
      allDay?: boolean;
      horseId?: string;
      riderId?: string;
      location?: string;
      reminder?: number;
      recurrence?: string;
      status?: string;
    },
  ) {
    return this.calendarService.updateEvent(id, user.organizationId, data);
  }

  @Delete('events/:id')
  @ApiOperation({ summary: 'Delete calendar event' })
  async deleteEvent(@CurrentUser() user: any, @Param('id') id: string) {
    return this.calendarService.deleteEvent(id, user.organizationId);
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
    @Body() data: {
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
    @Body() data: {
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

  @Get('planning/summary')
  @ApiOperation({ summary: 'Get planning summary' })
  async getPlanningSummary(@CurrentUser() user: any) {
    return this.calendarService.getPlanningSummary(user.organizationId);
  }
}
