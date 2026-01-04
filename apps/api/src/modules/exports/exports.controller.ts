import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { Response } from 'express';

import { ExportsService } from './exports.service';
import { ExportRequestDto } from './dto/export.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { OrganizationGuard } from '../auth/guards/organization.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentOrganization } from '../auth/decorators/organization.decorator';

@ApiTags('exports')
@Controller('exports')
@UseGuards(JwtAuthGuard, OrganizationGuard)
@ApiBearerAuth()
export class ExportsController {
  constructor(private readonly exportsService: ExportsService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin', 'veterinarian')
  @ApiOperation({ summary: 'Export data to file' })
  async exportData(
    @CurrentOrganization() organizationId: string,
    @Body() dto: ExportRequestDto,
    @Res() res: Response,
  ) {
    const result = await this.exportsService.exportData(organizationId, dto);

    res.setHeader('Content-Type', result.contentType);
    res.setHeader('Content-Disposition', `attachment; filename="${result.filename}"`);
    res.send(result.data);
  }

  @Get('reports/:id')
  @ApiOperation({ summary: 'Export a specific report' })
  async exportReport(
    @CurrentOrganization() organizationId: string,
    @Param('id') reportId: string,
    @Query('format') format: 'pdf' | 'html' = 'pdf',
    @Res() res: Response,
  ) {
    const result = await this.exportsService.exportReport(organizationId, reportId, format);

    res.setHeader('Content-Type', result.contentType);
    res.setHeader('Content-Disposition', `attachment; filename="${result.filename}"`);
    res.send(result.data);
  }

  @Get('history')
  @ApiOperation({ summary: 'Get export history' })
  async getExportHistory(@CurrentOrganization() organizationId: string) {
    return this.exportsService.getExportHistory(organizationId);
  }
}
