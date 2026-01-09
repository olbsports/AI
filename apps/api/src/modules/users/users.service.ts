import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';

interface CreateUserData {
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  organizationName: string;
}

// SECURITY: Fields to exclude from user responses
const SENSITIVE_FIELDS = ['passwordHash', 'twoFactorSecret'] as const;

// Helper to remove sensitive fields from user object
function sanitizeUser<T extends Record<string, any>>(user: T | null): Omit<T, typeof SENSITIVE_FIELDS[number]> | null {
  if (!user) return null;
  const { passwordHash, twoFactorSecret, ...safeUser } = user;
  return safeUser as any;
}

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { organization: true },
    });

    return sanitizeUser(user);
  }

  // Internal method that returns full user (including passwordHash) - for auth only
  async findByIdInternal(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
      include: { organization: true },
    });
  }

  async findByEmail(email: string) {
    // This is used for auth, so we need passwordHash
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

    return sanitizeUser(user);
  }

  async update(id: string, data: Partial<{
    firstName: string;
    lastName: string;
    avatarUrl: string;
    preferences: any;
  }>) {
    const user = await this.prisma.user.update({
      where: { id },
      data,
      include: { organization: true },
    });
    return sanitizeUser(user);
  }

  async findByOrganization(organizationId: string) {
    const users = await this.prisma.user.findMany({
      where: { organizationId },
      orderBy: { createdAt: 'desc' },
    });
    // SECURITY: Remove sensitive fields from all users
    return users.map(u => sanitizeUser(u));
  }
}
