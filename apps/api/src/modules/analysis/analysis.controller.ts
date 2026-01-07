import { Controller, Get, Post, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { AnalysisService } from './analysis.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { CreateAnalysisDto } from './dto/create-analysis.dto';
import { ListAnalysisQueryDto } from './dto/list-analysis-query.dto';

@ApiTags('analyses')
@Controller('analyses')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class AnalysisController {
  constructor(private readonly analysisService: AnalysisService) {}

  @Get()
  @ApiOperation({ summary: 'List analyses' })
  async list(@CurrentUser() user: any, @Query() query: ListAnalysisQueryDto) {
    return this.analysisService.findAll(user.organizationId, query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get analysis by ID' })
  async findOne(@CurrentUser() user: any, @Param('id') id: string) {
    return this.analysisService.findById(id, user.organizationId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new analysis' })
  async create(@CurrentUser() user: any, @Body() dto: CreateAnalysisDto) {
    return this.analysisService.create(user.organizationId, user.id, dto);
  }

  @Post(':id/cancel')
  @ApiOperation({ summary: 'Cancel an analysis' })
  async cancel(@CurrentUser() user: any, @Param('id') id: string) {
    return this.analysisService.cancel(id, user.organizationId);
  }

  @Get(':id/status')
  @ApiOperation({ summary: 'Get analysis status' })
  async getStatus(@CurrentUser() user: any, @Param('id') id: string) {
    const analysis = await this.analysisService.findById(id, user.organizationId);
    return {
      status: analysis.status,
      progress: analysis.status === 'processing' ? 50 : analysis.status === 'completed' ? 100 : 0,
    };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete an analysis' })
  async delete(@CurrentUser() user: any, @Param('id') id: string) {
    return this.analysisService.delete(id, user.organizationId);
  }

  @Post(':id/retry')
  @ApiOperation({ summary: 'Retry a failed analysis' })
  async retry(@CurrentUser() user: any, @Param('id') id: string) {
    return this.analysisService.retry(id, user.organizationId, user.id);
  }
}
