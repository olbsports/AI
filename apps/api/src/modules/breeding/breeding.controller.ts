import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { BreedingService } from './breeding.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('breeding')
@Controller('breeding')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class BreedingController {
  constructor(private readonly breedingService: BreedingService) {}

  // ========== STALLIONS ==========

  @Get('stallions')
  @ApiOperation({ summary: 'List stallions' })
  async getStallions(
    @CurrentUser() user: any,
    @Query('search') search?: string,
    @Query('discipline') discipline?: string,
    @Query('studFee') studFee?: string,
    @Query('page') page?: number,
    @Query('pageSize') pageSize?: number
  ) {
    return this.breedingService.getStallions({
      search,
      discipline,
      studFee,
      page,
      pageSize,
    });
  }

  @Get('stallions/featured')
  @ApiOperation({ summary: 'Get featured stallions' })
  async getFeaturedStallions(@CurrentUser() user: any) {
    return this.breedingService.getFeaturedStallions();
  }

  @Get('stallions/:id')
  @ApiOperation({ summary: 'Get stallion details' })
  async getStallionDetails(@CurrentUser() user: any, @Param('id') id: string) {
    return this.breedingService.getStallionDetails(id);
  }

  @Get('stallions/:id/offspring')
  @ApiOperation({ summary: 'Get stallion offspring' })
  async getStallionOffspring(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Query('page') page?: number,
    @Query('pageSize') pageSize?: number
  ) {
    return this.breedingService.getStallionOffspring(id, { page, pageSize });
  }

  @Post('stallions/:id/save')
  @ApiOperation({ summary: 'Save/unsave stallion to favorites' })
  async saveStallion(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: { saved: boolean }
  ) {
    return this.breedingService.saveStallion(user.id, id, data.saved);
  }

  // ========== MARES ==========

  @Get('mares/:id')
  @ApiOperation({ summary: 'Get mare details' })
  async getMareDetails(@CurrentUser() user: any, @Param('id') id: string) {
    return this.breedingService.getMareDetails(id, user.id);
  }

  @Get('my-mares')
  @ApiOperation({ summary: 'Get my mares' })
  async getMyMares(
    @CurrentUser() user: any,
    @Query('page') page?: number,
    @Query('pageSize') pageSize?: number
  ) {
    return this.breedingService.getMyMares(user.id, { page, pageSize });
  }

  @Post('mares')
  @ApiOperation({ summary: 'Add a mare' })
  async addMare(
    @CurrentUser() user: any,
    @Body()
    data: {
      horseId?: string;
      name: string;
      breed?: string;
      birthYear?: number;
      color?: string;
      pedigree?: any;
      performance?: any;
    }
  ) {
    return this.breedingService.addMare(user.id, data);
  }

  @Put('mares/:id')
  @ApiOperation({ summary: 'Update mare information' })
  async updateMare(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body()
    data: {
      name?: string;
      breed?: string;
      birthYear?: number;
      color?: string;
      pedigree?: any;
      performance?: any;
    }
  ) {
    return this.breedingService.updateMare(id, user.id, data);
  }

  // ========== BREEDING STATIONS ==========

  @Get('stations')
  @ApiOperation({ summary: 'Get breeding stations/haras' })
  async getBreedingStations(
    @CurrentUser() user: any,
    @Query('search') search?: string,
    @Query('region') region?: string,
    @Query('page') page?: number,
    @Query('pageSize') pageSize?: number
  ) {
    return this.breedingService.getBreedingStations({
      search,
      region,
      page,
      pageSize,
    });
  }

  @Post('stations/:id/contact')
  @ApiOperation({ summary: 'Contact a breeding station' })
  async contactStation(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body()
    data: {
      message: string;
      subject: string;
      stallionId?: string;
      preferredContactMethod?: string;
    }
  ) {
    return this.breedingService.contactStation(user.id, id, data);
  }

  // ========== RECOMMENDATIONS ==========

  @Get('recommendations/:id')
  @ApiOperation({ summary: 'Get breeding recommendations for a mare' })
  async getRecommendations(@CurrentUser() user: any, @Param('id') id: string) {
    return this.breedingService.getRecommendations(id, user.id);
  }

  @Post('ai-recommendations')
  @ApiOperation({ summary: 'Generate AI-powered breeding recommendations' })
  async generateAIRecommendations(
    @CurrentUser() user: any,
    @Body()
    data: {
      mareId: string;
      goals?: string[];
      preferences?: {
        maxStudFee?: number;
        preferredDisciplines?: string[];
        temperamentPreference?: string;
        sizePreference?: string;
      };
    }
  ) {
    return this.breedingService.generateAIRecommendations(user.id, data);
  }

  // ========== RESERVATIONS ==========

  @Post('reservations')
  @ApiOperation({ summary: 'Create breeding reservation' })
  async createReservation(
    @CurrentUser() user: any,
    @Body()
    data: {
      stallionId: string;
      mareId: string;
      preferredDate?: string;
      breedingType: 'live_cover' | 'ai_fresh' | 'ai_frozen';
      notes?: string;
    }
  ) {
    return this.breedingService.createReservation(user.id, data);
  }

  @Get('my-reservations')
  @ApiOperation({ summary: 'Get my breeding reservations' })
  async getMyReservations(
    @CurrentUser() user: any,
    @Query('status') status?: string,
    @Query('page') page?: number,
    @Query('pageSize') pageSize?: number
  ) {
    return this.breedingService.getMyReservations(user.id, {
      status,
      page,
      pageSize,
    });
  }
}
