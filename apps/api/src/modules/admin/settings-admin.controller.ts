import { Controller, Get, Put, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { PrismaService } from '../../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('settings')
@Controller('settings')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('owner')
@ApiBearerAuth()
export class SettingsAdminController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'Get system settings' })
  async getSettings() {
    try {
      const settings = await this.prisma.systemSettings.findFirst();

      if (!settings) {
        return this.getDefaultSettings();
      }

      return {
        maintenanceMode: settings.maintenanceMode,
        maintenanceMessage: settings.maintenanceMessage,
        registrationEnabled: settings.registrationEnabled,
        freeTrialEnabled: settings.freeTrialEnabled,
        freeTrialDays: settings.freeTrialDays,
        analysisPrice: settings.analysisPrice,
        maxAnalysesPerDay: settings.maxAnalysesPerDay,
        allowedFileTypes: settings.allowedFileTypes,
        maxFileSize: settings.maxFileSize,
        featureFlags: settings.featureFlags,
        termsVersion: settings.termsVersion,
        privacyVersion: settings.privacyVersion,
        lastUpdated: settings.updatedAt,
      };
    } catch {
      return this.getDefaultSettings();
    }
  }

  private getDefaultSettings() {
    return {
      maintenanceMode: false,
      maintenanceMessage: null,
      registrationEnabled: true,
      freeTrialEnabled: true,
      freeTrialDays: 7,
      analysisPrice: 0,
      maxAnalysesPerDay: 100,
      allowedFileTypes: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
      maxFileSize: 100000000,
      featureFlags: {
        social: true,
        marketplace: true,
        breeding: true,
        clubs: true,
      },
      termsVersion: '1.0.0',
      privacyVersion: '1.0.0',
      lastUpdated: new Date(),
    };
  }

  @Put()
  @ApiOperation({ summary: 'Update system settings' })
  async updateSettings(@Body() data: any) {
    try {
      const existing = await this.prisma.systemSettings.findFirst();

      if (existing) {
        await this.prisma.systemSettings.update({
          where: { id: existing.id },
          data,
        });
      } else {
        await this.prisma.systemSettings.create({ data });
      }

      return { success: true };
    } catch {
      return { success: false, message: 'Settings table may not exist' };
    }
  }

  @Put('maintenance')
  @ApiOperation({ summary: 'Toggle maintenance mode' })
  async toggleMaintenance(@Body() body: { enabled: boolean; message?: string }) {
    try {
      const existing = await this.prisma.systemSettings.findFirst();

      const data = {
        maintenanceMode: body.enabled,
        maintenanceMessage: body.message,
      };

      if (existing) {
        await this.prisma.systemSettings.update({
          where: { id: existing.id },
          data,
        });
      } else {
        await this.prisma.systemSettings.create({ data: { ...data } as any });
      }

      return { success: true };
    } catch {
      return { success: false };
    }
  }

  @Put('features/:feature')
  @ApiOperation({ summary: 'Toggle feature flag' })
  async toggleFeature(@Param('feature') feature: string, @Body() body: { enabled: boolean }) {
    try {
      const existing = await this.prisma.systemSettings.findFirst();

      if (existing) {
        const currentFlags = (existing.featureFlags as Record<string, boolean>) || {};
        currentFlags[feature] = body.enabled;

        await this.prisma.systemSettings.update({
          where: { id: existing.id },
          data: { featureFlags: currentFlags },
        });
      }

      return { success: true };
    } catch {
      return { success: false };
    }
  }
}
