import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { AnalyticsService } from './analytics.service';
import { AnalyticsQueryDto, ComparisonQueryDto } from './dto/analytics.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { OrganizationGuard } from '../auth/guards/organization.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentOrganization } from '../auth/decorators/organization.decorator';

@ApiTags('analytics')
@Controller('analytics')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  // Organization-scoped analytics
  @Get('analyses')
  @UseGuards(OrganizationGuard)
  @ApiOperation({ summary: 'Get analysis metrics for organization' })
  async getAnalysisMetrics(
    @CurrentOrganization() organizationId: string,
    @Query() query: AnalyticsQueryDto,
  ) {
    return this.analyticsService.getAnalysisMetrics(organizationId, query);
  }

  @Get('tokens')
  @UseGuards(OrganizationGuard)
  @ApiOperation({ summary: 'Get token usage metrics for organization' })
  async getTokenMetrics(
    @CurrentOrganization() organizationId: string,
    @Query() query: AnalyticsQueryDto,
  ) {
    return this.analyticsService.getTokenMetrics(organizationId, query);
  }

  @Get('users')
  @UseGuards(OrganizationGuard)
  @ApiOperation({ summary: 'Get user metrics for organization' })
  async getUserMetrics(
    @CurrentOrganization() organizationId: string,
    @Query() query: AnalyticsQueryDto,
  ) {
    return this.analyticsService.getUserMetrics(organizationId, query);
  }

  @Get('horses')
  @UseGuards(OrganizationGuard)
  @ApiOperation({ summary: 'Get horse analytics for organization' })
  async getHorseAnalytics(@CurrentOrganization() organizationId: string) {
    return this.analyticsService.getHorseAnalytics(organizationId);
  }

  // Admin-only platform-wide analytics
  @Get('platform/analyses')
  @UseGuards(RolesGuard)
  @Roles('owner')
  @ApiOperation({ summary: 'Get platform-wide analysis metrics (admin)' })
  async getPlatformAnalysisMetrics(@Query() query: AnalyticsQueryDto) {
    return this.analyticsService.getAnalysisMetrics(null, query);
  }

  @Get('platform/tokens')
  @UseGuards(RolesGuard)
  @Roles('owner')
  @ApiOperation({ summary: 'Get platform-wide token metrics (admin)' })
  async getPlatformTokenMetrics(@Query() query: AnalyticsQueryDto) {
    return this.analyticsService.getTokenMetrics(null, query);
  }

  @Get('platform/revenue')
  @UseGuards(RolesGuard)
  @Roles('owner')
  @ApiOperation({ summary: 'Get revenue metrics (admin)' })
  async getRevenueMetrics(@Query() query: AnalyticsQueryDto) {
    return this.analyticsService.getRevenueMetrics(query);
  }

  @Get('platform/users')
  @UseGuards(RolesGuard)
  @Roles('owner')
  @ApiOperation({ summary: 'Get platform-wide user metrics (admin)' })
  async getPlatformUserMetrics(@Query() query: AnalyticsQueryDto) {
    return this.analyticsService.getUserMetrics(null, query);
  }

  @Get('platform/comparison')
  @UseGuards(RolesGuard)
  @Roles('owner')
  @ApiOperation({ summary: 'Get period comparison metrics (admin)' })
  async getComparisonMetrics(@Query() query: ComparisonQueryDto) {
    return this.analyticsService.getComparisonMetrics(query);
  }
}
