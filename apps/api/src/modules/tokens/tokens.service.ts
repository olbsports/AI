import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../../prisma/prisma.service';
import {
  DebitTokensDto,
  TransferTokensDto,
  TokenTransactionQueryDto,
  TransactionType,
} from './dto/token.dto';

export interface TokenBalance {
  balance: number;
  reservedTokens: number;
  availableTokens: number;
  monthlyAllocation: number;
  usedThisMonth: number;
}

export interface TokenTransaction {
  id: string;
  type: string;
  amount: number;
  description: string;
  createdAt: Date;
  metadata: any;
}

@Injectable()
export class TokensService {
  private readonly logger = new Logger(TokensService.name);

  // Token costs per operation
  private readonly tokenCosts = {
    basicAnalysis: 1,
    advancedAnalysis: 3,
    videoAnalysis: 5,
    reportGeneration: 2,
    aiRecommendation: 1,
  };

  constructor(private readonly prisma: PrismaService) {}

  async getBalance(organizationId: string): Promise<TokenBalance> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const settings = organization.settings as any;

    // Calculate usage this month
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const monthlyUsage = await this.prisma.tokenTransaction.aggregate({
      where: {
        organizationId,
        type: 'debit',
        createdAt: { gte: startOfMonth },
      },
      _sum: { amount: true },
    });

    // Calculate reserved tokens (for pending analyses)
    const reservedTokens = await this.getReservedTokens(organizationId);

    return {
      balance: organization.tokenBalance || 0,
      reservedTokens,
      availableTokens: Math.max(0, (organization.tokenBalance || 0) - reservedTokens),
      monthlyAllocation: settings?.tokensPerMonth || 0,
      usedThisMonth: Math.abs(monthlyUsage._sum.amount || 0),
    };
  }

  async getTransactions(
    organizationId: string,
    query: TokenTransactionQueryDto,
  ): Promise<{ transactions: TokenTransaction[]; total: number; page: number; limit: number }> {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = { organizationId };

    if (query.type) {
      where.type = query.type;
    }

    const [transactions, total] = await Promise.all([
      this.prisma.tokenTransaction.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.tokenTransaction.count({ where }),
    ]);

    return {
      transactions: transactions.map((t) => ({
        id: t.id,
        type: t.type,
        amount: t.amount,
        description: t.description,
        createdAt: t.createdAt,
        metadata: t.metadata,
      })),
      total,
      page,
      limit,
    };
  }

  async debitTokens(
    organizationId: string,
    dto: DebitTokensDto,
  ): Promise<{ success: boolean; newBalance: number }> {
    const balance = await this.getBalance(organizationId);

    if (balance.availableTokens < dto.amount) {
      throw new BadRequestException(
        `Insufficient tokens. Available: ${balance.availableTokens}, Required: ${dto.amount}`,
      );
    }

    const result = await this.prisma.$transaction(async (tx) => {
      const org = await tx.organization.update({
        where: { id: organizationId },
        data: {
          tokenBalance: { decrement: dto.amount },
        },
      });

      await tx.tokenTransaction.create({
        data: {
          organizationId,
          amount: -dto.amount,
          type: 'debit',
          description: dto.reason,
          metadata: {
            analysisId: dto.analysisId,
          },
        },
      });

      return org;
    });

    this.logger.log(`Debited ${dto.amount} tokens from org ${organizationId}`);

    return {
      success: true,
      newBalance: result.tokenBalance || 0,
    };
  }

  async creditTokens(
    organizationId: string,
    amount: number,
    description: string,
    metadata?: Record<string, any>,
  ): Promise<{ success: boolean; newBalance: number }> {
    const result = await this.prisma.$transaction(async (tx) => {
      const org = await tx.organization.update({
        where: { id: organizationId },
        data: {
          tokenBalance: { increment: amount },
        },
      });

      await tx.tokenTransaction.create({
        data: {
          organizationId,
          amount,
          type: 'credit',
          description,
          metadata: metadata || {},
        },
      });

      return org;
    });

    this.logger.log(`Credited ${amount} tokens to org ${organizationId}`);

    return {
      success: true,
      newBalance: result.tokenBalance || 0,
    };
  }

  async transferTokens(
    sourceOrganizationId: string,
    dto: TransferTokensDto,
  ): Promise<{ success: boolean; sourceBalance: number; targetBalance: number }> {
    // Check source balance
    const sourceBalance = await this.getBalance(sourceOrganizationId);

    if (sourceBalance.availableTokens < dto.amount) {
      throw new BadRequestException('Insufficient tokens for transfer');
    }

    // Check target exists
    const targetOrg = await this.prisma.organization.findUnique({
      where: { id: dto.targetOrganizationId },
    });

    if (!targetOrg) {
      throw new NotFoundException('Target organization not found');
    }

    const result = await this.prisma.$transaction(async (tx) => {
      // Debit source
      const source = await tx.organization.update({
        where: { id: sourceOrganizationId },
        data: {
          tokenBalance: { decrement: dto.amount },
        },
      });

      // Credit target
      const target = await tx.organization.update({
        where: { id: dto.targetOrganizationId },
        data: {
          tokenBalance: { increment: dto.amount },
        },
      });

      // Record transactions
      await tx.tokenTransaction.createMany({
        data: [
          {
            organizationId: sourceOrganizationId,
            amount: -dto.amount,
            type: 'transfer_out',
            description: `Transfert vers ${targetOrg.name}`,
            metadata: {
              targetOrganizationId: dto.targetOrganizationId,
              note: dto.note,
            },
          },
          {
            organizationId: dto.targetOrganizationId,
            amount: dto.amount,
            type: 'transfer_in',
            description: `Transfert depuis une organisation partenaire`,
            metadata: {
              sourceOrganizationId,
              note: dto.note,
            },
          },
        ],
      });

      return { source, target };
    });

    this.logger.log(
      `Transferred ${dto.amount} tokens from ${sourceOrganizationId} to ${dto.targetOrganizationId}`,
    );

    return {
      success: true,
      sourceBalance: result.source.tokenBalance || 0,
      targetBalance: result.target.tokenBalance || 0,
    };
  }

  async reserveTokens(
    organizationId: string,
    amount: number,
    analysisId: string,
  ): Promise<boolean> {
    const balance = await this.getBalance(organizationId);

    if (balance.availableTokens < amount) {
      return false;
    }

    // Create reservation record
    await this.prisma.tokenReservation.create({
      data: {
        organizationId,
        analysisId,
        amount,
        expiresAt: new Date(Date.now() + 30 * 60 * 1000), // 30 minutes
      },
    });

    return true;
  }

  async releaseReservation(analysisId: string): Promise<void> {
    await this.prisma.tokenReservation.deleteMany({
      where: { analysisId },
    });
  }

  async consumeReservation(analysisId: string): Promise<void> {
    const reservation = await this.prisma.tokenReservation.findFirst({
      where: { analysisId },
    });

    if (!reservation) {
      this.logger.warn(`No reservation found for analysis ${analysisId}`);
      return;
    }

    await this.debitTokens(reservation.organizationId, {
      amount: reservation.amount,
      reason: 'Analyse complétée',
      analysisId,
    });

    await this.releaseReservation(analysisId);
  }

  async getUsageStats(organizationId: string): Promise<{
    daily: { date: string; usage: number }[];
    byType: { type: string; count: number; tokens: number }[];
    trend: number;
  }> {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const transactions = await this.prisma.tokenTransaction.findMany({
      where: {
        organizationId,
        type: 'debit',
        createdAt: { gte: thirtyDaysAgo },
      },
      orderBy: { createdAt: 'asc' },
    });

    // Group by day
    const dailyMap = new Map<string, number>();
    transactions.forEach((t) => {
      const date = t.createdAt.toISOString().split('T')[0];
      dailyMap.set(date, (dailyMap.get(date) || 0) + Math.abs(t.amount));
    });

    const daily = Array.from(dailyMap.entries()).map(([date, usage]) => ({
      date,
      usage,
    }));

    // Group by type (from metadata)
    const typeMap = new Map<string, { count: number; tokens: number }>();
    transactions.forEach((t) => {
      const type = (t.metadata as any)?.type || 'other';
      const current = typeMap.get(type) || { count: 0, tokens: 0 };
      typeMap.set(type, {
        count: current.count + 1,
        tokens: current.tokens + Math.abs(t.amount),
      });
    });

    const byType = Array.from(typeMap.entries()).map(([type, data]) => ({
      type,
      ...data,
    }));

    // Calculate trend (comparing last 15 days to previous 15 days)
    const midpoint = new Date();
    midpoint.setDate(midpoint.getDate() - 15);

    const recentUsage = transactions
      .filter((t) => t.createdAt >= midpoint)
      .reduce((sum, t) => sum + Math.abs(t.amount), 0);

    const previousUsage = transactions
      .filter((t) => t.createdAt < midpoint)
      .reduce((sum, t) => sum + Math.abs(t.amount), 0);

    const trend = previousUsage > 0 ? ((recentUsage - previousUsage) / previousUsage) * 100 : 0;

    return { daily, byType, trend: Math.round(trend) };
  }

  getTokenCosts(): Record<string, number> {
    return this.tokenCosts;
  }

  private async getReservedTokens(organizationId: string): Promise<number> {
    const reservations = await this.prisma.tokenReservation.aggregate({
      where: {
        organizationId,
        expiresAt: { gt: new Date() },
      },
      _sum: { amount: true },
    });

    return reservations._sum.amount || 0;
  }
}
