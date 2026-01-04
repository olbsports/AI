import {
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';

import { PrismaService } from '../../prisma/prisma.service';
import { InvoiceQueryDto, InvoiceStatus } from './dto/invoice.dto';

export interface InvoiceData {
  id: string;
  invoiceNumber: string;
  amount: number;
  currency: string;
  status: InvoiceStatus;
  description: string | null;
  createdAt: Date;
  paidAt: Date | null;
  dueDate: Date | null;
  invoiceUrl: string | null;
  pdfUrl: string | null;
}

export interface InvoiceSummary {
  totalPaid: number;
  totalPending: number;
  invoiceCount: number;
  currency: string;
}

@Injectable()
export class InvoicesService {
  private readonly logger = new Logger(InvoicesService.name);
  private readonly stripe: Stripe;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    this.stripe = new Stripe(
      this.configService.get('STRIPE_SECRET_KEY', 'sk_test_placeholder'),
      { apiVersion: '2023-10-16' },
    );
  }

  async getInvoices(
    organizationId: string,
    query: InvoiceQueryDto,
  ): Promise<{ invoices: InvoiceData[]; total: number; page: number; limit: number }> {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = { organizationId };

    if (query.status) {
      where.status = query.status;
    }

    if (query.from || query.to) {
      where.createdAt = {};
      if (query.from) {
        where.createdAt.gte = new Date(query.from);
      }
      if (query.to) {
        where.createdAt.lte = new Date(query.to);
      }
    }

    const [invoices, total] = await Promise.all([
      this.prisma.invoice.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.invoice.count({ where }),
    ]);

    return {
      invoices: invoices.map((inv) => ({
        id: inv.id,
        invoiceNumber: inv.invoiceNumber,
        amount: inv.amount,
        currency: inv.currency,
        status: inv.status as InvoiceStatus,
        description: inv.description,
        createdAt: inv.createdAt,
        paidAt: inv.paidAt,
        dueDate: inv.dueDate,
        invoiceUrl: inv.invoiceUrl,
        pdfUrl: inv.pdfUrl,
      })),
      total,
      page,
      limit,
    };
  }

  async getInvoice(organizationId: string, invoiceId: string): Promise<InvoiceData> {
    const invoice = await this.prisma.invoice.findFirst({
      where: {
        id: invoiceId,
        organizationId,
      },
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    return {
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      amount: invoice.amount,
      currency: invoice.currency,
      status: invoice.status as InvoiceStatus,
      description: invoice.description,
      createdAt: invoice.createdAt,
      paidAt: invoice.paidAt,
      dueDate: invoice.dueDate,
      invoiceUrl: invoice.invoiceUrl,
      pdfUrl: invoice.pdfUrl,
    };
  }

  async getSummary(organizationId: string): Promise<InvoiceSummary> {
    const [paid, pending, count] = await Promise.all([
      this.prisma.invoice.aggregate({
        where: { organizationId, status: 'paid' },
        _sum: { amount: true },
      }),
      this.prisma.invoice.aggregate({
        where: { organizationId, status: 'pending' },
        _sum: { amount: true },
      }),
      this.prisma.invoice.count({
        where: { organizationId },
      }),
    ]);

    return {
      totalPaid: paid._sum.amount || 0,
      totalPending: pending._sum.amount || 0,
      invoiceCount: count,
      currency: 'EUR',
    };
  }

  async downloadInvoice(
    organizationId: string,
    invoiceId: string,
  ): Promise<{ url: string }> {
    const invoice = await this.prisma.invoice.findFirst({
      where: {
        id: invoiceId,
        organizationId,
      },
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    if (invoice.pdfUrl) {
      return { url: invoice.pdfUrl };
    }

    // Try to get from Stripe
    if (invoice.stripeInvoiceId) {
      const stripeInvoice = await this.stripe.invoices.retrieve(invoice.stripeInvoiceId);
      if (stripeInvoice.invoice_pdf) {
        // Cache the URL
        await this.prisma.invoice.update({
          where: { id: invoiceId },
          data: { pdfUrl: stripeInvoice.invoice_pdf },
        });
        return { url: stripeInvoice.invoice_pdf };
      }
    }

    throw new NotFoundException('PDF not available for this invoice');
  }

  async getUpcomingInvoice(organizationId: string): Promise<{
    amount: number;
    currency: string;
    nextBillingDate: Date;
    lineItems: { description: string; amount: number }[];
  } | null> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const settings = organization.settings as any;
    const stripeCustomerId = settings?.stripeCustomerId;

    if (!stripeCustomerId) {
      return null;
    }

    try {
      const upcoming = await this.stripe.invoices.retrieveUpcoming({
        customer: stripeCustomerId,
      });

      return {
        amount: upcoming.amount_due / 100,
        currency: upcoming.currency,
        nextBillingDate: new Date(upcoming.next_payment_attempt! * 1000),
        lineItems: upcoming.lines.data.map((line) => ({
          description: line.description || 'Subscription',
          amount: line.amount / 100,
        })),
      };
    } catch (error) {
      // No upcoming invoice (no active subscription)
      return null;
    }
  }

  async syncInvoicesFromStripe(organizationId: string): Promise<{ synced: number }> {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const settings = organization.settings as any;
    const stripeCustomerId = settings?.stripeCustomerId;

    if (!stripeCustomerId) {
      return { synced: 0 };
    }

    const stripeInvoices = await this.stripe.invoices.list({
      customer: stripeCustomerId,
      limit: 100,
    });

    let synced = 0;

    for (const stripeInv of stripeInvoices.data) {
      const exists = await this.prisma.invoice.findFirst({
        where: { stripeInvoiceId: stripeInv.id },
      });

      if (!exists) {
        await this.prisma.invoice.create({
          data: {
            organizationId,
            stripeInvoiceId: stripeInv.id,
            invoiceNumber: stripeInv.number || `INV-${stripeInv.id}`,
            amount: stripeInv.amount_paid / 100,
            currency: stripeInv.currency,
            status: this.mapStripeStatus(stripeInv.status),
            paidAt: stripeInv.status_transitions?.paid_at
              ? new Date(stripeInv.status_transitions.paid_at * 1000)
              : null,
            dueDate: stripeInv.due_date
              ? new Date(stripeInv.due_date * 1000)
              : null,
            invoiceUrl: stripeInv.hosted_invoice_url || null,
            pdfUrl: stripeInv.invoice_pdf || null,
          },
        });
        synced++;
      }
    }

    this.logger.log(`Synced ${synced} invoices for org ${organizationId}`);

    return { synced };
  }

  async getYearlyReport(
    organizationId: string,
    year: number,
  ): Promise<{
    year: number;
    totalAmount: number;
    invoiceCount: number;
    byMonth: { month: number; amount: number; count: number }[];
  }> {
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year + 1, 0, 1);

    const invoices = await this.prisma.invoice.findMany({
      where: {
        organizationId,
        status: 'paid',
        paidAt: {
          gte: startDate,
          lt: endDate,
        },
      },
    });

    const byMonth = new Map<number, { amount: number; count: number }>();

    // Initialize all months
    for (let i = 0; i < 12; i++) {
      byMonth.set(i, { amount: 0, count: 0 });
    }

    let totalAmount = 0;

    invoices.forEach((inv) => {
      const month = inv.paidAt!.getMonth();
      const current = byMonth.get(month)!;
      byMonth.set(month, {
        amount: current.amount + inv.amount,
        count: current.count + 1,
      });
      totalAmount += inv.amount;
    });

    return {
      year,
      totalAmount,
      invoiceCount: invoices.length,
      byMonth: Array.from(byMonth.entries()).map(([month, data]) => ({
        month: month + 1,
        ...data,
      })),
    };
  }

  private mapStripeStatus(
    status: Stripe.Invoice.Status | null,
  ): InvoiceStatus {
    switch (status) {
      case 'paid':
        return InvoiceStatus.PAID;
      case 'draft':
        return InvoiceStatus.DRAFT;
      case 'open':
        return InvoiceStatus.PENDING;
      case 'void':
      case 'uncollectible':
        return InvoiceStatus.FAILED;
      default:
        return InvoiceStatus.PENDING;
    }
  }
}
