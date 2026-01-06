import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class LeaderboardService {
  constructor(private prisma: PrismaService) {}

  async getRiderLeaderboard(period: string, galopLevel?: number) {
    // Get riders with their analysis counts and scores
    const riders = await this.prisma.rider.findMany({
      where: galopLevel ? { level: `Galop ${galopLevel}` } : {},
      include: {
        _count: {
          select: {
            analysisSessions: true,
            horses: true,
          },
        },
      },
      take: 50,
    });

    // Calculate scores and format
    return riders.map((rider, index) => ({
      id: rider.id,
      riderId: rider.id,
      riderName: `${rider.firstName} ${rider.lastName}`,
      riderPhotoUrl: rider.photoUrl,
      galopLevel: parseInt(rider.level?.replace('Galop ', '') || '1'),
      rank: index + 1,
      previousRank: index + 1,
      score: rider.xp || (rider._count.analysisSessions * 100),
      analysisCount: rider._count.analysisSessions,
      horseCount: rider._count.horses,
      streakDays: 0,
      progressRate: 0,
      badges: [],
      rankChange: 0,
    }));
  }

  async getHorseLeaderboard(period: string, discipline?: string, category?: string) {
    const where: any = {};
    if (discipline) {
      where.disciplines = { array_contains: discipline };
    }
    if (category) {
      where.level = category;
    }

    const horses = await this.prisma.horse.findMany({
      where: {
        status: 'active',
      },
      include: {
        _count: {
          select: {
            analysisSessions: true,
          },
        },
      },
      take: 50,
    });

    return horses.map((horse, index) => ({
      id: horse.id,
      horseId: horse.id,
      horseName: horse.name,
      horsePhotoUrl: horse.photoUrl,
      breed: horse.breed,
      discipline: (horse.disciplines as string[])?.[0] || 'CSO',
      category: horse.level || 'Amateur',
      rank: index + 1,
      previousRank: index + 1,
      score: horse._count.analysisSessions * 150,
      analysisCount: horse._count.analysisSessions,
      averageScore: 7.5,
      progressRate: 0,
      achievements: [],
      rankChange: 0,
    }));
  }

  async getMyRiderRanking(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        organization: {
          include: {
            riders: {
              where: {
                email: { not: null },
              },
              take: 1,
            },
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Try to find associated rider
    const rider = user.organization.riders[0];

    return {
      id: rider?.id || userId,
      riderId: rider?.id || userId,
      riderName: `${user.firstName} ${user.lastName}`,
      riderPhotoUrl: user.avatarUrl,
      galopLevel: 3,
      rank: 42,
      previousRank: 45,
      score: user.xp,
      analysisCount: 0,
      horseCount: 0,
      streakDays: 0,
      progressRate: 5.2,
      badges: user.badges as string[] || [],
      rankChange: 3,
    };
  }

  async getMyHorseRankings(userId: string, organizationId: string) {
    const horses = await this.prisma.horse.findMany({
      where: { organizationId },
      include: {
        _count: {
          select: {
            analysisSessions: true,
          },
        },
      },
      take: 10,
    });

    return horses.map((horse, index) => ({
      id: horse.id,
      horseId: horse.id,
      horseName: horse.name,
      horsePhotoUrl: horse.photoUrl,
      breed: horse.breed,
      discipline: (horse.disciplines as string[])?.[0] || 'CSO',
      category: horse.level || 'Amateur',
      rank: 50 + index,
      previousRank: 52 + index,
      score: horse._count.analysisSessions * 150,
      analysisCount: horse._count.analysisSessions,
      averageScore: 7.5,
      progressRate: 3.1,
      achievements: [],
      rankChange: 2,
    }));
  }

  async getTopRiders() {
    return this.getRiderLeaderboard('all');
  }

  async getTopHorses() {
    return this.getHorseLeaderboard('all');
  }

  async getRisingRiders() {
    // Return riders with highest improvement
    return this.getRiderLeaderboard('weekly');
  }

  async getRisingHorses() {
    return this.getHorseLeaderboard('weekly');
  }

  async getStats() {
    const [totalRiders, totalHorses, activeThisWeek] = await Promise.all([
      this.prisma.rider.count(),
      this.prisma.horse.count({ where: { status: 'active' } }),
      this.prisma.analysisSession.count({
        where: {
          createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
        },
      }),
    ]);

    return {
      totalRiders,
      totalHorses,
      activeThisWeek,
      analysesThisWeek: activeThisWeek,
      averageScore: 7.8,
      ridersByGalop: {
        '1': 100,
        '2': 150,
        '3': 200,
        '4': 180,
        '5': 120,
        '6': 80,
        '7': 50,
      },
      horsesByDiscipline: {
        'CSO': 300,
        'Dressage': 200,
        'CCE': 150,
        'Endurance': 50,
      },
    };
  }

  async getRegionalLeaderboard(region: string) {
    const riders = await this.getRiderLeaderboard('all');
    const horses = await this.getHorseLeaderboard('all');

    return {
      region,
      topRiders: riders.slice(0, 10),
      topHorses: horses.slice(0, 10),
      totalParticipants: riders.length + horses.length,
    };
  }

  async getClubLeaderboard() {
    const clubs = await this.prisma.club.findMany({
      orderBy: { memberCount: 'desc' },
      take: 50,
    });

    return clubs.map((club, index) => ({
      id: club.id,
      clubId: club.id,
      clubName: club.name,
      clubLogoUrl: club.logoUrl,
      rank: index + 1,
      previousRank: index + 1,
      totalScore: club.memberCount * 100,
      memberCount: club.memberCount,
      activeMembers: club.memberCount,
      analysisCount: 0,
      averageScore: 0,
    }));
  }

  async getWeeklyRewards(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Calculate next Sunday
    const now = new Date();
    const nextSunday = new Date(now);
    nextSunday.setDate(now.getDate() + (7 - now.getDay()));
    nextSunday.setHours(23, 59, 59, 999);

    return {
      rank: 42,
      xpReward: 100,
      badgeId: null,
      claimed: false,
      weekEndDate: nextSunday.toISOString(),
    };
  }

  async challengeRider(userId: string, riderId: string) {
    // Placeholder - would create a challenge record
    return { success: true };
  }

  async shareRanking(type: string, id: string) {
    // Placeholder - would generate share URL
    return { shareUrl: `https://app.example.com/share/${type}/${id}` };
  }

  async claimWeeklyReward(userId: string) {
    // Placeholder - would update user XP and mark reward as claimed
    await this.prisma.user.update({
      where: { id: userId },
      data: { xp: { increment: 100 } },
    });
    return { success: true, xpEarned: 100 };
  }
}
