import { Injectable, Logger, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../../prisma/prisma.service';
import {
  OrganizationQueryDto,
  UserQueryDto,
  DateRangeDto,
  UpdateOrganizationDto,
  UpdateUserDto,
} from './dto/admin.dto';

export interface DashboardStats {
  organizations: {
    total: number;
    active: number;
    newThisMonth: number;
    byPlan: Record<string, number>;
  };
  users: {
    total: number;
    active: number;
    newThisMonth: number;
    byRole: Record<string, number>;
  };
  analyses: {
    total: number;
    thisMonth: number;
    successRate: number;
    averageProcessingTime: number;
  };
  revenue: {
    thisMonth: number;
    lastMonth: number;
    growth: number;
    mrr: number;
  };
  tokens: {
    totalConsumed: number;
    thisMonth: number;
    averagePerOrg: number;
  };
}

@Injectable()
export class AdminService {
  private readonly logger = new Logger(AdminService.name);

  constructor(private readonly prisma: PrismaService) {}

  async getDashboardStats(): Promise<DashboardStats> {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

    // Organizations
    const [totalOrgs, activeOrgs, newOrgsThisMonth, orgsByPlan] = await Promise.all([
      this.prisma.organization.count(),
      this.prisma.organization.count({ where: { users: { some: { isActive: true } } } }),
      this.prisma.organization.count({ where: { createdAt: { gte: startOfMonth } } }),
      this.prisma.organization.groupBy({
        by: ['plan'],
        _count: true,
      }),
    ]);

    // Users
    const [totalUsers, activeUsers, newUsersThisMonth, usersByRole] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { isActive: true } }),
      this.prisma.user.count({ where: { createdAt: { gte: startOfMonth } } }),
      this.prisma.user.groupBy({
        by: ['role'],
        _count: true,
      }),
    ]);

    // Analyses
    const [totalAnalyses, analysesThisMonth, completedAnalyses, failedAnalyses, avgProcessingTime] =
      await Promise.all([
        this.prisma.analysisSession.count(),
        this.prisma.analysisSession.count({ where: { createdAt: { gte: startOfMonth } } }),
        this.prisma.analysisSession.count({ where: { status: 'completed' } }),
        this.prisma.analysisSession.count({ where: { status: 'failed' } }),
        this.prisma.analysisSession.aggregate({
          where: { status: 'completed', processingTimeMs: { not: null } },
          _avg: { processingTimeMs: true },
        }),
      ]);

    // Revenue
    const [revenueThisMonth, revenueLastMonth] = await Promise.all([
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
    ]);

    const thisMonthRevenue = revenueThisMonth._sum.amount || 0;
    const lastMonthRevenue = revenueLastMonth._sum.amount || 0;
    const revenueGrowth =
      lastMonthRevenue > 0 ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100 : 0;

    // Tokens
    const [totalTokensConsumed, tokensThisMonth] = await Promise.all([
      this.prisma.tokenTransaction.aggregate({
        where: { type: 'debit' },
        _sum: { amount: true },
      }),
      this.prisma.tokenTransaction.aggregate({
        where: { type: 'debit', createdAt: { gte: startOfMonth } },
        _sum: { amount: true },
      }),
    ]);

    return {
      organizations: {
        total: totalOrgs,
        active: activeOrgs,
        newThisMonth: newOrgsThisMonth,
        byPlan: Object.fromEntries(orgsByPlan.map((p) => [p.plan, p._count])),
      },
      users: {
        total: totalUsers,
        active: activeUsers,
        newThisMonth: newUsersThisMonth,
        byRole: Object.fromEntries(usersByRole.map((r) => [r.role, r._count])),
      },
      analyses: {
        total: totalAnalyses,
        thisMonth: analysesThisMonth,
        successRate:
          completedAnalyses + failedAnalyses > 0
            ? (completedAnalyses / (completedAnalyses + failedAnalyses)) * 100
            : 0,
        averageProcessingTime: avgProcessingTime._avg.processingTimeMs || 0,
      },
      revenue: {
        thisMonth: thisMonthRevenue,
        lastMonth: lastMonthRevenue,
        growth: Math.round(revenueGrowth * 100) / 100,
        mrr: thisMonthRevenue, // Simplified MRR calculation
      },
      tokens: {
        totalConsumed: Math.abs(totalTokensConsumed._sum.amount || 0),
        thisMonth: Math.abs(tokensThisMonth._sum.amount || 0),
        averagePerOrg: totalOrgs > 0 ? Math.abs(totalTokensConsumed._sum.amount || 0) / totalOrgs : 0,
      },
    };
  }

  async getOrganizations(query: OrganizationQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (query.search) {
      where.OR = [
        { name: { contains: query.search, mode: 'insensitive' } },
        { slug: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    if (query.plan) {
      where.plan = query.plan;
    }

    const orderBy: any = {};
    if (query.sortBy) {
      orderBy[query.sortBy] = query.sortOrder || 'desc';
    } else {
      orderBy.createdAt = 'desc';
    }

    const [organizations, total] = await Promise.all([
      this.prisma.organization.findMany({
        where,
        orderBy,
        skip,
        take: limit,
        include: {
          _count: {
            select: {
              users: true,
              horses: true,
              analysisSessions: true,
            },
          },
        },
      }),
      this.prisma.organization.count({ where }),
    ]);

    return {
      data: organizations.map((org) => ({
        id: org.id,
        name: org.name,
        slug: org.slug,
        plan: org.plan,
        tokenBalance: org.tokenBalance,
        createdAt: org.createdAt,
        counts: org._count,
        settings: org.settings,
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getOrganization(id: string) {
    const org = await this.prisma.organization.findUnique({
      where: { id },
      include: {
        users: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            role: true,
            isActive: true,
            createdAt: true,
            lastLoginAt: true,
          },
        },
        _count: {
          select: {
            horses: true,
            riders: true,
            analysisSessions: true,
            reports: true,
            invoices: true,
          },
        },
      },
    });

    if (!org) {
      throw new NotFoundException('Organization not found');
    }

    // Get recent activity
    const recentAnalyses = await this.prisma.analysisSession.findMany({
      where: { organizationId: id },
      orderBy: { createdAt: 'desc' },
      take: 5,
      select: {
        id: true,
        title: true,
        status: true,
        createdAt: true,
      },
    });

    return {
      ...org,
      recentAnalyses,
    };
  }

  async updateOrganization(id: string, dto: UpdateOrganizationDto) {
    const org = await this.prisma.organization.findUnique({ where: { id } });

    if (!org) {
      throw new NotFoundException('Organization not found');
    }

    return this.prisma.organization.update({
      where: { id },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.plan && { plan: dto.plan }),
        ...(dto.tokenBalance !== undefined && { tokenBalance: dto.tokenBalance }),
      },
    });
  }

  async getUsers(query: UserQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (query.search) {
      where.OR = [
        { email: { contains: query.search, mode: 'insensitive' } },
        { firstName: { contains: query.search, mode: 'insensitive' } },
        { lastName: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    if (query.role) {
      where.role = query.role;
    }

    if (query.organizationId) {
      where.organizationId = query.organizationId;
    }

    if (query.active !== undefined) {
      where.isActive = query.active;
    }

    const orderBy: any = {};
    if (query.sortBy) {
      orderBy[query.sortBy] = query.sortOrder || 'desc';
    } else {
      orderBy.createdAt = 'desc';
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        orderBy,
        skip,
        take: limit,
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          role: true,
          isActive: true,
          emailVerified: true,
          createdAt: true,
          lastLoginAt: true,
          organization: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: users,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getUser(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        organization: {
          select: {
            id: true,
            name: true,
            plan: true,
          },
        },
        createdAnalyses: {
          orderBy: { createdAt: 'desc' },
          take: 10,
          select: {
            id: true,
            title: true,
            status: true,
            createdAt: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const { passwordHash, twoFactorSecret, ...userData } = user;
    return userData;
  }

  async updateUser(id: string, dto: UpdateUserDto) {
    const user = await this.prisma.user.findUnique({ where: { id } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.role && { role: dto.role }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
        ...(dto.emailVerified !== undefined && { emailVerified: dto.emailVerified }),
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        isActive: true,
        emailVerified: true,
      },
    });
  }

  async getRecentActivity(range: DateRangeDto) {
    const from = range.from ? new Date(range.from) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const to = range.to ? new Date(range.to) : new Date();

    const [analyses, reports, users, invoices] = await Promise.all([
      this.prisma.analysisSession.findMany({
        where: { createdAt: { gte: from, lte: to } },
        orderBy: { createdAt: 'desc' },
        take: 50,
        select: {
          id: true,
          title: true,
          status: true,
          createdAt: true,
          organization: { select: { name: true } },
        },
      }),
      this.prisma.report.findMany({
        where: { createdAt: { gte: from, lte: to } },
        orderBy: { createdAt: 'desc' },
        take: 50,
        select: {
          id: true,
          reportNumber: true,
          status: true,
          createdAt: true,
          organization: { select: { name: true } },
        },
      }),
      this.prisma.user.findMany({
        where: { createdAt: { gte: from, lte: to } },
        orderBy: { createdAt: 'desc' },
        take: 50,
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          createdAt: true,
          organization: { select: { name: true } },
        },
      }),
      this.prisma.invoice.findMany({
        where: { createdAt: { gte: from, lte: to } },
        orderBy: { createdAt: 'desc' },
        take: 50,
        select: {
          id: true,
          invoiceNumber: true,
          amount: true,
          status: true,
          createdAt: true,
          organization: { select: { name: true } },
        },
      }),
    ]);

    return {
      analyses,
      reports,
      users,
      invoices,
    };
  }

  async getTopOrganizations(limit: number = 10) {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const orgs = await this.prisma.organization.findMany({
      take: limit,
      orderBy: {
        analysisSessions: {
          _count: 'desc',
        },
      },
      include: {
        _count: {
          select: {
            analysisSessions: true,
            users: true,
          },
        },
      },
    });

    return orgs.map((org) => ({
      id: org.id,
      name: org.name,
      plan: org.plan,
      tokenBalance: org.tokenBalance,
      analysisCount: org._count.analysisSessions,
      userCount: org._count.users,
    }));
  }
}
