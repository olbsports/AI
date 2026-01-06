import { Module } from '@nestjs/common';
import { EquiCoteService } from './equicote.service';
import { EquiCoteController } from './equicote.controller';
import { PrismaModule } from '../../prisma/prisma.module';
import { ExternalDataModule } from '../external-data/external-data.module';
import { AIModule } from '../ai/ai.module';

@Module({
  imports: [PrismaModule, ExternalDataModule, AIModule],
  controllers: [EquiCoteController],
  providers: [EquiCoteService],
  exports: [EquiCoteService],
})
export class EquiCoteModule {}
