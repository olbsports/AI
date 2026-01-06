import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { EquiTraceService } from './equitrace.service';
import { CreateEntryDto } from './dto/equitrace.dto';

@ApiTags('EquiTrace - Historique')
@Controller('equitrace')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class EquiTraceController {
  constructor(private readonly equiTraceService: EquiTraceService) {}

  @Post('report/:horseId')
  @ApiOperation({ summary: 'Generate complete EquiTrace report' })
  async generateReport(@Param('horseId') horseId: string, @Request() req: any) {
    return this.equiTraceService.generateReport(
      horseId,
      req.user.id,
      req.user.organizationId,
    );
  }

  @Get('timeline/:horseId')
  @ApiOperation({ summary: 'Get timeline for a horse' })
  async getTimeline(@Param('horseId') horseId: string) {
    return this.equiTraceService.getTimeline(horseId);
  }

  @Post('entry/:horseId')
  @ApiOperation({ summary: 'Add manual entry to horse history' })
  async addEntry(
    @Param('horseId') horseId: string,
    @Body() data: CreateEntryDto,
    @Request() req: any,
  ) {
    return this.equiTraceService.addEntry(
      horseId,
      data,
      req.user.id,
      req.user.organizationId,
    );
  }

  @Post('sync/:horseId')
  @ApiOperation({ summary: 'Sync horse data from external sources' })
  async syncFromExternalSources(@Param('horseId') horseId: string) {
    return this.equiTraceService.syncFromExternalSources(horseId);
  }
}
