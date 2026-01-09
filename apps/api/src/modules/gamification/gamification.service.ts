import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ChallengesService } from './challenges.service';
import { StreaksService } from './streaks.service';
import { ReferralsService } from './referrals.service';

// XP reward configuration
const XP_REWARDS = {
  daily_login: 10,
  publish_post: 15,
  comment: 5,
  like: 2,
  add_horse: 50,
  analyze_horse: 25,
  complete_profile: 100,
  first_follow: 20,
};

@Injectable()
export class GamificationService {
  constructor(
    private prisma: PrismaService,
    private challengesService: ChallengesService,
    private streaksService: StreaksService,
    private referralsService: ReferralsService,
  ) {}

  /**
   * Get user level and XP information
   */
  async getLevel(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { xp: true, level: true, badges: true },
    });

    if (!user) {
      return { xp: 0, level: 1, nextLevelXp: 100 };
    }

    // Calculate XP needed for next level (progressive scaling)
    const xpForLevel = (level: number) => Math.floor(100 * Math.pow(1.5, level - 1));
    const currentLevelXp = xpForLevel(user.level);
    const nextLevelXp = xpForLevel(user.level + 1);
    const xpInCurrentLevel = user.xp - currentLevelXp;
    const xpNeededForNextLevel = nextLevelXp - currentLevelXp;
    const progressToNextLevel = (xpInCurrentLevel / xpNeededForNextLevel) * 100;

    return {
      xp: user.xp,
      level: user.level,
      currentLevelXp,
      nextLevelXp,
      xpToNextLevel: nextLevelXp - user.xp,
      progressToNextLevel: Math.min(100, Math.max(0, progressToNextLevel)),
      badges: user.badges,
    };
  }

  /**
   * Get XP transaction history
   */
  async getXpHistory(userId: string, limit: number = 50, offset: number = 0) {
    const [transactions, total] = await Promise.all([
      this.prisma.xpTransaction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.xpTransaction.count({ where: { userId } }),
    ]);

    // Group by source for summary
    const summary = await this.prisma.xpTransaction.groupBy({
      by: ['source'],
      where: { userId },
      _sum: { amount: true },
      _count: true,
    });

    return {
      transactions: transactions.map((t) => ({
        id: t.id,
        amount: t.amount,
        source: t.source,
        description: t.description,
        createdAt: t.createdAt,
      })),
      total,
      summary: summary.map((s) => ({
        source: s.source,
        totalXp: s._sum.amount || 0,
        count: s._count,
      })),
    };
  }

  /**
   * Award XP to a user with transaction tracking
   */
  async awardXp(
    userId: string,
    amount: number,
    source: string,
    description: string,
  ) {
    const [, updatedUser] = await this.prisma.$transaction([
      this.prisma.xpTransaction.create({
        data: {
          userId,
          amount,
          source,
          description,
        },
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: { xp: { increment: amount } },
        select: { xp: true, level: true },
      }),
    ]);

    // Check if user should level up
    const levelUp = await this.checkLevelUp(userId, updatedUser.xp);

    // Update challenge progress
    await this.challengesService.updateProgress(userId, source);

    return {
      xpAwarded: amount,
      totalXp: updatedUser.xp,
      levelUp,
    };
  }

  /**
   * Check and apply level up if necessary
   */
  private async checkLevelUp(userId: string, currentXp: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { level: true },
    });

    if (!user) return null;

    const xpForLevel = (level: number) => Math.floor(100 * Math.pow(1.5, level - 1));
    const nextLevelXp = xpForLevel(user.level + 1);

    if (currentXp >= nextLevelXp) {
      const newLevel = user.level + 1;
      await this.prisma.user.update({
        where: { id: userId },
        data: { level: newLevel },
      });

      return {
        previousLevel: user.level,
        newLevel,
        message: `Félicitations ! Vous êtes passé au niveau ${newLevel} !`,
      };
    }

    return null;
  }

  /**
   * Get all available badges
   */
  async getAllBadges() {
    return [
      {
        id: 'first_horse',
        name: 'Premier Cheval',
        description: 'Ajoutez votre premier cheval',
        icon: 'horse',
        xpReward: 50,
        category: 'horses',
      },
      {
        id: 'first_analysis',
        name: 'Première Analyse',
        description: 'Effectuez votre première analyse',
        icon: 'analysis',
        xpReward: 100,
        category: 'analysis',
      },
      {
        id: 'week_streak',
        name: 'Semaine Active',
        description: 'Connectez-vous 7 jours de suite',
        icon: 'fire',
        xpReward: 200,
        category: 'streak',
      },
      {
        id: 'month_streak',
        name: 'Mois Actif',
        description: 'Connectez-vous 30 jours de suite',
        icon: 'fire-alt',
        xpReward: 1000,
        category: 'streak',
      },
      {
        id: 'social_butterfly',
        name: 'Papillon Social',
        description: 'Suivez 10 utilisateurs',
        icon: 'users',
        xpReward: 75,
        category: 'social',
      },
      {
        id: 'influencer',
        name: 'Influenceur',
        description: 'Obtenez 100 abonnés',
        icon: 'star',
        xpReward: 500,
        category: 'social',
      },
      {
        id: 'stable_5',
        name: 'Petite Écurie',
        description: 'Gérez 5 chevaux',
        icon: 'barn',
        xpReward: 200,
        category: 'horses',
      },
      {
        id: 'stable_10',
        name: 'Grande Écurie',
        description: 'Gérez 10 chevaux',
        icon: 'castle',
        xpReward: 500,
        category: 'horses',
      },
      {
        id: 'analyst',
        name: 'Analyste',
        description: 'Effectuez 10 analyses',
        icon: 'chart',
        xpReward: 300,
        category: 'analysis',
      },
      {
        id: 'expert_analyst',
        name: 'Expert Analyste',
        description: 'Effectuez 50 analyses',
        icon: 'chart-pro',
        xpReward: 1000,
        category: 'analysis',
      },
      {
        id: 'champion',
        name: 'Champion',
        description: 'Atteignez le top 10 du classement',
        icon: 'trophy',
        xpReward: 1000,
        category: 'leaderboard',
      },
      {
        id: 'referrer_bronze',
        name: 'Ambassadeur Bronze',
        description: 'Parrainez 3 utilisateurs',
        icon: 'gift',
        xpReward: 300,
        category: 'referral',
      },
      {
        id: 'referrer_silver',
        name: 'Ambassadeur Argent',
        description: 'Parrainez 10 utilisateurs',
        icon: 'gift-silver',
        xpReward: 1000,
        category: 'referral',
      },
      {
        id: 'referrer_gold',
        name: 'Ambassadeur Or',
        description: 'Parrainez 25 utilisateurs',
        icon: 'gift-gold',
        xpReward: 3000,
        category: 'referral',
      },
    ];
  }

  /**
   * Get user's earned badges
   */
  async getEarnedBadges(userId: string) {
    const achievements = await this.prisma.achievement.findMany({
      where: { userId },
      orderBy: { unlockedAt: 'desc' },
    });

    return achievements.map((a) => ({
      id: a.id,
      type: a.type,
      name: a.name,
      description: a.description,
      icon: a.iconUrl,
      xpReward: a.xpReward,
      unlockedAt: a.unlockedAt,
    }));
  }

  /**
   * Get active challenges - delegates to ChallengesService
   */
  async getActiveChallenges(userId: string) {
    return this.challengesService.getActiveChallenges(userId);
  }

  /**
   * Get challenge progress summary
   */
  async getChallengeProgress(userId: string) {
    return this.challengesService.getChallengeProgress(userId);
  }

  /**
   * Claim challenge reward - delegates to ChallengesService
   */
  async claimChallengeReward(userId: string, challengeId: string) {
    return this.challengesService.claimReward(userId, challengeId);
  }

  /**
   * Get user streak - delegates to StreaksService
   */
  async getStreak(userId: string) {
    return this.streaksService.getStreak(userId);
  }

  /**
   * Get available rewards
   */
  async getRewards(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { xp: true },
    });

    const userXp = user?.xp || 0;

    return [
      {
        id: 'reward_1',
        name: 'Analyse gratuite',
        description: 'Obtenez une analyse vidéo gratuite',
        cost: 500,
        available: userXp >= 500,
        type: 'token',
        tokenValue: 1,
      },
      {
        id: 'reward_2',
        name: 'Badge exclusif',
        description: 'Débloquez un badge exclusif',
        cost: 1000,
        available: userXp >= 1000,
        type: 'badge',
      },
      {
        id: 'reward_3',
        name: 'Pack 3 analyses',
        description: 'Obtenez 3 analyses vidéo gratuites',
        cost: 1500,
        available: userXp >= 1500,
        type: 'token',
        tokenValue: 3,
      },
      {
        id: 'reward_4',
        name: 'Profil mis en avant',
        description: 'Votre profil sera mis en avant pendant 7 jours',
        cost: 2000,
        available: userXp >= 2000,
        type: 'feature',
        duration: 7,
      },
      {
        id: 'reward_5',
        name: 'Pack 5 analyses',
        description: 'Obtenez 5 analyses vidéo gratuites',
        cost: 3000,
        available: userXp >= 3000,
        type: 'token',
        tokenValue: 5,
      },
    ];
  }

  /**
   * Get referral statistics - delegates to ReferralsService
   */
  async getReferralStats(userId: string) {
    return this.referralsService.getReferralStats(userId);
  }

  /**
   * Get referral code - delegates to ReferralsService
   */
  async getReferralCode(userId: string) {
    return this.referralsService.getReferralCode(userId);
  }

  /**
   * Get referral list - delegates to ReferralsService
   */
  async getReferrals(userId: string) {
    return this.referralsService.getReferrals(userId);
  }

  /**
   * Send referral invitation - delegates to ReferralsService
   */
  async sendReferralInvite(userId: string, email: string, message?: string) {
    return this.referralsService.sendInvitation(userId, email, message);
  }

  /**
   * Get XP leaderboard
   */
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
        userStreak: {
          select: { currentStreak: true },
        },
      },
    });

    return users.map((user, index) => ({
      rank: index + 1,
      id: user.id,
      name: `${user.firstName} ${user.lastName}`,
      avatarUrl: user.avatarUrl,
      xp: user.xp,
      level: user.level,
      currentStreak: user.userStreak?.currentStreak || 0,
    }));
  }

  /**
   * Claim daily login XP
   */
  async claimDailyLogin(userId: string) {
    const xpReward = XP_REWARDS.daily_login;

    // Record activity for streak
    const streakResult = await this.streaksService.recordActivity(userId);

    // Award XP
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: {
          xp: { increment: xpReward },
          lastLoginAt: new Date(),
        },
      }),
      this.prisma.xpTransaction.create({
        data: {
          userId,
          amount: xpReward,
          source: 'daily_login',
          description: 'Connexion quotidienne',
        },
      }),
    ]);

    // Update challenge progress for login action
    await this.challengesService.updateProgress(userId, 'login');

    return {
      success: true,
      xpEarned: xpReward,
      streakUpdated: streakResult.streakUpdated,
      currentStreak: streakResult.currentStreak,
      streakBonus: streakResult.bonusAwarded,
      isNewRecord: streakResult.isNewRecord,
      message: streakResult.bonusAwarded
        ? `Connexion quotidienne récompensée ! +${streakResult.bonusAwarded.xp} XP bonus pour ${streakResult.bonusAwarded.name} !`
        : 'Connexion quotidienne récompensée !',
    };
  }

  /**
   * Record action and award XP
   */
  async recordAction(
    userId: string,
    action: keyof typeof XP_REWARDS,
    metadata?: Record<string, any>,
  ) {
    const xpReward = XP_REWARDS[action];

    if (!xpReward) {
      return { success: false, message: 'Action inconnue' };
    }

    // Record activity for streak
    await this.streaksService.recordActivity(userId);

    // Award XP
    const result = await this.awardXp(
      userId,
      xpReward,
      action,
      this.getActionDescription(action, metadata),
    );

    return {
      success: true,
      xpEarned: xpReward,
      totalXp: result.totalXp,
      levelUp: result.levelUp,
    };
  }

  /**
   * Get action description for XP transaction
   */
  private getActionDescription(
    action: string,
    metadata?: Record<string, any>,
  ): string {
    const descriptions: Record<string, string> = {
      daily_login: 'Connexion quotidienne',
      publish_post: 'Publication d\'un post',
      comment: 'Commentaire',
      like: 'Like',
      add_horse: 'Ajout d\'un cheval',
      analyze_horse: 'Analyse d\'un cheval',
      complete_profile: 'Profil complété',
      first_follow: 'Premier abonnement',
    };

    return descriptions[action] || action;
  }

  /**
   * Complete and claim a challenge reward
   * @deprecated Use claimChallengeReward instead
   */
  async completeChallenge(userId: string, challengeId: string) {
    return this.claimChallengeReward(userId, challengeId);
  }

  /**
   * Claim a reward
   */
  async claimReward(userId: string, rewardId: string) {
    const rewards = await this.getRewards(userId);
    const reward = rewards.find((r) => r.id === rewardId);

    if (!reward) {
      return { success: false, message: 'Récompense non trouvée' };
    }

    if (!reward.available) {
      return { success: false, message: 'XP insuffisant pour cette récompense' };
    }

    // Deduct XP and apply reward
    await this.prisma.$transaction(async (tx) => {
      // Deduct XP
      await tx.user.update({
        where: { id: userId },
        data: { xp: { decrement: reward.cost } },
      });

      await tx.xpTransaction.create({
        data: {
          userId,
          amount: -reward.cost,
          source: 'reward_claim',
          description: `Échange contre: ${reward.name}`,
        },
      });

      // Apply reward based on type
      if (reward.type === 'token' && 'tokenValue' in reward) {
        const user = await tx.user.findUnique({
          where: { id: userId },
          select: { organizationId: true },
        });

        if (user) {
          await tx.organization.update({
            where: { id: user.organizationId },
            data: { tokenBalance: { increment: reward.tokenValue } },
          });

          await tx.tokenTransaction.create({
            data: {
              organizationId: user.organizationId,
              amount: reward.tokenValue,
              type: 'credit',
              description: `Récompense XP: ${reward.name}`,
            },
          });
        }
      }
    });

    return {
      success: true,
      message: `Récompense réclamée : ${reward.name}`,
      xpDeducted: reward.cost,
    };
  }
}
