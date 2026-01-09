import { Controller, Get, Put, Delete, Post, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { PrismaService } from '../../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('users')
@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin', 'owner')
@ApiBearerAuth()
export class UsersAdminController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'Get all users (paginated)' })
  async getUsers(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
    @Query('status') status?: string,
    @Query('plan') plan?: string,
    @Query('sortBy') sortBy?: string,
    @Query('sortDir') sortDir?: string
  ) {
    const pageNum = page ? parseInt(page) : 1;
    const limitNum = limit ? parseInt(limit) : 25;
    const skip = (pageNum - 1) * limitNum;

    const where: any = {};

    if (search) {
      where.OR = [
        { email: { contains: search } },
        { firstName: { contains: search } },
        { lastName: { contains: search } },
      ];
    }

    if (status === 'active') {
      where.isActive = true;
    } else if (status === 'inactive') {
      where.isActive = false;
    }

    const orderBy: any = {};
    if (sortBy) {
      orderBy[sortBy] = sortDir || 'desc';
    } else {
      orderBy.createdAt = 'desc';
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        orderBy,
        skip,
        take: limitNum,
        include: {
          organization: {
            select: {
              id: true,
              name: true,
              plan: true,
            },
          },
          _count: {
            select: {
              ownedHorses: true,
              createdAnalyses: true,
            },
          },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      users: users.map((user) => ({
        id: user.id,
        email: user.email,
        name: `${user.firstName} ${user.lastName}`,
        photoUrl: user.avatarUrl,
        phone: user.phone,
        status: user.isActive ? 'active' : 'inactive',
        subscriptionPlan: user.organization?.plan,
        horseCount: user._count.ownedHorses,
        analysisCount: user._count.createdAnalyses,
        loginCount: 0,
        createdAt: user.createdAt,
        lastActiveAt: user.lastLoginAt,
        isVerified: user.emailVerified,
        flags: [],
      })),
      total,
      page: pageNum,
      totalPages: Math.ceil(total / limitNum),
    };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get user details' })
  async getUser(@Param('id') id: string) {
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
        _count: {
          select: {
            ownedHorses: true,
            createdAnalyses: true,
          },
        },
      },
    });

    if (!user) {
      return null;
    }

    return {
      id: user.id,
      email: user.email,
      name: `${user.firstName} ${user.lastName}`,
      photoUrl: user.avatarUrl,
      phone: user.phone,
      status: user.isActive ? 'active' : 'inactive',
      subscriptionPlan: user.organization?.plan,
      horseCount: user._count.ownedHorses,
      analysisCount: user._count.createdAnalyses,
      loginCount: 0,
      createdAt: user.createdAt,
      lastActiveAt: user.lastLoginAt,
      isVerified: user.emailVerified,
      flags: [],
    };
  }

  @Get(':id/activity')
  @ApiOperation({ summary: 'Get user activity log' })
  async getUserActivity(@Param('id') id: string) {
    const logs = await this.prisma.auditLog.findMany({
      where: { actorId: id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return logs;
  }

  @Put(':id/status')
  @ApiOperation({ summary: 'Update user status' })
  async updateUserStatus(
    @Param('id') id: string,
    @Body() body: { status: string; reason?: string }
  ) {
    const updateData: any = {};

    switch (body.status) {
      case 'active':
        updateData.isActive = true;
        break;
      case 'inactive':
        updateData.isActive = false;
        break;
    }

    await this.prisma.user.update({
      where: { id },
      data: updateData,
    });

    return { success: true };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete user' })
  async deleteUser(@Param('id') id: string) {
    await this.prisma.user.delete({ where: { id } });
    return { success: true };
  }

  @Post(':id/impersonate')
  @ApiOperation({ summary: 'Impersonate user (get their token)' })
  async impersonateUser(@Param('id') id: string) {
    // This would need proper JWT generation
    // For now, return a placeholder
    return { token: null, message: 'Impersonation not implemented' };
  }
}
