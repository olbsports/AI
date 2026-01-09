import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Cron, CronExpression } from '@nestjs/schedule';

interface ChallengeTemplate {
  title: string;
  description: string;
  conditionAction: string;
  conditionCount: number;
  xpReward: number;
  tokenReward: number;
}

const DAILY_CHALLENGES: ChallengeTemplate[] = [
  {
    title: 'Connexion quotidienne',
    description: 'Connectez-vous à l\'application',
    conditionAction: 'login',
    conditionCount: 1,
    xpReward: 10,
    tokenReward: 0,
  },
  {
    title: 'Première analyse',
    description: 'Effectuez une analyse vidéo',
    conditionAction: 'analyze_horse',
    conditionCount: 1,
    xpReward: 25,
    tokenReward: 0,
  },
  {
    title: 'Partagez votre passion',
    description: 'Publiez un post sur le réseau social',
    conditionAction: 'publish_post',
    conditionCount: 1,
    xpReward: 15,
    tokenReward: 0,
  },
  {
    title: 'Explorateur',
    description: 'Consultez 3 profils de chevaux',
    conditionAction: 'view_horse',
    conditionCount: 3,
    xpReward: 10,
    tokenReward: 0,
  },
];

const WEEKLY_CHALLENGES: ChallengeTemplate[] = [
  {
    title: 'Analyste de la semaine',
    description: 'Effectuez 5 analyses cette semaine',
    conditionAction: 'analyze_horse',
    conditionCount: 5,
    xpReward: 150,
    tokenReward: 1,
  },
  {
    title: 'Réseau actif',
    description: 'Publiez 3 posts cette semaine',
    conditionAction: 'publish_post',
    conditionCount: 3,
    xpReward: 75,
    tokenReward: 0,
  },
  {
    title: 'Engagement social',
    description: 'Commentez 10 publications',
    conditionAction: 'comment',
    conditionCount: 10,
    xpReward: 50,
    tokenReward: 0,
  },
  {
    title: 'Fidèle',
    description: 'Connectez-vous 5 jours cette semaine',
    conditionAction: 'login',
    conditionCount: 5,
    xpReward: 100,
    tokenReward: 0,
  },
  {
    title: 'Découvreur',
    description: 'Ajoutez un nouveau cheval',
    conditionAction: 'add_horse',
    conditionCount: 1,
    xpReward: 50,
    tokenReward: 0,
  },
];

const MONTHLY_CHALLENGES: ChallengeTemplate[] = [
  {
    title: 'Expert du mois',
    description: 'Effectuez 20 analyses ce mois',
    conditionAction: 'analyze_horse',
    conditionCount: 20,
    xpReward: 500,
    tokenReward: 5,
  },
  {
    title: 'Influenceur équestre',
    description: 'Obtenez 50 likes sur vos publications',
    conditionAction: 'receive_like',
    conditionCount: 50,
    xpReward: 300,
    tokenReward: 2,
  },
  {
    title: 'Communauté grandissante',
    description: 'Gagnez 10 nouveaux abonnés',
    conditionAction: 'gain_follower',
    conditionCount: 10,
    xpReward: 250,
    tokenReward: 2,
  },
  {
    title: 'Utilisateur assidu',
    description: 'Connectez-vous 20 jours ce mois',
    conditionAction: 'login',
    conditionCount: 20,
    xpReward: 400,
    tokenReward: 3,
  },
  {
    title: 'Écurie complète',
    description: 'Ajoutez 3 chevaux ce mois',
    conditionAction: 'add_horse',
    conditionCount: 3,
    xpReward: 200,
    tokenReward: 1,
  },
];

@Injectable()
export class ChallengesService {
  constructor(private prisma: PrismaService) {}

  /**
   * Generate daily challenges - runs every day at midnight
   */
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async generateDailyChallenges() {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(23, 59, 59, 999);

    // Deactivate old daily challenges
    await this.prisma.challenge.updateMany({
      where: {
        type: 'daily',
        expiresAt: { lt: now },
      },
      data: { isActive: false },
    });

    // Select 2 random daily challenges
    const selectedTemplates = this.getRandomChallenges(DAILY_CHALLENGES, 2);

    for (const template of selectedTemplates) {
      await this.prisma.challenge.create({
        data: {
          ...template,
          type: 'daily',
          startsAt: now,
          expiresAt: tomorrow,
          isActive: true,
        },
      });
    }
  }

  /**
   * Generate weekly challenges - runs every Monday at midnight
   */
  @Cron('0 0 * * 1')
  async generateWeeklyChallenges() {
    const now = new Date();
    const nextWeek = new Date(now);
    nextWeek.setDate(nextWeek.getDate() + 7);
    nextWeek.setHours(23, 59, 59, 999);

    // Deactivate old weekly challenges
    await this.prisma.challenge.updateMany({
      where: {
        type: 'weekly',
        expiresAt: { lt: now },
      },
      data: { isActive: false },
    });

    // Select 3 random weekly challenges
    const selectedTemplates = this.getRandomChallenges(WEEKLY_CHALLENGES, 3);

    for (const template of selectedTemplates) {
      await this.prisma.challenge.create({
        data: {
          ...template,
          type: 'weekly',
          startsAt: now,
          expiresAt: nextWeek,
          isActive: true,
        },
      });
    }
  }

  /**
   * Generate monthly challenges - runs on the 1st of each month at midnight
   */
  @Cron('0 0 1 * *')
  async generateMonthlyChallenges() {
    const now = new Date();
    const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    nextMonth.setHours(23, 59, 59, 999);

    // Deactivate old monthly challenges
    await this.prisma.challenge.updateMany({
      where: {
        type: 'monthly',
        expiresAt: { lt: now },
      },
      data: { isActive: false },
    });

    // Select 3 random monthly challenges
    const selectedTemplates = this.getRandomChallenges(MONTHLY_CHALLENGES, 3);

    for (const template of selectedTemplates) {
      await this.prisma.challenge.create({
        data: {
          ...template,
          type: 'monthly',
          startsAt: now,
          expiresAt: nextMonth,
          isActive: true,
        },
      });
    }
  }

  /**
   * Get all active challenges for a user with their progress
   */
  async getActiveChallenges(userId: string) {
    const now = new Date();

    const challenges = await this.prisma.challenge.findMany({
      where: {
        isActive: true,
        startsAt: { lte: now },
        expiresAt: { gte: now },
      },
      include: {
        userChallenges: {
          where: { userId },
        },
      },
      orderBy: [{ type: 'asc' }, { xpReward: 'desc' }],
    });

    return challenges.map((challenge) => {
      const userChallenge = challenge.userChallenges[0];
      return {
        id: challenge.id,
        title: challenge.title,
        description: challenge.description,
        type: challenge.type,
        conditionAction: challenge.conditionAction,
        conditionCount: challenge.conditionCount,
        xpReward: challenge.xpReward,
        tokenReward: challenge.tokenReward,
        expiresAt: challenge.expiresAt,
        progress: userChallenge?.progress || 0,
        isCompleted: userChallenge?.completedAt != null,
        isClaimed: userChallenge?.claimedAt != null,
        completedAt: userChallenge?.completedAt,
      };
    });
  }

  /**
   * Get user's challenge progress summary
   */
  async getChallengeProgress(userId: string) {
    const [completed, claimed, active] = await Promise.all([
      this.prisma.userChallenge.count({
        where: { userId, completedAt: { not: null } },
      }),
      this.prisma.userChallenge.count({
        where: { userId, claimedAt: { not: null } },
      }),
      this.prisma.challenge.count({
        where: {
          isActive: true,
          startsAt: { lte: new Date() },
          expiresAt: { gte: new Date() },
        },
      }),
    ]);

    const totalXpEarned = await this.prisma.userChallenge.aggregate({
      where: { userId, claimedAt: { not: null } },
      _sum: { progress: true },
    });

    return {
      activeChallenges: active,
      completedChallenges: completed,
      claimedRewards: claimed,
      totalXpFromChallenges: totalXpEarned._sum.progress || 0,
    };
  }

  /**
   * Update challenge progress for a user action
   */
  async updateProgress(userId: string, action: string, increment: number = 1) {
    const now = new Date();

    // Find active challenges matching this action
    const challenges = await this.prisma.challenge.findMany({
      where: {
        isActive: true,
        conditionAction: action,
        startsAt: { lte: now },
        expiresAt: { gte: now },
      },
    });

    const results = [];

    for (const challenge of challenges) {
      // Get or create user challenge
      let userChallenge = await this.prisma.userChallenge.findUnique({
        where: {
          userId_challengeId: {
            userId,
            challengeId: challenge.id,
          },
        },
      });

      if (!userChallenge) {
        userChallenge = await this.prisma.userChallenge.create({
          data: {
            userId,
            challengeId: challenge.id,
            progress: 0,
          },
        });
      }

      // Skip if already completed
      if (userChallenge.completedAt) {
        continue;
      }

      const newProgress = Math.min(
        userChallenge.progress + increment,
        challenge.conditionCount,
      );
      const isCompleted = newProgress >= challenge.conditionCount;

      const updated = await this.prisma.userChallenge.update({
        where: { id: userChallenge.id },
        data: {
          progress: newProgress,
          completedAt: isCompleted ? now : null,
        },
        include: { challenge: true },
      });

      results.push({
        challengeId: challenge.id,
        title: challenge.title,
        progress: newProgress,
        target: challenge.conditionCount,
        isCompleted,
        xpReward: isCompleted ? challenge.xpReward : 0,
        tokenReward: isCompleted ? challenge.tokenReward : 0,
      });
    }

    return results;
  }

  /**
   * Claim reward for a completed challenge
   */
  async claimReward(userId: string, challengeId: string) {
    const userChallenge = await this.prisma.userChallenge.findUnique({
      where: {
        userId_challengeId: {
          userId,
          challengeId,
        },
      },
      include: { challenge: true },
    });

    if (!userChallenge) {
      throw new NotFoundException('Défi non trouvé');
    }

    if (!userChallenge.completedAt) {
      throw new BadRequestException('Ce défi n\'est pas encore complété');
    }

    if (userChallenge.claimedAt) {
      throw new BadRequestException('La récompense a déjà été réclamée');
    }

    const { challenge } = userChallenge;

    // Update user XP and tokens in a transaction
    const [updatedUserChallenge] = await this.prisma.$transaction([
      this.prisma.userChallenge.update({
        where: { id: userChallenge.id },
        data: { claimedAt: new Date() },
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: {
          xp: { increment: challenge.xpReward },
        },
      }),
      this.prisma.xpTransaction.create({
        data: {
          userId,
          amount: challenge.xpReward,
          source: 'challenge',
          description: `Défi complété: ${challenge.title}`,
        },
      }),
    ]);

    // If there's a token reward, update organization balance
    if (challenge.tokenReward > 0) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { organizationId: true },
      });

      if (user) {
        await this.prisma.organization.update({
          where: { id: user.organizationId },
          data: {
            tokenBalance: { increment: challenge.tokenReward },
          },
        });

        await this.prisma.tokenTransaction.create({
          data: {
            organizationId: user.organizationId,
            amount: challenge.tokenReward,
            type: 'credit',
            description: `Récompense défi: ${challenge.title}`,
          },
        });
      }
    }

    return {
      success: true,
      xpAwarded: challenge.xpReward,
      tokensAwarded: challenge.tokenReward,
      message: `Félicitations ! Vous avez gagné ${challenge.xpReward} XP${challenge.tokenReward > 0 ? ` et ${challenge.tokenReward} token(s)` : ''} !`,
    };
  }

  /**
   * Initialize challenges if none exist (for fresh installs)
   */
  async initializeChallenges() {
    const existingCount = await this.prisma.challenge.count({
      where: { isActive: true },
    });

    if (existingCount === 0) {
      await this.generateDailyChallenges();
      await this.generateWeeklyChallenges();
      await this.generateMonthlyChallenges();
    }
  }

  private getRandomChallenges(
    templates: ChallengeTemplate[],
    count: number,
  ): ChallengeTemplate[] {
    const shuffled = [...templates].sort(() => Math.random() - 0.5);
    return shuffled.slice(0, Math.min(count, shuffled.length));
  }
}
