import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateAnalysisDto } from './dto/create-analysis.dto';
import { calculatePagination, calculateOffset } from '@horse-vision/types';
import { calculateTokenCost, hasEnoughTokens } from '@horse-vision/core';

@Injectable()
export class AnalysisService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(
    organizationId: string,
    params: {
      page?: number;
      pageSize?: number;
      type?: string;
      status?: string;
      horseId?: string;
    }
  ) {
    const page = params.page ?? 1;
    const pageSize = params.pageSize ?? 20;
    const offset = calculateOffset(page, pageSize);

    const where: any = { organizationId };

    if (params.type) where.type = params.type;
    if (params.status) where.status = params.status;
    if (params.horseId) where.horseId = params.horseId;

    const [items, totalItems] = await Promise.all([
      this.prisma.analysisSession.findMany({
        where,
        skip: offset,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
        include: { horse: true, rider: true },
      }),
      this.prisma.analysisSession.count({ where }),
    ]);

    return {
      items,
      pagination: calculatePagination(totalItems, page, pageSize),
    };
  }

  async findById(id: string, organizationId: string) {
    const analysis = await this.prisma.analysisSession.findFirst({
      where: { id, organizationId },
      include: { horse: true, rider: true, report: true },
    });

    if (!analysis) {
      throw new NotFoundException('Analysis not found');
    }

    return analysis;
  }

  async create(organizationId: string, userId: string, data: CreateAnalysisDto) {
    // Check token balance
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const tokenCost = calculateTokenCost(data.type as any);

    if (!hasEnoughTokens(organization.tokenBalance, data.type as any)) {
      throw new BadRequestException('Insufficient tokens');
    }

    // Create analysis session
    const analysis = await this.prisma.analysisSession.create({
      data: {
        type: data.type,
        title: data.title,
        horseId: data.horseId,
        riderId: data.riderId,
        competition: data.competition as any,
        inputMediaUrls: data.inputMediaUrls,
        organizationId,
        createdById: userId,
        status: 'pending',
        tokensConsumed: tokenCost,
      },
    });

    // Deduct tokens
    await this.prisma.organization.update({
      where: { id: organizationId },
      data: {
        tokenBalance: { decrement: tokenCost },
      },
    });

    // TODO: Queue analysis job

    return analysis;
  }

  async cancel(id: string, organizationId: string) {
    const analysis = await this.findById(id, organizationId);

    if (!['pending', 'processing'].includes(analysis.status)) {
      throw new BadRequestException('Cannot cancel completed analysis');
    }

    // Refund tokens if pending
    if (analysis.status === 'pending') {
      await this.prisma.organization.update({
        where: { id: organizationId },
        data: {
          tokenBalance: { increment: analysis.tokensConsumed },
        },
      });
    }

    return this.prisma.analysisSession.update({
      where: { id },
      data: { status: 'cancelled' },
    });
  }

  async updateStatus(id: string, status: string, results?: any) {
    const data: any = { status };

    if (status === 'processing') {
      data.startedAt = new Date();
    }

    if (status === 'completed') {
      data.completedAt = new Date();
      if (results) {
        data.scores = results.scores;
        data.obstacles = results.obstacles;
        data.issues = results.issues;
        data.recommendations = results.recommendations;
        data.aiAnalysis = results.aiAnalysis;
        data.confidenceScore = results.confidenceScore;
      }
    }

    if (status === 'failed') {
      data.errorMessage = results?.errorMessage;
    }

    return this.prisma.analysisSession.update({
      where: { id },
      data,
    });
  }

  async delete(id: string, organizationId: string) {
    const analysis = await this.findById(id, organizationId);

    // Refund tokens if not completed
    if (analysis.status === 'pending') {
      await this.prisma.organization.update({
        where: { id: organizationId },
        data: {
          tokenBalance: { increment: analysis.tokensConsumed },
        },
      });
    }

    return this.prisma.analysisSession.delete({
      where: { id },
    });
  }

  async retry(id: string, organizationId: string, userId: string) {
    const analysis = await this.findById(id, organizationId);

    if (analysis.status !== 'failed') {
      throw new BadRequestException('Can only retry failed analyses');
    }

    // Check token balance
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    const tokenCost = calculateTokenCost(analysis.type as any);

    if (!hasEnoughTokens(organization.tokenBalance, analysis.type as any)) {
      throw new BadRequestException('Insufficient tokens');
    }

    // Deduct tokens
    await this.prisma.organization.update({
      where: { id: organizationId },
      data: {
        tokenBalance: { decrement: tokenCost },
      },
    });

    // Reset analysis to pending
    const updatedAnalysis = await this.prisma.analysisSession.update({
      where: { id },
      data: {
        status: 'pending',
        errorMessage: null,
        startedAt: null,
        completedAt: null,
        tokensConsumed: tokenCost,
      },
    });

    // TODO: Queue analysis job

    return updatedAnalysis;
  }
}
