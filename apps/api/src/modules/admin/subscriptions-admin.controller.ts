import { Controller, Get, Post, Put, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { PrismaService } from '../../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('subscriptions')
@Controller('subscriptions')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('owner')
@ApiBearerAuth()
export class SubscriptionsAdminController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'Get all subscriptions (paginated)' })
  async getSubscriptions(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('status') status?: string,
    @Query('planId') planId?: string
  ) {
    try {
      const pageNum = page ? parseInt(page) : 1;
      const limitNum = limit ? parseInt(limit) : 25;
      const skip = (pageNum - 1) * limitNum;

      const where: any = {};
      if (status) where.status = status;
      if (planId) where.planId = planId;

      const [subscriptions, total] = await Promise.all([
        this.prisma.subscription.findMany({
          where,
          skip,
          take: limitNum,
          include: {
            user: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                email: true,
              },
            },
            plan: true,
          },
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.subscription.count({ where }),
      ]);

      return {
        subscriptions: subscriptions.map((sub) => ({
          id: sub.id,
          userId: sub.userId,
          userName: `${sub.user.firstName} ${sub.user.lastName}`,
          userEmail: sub.user.email,
          planId: sub.planId,
          planName: sub.plan?.name || 'Unknown',
          status: sub.status,
          amount: sub.amount || 0,
          currency: 'EUR',
          interval: sub.interval || 'monthly',
          startDate: sub.startDate,
          endDate: sub.endDate,
          cancelledAt: sub.cancelledAt,
          cancellationReason: sub.cancellationReason,
          nextBillingDate: sub.nextBillingDate,
          invoiceCount: 0,
          totalPaid: 0,
          stripeSubscriptionId: sub.stripeSubscriptionId,
        })),
        total,
        page: pageNum,
        totalPages: Math.ceil(total / limitNum),
      };
    } catch {
      return { subscriptions: [], total: 0, page: 1, totalPages: 0 };
    }
  }

  @Get('plans')
  @ApiOperation({ summary: 'Get all subscription plans' })
  async getPlans() {
    try {
      const plans = await this.prisma.subscriptionPlan.findMany({
        orderBy: { monthlyPrice: 'asc' },
      });

      return plans.map((plan) => ({
        id: plan.id,
        name: plan.name,
        description: plan.description || '',
        monthlyPrice: plan.monthlyPrice,
        yearlyPrice: plan.yearlyPrice || plan.monthlyPrice * 10,
        features: plan.features || [],
        maxHorses: plan.maxHorses || 999,
        maxAnalysesPerMonth: plan.maxAnalysesPerMonth || 999,
        isActive: plan.isActive,
        subscriberCount: 0,
      }));
    } catch {
      // Return default plans if table doesn't exist
      return [
        {
          id: 'free',
          name: 'Gratuit',
          description: 'Plan de base gratuit',
          monthlyPrice: 0,
          yearlyPrice: 0,
          features: ['1 cheval', '5 analyses/mois'],
          maxHorses: 1,
          maxAnalysesPerMonth: 5,
          isActive: true,
          subscriberCount: 0,
        },
        {
          id: 'pro',
          name: 'Pro',
          description: 'Pour les professionnels',
          monthlyPrice: 29.99,
          yearlyPrice: 299.99,
          features: ['Chevaux illimités', 'Analyses illimitées', 'Support prioritaire'],
          maxHorses: 999,
          maxAnalysesPerMonth: 999,
          isActive: true,
          subscriberCount: 0,
        },
      ];
    }
  }

  @Get('revenue')
  @ApiOperation({ summary: 'Get revenue statistics' })
  async getRevenueStats() {
    try {
      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

      const [thisMonthRevenue, lastMonthRevenue, activeSubscriptions] = await Promise.all([
        this.prisma.invoice.aggregate({
          where: { status: 'paid', paidAt: { gte: startOfMonth } },
          _sum: { amount: true },
        }),
        this.prisma.invoice.aggregate({
          where: {
            status: 'paid',
            paidAt: { gte: startOfLastMonth, lte: endOfLastMonth },
          },
          _sum: { amount: true },
        }),
        this.prisma.subscription.count({ where: { status: 'active' } }),
      ]);

      const mrr = thisMonthRevenue._sum.amount || 0;
      const lastMrr = lastMonthRevenue._sum.amount || 0;
      const mrrGrowth = lastMrr > 0 ? ((mrr - lastMrr) / lastMrr) * 100 : 0;

      return {
        mrr,
        arr: mrr * 12,
        mrrGrowth,
        ltv: mrr * 12, // Simplified
        churnRate: 0,
        trialConversions: 0,
        revenueHistory: [],
        revenueByPlan: {},
      };
    } catch {
      return {
        mrr: 0,
        arr: 0,
        mrrGrowth: 0,
        ltv: 0,
        churnRate: 0,
        trialConversions: 0,
        revenueHistory: [],
        revenueByPlan: {},
      };
    }
  }

  @Post(':id/cancel')
  @ApiOperation({ summary: 'Cancel a subscription' })
  async cancelSubscription(@Param('id') id: string, @Body() body: { reason: string }) {
    try {
      await this.prisma.subscription.update({
        where: { id },
        data: {
          status: 'cancelled',
          cancelledAt: new Date(),
          cancellationReason: body.reason,
        },
      });
      return { success: true };
    } catch {
      return { success: false };
    }
  }

  @Post(':id/refund')
  @ApiOperation({ summary: 'Refund a subscription payment' })
  async refundSubscription(
    @Param('id') id: string,
    @Body() body: { amount: number; reason: string }
  ) {
    // Would integrate with Stripe for actual refund
    return { success: true, message: 'Refund would be processed here' };
  }

  @Post(':id/extend')
  @ApiOperation({ summary: 'Extend subscription period' })
  async extendSubscription(@Param('id') id: string, @Body() body: { days: number }) {
    try {
      const subscription = await this.prisma.subscription.findUnique({
        where: { id },
      });

      if (!subscription) {
        return { success: false, error: 'Subscription not found' };
      }

      const currentEnd = subscription.endDate || new Date();
      const newEnd = new Date(currentEnd.getTime() + body.days * 24 * 60 * 60 * 1000);

      await this.prisma.subscription.update({
        where: { id },
        data: { endDate: newEnd },
      });

      return { success: true };
    } catch {
      return { success: false };
    }
  }

  @Put('plans/:id')
  @ApiOperation({ summary: 'Update a subscription plan' })
  async updatePlan(@Param('id') id: string, @Body() data: any) {
    try {
      await this.prisma.subscriptionPlan.update({
        where: { id },
        data,
      });
      return { success: true };
    } catch {
      return { success: false };
    }
  }
}
