import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { CreateHorseDto } from './dto/create-horse.dto';
import { UpdateHorseDto } from './dto/update-horse.dto';
import { calculatePagination, calculateOffset } from '@horse-vision/types';

@Injectable()
export class HorsesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploadService: UploadService,
  ) {}

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

  async uploadPhoto(id: string, organizationId: string, file: Express.Multer.File) {
    const horse = await this.findById(id, organizationId);

    // Delete old photo if exists
    if (horse.photoUrl) {
      try {
        // Extract key from URL
        const urlParts = horse.photoUrl.split('/');
        const key = urlParts.slice(3).join('/');
        await this.uploadService.deleteFile(key);
      } catch {
        // Ignore delete errors
      }
    }

    // Upload new photo
    const { url } = await this.uploadService.uploadFile(
      organizationId,
      'avatars', // Use avatars category for horse photos
      file,
    );

    // Update horse with new photo URL
    return this.prisma.horse.update({
      where: { id },
      data: { photoUrl: url },
    });
  }

  async deletePhoto(id: string, organizationId: string) {
    const horse = await this.findById(id, organizationId);

    if (horse.photoUrl) {
      try {
        const urlParts = horse.photoUrl.split('/');
        const key = urlParts.slice(3).join('/');
        await this.uploadService.deleteFile(key);
      } catch {
        // Ignore delete errors
      }
    }

    return this.prisma.horse.update({
      where: { id },
      data: { photoUrl: null },
    });
  }
}
