import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';

const MAX_SESSIONS_PER_USER = 5;

interface CreateSessionDto {
  userId: string;
  deviceId: string;
  deviceName?: string;
  platform?: string;
  ipAddress?: string;
  userAgent?: string;
}

interface SessionInfo {
  id: string;
  deviceId: string;
  deviceName: string | null;
  platform: string | null;
  ipAddress: string | null;
  lastActiveAt: Date;
  createdAt: Date;
  isCurrent?: boolean;
}

@Injectable()
export class SessionTrackingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService
  ) {}

  /**
   * Create or update a user session
   * Enforces maximum 5 active sessions per user
   */
  async createOrUpdateSession(dto: CreateSessionDto): Promise<SessionInfo> {
    const { userId, deviceId, deviceName, platform, ipAddress, userAgent } = dto;

    // Calculate session expiry (default 30 days)
    const sessionDurationDays = this.configService.get('SESSION_DURATION_DAYS', 30);
    const expiresAt = new Date(Date.now() + sessionDurationDays * 24 * 60 * 60 * 1000);

    // Try to find existing session for this device
    const existingSession = await this.prisma.userSession.findUnique({
      where: {
        userId_deviceId: { userId, deviceId },
      },
    });

    if (existingSession && !existingSession.isRevoked) {
      // Update existing session
      const updated = await this.prisma.userSession.update({
        where: { id: existingSession.id },
        data: {
          lastActiveAt: new Date(),
          expiresAt,
          ipAddress,
          userAgent,
          deviceName: deviceName || existingSession.deviceName,
          platform: platform || existingSession.platform,
        },
      });

      return this.mapToSessionInfo(updated);
    }

    // Check active session count
    const activeSessionCount = await this.prisma.userSession.count({
      where: {
        userId,
        isRevoked: false,
        expiresAt: { gt: new Date() },
      },
    });

    if (activeSessionCount >= MAX_SESSIONS_PER_USER) {
      // Revoke oldest session to make room
      const oldestSession = await this.prisma.userSession.findFirst({
        where: {
          userId,
          isRevoked: false,
          expiresAt: { gt: new Date() },
        },
        orderBy: { lastActiveAt: 'asc' },
      });

      if (oldestSession) {
        await this.prisma.userSession.update({
          where: { id: oldestSession.id },
          data: {
            isRevoked: true,
            revokedAt: new Date(),
          },
        });
      }
    }

    // Create new session (upsert to handle race conditions)
    const session = await this.prisma.userSession.upsert({
      where: {
        userId_deviceId: { userId, deviceId },
      },
      update: {
        lastActiveAt: new Date(),
        expiresAt,
        ipAddress,
        userAgent,
        deviceName,
        platform,
        isRevoked: false,
        revokedAt: null,
      },
      create: {
        userId,
        deviceId,
        deviceName,
        platform,
        ipAddress,
        userAgent,
        expiresAt,
      },
    });

    return this.mapToSessionInfo(session);
  }

  /**
   * Get all active sessions for a user
   */
  async getUserSessions(userId: string, currentDeviceId?: string): Promise<SessionInfo[]> {
    const sessions = await this.prisma.userSession.findMany({
      where: {
        userId,
        isRevoked: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { lastActiveAt: 'desc' },
    });

    return sessions.map((session) => ({
      ...this.mapToSessionInfo(session),
      isCurrent: currentDeviceId ? session.deviceId === currentDeviceId : undefined,
    }));
  }

  /**
   * Revoke a specific session
   */
  async revokeSession(userId: string, sessionId: string): Promise<{ success: boolean }> {
    const session = await this.prisma.userSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      throw new NotFoundException('Session not found');
    }

    if (session.userId !== userId) {
      throw new ForbiddenException('Cannot revoke session belonging to another user');
    }

    if (session.isRevoked) {
      throw new BadRequestException('Session is already revoked');
    }

    await this.prisma.userSession.update({
      where: { id: sessionId },
      data: {
        isRevoked: true,
        revokedAt: new Date(),
      },
    });

    return { success: true };
  }

  /**
   * Revoke all sessions for a user except the current one
   */
  async revokeAllSessions(
    userId: string,
    exceptDeviceId?: string
  ): Promise<{ revokedCount: number }> {
    const result = await this.prisma.userSession.updateMany({
      where: {
        userId,
        isRevoked: false,
        ...(exceptDeviceId && {
          deviceId: { not: exceptDeviceId },
        }),
      },
      data: {
        isRevoked: true,
        revokedAt: new Date(),
      },
    });

    return { revokedCount: result.count };
  }

  /**
   * Update last active timestamp for a session
   */
  async updateLastActive(userId: string, deviceId: string): Promise<void> {
    await this.prisma.userSession.updateMany({
      where: {
        userId,
        deviceId,
        isRevoked: false,
      },
      data: {
        lastActiveAt: new Date(),
      },
    });
  }

  /**
   * Check if a session is valid
   */
  async isSessionValid(userId: string, deviceId: string): Promise<boolean> {
    const session = await this.prisma.userSession.findUnique({
      where: {
        userId_deviceId: { userId, deviceId },
      },
    });

    if (!session) return false;
    if (session.isRevoked) return false;
    if (session.expiresAt < new Date()) return false;

    return true;
  }

  /**
   * Cleanup expired sessions (can be called by a cron job)
   */
  async cleanupExpiredSessions(): Promise<{ deletedCount: number }> {
    const result = await this.prisma.userSession.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: new Date() } },
          {
            isRevoked: true,
            revokedAt: { lt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }, // 30 days ago
          },
        ],
      },
    });

    return { deletedCount: result.count };
  }

  private mapToSessionInfo(session: any): SessionInfo {
    return {
      id: session.id,
      deviceId: session.deviceId,
      deviceName: session.deviceName,
      platform: session.platform,
      ipAddress: session.ipAddress,
      lastActiveAt: session.lastActiveAt,
      createdAt: session.createdAt,
    };
  }
}
