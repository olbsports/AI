import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateHorseDto } from './dto/create-horse.dto';
import { UpdateHorseDto } from './dto/update-horse.dto';
import { calculatePagination, calculateOffset } from '@horse-vision/types';

@Injectable()
export class HorsesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(
    organizationId: string,
    params: {
      page?: number;
      pageSize?: number;
      search?: string;
      status?: string;
      gender?: string;
    },
  ) {
    const page = params.page ?? 1;
    const pageSize = params.pageSize ?? 20;
    const offset = calculateOffset(page, pageSize);

    const where: any = { organizationId };

    if (params.search) {
      where.OR = [
        { name: { contains: params.search, mode: 'insensitive' } },
        { sireId: { contains: params.search, mode: 'insensitive' } },
      ];
    }

    if (params.status) {
      where.status = params.status;
    }

    if (params.gender) {
      where.gender = params.gender;
    }

    const [items, totalItems] = await Promise.all([
      this.prisma.horse.findMany({
        where,
        skip: offset,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
        include: { rider: true },
      }),
      this.prisma.horse.count({ where }),
    ]);

    return {
      items,
      pagination: calculatePagination(totalItems, page, pageSize),
    };
  }

  async findById(id: string, organizationId: string) {
    const horse = await this.prisma.horse.findFirst({
      where: { id, organizationId },
      include: { rider: true },
    });

    if (!horse) {
      throw new NotFoundException('Horse not found');
    }

    return horse;
  }

  async create(organizationId: string, data: CreateHorseDto) {
    return this.prisma.horse.create({
      data: {
        ...data,
        organizationId,
      },
    });
  }

  async update(id: string, organizationId: string, data: UpdateHorseDto) {
    await this.findById(id, organizationId);

    return this.prisma.horse.update({
      where: { id },
      data,
    });
  }

  async delete(id: string, organizationId: string) {
    await this.findById(id, organizationId);

    return this.prisma.horse.delete({
      where: { id },
    });
  }

  async archive(id: string, organizationId: string) {
    await this.findById(id, organizationId);

    return this.prisma.horse.update({
      where: { id },
      data: { status: 'retired' },
    });
  }
}
