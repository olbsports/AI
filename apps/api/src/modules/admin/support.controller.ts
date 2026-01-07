import { Controller, Get, Post, Put, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { PrismaService } from '../../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('support')
@Controller('support')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('owner')
@ApiBearerAuth()
export class SupportController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('tickets')
  @ApiOperation({ summary: 'Get all support tickets' })
  async getTickets(@Query('status') status?: string) {
    try {
      const where: any = {};
      if (status) {
        where.status = status;
      }

      const tickets = await this.prisma.supportTicket.findMany({
        where,
        include: {
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
            },
          },
          assignee: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      return tickets.map((ticket) => ({
        id: ticket.id,
        userId: ticket.userId,
        userName: `${ticket.user.firstName} ${ticket.user.lastName}`,
        userEmail: ticket.user.email,
        subject: ticket.subject,
        description: ticket.description,
        category: ticket.category,
        priority: ticket.priority,
        status: ticket.status,
        assigneeId: ticket.assigneeId,
        assigneeName: ticket.assignee
          ? `${ticket.assignee.firstName} ${ticket.assignee.lastName}`
          : null,
        messages: [],
        createdAt: ticket.createdAt,
        resolvedAt: ticket.resolvedAt,
        responseCount: 0,
      }));
    } catch {
      return [];
    }
  }

  @Get('tickets/open-count')
  @ApiOperation({ summary: 'Get open tickets count' })
  async getOpenCount() {
    try {
      const count = await this.prisma.supportTicket.count({
        where: { status: { in: ['open', 'in_progress'] } },
      });
      return { count };
    } catch {
      return { count: 0 };
    }
  }

  @Get('tickets/:id')
  @ApiOperation({ summary: 'Get ticket details' })
  async getTicket(@Param('id') id: string) {
    try {
      const ticket = await this.prisma.supportTicket.findUnique({
        where: { id },
        include: {
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
            },
          },
          assignee: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
            },
          },
          messages: {
            include: {
              author: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                  role: true,
                },
              },
            },
            orderBy: { createdAt: 'asc' },
          },
        },
      });

      if (!ticket) {
        return null;
      }

      return {
        id: ticket.id,
        userId: ticket.userId,
        userName: `${ticket.user.firstName} ${ticket.user.lastName}`,
        userEmail: ticket.user.email,
        subject: ticket.subject,
        description: ticket.description,
        category: ticket.category,
        priority: ticket.priority,
        status: ticket.status,
        assigneeId: ticket.assigneeId,
        assigneeName: ticket.assignee
          ? `${ticket.assignee.firstName} ${ticket.assignee.lastName}`
          : null,
        messages: ticket.messages.map((msg: any) => ({
          id: msg.id,
          authorId: msg.authorId,
          authorName: `${msg.author.firstName} ${msg.author.lastName}`,
          isStaff: msg.author.role === 'owner' || msg.author.role === 'admin',
          content: msg.content,
          attachments: msg.attachments || [],
          createdAt: msg.createdAt,
        })),
        createdAt: ticket.createdAt,
        resolvedAt: ticket.resolvedAt,
        responseCount: ticket.messages.length,
      };
    } catch {
      return null;
    }
  }

  @Put('tickets/:id/assign')
  @ApiOperation({ summary: 'Assign ticket to staff member' })
  async assignTicket(@Param('id') id: string, @Body() body: { assigneeId: string }) {
    try {
      await this.prisma.supportTicket.update({
        where: { id },
        data: {
          assigneeId: body.assigneeId,
          status: 'in_progress',
        },
      });
      return { success: true };
    } catch {
      return { success: false, error: 'Failed to assign ticket' };
    }
  }

  @Post('tickets/:id/reply')
  @ApiOperation({ summary: 'Reply to a ticket' })
  async replyToTicket(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { message: string }
  ) {
    try {
      await this.prisma.ticketMessage.create({
        data: {
          ticketId: id,
          authorId: user.id,
          content: body.message,
        },
      });

      await this.prisma.supportTicket.update({
        where: { id },
        data: { status: 'in_progress' },
      });

      return { success: true };
    } catch {
      return { success: false, error: 'Failed to send reply' };
    }
  }

  @Put('tickets/:id/close')
  @ApiOperation({ summary: 'Close a ticket' })
  async closeTicket(@Param('id') id: string) {
    try {
      await this.prisma.supportTicket.update({
        where: { id },
        data: {
          status: 'closed',
          resolvedAt: new Date(),
        },
      });
      return { success: true };
    } catch {
      return { success: false, error: 'Failed to close ticket' };
    }
  }
}
