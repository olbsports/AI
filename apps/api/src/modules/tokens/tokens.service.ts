import { Injectable, Logger, BadRequestException, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../../prisma/prisma.service';
import {
  DebitTokensDto,
  TransferTokensDto,
  TokenTransactionQueryDto,
  TransactionType,
  PurchaseTokensDto,
  CheckTokensDto,
  TokenPackResponseDto,
  PurchaseHistoryQueryDto,
} from './dto/token.dto';
import Stripe from 'stripe';

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
  private stripe: Stripe | null = null;

  // Token costs per operation
  private readonly tokenCosts = {
    basicAnalysis: 1,
    advancedAnalysis: 3,
    videoAnalysis: 5,
    reportGeneration: 2,
    aiRecommendation: 1,
    radiologySimple: 150,
    radiologyComplete: 300,
    radiologyExpert: 500,
    equicoteStandard: 100,
    equicotePremium: 200,
    breedingRecommendation: 200,
    breedingMatch: 50,
  };

  constructor(private readonly prisma: PrismaService) {
    // Initialize Stripe if key is available
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    if (stripeKey) {
      this.stripe = new Stripe(stripeKey, {
        apiVersion: '2023-10-16',
      });
    } else {
      this.logger.warn('STRIPE_SECRET_KEY not set - token purchases disabled');
    }
  }

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
    query: TokenTransactionQueryDto
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
    dto: DebitTokensDto
  ): Promise<{ success: boolean; newBalance: number }> {
    const balance = await this.getBalance(organizationId);

    if (balance.availableTokens < dto.amount) {
      throw new BadRequestException(
        `Insufficient tokens. Available: ${balance.availableTokens}, Required: ${dto.amount}`
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
    metadata?: Record<string, any>
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
    dto: TransferTokensDto
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
      `Transferred ${dto.amount} tokens from ${sourceOrganizationId} to ${dto.targetOrganizationId}`
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
    analysisId: string
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

  // ==================== TOKEN PACKS & PURCHASE ====================

  async getTokenPacks(): Promise<TokenPackResponseDto[]> {
    const packs = await this.prisma.tokenPack.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
    });

    if (packs.length === 0) {
      // Return default packs if none exist in DB
      return this.getDefaultPacks();
    }

    // Calculate price per token and savings
    const basePricePerToken = packs[0].price / packs[0].totalTokens;

    return packs.map((pack) => {
      const pricePerToken = pack.price / pack.totalTokens;
      const savingsPercent = Math.round(
        ((basePricePerToken - pricePerToken) / basePricePerToken) * 100
      );

      return {
        id: pack.id,
        name: pack.name,
        description: pack.description,
        baseTokens: pack.baseTokens,
        bonusPercent: pack.bonusPercent,
        totalTokens: pack.totalTokens,
        price: pack.price,
        currency: pack.currency,
        pricePerToken: Math.round(pricePerToken * 100) / 100,
        isPopular: pack.isPopular,
        savingsPercent: Math.max(0, savingsPercent),
      };
    });
  }

  private getDefaultPacks(): TokenPackResponseDto[] {
    // Default packs as specified in specs
    const packs = [
      { id: 'starter', name: 'Starter', baseTokens: 100, bonusPercent: 0, price: 999 },
      {
        id: 'standard',
        name: 'Standard',
        baseTokens: 300,
        bonusPercent: 10,
        price: 2499,
        isPopular: true,
      },
      { id: 'pro', name: 'Pro', baseTokens: 600, bonusPercent: 20, price: 4499 },
      { id: 'business', name: 'Business', baseTokens: 1500, bonusPercent: 30, price: 9999 },
      { id: 'enterprise', name: 'Enterprise', baseTokens: 5000, bonusPercent: 40, price: 29999 },
    ];

    const basePricePerToken = packs[0].price / packs[0].baseTokens;

    return packs.map((pack) => {
      const totalTokens = Math.floor(pack.baseTokens * (1 + pack.bonusPercent / 100));
      const pricePerToken = pack.price / totalTokens;
      const savingsPercent = Math.round(
        ((basePricePerToken - pricePerToken) / basePricePerToken) * 100
      );

      return {
        id: pack.id,
        name: pack.name,
        description: `${pack.baseTokens} tokens${pack.bonusPercent > 0 ? ` +${pack.bonusPercent}% bonus` : ''}`,
        baseTokens: pack.baseTokens,
        bonusPercent: pack.bonusPercent,
        totalTokens,
        price: pack.price,
        currency: 'EUR',
        pricePerToken: Math.round(pricePerToken * 100) / 100,
        isPopular: pack.isPopular || false,
        savingsPercent: Math.max(0, savingsPercent),
      };
    });
  }

  async checkTokenAvailability(
    organizationId: string,
    dto: CheckTokensDto
  ): Promise<{
    available: boolean;
    currentBalance: number;
    required: number;
    shortfall: number;
    suggestedPack: TokenPackResponseDto | null;
  }> {
    const balance = await this.getBalance(organizationId);
    const required = dto.serviceType ? this.tokenCosts[dto.serviceType] || dto.amount : dto.amount;

    const available = balance.availableTokens >= required;
    const shortfall = Math.max(0, required - balance.availableTokens);

    // Suggest a pack if tokens are insufficient
    let suggestedPack: TokenPackResponseDto | null = null;
    if (!available) {
      const packs = await this.getTokenPacks();
      suggestedPack = packs.find((p) => p.totalTokens >= shortfall) || packs[packs.length - 1];
    }

    return {
      available,
      currentBalance: balance.availableTokens,
      required,
      shortfall,
      suggestedPack,
    };
  }

  async estimateCost(
    serviceType: string
  ): Promise<{ tokens: number; priceEstimate: number; currency: string }> {
    const tokens = this.tokenCosts[serviceType] || 0;
    const packs = await this.getTokenPacks();
    const avgPricePerToken =
      packs.length > 0 ? packs.reduce((sum, p) => sum + p.pricePerToken, 0) / packs.length : 0.1;

    return {
      tokens,
      priceEstimate: Math.round(tokens * avgPricePerToken * 100) / 100,
      currency: 'EUR',
    };
  }

  async createPurchaseSession(
    organizationId: string,
    userId: string,
    dto: PurchaseTokensDto
  ): Promise<{ sessionId: string; checkoutUrl: string }> {
    if (!this.stripe) {
      throw new BadRequestException('Payment system not configured');
    }

    // Get pack details
    let pack = await this.prisma.tokenPack.findUnique({
      where: { id: dto.packId },
    });

    // If no pack in DB, use defaults
    if (!pack) {
      const defaultPacks = this.getDefaultPacks();
      const defaultPack = defaultPacks.find((p) => p.id === dto.packId);
      if (!defaultPack) {
        throw new NotFoundException('Token pack not found');
      }
      // Create pack in DB for reference
      pack = await this.prisma.tokenPack.create({
        data: {
          id: dto.packId,
          name: defaultPack.name,
          description: defaultPack.description,
          baseTokens: defaultPack.baseTokens,
          bonusPercent: defaultPack.bonusPercent,
          totalTokens: defaultPack.totalTokens,
          price: defaultPack.price,
          currency: 'EUR',
          isPopular: defaultPack.isPopular,
        },
      });
    }

    const quantity = dto.quantity || 1;
    const totalAmount = pack.price * quantity;
    const totalTokens = pack.totalTokens * quantity;

    // Get organization for Stripe customer
    const org = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    // Create or get Stripe customer
    let stripeCustomerId = org?.stripeCustomerId;
    if (!stripeCustomerId) {
      const customer = await this.stripe.customers.create({
        metadata: {
          organizationId,
        },
      });
      stripeCustomerId = customer.id;
      await this.prisma.organization.update({
        where: { id: organizationId },
        data: { stripeCustomerId },
      });
    }

    // Create purchase record
    const purchase = await this.prisma.tokenPurchase.create({
      data: {
        packId: pack.id,
        quantity,
        baseTokens: pack.baseTokens * quantity,
        bonusTokens: (pack.totalTokens - pack.baseTokens) * quantity,
        totalTokens,
        amount: totalAmount,
        currency: pack.currency,
        status: 'pending',
        organizationId,
        purchasedById: userId,
      },
    });

    // Create Stripe checkout session
    const session = await this.stripe.checkout.sessions.create({
      customer: stripeCustomerId,
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: pack.currency.toLowerCase(),
            product_data: {
              name: `${pack.name} - ${totalTokens} Tokens`,
              description: `Pack ${pack.name}: ${pack.baseTokens} tokens${pack.bonusPercent > 0 ? ` + ${pack.bonusPercent}% bonus` : ''}`,
            },
            unit_amount: pack.price,
          },
          quantity,
        },
      ],
      mode: 'payment',
      success_url:
        dto.successUrl ||
        `${process.env.FRONTEND_URL}/tokens/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: dto.cancelUrl || `${process.env.FRONTEND_URL}/tokens/cancel`,
      metadata: {
        purchaseId: purchase.id,
        organizationId,
        userId,
        packId: pack.id,
        totalTokens: totalTokens.toString(),
      },
    });

    // Update purchase with session ID
    await this.prisma.tokenPurchase.update({
      where: { id: purchase.id },
      data: { stripeSessionId: session.id },
    });

    this.logger.log(
      `Created checkout session ${session.id} for ${totalTokens} tokens (org: ${organizationId})`
    );

    return {
      sessionId: session.id,
      checkoutUrl: session.url || '',
    };
  }

  async handleStripeWebhook(event: Stripe.Event): Promise<void> {
    this.logger.log(`Processing Stripe webhook: ${event.type}`);

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as Stripe.Checkout.Session;
      await this.completePurchase(session);
    } else if (event.type === 'checkout.session.expired') {
      const session = event.data.object as Stripe.Checkout.Session;
      await this.expirePurchase(session.metadata?.purchaseId);
    }
  }

  private async completePurchase(session: Stripe.Checkout.Session): Promise<void> {
    const purchaseId = session.metadata?.purchaseId;
    if (!purchaseId) {
      this.logger.error('No purchaseId in session metadata');
      return;
    }

    const purchase = await this.prisma.tokenPurchase.findUnique({
      where: { id: purchaseId },
      include: { pack: true },
    });

    if (!purchase) {
      this.logger.error(`Purchase ${purchaseId} not found`);
      return;
    }

    if (purchase.status === 'completed') {
      this.logger.warn(`Purchase ${purchaseId} already completed`);
      return;
    }

    // Complete purchase and credit tokens
    await this.prisma.$transaction(async (tx) => {
      // Update purchase status
      await tx.tokenPurchase.update({
        where: { id: purchaseId },
        data: {
          status: 'completed',
          stripePaymentIntentId: session.payment_intent as string,
          completedAt: new Date(),
        },
      });

      // Credit tokens to organization
      await tx.organization.update({
        where: { id: purchase.organizationId },
        data: {
          tokenBalance: { increment: purchase.totalTokens },
        },
      });

      // Create transaction record
      await tx.tokenTransaction.create({
        data: {
          organizationId: purchase.organizationId,
          amount: purchase.totalTokens,
          type: 'credit',
          description: `Achat pack ${purchase.pack?.name || 'tokens'}: ${purchase.totalTokens} tokens`,
          metadata: {
            purchaseId,
            packId: purchase.packId,
            stripeSessionId: session.id,
          },
        },
      });
    });

    this.logger.log(
      `Completed purchase ${purchaseId}: credited ${purchase.totalTokens} tokens to org ${purchase.organizationId}`
    );
  }

  private async expirePurchase(purchaseId: string | undefined): Promise<void> {
    if (!purchaseId) return;

    await this.prisma.tokenPurchase.update({
      where: { id: purchaseId },
      data: { status: 'failed' },
    });

    this.logger.log(`Purchase ${purchaseId} expired/failed`);
  }

  async getPurchaseHistory(
    organizationId: string,
    query: PurchaseHistoryQueryDto
  ): Promise<{
    purchases: any[];
    total: number;
    page: number;
    limit: number;
  }> {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const [purchases, total] = await Promise.all([
      this.prisma.tokenPurchase.findMany({
        where: { organizationId },
        include: { pack: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.tokenPurchase.count({ where: { organizationId } }),
    ]);

    return {
      purchases: purchases.map((p) => ({
        id: p.id,
        packName: p.pack?.name || 'Unknown',
        quantity: p.quantity,
        totalTokens: p.totalTokens,
        amount: p.amount,
        currency: p.currency,
        status: p.status,
        createdAt: p.createdAt,
        completedAt: p.completedAt,
      })),
      total,
      page,
      limit,
    };
  }

  // Seed default packs if needed
  async seedDefaultPacks(): Promise<void> {
    const existingPacks = await this.prisma.tokenPack.count();
    if (existingPacks > 0) return;

    const defaultPacks = [
      { name: 'Starter', baseTokens: 100, bonusPercent: 0, price: 999, sortOrder: 1 },
      {
        name: 'Standard',
        baseTokens: 300,
        bonusPercent: 10,
        price: 2499,
        sortOrder: 2,
        isPopular: true,
      },
      { name: 'Pro', baseTokens: 600, bonusPercent: 20, price: 4499, sortOrder: 3 },
      { name: 'Business', baseTokens: 1500, bonusPercent: 30, price: 9999, sortOrder: 4 },
      { name: 'Enterprise', baseTokens: 5000, bonusPercent: 40, price: 29999, sortOrder: 5 },
    ];

    for (const pack of defaultPacks) {
      const totalTokens = Math.floor(pack.baseTokens * (1 + pack.bonusPercent / 100));
      await this.prisma.tokenPack.create({
        data: {
          ...pack,
          totalTokens,
          currency: 'EUR',
          description: `${pack.baseTokens} tokens${pack.bonusPercent > 0 ? ` +${pack.bonusPercent}% bonus` : ''}`,
        },
      });
    }

    this.logger.log('Seeded default token packs');
  }
}
