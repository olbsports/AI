import { Injectable, Logger } from '@nestjs/common';

import { PrismaService } from '../../prisma/prisma.service';
import { AnalyticsQueryDto, TimeGranularity, ComparisonQueryDto } from './dto/analytics.dto';

export interface TimeSeriesPoint {
  date: string;
  value: number;
}

export interface AnalysisMetrics {
  total: number;
  completed: number;
  failed: number;
  pending: number;
  avgProcessingTime: number;
  byType: Record<string, number>;
  successRate: number;
}

export interface RevenueMetrics {
  total: number;
  recurring: number;
  oneTime: number;
  avgPerCustomer: number;
  churnRate: number;
}

@Injectable()
export class AnalyticsService {
  private readonly logger = new Logger(AnalyticsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async getAnalysisMetrics(
    organizationId: string | null,
    query: AnalyticsQueryDto,
  ): Promise<{
    metrics: AnalysisMetrics;
    timeSeries: TimeSeriesPoint[];
  }> {
    const { from, to } = this.getDateRange(query);
    const where: any = { createdAt: { gte: from, lte: to } };

    if (organizationId) {
      where.organizationId = organizationId;
    }

    const [total, completed, failed, pending, avgTime, byType] = await Promise.all([
      this.prisma.analysisSession.count({ where }),
      this.prisma.analysisSession.count({ where: { ...where, status: 'completed' } }),
      this.prisma.analysisSession.count({ where: { ...where, status: 'failed' } }),
      this.prisma.analysisSession.count({ where: { ...where, status: 'pending' } }),
      this.prisma.analysisSession.aggregate({
        where: { ...where, status: 'completed' },
        _avg: { processingTimeMs: true },
      }),
      this.prisma.analysisSession.groupBy({
        by: ['type'],
        where,
        _count: true,
      }),
    ]);

    // Generate time series
    const timeSeries = await this.getTimeSeriesData(
      'analysisSession',
      where,
      query.granularity || TimeGranularity.DAY,
      from,
      to,
    );

    return {
      metrics: {
        total,
        completed,
        failed,
        pending,
        avgProcessingTime: avgTime._avg.processingTimeMs || 0,
        byType: Object.fromEntries(byType.map((t) => [t.type, t._count])),
        successRate: total > 0 ? (completed / total) * 100 : 0,
      },
      timeSeries,
    };
  }

  async getTokenMetrics(
    organizationId: string | null,
    query: AnalyticsQueryDto,
  ): Promise<{
    consumed: number;
    credited: number;
    balance: number;
    timeSeries: TimeSeriesPoint[];
    byUsageType: Record<string, number>;
  }> {
    const { from, to } = this.getDateRange(query);
    const where: any = { createdAt: { gte: from, lte: to } };

    if (organizationId) {
      where.organizationId = organizationId;
    }

    const [consumed, credited] = await Promise.all([
      this.prisma.tokenTransaction.aggregate({
        where: { ...where, type: 'debit' },
        _sum: { amount: true },
      }),
      this.prisma.tokenTransaction.aggregate({
        where: { ...where, type: 'credit' },
        _sum: { amount: true },
      }),
    ]);

    // Get current balance
    let balance = 0;
    if (organizationId) {
      const org = await this.prisma.organization.findUnique({
        where: { id: organizationId },
        select: { tokenBalance: true },
      });
      balance = org?.tokenBalance || 0;
    } else {
      const totalBalance = await this.prisma.organization.aggregate({
        _sum: { tokenBalance: true },
      });
      balance = totalBalance._sum.tokenBalance || 0;
    }

    // Usage by type from metadata
    const transactions = await this.prisma.tokenTransaction.findMany({
      where: { ...where, type: 'debit' },
      select: { metadata: true, amount: true },
    });

    const byUsageType: Record<string, number> = {};
    transactions.forEach((t) => {
      const usageType = (t.metadata as any)?.type || 'other';
      byUsageType[usageType] = (byUsageType[usageType] || 0) + Math.abs(t.amount);
    });

    // Time series for consumption
    const timeSeries = await this.getTokenTimeSeries(
      where,
      query.granularity || TimeGranularity.DAY,
      from,
      to,
    );

    return {
      consumed: Math.abs(consumed._sum.amount || 0),
      credited: credited._sum.amount || 0,
      balance,
      timeSeries,
      byUsageType,
    };
  }

  async getRevenueMetrics(query: AnalyticsQueryDto): Promise<{
    metrics: RevenueMetrics;
    timeSeries: TimeSeriesPoint[];
    byPlan: Record<string, number>;
  }> {
    const { from, to } = this.getDateRange(query);

    const [total, invoices, orgsByPlan] = await Promise.all([
      this.prisma.invoice.aggregate({
        where: { status: 'paid', paidAt: { gte: from, lte: to } },
        _sum: { amount: true },
        _count: true,
      }),
      this.prisma.invoice.findMany({
        where: { status: 'paid', paidAt: { gte: from, lte: to } },
        select: { amount: true, organizationId: true },
      }),
      this.prisma.organization.groupBy({
        by: ['plan'],
        _count: true,
      }),
    ]);

    const uniqueCustomers = new Set(invoices.map((i) => i.organizationId)).size;
    const avgPerCustomer = uniqueCustomers > 0 ? (total._sum.amount || 0) / uniqueCustomers : 0;

    // Time series
    const timeSeries = await this.getRevenueTimeSeries(
      query.granularity || TimeGranularity.DAY,
      from,
      to,
    );

    // Revenue by plan (simplified)
    const byPlan: Record<string, number> = {};
    orgsByPlan.forEach((p) => {
      byPlan[p.plan] = p._count;
    });

    return {
      metrics: {
        total: total._sum.amount || 0,
        recurring: total._sum.amount || 0, // Simplified
        oneTime: 0,
        avgPerCustomer,
        churnRate: 0, // Would need historical data
      },
      timeSeries,
      byPlan,
    };
  }

  async getUserMetrics(
    organizationId: string | null,
    query: AnalyticsQueryDto,
  ): Promise<{
    total: number;
    active: number;
    new: number;
    byRole: Record<string, number>;
    timeSeries: TimeSeriesPoint[];
    retention: number;
  }> {
    const { from, to } = this.getDateRange(query);
    const where: any = {};

    if (organizationId) {
      where.organizationId = organizationId;
    }

    const [total, active, newUsers, byRole] = await Promise.all([
      this.prisma.user.count({ where }),
      this.prisma.user.count({ where: { ...where, isActive: true } }),
      this.prisma.user.count({ where: { ...where, createdAt: { gte: from, lte: to } } }),
      this.prisma.user.groupBy({
        by: ['role'],
        where,
        _count: true,
      }),
    ]);

    // Users who logged in this period
    const activeThisPeriod = await this.prisma.user.count({
      where: { ...where, lastLoginAt: { gte: from, lte: to } },
    });

    const retention = total > 0 ? (activeThisPeriod / total) * 100 : 0;

    // Time series for new users
    const timeSeries = await this.getUserTimeSeries(
      organizationId,
      query.granularity || TimeGranularity.DAY,
      from,
      to,
    );

    return {
      total,
      active,
      new: newUsers,
      byRole: Object.fromEntries(byRole.map((r) => [r.role, r._count])),
      timeSeries,
      retention: Math.round(retention * 100) / 100,
    };
  }

  async getComparisonMetrics(query: ComparisonQueryDto): Promise<{
    analyses: { current: number; previous: number; change: number };
    revenue: { current: number; previous: number; change: number };
    users: { current: number; previous: number; change: number };
    tokens: { current: number; previous: number; change: number };
  }> {
    const periodDays = this.parsePeriod(query.period || '30d');
    const now = new Date();
    const currentStart = new Date(now.getTime() - periodDays * 24 * 60 * 60 * 1000);
    const previousStart = new Date(currentStart.getTime() - periodDays * 24 * 60 * 60 * 1000);

    const [
      currentAnalyses,
      previousAnalyses,
      currentRevenue,
      previousRevenue,
      currentUsers,
      previousUsers,
      currentTokens,
      previousTokens,
    ] = await Promise.all([
      this.prisma.analysisSession.count({ where: { createdAt: { gte: currentStart } } }),
      this.prisma.analysisSession.count({
        where: { createdAt: { gte: previousStart, lt: currentStart } },
      }),
      this.prisma.invoice.aggregate({
        where: { status: 'paid', paidAt: { gte: currentStart } },
        _sum: { amount: true },
      }),
      this.prisma.invoice.aggregate({
        where: { status: 'paid', paidAt: { gte: previousStart, lt: currentStart } },
        _sum: { amount: true },
      }),
      this.prisma.user.count({ where: { createdAt: { gte: currentStart } } }),
      this.prisma.user.count({ where: { createdAt: { gte: previousStart, lt: currentStart } } }),
      this.prisma.tokenTransaction.aggregate({
        where: { type: 'debit', createdAt: { gte: currentStart } },
        _sum: { amount: true },
      }),
      this.prisma.tokenTransaction.aggregate({
        where: { type: 'debit', createdAt: { gte: previousStart, lt: currentStart } },
        _sum: { amount: true },
      }),
    ]);

    return {
      analyses: this.calculateChange(currentAnalyses, previousAnalyses),
      revenue: this.calculateChange(
        currentRevenue._sum.amount || 0,
        previousRevenue._sum.amount || 0,
      ),
      users: this.calculateChange(currentUsers, previousUsers),
      tokens: this.calculateChange(
        Math.abs(currentTokens._sum.amount || 0),
        Math.abs(previousTokens._sum.amount || 0),
      ),
    };
  }

  async getHorseAnalytics(organizationId: string): Promise<{
    totalHorses: number;
    analysedHorses: number;
    avgScoreByHorse: { horseId: string; horseName: string; avgScore: number }[];
    topPerformers: { horseId: string; horseName: string; score: number }[];
  }> {
    const horses = await this.prisma.horse.findMany({
      where: { organizationId },
      include: {
        analysisSessions: {
          where: { status: 'completed' },
          select: { scores: true },
        },
      },
    });

    const horseScores = horses.map((horse) => {
      const scores = horse.analysisSessions
        .map((a) => (a.scores as any)?.global)
        .filter((s) => s !== undefined);
      const avgScore = scores.length > 0 ? scores.reduce((a, b) => a + b, 0) / scores.length : 0;
      return {
        horseId: horse.id,
        horseName: horse.name,
        avgScore: Math.round(avgScore * 100) / 100,
        analysisCount: horse.analysisSessions.length,
      };
    });

    const analysedHorses = horseScores.filter((h) => h.analysisCount > 0).length;
    const topPerformers = [...horseScores]
      .sort((a, b) => b.avgScore - a.avgScore)
      .slice(0, 5)
      .map((h) => ({ horseId: h.horseId, horseName: h.horseName, score: h.avgScore }));

    return {
      totalHorses: horses.length,
      analysedHorses,
      avgScoreByHorse: horseScores.filter((h) => h.analysisCount > 0),
      topPerformers,
    };
  }

  private getDateRange(query: AnalyticsQueryDto): { from: Date; to: Date } {
    const to = query.to ? new Date(query.to) : new Date();
    const from = query.from ? new Date(query.from) : new Date(to.getTime() - 30 * 24 * 60 * 60 * 1000);
    return { from, to };
  }

  private parsePeriod(period: string): number {
    const match = period.match(/^(\d+)([dhwm])$/);
    if (!match) return 30;

    const value = parseInt(match[1], 10);
    const unit = match[2];

    switch (unit) {
      case 'd':
        return value;
      case 'w':
        return value * 7;
      case 'm':
        return value * 30;
      default:
        return 30;
    }
  }

  private calculateChange(
    current: number,
    previous: number,
  ): { current: number; previous: number; change: number } {
    const change = previous > 0 ? ((current - previous) / previous) * 100 : current > 0 ? 100 : 0;
    return {
      current,
      previous,
      change: Math.round(change * 100) / 100,
    };
  }

  private async getTimeSeriesData(
    model: string,
    where: any,
    granularity: TimeGranularity,
    from: Date,
    to: Date,
  ): Promise<TimeSeriesPoint[]> {
    // Simplified: group by day
    const data = await (this.prisma as any)[model].groupBy({
      by: ['createdAt'],
      where,
      _count: true,
    });

    const dateMap = new Map<string, number>();
    data.forEach((d: any) => {
      const date = d.createdAt.toISOString().split('T')[0];
      dateMap.set(date, (dateMap.get(date) || 0) + d._count);
    });

    return Array.from(dateMap.entries())
      .map(([date, value]) => ({ date, value }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }

  private async getTokenTimeSeries(
    where: any,
    granularity: TimeGranularity,
    from: Date,
    to: Date,
  ): Promise<TimeSeriesPoint[]> {
    const transactions = await this.prisma.tokenTransaction.findMany({
      where: { ...where, type: 'debit' },
      select: { createdAt: true, amount: true },
    });

    const dateMap = new Map<string, number>();
    transactions.forEach((t) => {
      const date = t.createdAt.toISOString().split('T')[0];
      dateMap.set(date, (dateMap.get(date) || 0) + Math.abs(t.amount));
    });

    return Array.from(dateMap.entries())
      .map(([date, value]) => ({ date, value }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }

  private async getRevenueTimeSeries(
    granularity: TimeGranularity,
    from: Date,
    to: Date,
  ): Promise<TimeSeriesPoint[]> {
    const invoices = await this.prisma.invoice.findMany({
      where: { status: 'paid', paidAt: { gte: from, lte: to } },
      select: { paidAt: true, amount: true },
    });

    const dateMap = new Map<string, number>();
    invoices.forEach((i) => {
      if (i.paidAt) {
        const date = i.paidAt.toISOString().split('T')[0];
        dateMap.set(date, (dateMap.get(date) || 0) + i.amount);
      }
    });

    return Array.from(dateMap.entries())
      .map(([date, value]) => ({ date, value }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }

  private async getUserTimeSeries(
    organizationId: string | null,
    granularity: TimeGranularity,
    from: Date,
    to: Date,
  ): Promise<TimeSeriesPoint[]> {
    const where: any = { createdAt: { gte: from, lte: to } };
    if (organizationId) {
      where.organizationId = organizationId;
    }

    const users = await this.prisma.user.findMany({
      where,
      select: { createdAt: true },
    });

    const dateMap = new Map<string, number>();
    users.forEach((u) => {
      const date = u.createdAt.toISOString().split('T')[0];
      dateMap.set(date, (dateMap.get(date) || 0) + 1);
    });

    return Array.from(dateMap.entries())
      .map(([date, value]) => ({ date, value }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }
}
