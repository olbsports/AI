import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class GamificationService {
  constructor(private prisma: PrismaService) {}

  async getLevel(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { xp: true, level: true, badges: true },
    });

    if (!user) {
      return { xp: 0, level: 1, nextLevelXp: 100 };
    }

    // Calculate XP needed for next level
    const xpPerLevel = 100;
    const nextLevelXp = (user.level + 1) * xpPerLevel;
    const currentLevelXp = user.level * xpPerLevel;
    const progressToNextLevel = ((user.xp - currentLevelXp) / (nextLevelXp - currentLevelXp)) * 100;

    return {
      xp: user.xp,
      level: user.level,
      nextLevelXp,
      progressToNextLevel: Math.min(100, Math.max(0, progressToNextLevel)),
      badges: user.badges,
    };
  }

  async getXpHistory(userId: string) {
    // Return mock XP history - in production, you'd have an XP transactions table
    return [
      { id: '1', amount: 50, reason: 'Connexion quotidienne', date: new Date() },
      { id: '2', amount: 100, reason: 'Première analyse', date: new Date(Date.now() - 86400000) },
      { id: '3', amount: 25, reason: 'Publication', date: new Date(Date.now() - 172800000) },
    ];
  }

  async getAllBadges() {
    return [
      { id: 'first_horse', name: 'Premier Cheval', description: 'Ajoutez votre premier cheval', icon: '🐴', xpReward: 50 },
      { id: 'first_analysis', name: 'Première Analyse', description: 'Effectuez votre première analyse', icon: '🔍', xpReward: 100 },
      { id: 'week_streak', name: 'Semaine Active', description: 'Connectez-vous 7 jours de suite', icon: '🔥', xpReward: 150 },
      { id: 'social_butterfly', name: 'Papillon Social', description: 'Suivez 10 utilisateurs', icon: '🦋', xpReward: 75 },
      { id: 'stable_5', name: 'Petite Écurie', description: 'Gérez 5 chevaux', icon: '🏠', xpReward: 200 },
      { id: 'stable_10', name: 'Grande Écurie', description: 'Gérez 10 chevaux', icon: '🏰', xpReward: 500 },
      { id: 'analyst', name: 'Analyste', description: 'Effectuez 10 analyses', icon: '📊', xpReward: 300 },
      { id: 'champion', name: 'Champion', description: 'Atteignez le top 10 du classement', icon: '🏆', xpReward: 1000 },
    ];
  }

  async getEarnedBadges(userId: string) {
    const achievements = await this.prisma.achievement.findMany({
      where: { userId },
    });

    return achievements.map(a => ({
      id: a.id,
      type: a.type,
      name: a.name,
      description: a.description,
      icon: a.iconUrl,
      xpReward: a.xpReward,
      unlockedAt: a.unlockedAt,
    }));
  }

  async getActiveChallenges(userId: string) {
    // Return mock challenges
    return [
      {
        id: 'challenge_1',
        title: 'Explorateur',
        description: 'Analysez 3 chevaux différents',
        progress: 1,
        target: 3,
        xpReward: 100,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
      {
        id: 'challenge_2',
        title: 'Social',
        description: 'Publiez 5 notes cette semaine',
        progress: 2,
        target: 5,
        xpReward: 75,
        expiresAt: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
      },
      {
        id: 'challenge_3',
        title: 'Régulier',
        description: 'Connectez-vous 5 jours de suite',
        progress: 3,
        target: 5,
        xpReward: 50,
        expiresAt: null,
      },
    ];
  }

  async getStreak(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { lastLoginAt: true },
    });

    // Simple streak calculation - in production you'd track this properly
    return {
      currentStreak: 3,
      longestStreak: 7,
      lastLoginAt: user?.lastLoginAt,
      streakProtected: false,
    };
  }

  async getRewards(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { xp: true },
    });

    return [
      {
        id: 'reward_1',
        name: 'Analyse gratuite',
        description: 'Obtenez une analyse vidéo gratuite',
        cost: 500,
        available: (user?.xp || 0) >= 500,
        type: 'token',
      },
      {
        id: 'reward_2',
        name: 'Badge exclusif',
        description: 'Débloquez un badge exclusif',
        cost: 1000,
        available: (user?.xp || 0) >= 1000,
        type: 'badge',
      },
      {
        id: 'reward_3',
        name: 'Profil mis en avant',
        description: 'Votre profil sera mis en avant pendant 7 jours',
        cost: 2000,
        available: (user?.xp || 0) >= 2000,
        type: 'feature',
      },
    ];
  }

  async getReferralStats(userId: string) {
    return {
      referrals: 2,
      pendingReferrals: 1,
      totalXpEarned: 200,
      referralCode: `HT-${userId.substring(0, 6).toUpperCase()}`,
    };
  }

  async getReferralCode(userId: string) {
    return {
      code: `HT-${userId.substring(0, 6).toUpperCase()}`,
      shareUrl: `https://horsetempo.app/invite/${userId.substring(0, 6).toUpperCase()}`,
    };
  }

  async getLeaderboard(organizationId: string) {
    const users = await this.prisma.user.findMany({
      where: { organizationId },
      orderBy: { xp: 'desc' },
      take: 20,
      select: {
        id: true,
        firstName: true,
        lastName: true,
        avatarUrl: true,
        xp: true,
        level: true,
      },
    });

    return users.map((user, index) => ({
      rank: index + 1,
      id: user.id,
      name: `${user.firstName} ${user.lastName}`,
      avatarUrl: user.avatarUrl,
      xp: user.xp,
      level: user.level,
    }));
  }

  async claimDailyLogin(userId: string) {
    const xpReward = 10;

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        xp: { increment: xpReward },
        lastLoginAt: new Date(),
      },
    });

    return {
      success: true,
      xpEarned: xpReward,
      message: 'Connexion quotidienne récompensée !',
    };
  }

  async completeChallenge(userId: string, challengeId: string) {
    // In production, you'd verify the challenge is actually complete
    const xpReward = 100;

    await this.prisma.user.update({
      where: { id: userId },
      data: { xp: { increment: xpReward } },
    });

    return {
      success: true,
      xpEarned: xpReward,
      message: 'Défi complété !',
    };
  }

  async claimReward(userId: string, rewardId: string) {
    // In production, you'd deduct XP and give the reward
    return {
      success: true,
      message: 'Récompense réclamée !',
    };
  }
}
