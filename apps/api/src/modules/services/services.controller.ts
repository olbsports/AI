import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { ServicesService } from './services.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('services')
@Controller()
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ServicesController {
  constructor(private readonly servicesService: ServicesService) {}

  // ========== SERVICE PROVIDERS ==========

  @Get('services/search')
  @ApiOperation({ summary: 'Search service providers' })
  async searchProviders(
    @CurrentUser() user: any,
    @Query('q') query?: string,
    @Query('type') type?: string,
    @Query('location') location?: string,
  ) {
    return this.servicesService.searchProviders({ query, type, location });
  }

  @Get('services')
  @ApiOperation({ summary: 'Get providers by type' })
  async getProviders(
    @CurrentUser() user: any,
    @Query('type') type?: string,
  ) {
    return this.servicesService.getProviders(type);
  }

  @Get('services/nearby')
  @ApiOperation({ summary: 'Get nearby providers' })
  async getNearbyProviders(
    @CurrentUser() user: any,
    @Query('lat') lat?: string,
    @Query('lng') lng?: string,
    @Query('emergency') emergency?: string,
  ) {
    return this.servicesService.getNearbyProviders(
      lat ? parseFloat(lat) : undefined,
      lng ? parseFloat(lng) : undefined,
      emergency === 'true',
    );
  }

  @Get('services/saved')
  @ApiOperation({ summary: 'Get saved providers' })
  async getSavedProviders(@CurrentUser() user: any) {
    return this.servicesService.getSavedProviders(user.id);
  }

  @Get('services/featured')
  @ApiOperation({ summary: 'Get featured providers' })
  async getFeaturedProviders() {
    return this.servicesService.getFeaturedProviders();
  }

  @Get('services/stats')
  @ApiOperation({ summary: 'Get service statistics' })
  async getStats(@CurrentUser() user: any) {
    return this.servicesService.getStats(user.organizationId);
  }

  @Get('services/emergency-contacts')
  @ApiOperation({ summary: 'Get emergency contacts' })
  async getEmergencyContacts(@CurrentUser() user: any) {
    return this.servicesService.getEmergencyContacts(user.organizationId);
  }

  @Get('services/:id')
  @ApiOperation({ summary: 'Get provider details' })
  async getProvider(@Param('id') id: string) {
    return this.servicesService.getProvider(id);
  }

  @Get('services/:id/reviews')
  @ApiOperation({ summary: 'Get provider reviews' })
  async getProviderReviews(@Param('id') id: string) {
    return this.servicesService.getProviderReviews(id);
  }

  @Post('services/:id/save')
  @ApiOperation({ summary: 'Save provider' })
  async saveProvider(@CurrentUser() user: any, @Param('id') id: string) {
    return this.servicesService.saveProvider(user.id, id);
  }

  @Delete('services/:id/save')
  @ApiOperation({ summary: 'Remove saved provider' })
  async removeSavedProvider(@CurrentUser() user: any, @Param('id') id: string) {
    return this.servicesService.removeSavedProvider(user.id, id);
  }

  @Post('services/:id/reviews')
  @ApiOperation({ summary: 'Add review' })
  async addReview(
    @CurrentUser() user: any,
    @Param('id') providerId: string,
    @Body() data: { rating: number; comment: string },
  ) {
    return this.servicesService.addReview(user.id, providerId, data);
  }

  @Post('services/emergency-contacts')
  @ApiOperation({ summary: 'Add emergency contact' })
  async addEmergencyContact(
    @CurrentUser() user: any,
    @Body() data: { name: string; phone: string; type: string; notes?: string },
  ) {
    return this.servicesService.addEmergencyContact(user.organizationId, data);
  }

  @Put('services/emergency-contacts/:id')
  @ApiOperation({ summary: 'Update emergency contact' })
  async updateEmergencyContact(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: { name?: string; phone?: string; type?: string; notes?: string },
  ) {
    return this.servicesService.updateEmergencyContact(id, data);
  }

  @Delete('services/emergency-contacts/:id')
  @ApiOperation({ summary: 'Delete emergency contact' })
  async deleteEmergencyContact(
    @CurrentUser() user: any,
    @Param('id') id: string,
  ) {
    return this.servicesService.deleteEmergencyContact(id);
  }

  // ========== APPOINTMENTS ==========

  @Get('appointments')
  @ApiOperation({ summary: 'Get user appointments' })
  async getAppointments(@CurrentUser() user: any) {
    return this.servicesService.getAppointments(user.organizationId);
  }

  @Post('appointments')
  @ApiOperation({ summary: 'Create appointment' })
  async createAppointment(
    @CurrentUser() user: any,
    @Body() data: {
      providerId: string;
      horseId?: string;
      date: string;
      time: string;
      type: string;
      notes?: string;
    },
  ) {
    return this.servicesService.createAppointment(user.organizationId, user.id, data);
  }

  @Put('appointments/:id')
  @ApiOperation({ summary: 'Update appointment' })
  async updateAppointment(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: { date?: string; time?: string; notes?: string },
  ) {
    return this.servicesService.updateAppointment(id, data);
  }

  @Post('appointments/:id/cancel')
  @ApiOperation({ summary: 'Cancel appointment' })
  async cancelAppointment(@CurrentUser() user: any, @Param('id') id: string) {
    return this.servicesService.cancelAppointment(id);
  }

  @Post('appointments/:id/rate')
  @ApiOperation({ summary: 'Rate appointment' })
  async rateAppointment(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() data: { rating: number; comment?: string },
  ) {
    return this.servicesService.rateAppointment(id, data);
  }
}
