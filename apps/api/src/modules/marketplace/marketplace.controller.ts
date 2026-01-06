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

import { MarketplaceService } from './marketplace.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('marketplace')
@Controller('marketplace')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class MarketplaceController {
  constructor(private readonly marketplaceService: MarketplaceService) {}

  @Get('search')
  @ApiOperation({ summary: 'Search marketplace listings' })
  async search(
    @Query('type') type?: string,
    @Query('minPrice') minPrice?: string,
    @Query('maxPrice') maxPrice?: string,
    @Query('breed') breed?: string,
    @Query('sortBy') sortBy?: string,
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
  async getBreedingListings(
    @Query('type') type?: string,
    @Query('breed') breed?: string,
  ) {
    return this.marketplaceService.getBreedingListings(type || 'stallion_service', breed);
  }

  @Post()
  @ApiOperation({ summary: 'Create a listing' })
  async create(
    @CurrentUser() user: any,
    @Body() body: {
      type: string;
      title: string;
      description: string;
      price?: number;
      priceType?: string;
      horseId?: string;
      location?: string;
      photos?: string[];
      videos?: string[];
    },
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
  async update(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: any,
  ) {
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
    @Body() body: { message: string },
  ) {
    return this.marketplaceService.contactSeller(id, user.id, body.message);
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
