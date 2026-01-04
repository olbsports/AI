import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';

interface CreateUserData {
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  organizationName: string;
}

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { organization: true },
    });

    return user;
  }

  async findByEmail(email: string) {
    return this.prisma.user.findUnique({
      where: { email },
      include: { organization: true },
    });
  }

  async create(data: CreateUserData) {
    const existingUser = await this.findByEmail(data.email);
    if (existingUser) {
      throw new ConflictException('Email already registered');
    }

    // Create organization first
    const organization = await this.prisma.organization.create({
      data: {
        name: data.organizationName,
        plan: 'starter',
        tokenBalance: 100, // Initial free tokens
      },
    });

    // Create user as owner
    const user = await this.prisma.user.create({
      data: {
        email: data.email,
        passwordHash: data.passwordHash,
        firstName: data.firstName,
        lastName: data.lastName,
        role: 'owner',
        organizationId: organization.id,
      },
      include: { organization: true },
    });

    return user;
  }

  async update(id: string, data: Partial<{
    firstName: string;
    lastName: string;
    avatarUrl: string;
    preferences: any;
  }>) {
    return this.prisma.user.update({
      where: { id },
      data,
      include: { organization: true },
    });
  }

  async findByOrganization(organizationId: string) {
    return this.prisma.user.findMany({
      where: { organizationId },
      orderBy: { createdAt: 'desc' },
    });
  }
}
