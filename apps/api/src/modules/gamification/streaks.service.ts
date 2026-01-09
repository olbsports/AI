import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

// Streak bonus configuration
const STREAK_BONUSES = [
  { days: 7, xp: 200, name: 'Semaine parfaite' },
  { days: 14, xp: 400, name: 'Deux semaines' },
  { days: 30, xp: 1000, name: 'Un mois' },
  { days: 60, xp: 2000, name: 'Deux mois' },
  { days: 90, xp: 3500, name: 'Trois mois' },
  { days: 180, xp: 7500, name: 'Six mois' },
  { days: 365, xp: 20000, name: 'Un an' },
];

@Injectable()
export class StreaksService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get or create user streak record
   */
  async getOrCreateStreak(userId: string) {
    let streak = await this.prisma.userStreak.findUnique({
      where: { userId },
    });

    if (!streak) {
      streak = await this.prisma.userStreak.create({
        data: {
          userId,
          currentStreak: 0,
          longestStreak: 0,
        },
      });
    }

    return streak;
  }

  /**
   * Get user streak information
   */
  async getStreak(userId: string) {
    const streak = await this.getOrCreateStreak(userId);

    // Calculate next bonus milestone
    const nextBonus = STREAK_BONUSES.find((b) => b.days > streak.currentStreak);
    const previousBonuses = STREAK_BONUSES.filter(
      (b) => b.days <= streak.currentStreak,
    );

    return {
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
      lastActivityAt: streak.lastActivityAt,
      totalBonusXp: streak.totalBonusXp,
      nextBonus: nextBonus
        ? {
            daysRequired: nextBonus.days,
            daysRemaining: nextBonus.days - streak.currentStreak,
            xpReward: nextBonus.xp,
            name: nextBonus.name,
          }
        : null,
      earnedBonuses: previousBonuses.map((b) => ({
        days: b.days,
        xp: b.xp,
        name: b.name,
      })),
      streakProtected: this.isStreakProtected(streak.lastActivityAt),
    };
  }

  /**
   * Record user activity and update streak
   */
  async recordActivity(userId: string): Promise<{
    streakUpdated: boolean;
    currentStreak: number;
    bonusAwarded?: { xp: number; name: string };
    isNewRecord: boolean;
  }> {
    const streak = await this.getOrCreateStreak(userId);
    const now = new Date();
    const today = this.getDateOnly(now);
    const lastActivity = streak.lastActivityAt
      ? this.getDateOnly(streak.lastActivityAt)
      : null;

    // If already recorded activity today, skip
    if (lastActivity && lastActivity.getTime() === today.getTime()) {
      return {
        streakUpdated: false,
        currentStreak: streak.currentStreak,
        isNewRecord: false,
      };
    }

    let newStreak = streak.currentStreak;
    let bonusAwarded: { xp: number; name: string } | undefined;

    if (lastActivity) {
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);

      if (lastActivity.getTime() === yesterday.getTime()) {
        // Consecutive day - increment streak
        newStreak = streak.currentStreak + 1;
      } else if (lastActivity.getTime() < yesterday.getTime()) {
        // Streak broken - reset to 1
        newStreak = 1;
      }
    } else {
      // First activity ever
      newStreak = 1;
    }

    const isNewRecord = newStreak > streak.longestStreak;

    // Check for bonus milestone
    const bonus = STREAK_BONUSES.find((b) => b.days === newStreak);
    let totalBonusXp = streak.totalBonusXp;

    if (bonus) {
      bonusAwarded = { xp: bonus.xp, name: bonus.name };
      totalBonusXp += bonus.xp;

      // Award XP to user
      await this.prisma.$transaction([
        this.prisma.user.update({
          where: { id: userId },
          data: { xp: { increment: bonus.xp } },
        }),
        this.prisma.xpTransaction.create({
          data: {
            userId,
            amount: bonus.xp,
            source: 'streak_bonus',
            description: `Bonus streak ${bonus.name}: ${newStreak} jours consécutifs`,
          },
        }),
      ]);
    }

    // Update streak record
    await this.prisma.userStreak.update({
      where: { userId },
      data: {
        currentStreak: newStreak,
        longestStreak: isNewRecord ? newStreak : streak.longestStreak,
        lastActivityAt: now,
        lastBonusAt: bonus ? now : streak.lastBonusAt,
        totalBonusXp,
      },
    });

    return {
      streakUpdated: true,
      currentStreak: newStreak,
      bonusAwarded,
      isNewRecord,
    };
  }

  /**
   * Check if streak would be lost tomorrow (for notifications)
   */
  async checkStreakAtRisk(userId: string): Promise<boolean> {
    const streak = await this.prisma.userStreak.findUnique({
      where: { userId },
    });

    if (!streak || streak.currentStreak === 0) {
      return false;
    }

    const today = this.getDateOnly(new Date());
    const lastActivity = streak.lastActivityAt
      ? this.getDateOnly(streak.lastActivityAt)
      : null;

    if (!lastActivity) {
      return false;
    }

    // If last activity was yesterday, streak is at risk
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    return lastActivity.getTime() === yesterday.getTime();
  }

  /**
   * Get streak leaderboard for an organization
   */
  async getStreakLeaderboard(organizationId: string, limit: number = 10) {
    const users = await this.prisma.user.findMany({
      where: { organizationId },
      include: { userStreak: true },
    });

    const leaderboard = users
      .filter((u) => u.userStreak && u.userStreak.currentStreak > 0)
      .map((u) => ({
        userId: u.id,
        name: `${u.firstName} ${u.lastName}`,
        avatarUrl: u.avatarUrl,
        currentStreak: u.userStreak!.currentStreak,
        longestStreak: u.userStreak!.longestStreak,
      }))
      .sort((a, b) => b.currentStreak - a.currentStreak)
      .slice(0, limit);

    return leaderboard;
  }

  /**
   * Helper: Get date without time
   */
  private getDateOnly(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }

  /**
   * Helper: Check if streak is protected (activity today)
   */
  private isStreakProtected(lastActivityAt: Date | null): boolean {
    if (!lastActivityAt) return false;
    const today = this.getDateOnly(new Date());
    const lastActivity = this.getDateOnly(lastActivityAt);
    return lastActivity.getTime() === today.getTime();
  }
}
