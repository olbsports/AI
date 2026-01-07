import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { CreateRiderDto } from './dto/create-rider.dto';
import { UpdateRiderDto } from './dto/update-rider.dto';
import { calculatePagination, calculateOffset } from '@horse-vision/types';

@Injectable()
export class RidersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploadService: UploadService
  ) {}

  async findAll(
    organizationId: string,
    params: {
      page?: number;
      pageSize?: number;
      search?: string;
      discipline?: string;
      level?: string;
    }
  ) {
    const page = params.page ?? 1;
    const pageSize = params.pageSize ?? 20;
    const offset = calculateOffset(page, pageSize);

    const where: any = { organizationId };

    if (params.search) {
      where.OR = [
        { firstName: { contains: params.search, mode: 'insensitive' } },
        { lastName: { contains: params.search, mode: 'insensitive' } },
        { email: { contains: params.search, mode: 'insensitive' } },
        { federationId: { contains: params.search, mode: 'insensitive' } },
      ];
    }

    if (params.discipline) {
      where.discipline = params.discipline;
    }

    if (params.level) {
      where.level = params.level;
    }

    const [items, totalItems] = await Promise.all([
      this.prisma.rider.findMany({
        where,
        skip: offset,
        take: pageSize,
        orderBy: { lastName: 'asc' },
        include: {
          horses: {
            select: {
              id: true,
              name: true,
              photoUrl: true,
            },
          },
          _count: {
            select: {
              horses: true,
              analysisSessions: true,
            },
          },
        },
      }),
      this.prisma.rider.count({ where }),
    ]);

    return {
      items,
      pagination: calculatePagination(totalItems, page, pageSize),
    };
  }

  async findById(id: string, organizationId: string) {
    const rider = await this.prisma.rider.findFirst({
      where: { id, organizationId },
      include: {
        horses: true,
        analysisSessions: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: {
            horse: { select: { id: true, name: true } },
          },
        },
        _count: {
          select: {
            horses: true,
            analysisSessions: true,
          },
        },
      },
    });

    if (!rider) {
      throw new NotFoundException('Rider not found');
    }

    return rider;
  }

  async create(organizationId: string, data: CreateRiderDto) {
    return this.prisma.rider.create({
      data: {
        ...data,
        organizationId,
      },
      include: {
        horses: true,
      },
    });
  }

  async update(id: string, organizationId: string, data: UpdateRiderDto) {
    await this.findById(id, organizationId);

    return this.prisma.rider.update({
      where: { id },
      data,
      include: {
        horses: true,
      },
    });
  }

  async delete(id: string, organizationId: string) {
    await this.findById(id, organizationId);

    return this.prisma.rider.delete({
      where: { id },
    });
  }

  async assignHorse(id: string, organizationId: string, horseId: string) {
    await this.findById(id, organizationId);

    // Verify horse belongs to organization
    const horse = await this.prisma.horse.findFirst({
      where: { id: horseId, organizationId },
    });

    if (!horse) {
      throw new NotFoundException('Horse not found');
    }

    return this.prisma.horse.update({
      where: { id: horseId },
      data: { riderId: id },
    });
  }

  async unassignHorse(id: string, organizationId: string, horseId: string) {
    await this.findById(id, organizationId);

    const horse = await this.prisma.horse.findFirst({
      where: { id: horseId, organizationId, riderId: id },
    });

    if (!horse) {
      throw new NotFoundException('Horse not assigned to this rider');
    }

    return this.prisma.horse.update({
      where: { id: horseId },
      data: { riderId: null },
    });
  }

  async getStats(id: string, organizationId: string) {
    const rider = await this.findById(id, organizationId);

    const [analysisStats, recentPerformance] = await Promise.all([
      this.prisma.analysisSession.groupBy({
        by: ['type'],
        where: { riderId: id },
        _count: true,
      }),
      this.prisma.analysisSession.findMany({
        where: {
          riderId: id,
          status: 'completed',
          scores: { not: null },
        },
        take: 10,
        orderBy: { completedAt: 'desc' },
        select: {
          id: true,
          type: true,
          scores: true,
          completedAt: true,
          horse: { select: { name: true } },
        },
      }),
    ]);

    return {
      rider: {
        id: rider.id,
        firstName: rider.firstName,
        lastName: rider.lastName,
      },
      totalHorses: rider._count.horses,
      totalAnalyses: rider._count.analysisSessions,
      analysisByType: analysisStats,
      recentPerformance,
    };
  }

  async uploadPhoto(id: string, organizationId: string, file: any) {
    const rider = await this.findById(id, organizationId);

    // Delete old photo if exists
    if (rider.photoUrl) {
      try {
        const urlParts = rider.photoUrl.split('/');
        const key = urlParts.slice(3).join('/');
        await this.uploadService.deleteFile(key);
      } catch {
        // Ignore delete errors
      }
    }

    // Upload new photo
    const { url } = await this.uploadService.uploadFile(organizationId, 'avatars', file);

    // Update rider with new photo URL
    return this.prisma.rider.update({
      where: { id },
      data: { photoUrl: url },
    });
  }

  async deletePhoto(id: string, organizationId: string) {
    const rider = await this.findById(id, organizationId);

    if (rider.photoUrl) {
      try {
        const urlParts = rider.photoUrl.split('/');
        const key = urlParts.slice(3).join('/');
        await this.uploadService.deleteFile(key);
      } catch {
        // Ignore delete errors
      }
    }

    return this.prisma.rider.update({
      where: { id },
      data: { photoUrl: null },
    });
  }
}
