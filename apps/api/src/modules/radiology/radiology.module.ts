import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { RadiologyController } from './radiology.controller';
import { RadiologyService } from './radiology.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { TokensModule } from '../tokens/tokens.module';

@Module({
  imports: [
    PrismaModule,
    TokensModule,
    ConfigModule,
  ],
  controllers: [RadiologyController],
  providers: [RadiologyService],
  exports: [RadiologyService],
})
export class RadiologyModule {}
