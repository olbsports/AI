import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

// Referral rewards configuration
const REFERRAL_REWARDS = {
  referrer: {
    xp: 500,
    tokens: 5,
  },
  referee: {
    xp: 250,
    tokens: 2,
  },
};

@Injectable()
export class ReferralsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Generate a unique referral code for a user (HORSE-XXXXXX format)
   */
  async generateReferralCode(userId: string): Promise<string> {
    // Check if user already has a referral code
    const existingReferral = await this.prisma.referral.findFirst({
      where: {
        referrerId: userId,
        refereeId: null, // A placeholder referral without a referee
      },
    });

    if (existingReferral) {
      return existingReferral.code;
    }

    // Generate unique code
    const code = await this.createUniqueCode();

    // Create placeholder referral record
    await this.prisma.referral.create({
      data: {
        code,
        referrerId: userId,
        status: 'pending',
      },
    });

    return code;
  }

  /**
   * Get user's referral code and share URL
   */
  async getReferralCode(userId: string) {
    const code = await this.generateReferralCode(userId);

    return {
      code,
      shareUrl: `https://horsetempo.app/invite/${code}`,
      shareMessage: `Rejoignez-moi sur HorseTempo ! Utilisez mon code de parrainage ${code} pour obtenir ${REFERRAL_REWARDS.referee.xp} XP et ${REFERRAL_REWARDS.referee.tokens} tokens gratuits. https://horsetempo.app/invite/${code}`,
    };
  }

  /**
   * Get referral statistics for a user
   */
  async getReferralStats(userId: string) {
    const [completedReferrals, pendingReferrals, totalXp, totalTokens] =
      await Promise.all([
        this.prisma.referral.count({
          where: {
            referrerId: userId,
            status: 'completed',
          },
        }),
        this.prisma.referral.count({
          where: {
            referrerId: userId,
            status: 'pending',
            invitedEmail: { not: null },
          },
        }),
        this.prisma.referral.aggregate({
          where: {
            referrerId: userId,
            status: 'completed',
          },
          _sum: { xpAwarded: true },
        }),
        this.prisma.referral.aggregate({
          where: {
            referrerId: userId,
            status: 'completed',
          },
          _sum: { tokensAwarded: true },
        }),
      ]);

    const referralCode = await this.generateReferralCode(userId);

    return {
      referralCode,
      completedReferrals,
      pendingReferrals,
      totalXpEarned: totalXp._sum.xpAwarded || 0,
      totalTokensEarned: totalTokens._sum.tokensAwarded || 0,
      rewardPerReferral: REFERRAL_REWARDS.referrer,
      shareUrl: `https://horsetempo.app/invite/${referralCode}`,
    };
  }

  /**
   * Get list of referrals made by a user
   */
  async getReferrals(userId: string) {
    const referrals = await this.prisma.referral.findMany({
      where: {
        referrerId: userId,
        OR: [{ refereeId: { not: null } }, { invitedEmail: { not: null } }],
      },
      include: {
        referee: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
            createdAt: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return referrals.map((r) => ({
      id: r.id,
      code: r.code,
      status: r.status,
      invitedEmail: r.invitedEmail,
      referee: r.referee
        ? {
            id: r.referee.id,
            name: `${r.referee.firstName} ${r.referee.lastName}`,
            avatarUrl: r.referee.avatarUrl,
            joinedAt: r.referee.createdAt,
          }
        : null,
      xpAwarded: r.xpAwarded,
      tokensAwarded: r.tokensAwarded,
      createdAt: r.createdAt,
      completedAt: r.completedAt,
    }));
  }

  /**
   * Send a referral invitation by email
   */
  async sendInvitation(
    userId: string,
    email: string,
    message?: string,
  ): Promise<{ success: boolean; code: string; message: string }> {
    // Check if email is already registered
    const existingUser = await this.prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      throw new BadRequestException('Cet email est déjà inscrit sur HorseTempo');
    }

    // Check if invitation already sent
    const existingInvite = await this.prisma.referral.findFirst({
      where: {
        referrerId: userId,
        invitedEmail: email,
        status: 'pending',
      },
    });

    if (existingInvite) {
      return {
        success: true,
        code: existingInvite.code,
        message: 'Une invitation a déjà été envoyée à cet email',
      };
    }

    // Get or create referral code
    const code = await this.generateReferralCode(userId);

    // Create invitation referral
    await this.prisma.referral.create({
      data: {
        code: await this.createUniqueCode(), // New code for this specific invitation
        referrerId: userId,
        invitedEmail: email,
        status: 'pending',
      },
    });

    // TODO: Send email invitation using email service
    // For now, we just return success
    // await this.emailService.sendReferralInvitation(email, code, message);

    return {
      success: true,
      code,
      message: `Invitation envoyée à ${email}`,
    };
  }

  /**
   * Apply a referral code when a new user signs up
   */
  async applyReferralCode(refereeId: string, code: string) {
    // Find the referral by code
    const referral = await this.prisma.referral.findFirst({
      where: {
        code: code.toUpperCase(),
        status: 'pending',
      },
      include: {
        referrer: true,
      },
    });

    if (!referral) {
      throw new NotFoundException('Code de parrainage invalide ou expiré');
    }

    // Can't refer yourself
    if (referral.referrerId === refereeId) {
      throw new BadRequestException(
        'Vous ne pouvez pas utiliser votre propre code de parrainage',
      );
    }

    // Check if user already used a referral code
    const alreadyReferred = await this.prisma.referral.findFirst({
      where: {
        refereeId,
        status: 'completed',
      },
    });

    if (alreadyReferred) {
      throw new BadRequestException(
        'Vous avez déjà utilisé un code de parrainage',
      );
    }

    const now = new Date();

    // Complete the referral in a transaction
    await this.prisma.$transaction(async (tx) => {
      // Update the referral
      await tx.referral.update({
        where: { id: referral.id },
        data: {
          refereeId,
          status: 'completed',
          xpAwarded: REFERRAL_REWARDS.referrer.xp,
          tokensAwarded: REFERRAL_REWARDS.referrer.tokens,
          completedAt: now,
        },
      });

      // Award XP to referrer
      await tx.user.update({
        where: { id: referral.referrerId },
        data: { xp: { increment: REFERRAL_REWARDS.referrer.xp } },
      });

      await tx.xpTransaction.create({
        data: {
          userId: referral.referrerId,
          amount: REFERRAL_REWARDS.referrer.xp,
          source: 'referral',
          description: `Bonus parrainage - filleul inscrit`,
        },
      });

      // Award XP to referee
      await tx.user.update({
        where: { id: refereeId },
        data: { xp: { increment: REFERRAL_REWARDS.referee.xp } },
      });

      await tx.xpTransaction.create({
        data: {
          userId: refereeId,
          amount: REFERRAL_REWARDS.referee.xp,
          source: 'referral',
          description: `Bonus inscription avec parrainage`,
        },
      });

      // Award tokens to referrer's organization
      const referrer = await tx.user.findUnique({
        where: { id: referral.referrerId },
        select: { organizationId: true },
      });

      if (referrer) {
        await tx.organization.update({
          where: { id: referrer.organizationId },
          data: {
            tokenBalance: { increment: REFERRAL_REWARDS.referrer.tokens },
          },
        });

        await tx.tokenTransaction.create({
          data: {
            organizationId: referrer.organizationId,
            amount: REFERRAL_REWARDS.referrer.tokens,
            type: 'credit',
            description: `Bonus parrainage - filleul inscrit`,
          },
        });
      }

      // Award tokens to referee's organization
      const referee = await tx.user.findUnique({
        where: { id: refereeId },
        select: { organizationId: true },
      });

      if (referee) {
        await tx.organization.update({
          where: { id: referee.organizationId },
          data: {
            tokenBalance: { increment: REFERRAL_REWARDS.referee.tokens },
          },
        });

        await tx.tokenTransaction.create({
          data: {
            organizationId: referee.organizationId,
            amount: REFERRAL_REWARDS.referee.tokens,
            type: 'credit',
            description: `Bonus inscription avec parrainage`,
          },
        });
      }
    });

    return {
      success: true,
      referrerReward: REFERRAL_REWARDS.referrer,
      refereeReward: REFERRAL_REWARDS.referee,
      message: `Parrainage validé ! Vous avez reçu ${REFERRAL_REWARDS.referee.xp} XP et ${REFERRAL_REWARDS.referee.tokens} tokens.`,
    };
  }

  /**
   * Validate a referral code without applying it
   */
  async validateCode(code: string) {
    const referral = await this.prisma.referral.findFirst({
      where: {
        code: code.toUpperCase(),
        status: 'pending',
      },
      include: {
        referrer: {
          select: {
            firstName: true,
            lastName: true,
          },
        },
      },
    });

    if (!referral) {
      return {
        valid: false,
        message: 'Code de parrainage invalide ou expiré',
      };
    }

    return {
      valid: true,
      referrerName: `${referral.referrer.firstName} ${referral.referrer.lastName.charAt(0)}.`,
      reward: REFERRAL_REWARDS.referee,
      message: `Code valide ! Vous recevrez ${REFERRAL_REWARDS.referee.xp} XP et ${REFERRAL_REWARDS.referee.tokens} tokens.`,
    };
  }

  /**
   * Create a unique referral code (HORSE-XXXXXX format)
   */
  private async createUniqueCode(): Promise<string> {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code: string;
    let exists = true;

    while (exists) {
      const randomPart = Array.from({ length: 6 }, () =>
        characters.charAt(Math.floor(Math.random() * characters.length)),
      ).join('');

      code = `HORSE-${randomPart}`;

      const existing = await this.prisma.referral.findUnique({
        where: { code },
      });

      exists = !!existing;
    }

    return code!;
  }
}
