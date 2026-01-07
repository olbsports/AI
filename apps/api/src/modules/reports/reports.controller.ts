import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Public } from '../auth/decorators/public.decorator';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { UpdateReportDto } from './dto/update-report.dto';
import { CreateShareLinkDto } from './dto/create-share-link.dto';
import { CreateReportDto } from './dto/create-report.dto';

@ApiTags('reports')
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List reports' })
  async list(@CurrentUser() user: any, @Query() query: ListReportsQueryDto) {
    return this.reportsService.findAll(user.organizationId, query);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new report' })
  async create(@CurrentUser() user: any, @Body() dto: CreateReportDto) {
    return this.reportsService.create(user.organizationId, dto);
  }

  @Get('shared/:token')
  @Public()
  @ApiOperation({ summary: 'Get shared report by token' })
  async getShared(@Param('token') token: string) {
    return this.reportsService.findByShareToken(token);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get report by ID' })
  async findOne(@CurrentUser() user: any, @Param('id') id: string) {
    return this.reportsService.findById(id, user.organizationId);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a report' })
  async update(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: UpdateReportDto) {
    return this.reportsService.update(id, user.organizationId, dto);
  }

  @Post(':id/sign')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Sign a report' })
  async sign(@CurrentUser() user: any, @Param('id') id: string) {
    return this.reportsService.sign(id, user.organizationId, user.id);
  }

  @Post(':id/share')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create share link' })
  async createShareLink(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: CreateShareLinkDto
  ) {
    return this.reportsService.createShareLink(id, user.organizationId, dto.expiresInDays);
  }

  @Delete(':id/share')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke share link' })
  async revokeShareLink(@CurrentUser() user: any, @Param('id') id: string) {
    return this.reportsService.revokeShareLink(id, user.organizationId);
  }

  @Post(':id/archive')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Archive a report' })
  async archive(@CurrentUser() user: any, @Param('id') id: string) {
    return this.reportsService.archive(id, user.organizationId);
  }
}
