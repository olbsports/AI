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
    let dbStatus = 'ok';

    try {
      await this.prisma.$queryRawUnsafe('SELECT 1');
    } catch {
      dbStatus = 'error';
    }

    return {
      status: dbStatus === 'ok' ? 'ok' : 'degraded',
      version: '0.1.0',
      timestamp: new Date().toISOString(),
      services: {
        database: dbStatus,
      },
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
      await this.prisma.$queryRawUnsafe('SELECT 1');
      return { status: 'ok' };
    } catch {
      return { status: 'error' };
    }
  }
}
