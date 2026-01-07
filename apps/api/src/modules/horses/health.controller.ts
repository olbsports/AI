import { Controller, Get, Post, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { HorsesService } from './horses.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('health')
@Controller('health')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class HealthController {
  constructor(private readonly horsesService: HorsesService) {}

  @Get('reminders')
  @ApiOperation({ summary: 'Get all health reminders for the organization' })
  async getHealthReminders(@CurrentUser() user: any) {
    return this.horsesService.getHealthReminders(user.organizationId);
  }

  @Post('reminders/:id/dismiss')
  @ApiOperation({ summary: 'Dismiss a health reminder' })
  async dismissReminder(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.dismissReminder(id, user.organizationId);
  }

  @Post('reminders/:id/complete')
  @ApiOperation({ summary: 'Mark a health reminder as completed' })
  async completeReminder(@CurrentUser() user: any, @Param('id') id: string) {
    return this.horsesService.completeReminder(id, user.organizationId);
  }
}
