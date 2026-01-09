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
import { ApiTags, ApiOperation, ApiBearerAuth, ApiBody, ApiQuery } from '@nestjs/swagger';

import { MarketplaceService } from './marketplace.service';
import { MarketplaceRecommendationsService } from './marketplace-recommendations.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('marketplace')
@Controller('marketplace')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class MarketplaceController {
  constructor(
    private readonly marketplaceService: MarketplaceService,
    private readonly recommendationsService: MarketplaceRecommendationsService
  ) {}

  @Get('search')
  @ApiOperation({ summary: 'Search marketplace listings' })
  async search(
    @Query('type') type?: string,
    @Query('minPrice') minPrice?: string,
    @Query('maxPrice') maxPrice?: string,
    @Query('breed') breed?: string,
    @Query('sortBy') sortBy?: string
  ) {
    return this.marketplaceService.search({
      type,
      minPrice: minPrice ? parseInt(minPrice) : undefined,
      maxPrice: maxPrice ? parseInt(maxPrice) : undefined,
      breed,
      sortBy,
    });
  }

  @Get('recent')
  @ApiOperation({ summary: 'Get recent listings' })
  async getRecent() {
    return this.marketplaceService.getRecent();
  }

  @Get('featured')
  @ApiOperation({ summary: 'Get featured listings' })
  async getFeatured() {
    return this.marketplaceService.getFeatured();
  }

  @Get('my-listings')
  @ApiOperation({ summary: 'Get user own listings' })
  async getMyListings(@CurrentUser() user: any) {
    return this.marketplaceService.getMyListings(user.id);
  }

  @Get('favorites')
  @ApiOperation({ summary: 'Get favorite listings' })
  async getFavorites(@CurrentUser() user: any) {
    return this.marketplaceService.getFavorites(user.id);
  }

  @Get('breeding')
  @ApiOperation({ summary: 'Get breeding listings' })
  async getBreedingListings(@Query('type') type?: string, @Query('breed') breed?: string) {
    return this.marketplaceService.getBreedingListings(type || 'stallion_service', breed);
  }

  @Get('breeding-matches/:mareId')
  @ApiOperation({ summary: 'Get AI breeding matches for a mare' })
  async getBreedingMatches(@CurrentUser() user: any, @Param('mareId') mareId: string) {
    return this.marketplaceService.getBreedingMatches(mareId, user.id);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get marketplace statistics' })
  async getStats() {
    return this.marketplaceService.getStats();
  }

  // ============ RECOMMENDATIONS ============

  @Get('recommendations')
  @ApiOperation({ summary: 'Get personalized listing recommendations' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getRecommendations(
    @CurrentUser() user: any,
    @Query('limit') limit?: string
  ) {
    return this.recommendationsService.getPersonalizedRecommendations(
      user.id,
      user.organizationId,
      limit ? parseInt(limit) : 20
    );
  }

  @Get('recommendations/trending')
  @ApiOperation({ summary: 'Get trending listings' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getTrendingListings(@Query('limit') limit?: string) {
    return this.recommendationsService.getTrendingListings(limit ? parseInt(limit) : 10);
  }

  @Get('similar/:id')
  @ApiOperation({ summary: 'Get similar listings' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getSimilarListings(@Param('id') id: string, @Query('limit') limit?: string) {
    return this.recommendationsService.getSimilarListings(id, limit ? parseInt(limit) : 10);
  }

  // ============ SELLER STATS ============

  @Get('seller-stats')
  @ApiOperation({ summary: 'Get seller statistics (views, contacts, conversions)' })
  async getSellerStats(@CurrentUser() user: any) {
    return this.marketplaceService.getSellerStats(user.id);
  }

  // ============ LISTING ALERTS ============

  @Post('alerts')
  @ApiOperation({ summary: 'Create a listing alert' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        filters: {
          type: 'object',
          properties: {
            type: { type: 'string' },
            minPrice: { type: 'number' },
            maxPrice: { type: 'number' },
            breed: { type: 'string' },
            location: { type: 'string' },
            country: { type: 'string' },
          },
        },
        notifyEmail: { type: 'boolean', default: true },
        notifyPush: { type: 'boolean', default: true },
      },
      required: ['filters'],
    },
  })
  async createAlert(
    @CurrentUser() user: any,
    @Body()
    body: {
      filters: {
        type?: string;
        minPrice?: number;
        maxPrice?: number;
        breed?: string;
        location?: string;
        country?: string;
      };
      notifyEmail?: boolean;
      notifyPush?: boolean;
    }
  ) {
    return this.marketplaceService.createListingAlert(user.id, body);
  }

  @Get('alerts')
  @ApiOperation({ summary: 'Get user listing alerts' })
  async getAlerts(@CurrentUser() user: any) {
    return this.marketplaceService.getListingAlerts(user.id);
  }

  @Patch('alerts/:id')
  @ApiOperation({ summary: 'Update a listing alert' })
  async updateAlert(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body()
    body: {
      filters?: any;
      notifyEmail?: boolean;
      notifyPush?: boolean;
      isActive?: boolean;
    }
  ) {
    return this.marketplaceService.updateListingAlert(id, user.id, body);
  }

  @Delete('alerts/:id')
  @ApiOperation({ summary: 'Delete a listing alert' })
  async deleteAlert(@CurrentUser() user: any, @Param('id') id: string) {
    return this.marketplaceService.deleteListingAlert(id, user.id);
  }

  @Get('horses/:id')
  @ApiOperation({ summary: 'Get horse profile with all listings' })
  async getHorseProfile(@Param('id') id: string) {
    return this.marketplaceService.getHorseProfile(id);
  }

  @Get('ai-profile/:id')
  @ApiOperation({ summary: 'Get AI-generated horse profile' })
  async getAIHorseProfile(@Param('id') id: string) {
    return this.marketplaceService.getAIHorseProfile(id);
  }

  @Post('ai-profile/analyze')
  @ApiOperation({ summary: 'Analyze listing with AI' })
  async analyzeWithAI(
    @Body() body: { title: string; description: string; price?: number; horseId?: string }
  ) {
    return this.marketplaceService.analyzeWithAI(body);
  }

  @Post()
  @ApiOperation({ summary: 'Create a listing' })
  async create(
    @CurrentUser() user: any,
    @Body()
    body: {
      type: string;
      title: string;
      description: string;
      price?: number;
      priceType?: string;
      horseId?: string;
      location?: string;
      photos?: string[];
      videos?: string[];
    }
  ) {
    return this.marketplaceService.create(user.id, user.organizationId, body);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get listing by ID' })
  async getById(@CurrentUser() user: any, @Param('id') id: string) {
    return this.marketplaceService.getById(id, user.id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update listing' })
  async update(@CurrentUser() user: any, @Param('id') id: string, @Body() body: any) {
    return this.marketplaceService.update(id, user.id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete listing' })
  async delete(@CurrentUser() user: any, @Param('id') id: string) {
    return this.marketplaceService.delete(id, user.id);
  }

  @Post(':id/favorite')
  @ApiOperation({ summary: 'Toggle favorite' })
  async toggleFavorite(@CurrentUser() user: any, @Param('id') id: string) {
    return this.marketplaceService.toggleFavorite(id, user.id, user.organizationId);
  }

  @Post(':id/contact')
  @ApiOperation({ summary: 'Contact seller' })
  async contactSeller(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { message: string }
  ) {
    return this.marketplaceService.contactSeller(id, user.id, body.message);
  }

  @Post(':id/sold')
  @ApiOperation({ summary: 'Mark listing as sold' })
  async markAsSold(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { soldPrice?: number; soldDate?: Date }
  ) {
    return this.marketplaceService.markAsSold(id, user.id, body.soldPrice, body.soldDate);
  }

  @Post(':id/promote')
  @ApiOperation({ summary: 'Promote listing with tokens (featured: 50 tokens/7d, boost: 30 tokens/3d, refresh: 10 tokens)' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        type: {
          type: 'string',
          enum: ['featured', 'boost', 'refresh'],
          description: 'featured: 50 tokens for 7 days, boost: 30 tokens for 3 days, refresh: 10 tokens',
        },
      },
      required: ['type'],
    },
  })
  async promoteListing(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { type: 'featured' | 'boost' | 'refresh' }
  ) {
    return this.marketplaceService.promoteListingWithTokens(id, user.id, user.organizationId, body.type);
  }

  @Get(':id/promotion')
  @ApiOperation({ summary: 'Get listing promotion status and history' })
  async getListingPromotion(@Param('id') id: string) {
    return this.marketplaceService.getListingPromotion(id);
  }

  @Post(':id/report')
  @ApiOperation({ summary: 'Report a listing' })
  async reportListing(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { reason: string; details?: string }
  ) {
    return this.marketplaceService.reportListing(id, user.id, body.reason, body.details);
  }

  // Support for query param type filter
  @Get()
  @ApiOperation({ summary: 'Get listings by type' })
  async getByType(@Query('type') type?: string) {
    if (type) {
      return this.marketplaceService.getByType(type);
    }
    return this.marketplaceService.getRecent();
  }
}
