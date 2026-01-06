import { Module } from '@nestjs/common';
import { EquiTraceService } from './equitrace.service';
import { EquiTraceController } from './equitrace.controller';
import { PrismaModule } from '../../prisma/prisma.module';
import { ExternalDataModule } from '../external-data/external-data.module';

@Module({
  imports: [PrismaModule, ExternalDataModule],
  controllers: [EquiTraceController],
  providers: [EquiTraceService],
  exports: [EquiTraceService],
})
export class EquiTraceModule {}
