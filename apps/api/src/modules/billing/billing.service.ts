import { Injectable, Logger, BadRequestException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';

import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateCheckoutDto,
  PurchaseTokensDto,
  CreatePortalSessionDto,
  PlanType,
  BillingInterval,
} from './dto/create-checkout.dto';

export interface PlanConfig {
  name: string;
  monthlyPriceId: string;
  yearlyPriceId: string;
  tokensPerMonth: number;
  features: string[];
}

@Injectable()
export class BillingService {
  private readonly logger = new Logger(BillingService.name);
  private readonly stripe: Stripe;
  private readonly webhookSecret: string;
  private readonly frontendUrl: string;

  // Plan configurations with Stripe price IDs
  private readonly plans: Record<PlanType, PlanConfig> = {
    [PlanType.STARTER]: {
      name: 'Starter',
      monthlyPriceId: 'price_starter_monthly',
      yearlyPriceId: 'price_starter_yearly',
      tokensPerMonth: 100,
      features: ['10 analyses/mois', '2 utilisateurs', 'Support email'],
    },
    [PlanType.PROFESSIONAL]: {
      name: 'Professional',
      monthlyPriceId: 'price_professional_monthly',
      yearlyPriceId: 'price_professional_yearly',
      tokensPerMonth: 500,
      features: ['50 analyses/mois', '10 utilisateurs', 'Support prioritaire', 'API access'],
    },
    [PlanType.ENTERPRISE]: {
      name: 'Enterprise',
      monthlyPriceId: 'price_enterprise_monthly',
      yearlyPriceId: 'price_enterprise_yearly',
      tokensPerMonth: 2000,
      features: ['Analyses illimitées', 'Utilisateurs illimités', 'Support dédié', 'SLA garanti'],
    },
  };

  // Token pricing
  private readonly tokenPriceId = 'price_tokens_pack';
  private readonly tokenPricePerUnit = 0.1; // €0.10 per token

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService
  ) {
    this.stripe = new Stripe(this.configService.get('STRIPE_SECRET_KEY', 'sk_test_placeholder'), {
      apiVersion: '2023-10-16',
    });
    this.webhookSecret = this.configService.get('STRIPE_WEBHOOK_SECRET', 'whsec_placeholder');
    this.frontendUrl = this.configService.get('FRONTEND_URL', 'http://localhost:3000');
  }

  async createCheckoutSession(
    organizationId: string,
    userId: string,
    dto: CreateCheckoutDto
  ): Promise<{ sessionId: string; url: string }> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    // Get or create Stripe customer
    let stripeCustomerId = (organization.settings as any)?.stripeCustomerId;

    if (!stripeCustomerId) {
      const customer = await this.stripe.customers.create({
        name: organization.name,
        metadata: {
          organizationId: organization.id,
        },
      });
      stripeCustomerId = customer.id;

      // Save customer ID
      await this.prisma.organization.update({
        where: { id: organizationId },
        data: {
          settings: {
            ...(organization.settings as object),
            stripeCustomerId,
          },
        },
      });
    }

    const plan = this.plans[dto.plan];
    const priceId =
      dto.interval === BillingInterval.MONTHLY ? plan.monthlyPriceId : plan.yearlyPriceId;

    const session = await this.stripe.checkout.sessions.create({
      customer: stripeCustomerId,
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      success_url: dto.successUrl || `${this.frontendUrl}/dashboard/billing?success=true`,
      cancel_url: dto.cancelUrl || `${this.frontendUrl}/dashboard/billing?canceled=true`,
      metadata: {
        organizationId,
        userId,
        plan: dto.plan,
        interval: dto.interval,
      },
      subscription_data: {
        metadata: {
          organizationId,
          plan: dto.plan,
        },
      },
    });

    this.logger.log(`Checkout session created for org ${organizationId}: ${session.id}`);

    return {
      sessionId: session.id,
      url: session.url!,
    };
  }

  async createTokenPurchaseSession(
    organizationId: string,
    userId: string,
    dto: PurchaseTokensDto
  ): Promise<{ sessionId: string; url: string }> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    let stripeCustomerId = (organization.settings as any)?.stripeCustomerId;

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
            ...(organization.settings as object),
            stripeCustomerId,
          },
        },
      });
    }

    const amount = Math.round(dto.amount * this.tokenPricePerUnit * 100); // Convert to cents

    const session = await this.stripe.checkout.sessions.create({
      customer: stripeCustomerId,
      mode: 'payment',
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'eur',
            product_data: {
              name: `${dto.amount} Tokens Horse Vision AI`,
              description: `Pack de ${dto.amount} tokens pour analyses`,
            },
            unit_amount: amount,
          },
          quantity: 1,
        },
      ],
      success_url: `${this.frontendUrl}/dashboard/tokens?success=true&amount=${dto.amount}`,
      cancel_url: `${this.frontendUrl}/dashboard/tokens?canceled=true`,
      metadata: {
        organizationId,
        userId,
        type: 'token_purchase',
        tokenAmount: dto.amount.toString(),
      },
    });

    return {
      sessionId: session.id,
      url: session.url!,
    };
  }

  async createPortalSession(
    organizationId: string,
    dto: CreatePortalSessionDto
  ): Promise<{ url: string }> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const stripeCustomerId = (organization.settings as any)?.stripeCustomerId;

    if (!stripeCustomerId) {
      throw new BadRequestException('No billing account found. Please subscribe first.');
    }

    const session = await this.stripe.billingPortal.sessions.create({
      customer: stripeCustomerId,
      return_url: dto.returnUrl || `${this.frontendUrl}/dashboard/billing`,
    });

    return { url: session.url };
  }

  async handleWebhook(payload: Buffer, signature: string): Promise<void> {
    let event: Stripe.Event;

    try {
      event = this.stripe.webhooks.constructEvent(payload, signature, this.webhookSecret);
    } catch (err) {
      this.logger.error('Webhook signature verification failed', err);
      throw new BadRequestException('Invalid webhook signature');
    }

    this.logger.log(`Processing webhook: ${event.type}`);

    switch (event.type) {
      case 'checkout.session.completed':
        await this.handleCheckoutCompleted(event.data.object as Stripe.Checkout.Session);
        break;

      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        await this.handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
        break;

      case 'customer.subscription.deleted':
        await this.handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
        break;

      case 'invoice.paid':
        await this.handleInvoicePaid(event.data.object as Stripe.Invoice);
        break;

      case 'invoice.payment_failed':
        await this.handlePaymentFailed(event.data.object as Stripe.Invoice);
        break;

      default:
        this.logger.log(`Unhandled event type: ${event.type}`);
    }
  }

  private async handleCheckoutCompleted(session: Stripe.Checkout.Session): Promise<void> {
    const { organizationId, type, tokenAmount } = session.metadata || {};

    if (!organizationId) {
      this.logger.warn('Checkout completed without organizationId');
      return;
    }

    // Handle token purchase
    if (type === 'token_purchase' && tokenAmount) {
      await this.creditTokens(organizationId, parseInt(tokenAmount, 10), {
        type: 'purchase',
        description: `Achat de ${tokenAmount} tokens`,
        stripeSessionId: session.id,
      });
    }

    this.logger.log(`Checkout completed for org ${organizationId}`);
  }

  private async handleSubscriptionUpdated(subscription: Stripe.Subscription): Promise<void> {
    const organizationId = subscription.metadata?.organizationId;
    const plan = subscription.metadata?.plan as PlanType;

    if (!organizationId) {
      this.logger.warn('Subscription updated without organizationId');
      return;
    }

    const planConfig = this.plans[plan];

    await this.prisma.organization.update({
      where: { id: organizationId },
      data: {
        settings: {
          stripeSubscriptionId: subscription.id,
          plan,
          subscriptionStatus: subscription.status,
          currentPeriodEnd: new Date(subscription.current_period_end * 1000),
          tokensPerMonth: planConfig?.tokensPerMonth || 0,
        },
      },
    });

    this.logger.log(`Subscription updated for org ${organizationId}: ${plan}`);
  }

  private async handleSubscriptionDeleted(subscription: Stripe.Subscription): Promise<void> {
    const organizationId = subscription.metadata?.organizationId;

    if (!organizationId) return;

    await this.prisma.organization.update({
      where: { id: organizationId },
      data: {
        settings: {
          subscriptionStatus: 'canceled',
          plan: null,
        },
      },
    });

    this.logger.log(`Subscription canceled for org ${organizationId}`);
  }

  private async handleInvoicePaid(invoice: Stripe.Invoice): Promise<void> {
    const customerId = invoice.customer as string;

    // Find organization by customer ID
    const organizations = await this.prisma.organization.findMany({
      where: {
        settings: {
          path: '$.stripeCustomerId',
          equals: customerId,
        },
      },
    });

    if (organizations.length === 0) return;

    const organization = organizations[0];
    const settings = organization.settings as any;
    const plan = settings?.plan as PlanType;

    if (plan && this.plans[plan]) {
      // Credit monthly tokens on subscription renewal
      await this.creditTokens(organization.id, this.plans[plan].tokensPerMonth, {
        type: 'subscription',
        description: `Tokens mensuels - Plan ${this.plans[plan].name}`,
        stripeInvoiceId: invoice.id,
      });
    }

    // Record invoice
    await this.prisma.invoice.create({
      data: {
        organizationId: organization.id,
        stripeInvoiceId: invoice.id,
        amount: invoice.amount_paid / 100,
        currency: invoice.currency,
        status: 'paid',
        paidAt: new Date(),
        invoiceNumber: invoice.number || `INV-${Date.now()}`,
        invoiceUrl: invoice.hosted_invoice_url || undefined,
        pdfUrl: invoice.invoice_pdf || undefined,
      },
    });

    this.logger.log(`Invoice paid for org ${organization.id}: ${invoice.id}`);
  }

  private async handlePaymentFailed(invoice: Stripe.Invoice): Promise<void> {
    const customerId = invoice.customer as string;

    const organizations = await this.prisma.organization.findMany({
      where: {
        settings: {
          path: '$.stripeCustomerId',
          equals: customerId,
        },
      },
    });

    if (organizations.length === 0) return;

    const organization = organizations[0];

    await this.prisma.organization.update({
      where: { id: organization.id },
      data: {
        settings: {
          ...(organization.settings as object),
          subscriptionStatus: 'past_due',
        },
      },
    });

    // TODO: Send notification email about failed payment

    this.logger.warn(`Payment failed for org ${organization.id}`);
  }

  private async creditTokens(
    organizationId: string,
    amount: number,
    metadata: {
      type: string;
      description: string;
      stripeSessionId?: string;
      stripeInvoiceId?: string;
    }
  ): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      // Update balance
      await tx.organization.update({
        where: { id: organizationId },
        data: {
          tokenBalance: { increment: amount },
        },
      });

      // Record transaction
      await tx.tokenTransaction.create({
        data: {
          organizationId,
          amount,
          type: 'credit',
          description: metadata.description,
          metadata: {
            source: metadata.type,
            stripeSessionId: metadata.stripeSessionId,
            stripeInvoiceId: metadata.stripeInvoiceId,
          },
        },
      });
    });

    this.logger.log(`Credited ${amount} tokens to org ${organizationId}`);
  }

  async getSubscriptionStatus(organizationId: string): Promise<{
    plan: PlanType | null;
    status: string;
    currentPeriodEnd: Date | null;
    tokenBalance: number;
    tokensPerMonth: number;
  }> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const settings = organization.settings as any;

    return {
      plan: settings?.plan || null,
      status: settings?.subscriptionStatus || 'none',
      currentPeriodEnd: settings?.currentPeriodEnd || null,
      tokenBalance: organization.tokenBalance || 0,
      tokensPerMonth: settings?.tokensPerMonth || 0,
    };
  }

  getPlans(): Record<PlanType, PlanConfig> {
    return this.plans;
  }

  async getTokenBalance(organizationId: string): Promise<{
    balance: number;
    tokensPerMonth: number;
    plan: PlanType | null;
  }> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const settings = organization.settings as any;

    return {
      balance: organization.tokenBalance || 0,
      tokensPerMonth: settings?.tokensPerMonth || 0,
      plan: settings?.plan || null,
    };
  }

  async getTokenHistory(
    organizationId: string,
    page = 1,
    pageSize = 20
  ): Promise<{
    items: any[];
    pagination: {
      page: number;
      pageSize: number;
      totalItems: number;
      totalPages: number;
    };
  }> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const skip = (page - 1) * pageSize;

    const [items, totalItems] = await Promise.all([
      this.prisma.tokenTransaction.findMany({
        where: { organizationId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: pageSize,
      }),
      this.prisma.tokenTransaction.count({
        where: { organizationId },
      }),
    ]);

    return {
      items,
      pagination: {
        page,
        pageSize,
        totalItems,
        totalPages: Math.ceil(totalItems / pageSize),
      },
    };
  }
}
