import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';

import { PrismaService } from '../../prisma/prisma.service';
import {
  SubscriptionPlan,
  SubscriptionStatus,
  UpgradePlanDto,
  CancelSubscriptionDto,
} from './dto/subscription.dto';

export interface PlanDetails {
  name: string;
  description: string;
  monthlyPrice: number;
  yearlyPrice: number;
  features: string[];
  limits: {
    users: number;
    analyses: number;
    storage: number; // GB
    tokensPerMonth: number;
  };
}

@Injectable()
export class SubscriptionsService {
  private readonly logger = new Logger(SubscriptionsService.name);
  private readonly stripe: Stripe;

  private readonly planDetails: Record<SubscriptionPlan, PlanDetails> = {
    [SubscriptionPlan.FREE]: {
      name: 'Gratuit',
      description: 'Pour découvrir Horse Tempo',
      monthlyPrice: 0,
      yearlyPrice: 0,
      features: [
        '5 analyses par mois',
        '1 utilisateur',
        '1 GB stockage',
        'Support communautaire',
      ],
      limits: {
        users: 1,
        analyses: 5,
        storage: 1,
        tokensPerMonth: 10,
      },
    },
    [SubscriptionPlan.STARTER]: {
      name: 'Starter',
      description: 'Pour les professionnels indépendants',
      monthlyPrice: 49,
      yearlyPrice: 470,
      features: [
        '50 analyses par mois',
        '3 utilisateurs',
        '10 GB stockage',
        'Support email',
        'Rapports PDF',
      ],
      limits: {
        users: 3,
        analyses: 50,
        storage: 10,
        tokensPerMonth: 100,
      },
    },
    [SubscriptionPlan.PROFESSIONAL]: {
      name: 'Professional',
      description: 'Pour les cliniques vétérinaires',
      monthlyPrice: 149,
      yearlyPrice: 1430,
      features: [
        '200 analyses par mois',
        '10 utilisateurs',
        '50 GB stockage',
        'Support prioritaire',
        'API access',
        'Intégrations tierces',
      ],
      limits: {
        users: 10,
        analyses: 200,
        storage: 50,
        tokensPerMonth: 500,
      },
    },
    [SubscriptionPlan.ENTERPRISE]: {
      name: 'Enterprise',
      description: 'Pour les grandes organisations',
      monthlyPrice: 499,
      yearlyPrice: 4790,
      features: [
        'Analyses illimitées',
        'Utilisateurs illimités',
        'Stockage illimité',
        'Support dédié 24/7',
        'SLA garanti',
        'Formation personnalisée',
        'On-premise disponible',
      ],
      limits: {
        users: -1, // Unlimited
        analyses: -1,
        storage: -1,
        tokensPerMonth: 2000,
      },
    },
  };

  private readonly stripePriceIds: Record<SubscriptionPlan, { monthly: string; yearly: string }> = {
    [SubscriptionPlan.FREE]: { monthly: '', yearly: '' },
    [SubscriptionPlan.STARTER]: {
      monthly: 'price_starter_monthly',
      yearly: 'price_starter_yearly',
    },
    [SubscriptionPlan.PROFESSIONAL]: {
      monthly: 'price_professional_monthly',
      yearly: 'price_professional_yearly',
    },
    [SubscriptionPlan.ENTERPRISE]: {
      monthly: 'price_enterprise_monthly',
      yearly: 'price_enterprise_yearly',
    },
  };

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    this.stripe = new Stripe(
      this.configService.get('STRIPE_SECRET_KEY', 'sk_test_placeholder'),
      { apiVersion: '2023-10-16' },
    );
  }

  async getSubscription(organizationId: string): Promise<{
    plan: SubscriptionPlan;
    status: SubscriptionStatus;
    currentPeriodEnd: Date | null;
    cancelAtPeriodEnd: boolean;
    limits: PlanDetails['limits'];
    usage: {
      users: number;
      analysesThisMonth: number;
      storageUsed: number;
    };
  }> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
      include: {
        _count: {
          select: { users: true },
        },
      },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const settings = organization.settings as any;
    const plan = (settings?.plan as SubscriptionPlan) || SubscriptionPlan.FREE;
    const planDetails = this.planDetails[plan];

    // Get analyses this month
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const analysesCount = await this.prisma.analysisSession.count({
      where: {
        organizationId,
        createdAt: { gte: startOfMonth },
      },
    });

    // Estimate storage usage (in production, calculate from S3)
    const storageEstimate = 0; // Placeholder

    return {
      plan,
      status: (settings?.subscriptionStatus as SubscriptionStatus) || SubscriptionStatus.ACTIVE,
      currentPeriodEnd: settings?.currentPeriodEnd ? new Date(settings.currentPeriodEnd) : null,
      cancelAtPeriodEnd: settings?.cancelAtPeriodEnd || false,
      limits: planDetails.limits,
      usage: {
        users: organization._count.users,
        analysesThisMonth: analysesCount,
        storageUsed: storageEstimate,
      },
    };
  }

  async getPlans(): Promise<Record<SubscriptionPlan, PlanDetails>> {
    return this.planDetails;
  }

  async upgradePlan(
    organizationId: string,
    dto: UpgradePlanDto,
  ): Promise<{ checkoutUrl: string }> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const settings = organization.settings as any;
    const currentPlan = settings?.plan as SubscriptionPlan || SubscriptionPlan.FREE;

    // Validate upgrade path
    const planOrder = [
      SubscriptionPlan.FREE,
      SubscriptionPlan.STARTER,
      SubscriptionPlan.PROFESSIONAL,
      SubscriptionPlan.ENTERPRISE,
    ];

    const currentIndex = planOrder.indexOf(currentPlan);
    const targetIndex = planOrder.indexOf(dto.plan);

    if (targetIndex <= currentIndex) {
      throw new BadRequestException('Cannot downgrade via this endpoint. Use the billing portal.');
    }

    // Get or create Stripe customer
    let stripeCustomerId = settings?.stripeCustomerId;

    if (!stripeCustomerId) {
      const customer = await this.stripe.customers.create({
        name: organization.name,
        metadata: { organizationId },
      });
      stripeCustomerId = customer.id;

      await this.prisma.organization.update({
        where: { id: organizationId },
        data: {
          settings: {
            ...settings,
            stripeCustomerId,
          },
        },
      });
    }

    const priceId = dto.yearly
      ? this.stripePriceIds[dto.plan].yearly
      : this.stripePriceIds[dto.plan].monthly;

    // If already has subscription, create upgrade session
    if (settings?.stripeSubscriptionId) {
      // Update existing subscription
      await this.stripe.subscriptions.update(settings.stripeSubscriptionId, {
        items: [
          {
            id: settings.stripeSubscriptionItemId,
            price: priceId,
          },
        ],
        proration_behavior: 'create_prorations',
      });

      return {
        checkoutUrl: `${this.configService.get('FRONTEND_URL')}/dashboard/billing?upgraded=true`,
      };
    }

    // Create new checkout session
    const session = await this.stripe.checkout.sessions.create({
      customer: stripeCustomerId,
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${this.configService.get('FRONTEND_URL')}/dashboard/billing?success=true`,
      cancel_url: `${this.configService.get('FRONTEND_URL')}/dashboard/billing?canceled=true`,
      metadata: {
        organizationId,
        plan: dto.plan,
      },
      subscription_data: {
        metadata: {
          organizationId,
          plan: dto.plan,
        },
      },
    });

    return { checkoutUrl: session.url! };
  }

  async cancelSubscription(
    organizationId: string,
    dto: CancelSubscriptionDto,
  ): Promise<{ success: boolean; cancelAt: Date | null }> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const settings = organization.settings as any;
    const subscriptionId = settings?.stripeSubscriptionId;

    if (!subscriptionId) {
      throw new BadRequestException('No active subscription found');
    }

    if (dto.immediate) {
      await this.stripe.subscriptions.cancel(subscriptionId);

      await this.prisma.organization.update({
        where: { id: organizationId },
        data: {
          settings: {
            ...settings,
            plan: SubscriptionPlan.FREE,
            subscriptionStatus: SubscriptionStatus.CANCELED,
            stripeSubscriptionId: null,
          },
        },
      });

      // Record cancellation reason
      if (dto.reason) {
        await this.prisma.auditLog.create({
          data: {
            organizationId,
            action: 'subscription_canceled',
            details: { reason: dto.reason, immediate: true },
          },
        });
      }

      return { success: true, cancelAt: null };
    }

    // Cancel at period end
    const subscription = await this.stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: true,
    });

    await this.prisma.organization.update({
      where: { id: organizationId },
      data: {
        settings: {
          ...settings,
          cancelAtPeriodEnd: true,
        },
      },
    });

    if (dto.reason) {
      await this.prisma.auditLog.create({
        data: {
          organizationId,
          action: 'subscription_cancel_scheduled',
          details: { reason: dto.reason },
        },
      });
    }

    return {
      success: true,
      cancelAt: new Date(subscription.current_period_end * 1000),
    };
  }

  async reactivateSubscription(organizationId: string): Promise<{ success: boolean }> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const settings = organization.settings as any;
    const subscriptionId = settings?.stripeSubscriptionId;

    if (!subscriptionId) {
      throw new BadRequestException('No subscription to reactivate');
    }

    await this.stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: false,
    });

    await this.prisma.organization.update({
      where: { id: organizationId },
      data: {
        settings: {
          ...settings,
          cancelAtPeriodEnd: false,
        },
      },
    });

    return { success: true };
  }

  async checkLimits(
    organizationId: string,
    action: 'add_user' | 'create_analysis' | 'upload_file',
    size?: number,
  ): Promise<{ allowed: boolean; reason?: string }> {
    const subscription = await this.getSubscription(organizationId);
    const { limits, usage } = subscription;

    switch (action) {
      case 'add_user':
        if (limits.users !== -1 && usage.users >= limits.users) {
          return {
            allowed: false,
            reason: `User limit reached (${limits.users}). Upgrade your plan.`,
          };
        }
        break;

      case 'create_analysis':
        if (limits.analyses !== -1 && usage.analysesThisMonth >= limits.analyses) {
          return {
            allowed: false,
            reason: `Monthly analysis limit reached (${limits.analyses}). Upgrade your plan.`,
          };
        }
        break;

      case 'upload_file':
        if (limits.storage !== -1 && usage.storageUsed >= limits.storage) {
          return {
            allowed: false,
            reason: `Storage limit reached (${limits.storage} GB). Upgrade your plan.`,
          };
        }
        break;
    }

    return { allowed: true };
  }
}
