import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { QueueService } from './queue.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('admin/queues')
@Controller('admin/queues')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin', 'owner')
@ApiBearerAuth()
export class QueueController {
  constructor(private readonly queueService: QueueService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Get queue statistics' })
  async getStats() {
    return this.queueService.getQueueStats();
  }

  @Post('cleanup')
  @ApiOperation({ summary: 'Clean old completed/failed jobs' })
  async cleanup() {
    await this.queueService.cleanOldJobs();
    return { message: 'Old jobs cleaned successfully' };
  }
}
