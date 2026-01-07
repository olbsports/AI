import { Controller, Get, Post, Param, Body, Query, UseGuards, Delete } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { PrismaService } from '../../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('moderation')
@Controller('moderation')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('owner')
@ApiBearerAuth()
export class ModerationController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('reports')
  @ApiOperation({ summary: 'Get all content reports' })
  async getReports(@Query('status') status?: string) {
    const where: any = {};
    if (status) {
      where.status = status;
    }

    const reports = await this.prisma.userReport.findMany({
      where,
      include: {
        reporter: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        reportedUser: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        reportedPost: {
          select: {
            id: true,
            content: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return reports.map((report) => ({
      id: report.id,
      contentType: report.type,
      contentId: report.reportedPostId || report.reportedUserId,
      contentPreview: report.reportedPost?.content?.substring(0, 100),
      reporterId: report.reporterId,
      reporterName: `${report.reporter.firstName} ${report.reporter.lastName}`,
      reportReason: report.reason,
      reportDetails: report.details,
      status: report.status,
      moderatorId: report.moderatorId,
      moderatorNotes: report.moderatorNotes,
      actionTaken: report.actionTaken,
      createdAt: report.createdAt,
      resolvedAt: report.resolvedAt,
    }));
  }

  @Get('reports/pending-count')
  @ApiOperation({ summary: 'Get pending reports count' })
  async getPendingCount() {
    const count = await this.prisma.userReport.count({
      where: { status: 'pending' },
    });
    return { count };
  }

  @Get('reports/:id')
  @ApiOperation({ summary: 'Get report details' })
  async getReport(@Param('id') id: string) {
    const report = await this.prisma.userReport.findUnique({
      where: { id },
      include: {
        reporter: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        reportedUser: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        reportedPost: true,
      },
    });

    if (!report) {
      return null;
    }

    return {
      id: report.id,
      contentType: report.type,
      contentId: report.reportedPostId || report.reportedUserId,
      contentPreview: report.reportedPost?.content,
      reporterId: report.reporterId,
      reporterName: `${report.reporter.firstName} ${report.reporter.lastName}`,
      reportReason: report.reason,
      reportDetails: report.details,
      status: report.status,
      moderatorId: report.moderatorId,
      moderatorNotes: report.moderatorNotes,
      actionTaken: report.actionTaken,
      createdAt: report.createdAt,
      resolvedAt: report.resolvedAt,
    };
  }

  @Post('reports/:id/resolve')
  @ApiOperation({ summary: 'Resolve a report' })
  async resolveReport(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { action: string; notes?: string }
  ) {
    const report = await this.prisma.userReport.update({
      where: { id },
      data: {
        status: 'resolved',
        actionTaken: body.action,
        moderatorId: user.id,
        moderatorNotes: body.notes,
        resolvedAt: new Date(),
      },
    });

    // If action is to delete the content, do it
    if (body.action === 'deleted' && report.reportedPostId) {
      await this.prisma.socialPost
        .delete({
          where: { id: report.reportedPostId },
        })
        .catch(() => {});
    }

    return { success: true };
  }

  @Delete('content/:type/:id')
  @ApiOperation({ summary: 'Delete content' })
  async deleteContent(@Param('type') type: string, @Param('id') id: string) {
    switch (type) {
      case 'note':
      case 'post':
        await this.prisma.socialPost.delete({ where: { id } }).catch(() => {});
        break;
      case 'comment':
        await this.prisma.comment.delete({ where: { id } }).catch(() => {});
        break;
      case 'listing':
        await this.prisma.marketplaceListing.delete({ where: { id } }).catch(() => {});
        break;
    }

    return { success: true };
  }
}
