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

import { MonitoringService } from './monitoring.service';
import {
  LogQueryDto,
  CreateAlertRuleDto,
  AlertStatus,
  AcknowledgeAlertDto,
} from './dto/monitoring.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('monitoring')
@Controller('monitoring')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('owner') // Admin only
@ApiBearerAuth()
export class MonitoringController {
  constructor(private readonly monitoringService: MonitoringService) {}

  @Get('health')
  @ApiOperation({ summary: 'Get system health status' })
  async getHealth() {
    return this.monitoringService.getSystemHealth();
  }

  @Get('metrics')
  @ApiOperation({ summary: 'Get detailed system metrics' })
  async getMetrics() {
    return this.monitoringService.getDetailedMetrics();
  }

  @Get('logs')
  @ApiOperation({ summary: 'Get system logs' })
  async getLogs(@Query() query: LogQueryDto) {
    return this.monitoringService.getLogs(query);
  }

  @Get('alerts')
  @ApiOperation({ summary: 'Get active alerts' })
  async getAlerts(@Query('status') status?: AlertStatus) {
    return this.monitoringService.getAlerts(status);
  }

  @Get('alerts/rules')
  @ApiOperation({ summary: 'Get alert rules' })
  async getAlertRules() {
    return this.monitoringService.getAlertRules();
  }

  @Post('alerts/rules')
  @ApiOperation({ summary: 'Create alert rule' })
  async createAlertRule(@Body() dto: CreateAlertRuleDto) {
    return this.monitoringService.createAlertRule(dto);
  }

  @Delete('alerts/rules/:id')
  @ApiOperation({ summary: 'Delete alert rule' })
  async deleteAlertRule(@Param('id') id: string) {
    await this.monitoringService.deleteAlertRule(id);
    return { success: true };
  }

  @Put('alerts/:id/acknowledge')
  @ApiOperation({ summary: 'Acknowledge an alert' })
  async acknowledgeAlert(
    @Param('id') id: string,
    @Body() dto: AcknowledgeAlertDto,
  ) {
    return this.monitoringService.acknowledgeAlert(id, dto);
  }

  @Put('alerts/:id/resolve')
  @ApiOperation({ summary: 'Resolve an alert' })
  async resolveAlert(@Param('id') id: string) {
    return this.monitoringService.resolveAlert(id);
  }

  @Get('errors')
  @ApiOperation({ summary: 'Get error report' })
  async getErrorReport(@Query('days') days?: number) {
    return this.monitoringService.getErrorReport(days);
  }

  @Get('performance')
  @ApiOperation({ summary: 'Get performance report' })
  async getPerformanceReport() {
    return this.monitoringService.getPerformanceReport();
  }
}
