import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { PrismaService } from '../../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('dashboard')
@Controller('dashboard')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('owner')
@ApiBearerAuth()
export class DashboardController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Get dashboard statistics' })
  async getStats() {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      totalUsers,
      activeUsers,
      newUsersToday,
      newUsersThisWeek,
      newUsersThisMonth,
      totalHorses,
      totalAnalyses,
      analysesToday,
      pendingReports,
      openTickets,
      subscriptionStats,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { isActive: true } }),
      this.prisma.user.count({ where: { createdAt: { gte: startOfToday } } }),
      this.prisma.user.count({ where: { createdAt: { gte: startOfWeek } } }),
      this.prisma.user.count({ where: { createdAt: { gte: startOfMonth } } }),
      this.prisma.horse.count(),
      this.prisma.analysisSession.count(),
      this.prisma.analysisSession.count({ where: { createdAt: { gte: startOfToday } } }),
      this.prisma.userReport.count({ where: { status: 'pending' } }),
      this.prisma.supportTicket
        .count({ where: { status: { in: ['open', 'in_progress'] } } })
        .catch(() => 0),
      this.getSubscriptionStats(),
    ]);

    // Get users by plan
    const usersByPlan = await this.prisma.organization.groupBy({
      by: ['plan'],
      _count: { _all: true },
    });

    return {
      totalUsers,
      activeUsers,
      newUsersToday,
      newUsersThisWeek,
      newUsersThisMonth,
      totalHorses,
      totalAnalyses,
      analysesToday,
      activeSubscriptions: subscriptionStats.active,
      mrr: subscriptionStats.mrr,
      arr: subscriptionStats.arr,
      churnRate: subscriptionStats.churnRate,
      pendingReports,
      openTickets,
      userGrowth: [],
      revenueGrowth: [],
      analysisGrowth: [],
      usersByPlan: Object.fromEntries(usersByPlan.map((p) => [p.plan || 'free', p._count._all])),
      usersByCountry: {},
    };
  }

  private async getSubscriptionStats() {
    try {
      const activeSubscriptions = await this.prisma.subscription.count({
        where: { status: 'active' },
      });

      const monthlyRevenue = await this.prisma.invoice.aggregate({
        where: {
          status: 'paid',
          paidAt: {
            gte: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
          },
        },
        _sum: { amount: true },
      });

      return {
        active: activeSubscriptions,
        mrr: monthlyRevenue._sum.amount || 0,
        arr: (monthlyRevenue._sum.amount || 0) * 12,
        churnRate: 0,
      };
    } catch {
      return { active: 0, mrr: 0, arr: 0, churnRate: 0 };
    }
  }
}
