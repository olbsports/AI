import { Module } from '@nestjs/common';
import { MarketplaceController } from './marketplace.controller';
import { MarketplaceService } from './marketplace.service';
import { MarketplaceRecommendationsService } from './marketplace-recommendations.service';

@Module({
  controllers: [MarketplaceController],
  providers: [MarketplaceService, MarketplaceRecommendationsService],
  exports: [MarketplaceService, MarketplaceRecommendationsService],
})
export class MarketplaceModule {}
