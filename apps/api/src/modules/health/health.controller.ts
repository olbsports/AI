import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

import { PrismaService } from '@/prisma/prisma.service';
import { Public } from '../auth/decorators/public.decorator';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @Public()
  @ApiOperation({ summary: 'Health check' })
  async check() {
    const services = {
      database: 'ok' as const,
      redis: 'ok' as const,
      storage: 'ok' as const,
    };

    // Check database
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      services.database = 'error' as const;
    }

    // TODO: Check Redis and Storage

    const allOk = Object.values(services).every((s) => s === 'ok');

    return {
      status: allOk ? 'ok' : 'degraded',
      version: process.env.npm_package_version ?? '0.1.0',
      timestamp: new Date().toISOString(),
      services,
    };
  }

  @Get('live')
  @Public()
  @ApiOperation({ summary: 'Liveness probe' })
  async live() {
    return { status: 'ok' };
  }

  @Get('ready')
  @Public()
  @ApiOperation({ summary: 'Readiness probe' })
  async ready() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return { status: 'ok' };
    } catch {
      return { status: 'error' };
    }
  }
}
