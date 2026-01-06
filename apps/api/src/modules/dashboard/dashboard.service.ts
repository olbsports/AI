import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  async getStats(organizationId: string, userId: string) {
    // Get counts in parallel
    const [
      horsesCount,
      ridersCount,
      analysesCount,
      reportsCount,
      user,
      recentAnalyses,
      upcomingEvents,
    ] = await Promise.all([
      this.prisma.horse.count({
        where: { organizationId, status: 'active' },
      }),
      this.prisma.rider.count({
        where: { organizationId },
      }),
      this.prisma.analysisSession.count({
        where: { organizationId },
      }),
      this.prisma.report.count({
        where: { organizationId },
      }),
      this.prisma.user.findUnique({
        where: { id: userId },
        select: {
          xp: true,
          level: true,
          badges: true,
          followersCount: true,
          followingCount: true,
        },
      }),
      this.prisma.analysisSession.findMany({
        where: { organizationId },
        orderBy: { createdAt: 'desc' },
        take: 5,
        include: {
          horse: { select: { id: true, name: true } },
        },
      }),
      // Mock upcoming events since we don't have a calendar table
      Promise.resolve([
        { id: '1', title: 'Entraînement', date: new Date(), type: 'training' },
        { id: '2', title: 'Visite vétérinaire', date: new Date(Date.now() + 86400000), type: 'vet' },
      ]),
    ]);

    // Get organization token balance
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
      select: { tokenBalance: true, plan: true },
    });

    // Calculate some metrics
    const thisMonth = new Date();
    thisMonth.setDate(1);
    thisMonth.setHours(0, 0, 0, 0);

    const analysesThisMonth = await this.prisma.analysisSession.count({
      where: {
        organizationId,
        createdAt: { gte: thisMonth },
      },
    });

    return {
      // Counts
      horses: horsesCount,
      riders: ridersCount,
      analyses: analysesCount,
      reports: reportsCount,

      // User stats
      userXp: user?.xp || 0,
      userLevel: user?.level || 1,
      userBadges: user?.badges || [],
      followersCount: user?.followersCount || 0,
      followingCount: user?.followingCount || 0,

      // Organization
      tokenBalance: organization?.tokenBalance || 0,
      plan: organization?.plan || 'starter',

      // Activity
      analysesThisMonth,
      recentAnalyses: recentAnalyses.map(a => ({
        id: a.id,
        title: a.title,
        type: a.type,
        status: a.status,
        horseName: a.horse?.name,
        createdAt: a.createdAt,
      })),

      // Upcoming events
      upcomingEvents,

      // Quick stats
      quickStats: {
        horsesActive: horsesCount,
        analysesCompleted: analysesCount,
        reportsGenerated: reportsCount,
        tokensRemaining: organization?.tokenBalance || 0,
      },
    };
  }
}
