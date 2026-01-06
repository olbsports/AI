import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { DataSyncService } from './data-sync.service';
import { SyncScheduler } from './sync-scheduler.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { ExternalDataModule } from '../external-data/external-data.module';
import { QueueModule } from '../queue/queue.module';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    PrismaModule,
    ExternalDataModule,
    QueueModule,
  ],
  providers: [DataSyncService, SyncScheduler],
  exports: [DataSyncService],
})
export class SyncModule {}
