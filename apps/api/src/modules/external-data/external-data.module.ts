import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { FFEService } from './ffe.service';
import { SireWebService } from './sireweb.service';
import { IFCEService } from './ifce.service';
import { MarketDataService } from './market-data.service';
import { ScrapingService } from './scraping.service';
import { ExternalDataCacheService } from './cache.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [
    HttpModule.register({
      timeout: 30000,
      maxRedirects: 5,
    }),
    PrismaModule,
  ],
  providers: [
    FFEService,
    SireWebService,
    IFCEService,
    MarketDataService,
    ScrapingService,
    ExternalDataCacheService,
  ],
  exports: [
    FFEService,
    SireWebService,
    IFCEService,
    MarketDataService,
    ScrapingService,
    ExternalDataCacheService,
  ],
})
export class ExternalDataModule {}
