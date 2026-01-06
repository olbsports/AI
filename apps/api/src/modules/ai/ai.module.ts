import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { AnthropicService } from './anthropic.service';
import { AIAnalysisService } from './analysis.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [
    HttpModule.register({
      timeout: 120000, // 2 minutes for AI calls
    }),
    PrismaModule,
  ],
  providers: [AnthropicService, AIAnalysisService],
  exports: [AnthropicService, AIAnalysisService],
})
export class AIModule {}
