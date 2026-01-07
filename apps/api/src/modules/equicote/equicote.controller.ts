import { Controller, Get, Post, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { EquiCoteService } from './equicote.service';
import { CreateValuationDto, QuickEstimateDto } from './dto/equicote.dto';

@ApiTags('EquiCote - Valorisation')
@Controller('equicote')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class EquiCoteController {
  constructor(private readonly equiCoteService: EquiCoteService) {}

  @Post('valuate/:horseId')
  @ApiOperation({ summary: 'Create full valuation for a horse' })
  async createValuation(@Param('horseId') horseId: string, @Request() req: any) {
    return this.equiCoteService.createValuation(horseId, req.user.id, req.user.organizationId);
  }

  @Get('valuation/:valuationId')
  @ApiOperation({ summary: 'Get valuation by ID' })
  async getValuation(@Param('valuationId') valuationId: string) {
    return this.equiCoteService.getValuation(valuationId);
  }

  @Get('horse/:horseId/valuations')
  @ApiOperation({ summary: 'Get all valuations for a horse' })
  async getHorseValuations(@Param('horseId') horseId: string) {
    return this.equiCoteService.getHorseValuations(horseId);
  }

  @Post('quick-estimate')
  @ApiOperation({ summary: 'Get quick estimate without external data' })
  async quickEstimate(@Body() data: QuickEstimateDto) {
    return this.equiCoteService.quickEstimate(data);
  }

  @Get('comparables/:horseId')
  @ApiOperation({ summary: 'Get comparable horses for valuation' })
  async getComparables(@Param('horseId') horseId: string) {
    return this.equiCoteService.getComparables(horseId);
  }
}
