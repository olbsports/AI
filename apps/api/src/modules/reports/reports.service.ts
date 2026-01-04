import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { calculatePagination, calculateOffset } from '@horse-vision/types';
import { randomBytes } from 'crypto';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(
    organizationId: string,
    params: {
      page?: number;
      pageSize?: number;
      type?: string;
      status?: string;
      horseId?: string;
      category?: string;
    },
  ) {
    const page = params.page ?? 1;
    const pageSize = params.pageSize ?? 20;
    const offset = calculateOffset(page, pageSize);

    const where: any = { organizationId };

    if (params.type) where.type = params.type;
    if (params.status) where.status = params.status;
    if (params.horseId) where.horseId = params.horseId;
    if (params.category) where.category = params.category;

    const [items, totalItems] = await Promise.all([
      this.prisma.report.findMany({
        where,
        skip: offset,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
        include: { horse: true, analysisSession: true },
      }),
      this.prisma.report.count({ where }),
    ]);

    return {
      items,
      pagination: calculatePagination(totalItems, page, pageSize),
    };
  }

  async findById(id: string, organizationId: string) {
    const report = await this.prisma.report.findFirst({
      where: { id, organizationId },
      include: { horse: true, analysisSession: true },
    });

    if (!report) {
      throw new NotFoundException('Report not found');
    }

    return report;
  }

  async findByShareToken(token: string) {
    const report = await this.prisma.report.findFirst({
      where: {
        shareToken: token,
        shareExpiresAt: { gte: new Date() },
      },
      include: { horse: true },
    });

    if (!report) {
      throw new NotFoundException('Report not found or link expired');
    }

    return report;
  }

  async update(id: string, organizationId: string, data: any) {
    await this.findById(id, organizationId);

    return this.prisma.report.update({
      where: { id },
      data,
    });
  }

  async sign(id: string, organizationId: string, userId: string) {
    const report = await this.findById(id, organizationId);

    if (report.status !== 'pending_review') {
      throw new ForbiddenException('Report must be pending review to sign');
    }

    // Generate digital signature (simplified)
    const signature = `SIG-${randomBytes(16).toString('hex').toUpperCase()}`;

    return this.prisma.report.update({
      where: { id },
      data: {
        status: 'completed',
        reviewedById: userId,
        reviewedAt: new Date(),
        digitalSignature: signature,
      },
    });
  }

  async createShareLink(id: string, organizationId: string, expiresInDays = 30) {
    await this.findById(id, organizationId);

    const shareToken = randomBytes(32).toString('hex');
    const shareExpiresAt = new Date();
    shareExpiresAt.setDate(shareExpiresAt.getDate() + expiresInDays);

    const report = await this.prisma.report.update({
      where: { id },
      data: { shareToken, shareExpiresAt },
    });

    return {
      shareUrl: `/reports/shared/${shareToken}`,
      expiresAt: shareExpiresAt.toISOString(),
    };
  }

  async revokeShareLink(id: string, organizationId: string) {
    await this.findById(id, organizationId);

    return this.prisma.report.update({
      where: { id },
      data: { shareToken: null, shareExpiresAt: null },
    });
  }

  async archive(id: string, organizationId: string) {
    await this.findById(id, organizationId);

    return this.prisma.report.update({
      where: { id },
      data: { status: 'archived' },
    });
  }
}
