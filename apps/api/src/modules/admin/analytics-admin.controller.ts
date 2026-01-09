import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { PrismaService } from '../../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('analytics')
@Controller('analytics')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin', 'owner')
@ApiBearerAuth()
export class AnalyticsAdminController {
  constructor(private readonly prisma: PrismaService) {}

  @Get(':metric')
  @ApiOperation({ summary: 'Get analytics data for a metric' })
  async getMetric(@Param('metric') metric: string, @Query('period') period?: string) {
    const days = period === 'month' ? 30 : period === 'year' ? 365 : 7;
    const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    const previousStartDate = new Date(startDate.getTime() - days * 24 * 60 * 60 * 1000);

    let currentValue = 0;
    let previousValue = 0;

    switch (metric) {
      case 'users':
        [currentValue, previousValue] = await Promise.all([
          this.prisma.user.count({ where: { createdAt: { gte: startDate } } }),
          this.prisma.user.count({
            where: { createdAt: { gte: previousStartDate, lt: startDate } },
          }),
        ]);
        break;

      case 'analyses':
        [currentValue, previousValue] = await Promise.all([
          this.prisma.analysisSession.count({ where: { createdAt: { gte: startDate } } }),
          this.prisma.analysisSession.count({
            where: { createdAt: { gte: previousStartDate, lt: startDate } },
          }),
        ]);
        break;

      case 'horses':
        [currentValue, previousValue] = await Promise.all([
          this.prisma.horse.count({ where: { createdAt: { gte: startDate } } }),
          this.prisma.horse.count({
            where: { createdAt: { gte: previousStartDate, lt: startDate } },
          }),
        ]);
        break;

      case 'revenue':
        const [current, previous] = await Promise.all([
          this.prisma.invoice.aggregate({
            where: { status: 'paid', paidAt: { gte: startDate } },
            _sum: { amount: true },
          }),
          this.prisma.invoice.aggregate({
            where: { status: 'paid', paidAt: { gte: previousStartDate, lt: startDate } },
            _sum: { amount: true },
          }),
        ]);
        currentValue = current._sum.amount || 0;
        previousValue = previous._sum.amount || 0;
        break;
    }

    const changePercent =
      previousValue > 0 ? ((currentValue - previousValue) / previousValue) * 100 : 0;

    return {
      metric,
      currentValue,
      previousValue,
      changePercent: Math.round(changePercent * 100) / 100,
      history: [],
      breakdown: null,
    };
  }

  @Get('retention')
  @ApiOperation({ summary: 'Get user retention cohort data' })
  async getRetention() {
    // Simplified retention data
    const cohorts = [];
    const now = new Date();

    for (let i = 5; i >= 0; i--) {
      const monthStart = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0);

      const totalUsers = await this.prisma.user.count({
        where: {
          createdAt: { gte: monthStart, lte: monthEnd },
        },
      });

      cohorts.push({
        cohortMonth: `${monthStart.getFullYear()}-${String(monthStart.getMonth() + 1).padStart(2, '0')}`,
        totalUsers,
        retentionRates: [100, 85, 70, 60, 55, 50], // Placeholder data
      });
    }

    return cohorts;
  }
}
