import { Module, Global } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { ConfigService } from '@nestjs/config';

import { AnalysisProcessor } from './processors/analysis.processor';
import { ReportProcessor } from './processors/report.processor';
import { NotificationProcessor } from './processors/notification.processor';
import { QueueService } from './queue.service';
import { QueueController } from './queue.controller';
import { QUEUE_NAMES } from './queue.constants';

export { QUEUE_NAMES } from './queue.constants';

@Global()
@Module({
  imports: [
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        redis: {
          host: config.get('REDIS_HOST', 'localhost'),
          port: config.get('REDIS_PORT', 6379),
          password: config.get('REDIS_PASSWORD', undefined),
        },
        defaultJobOptions: {
          removeOnComplete: 100,
          removeOnFail: 50,
          attempts: 3,
          backoff: {
            type: 'exponential',
            delay: 2000,
          },
        },
      }),
    }),
    BullModule.registerQueue(
      { name: QUEUE_NAMES.ANALYSIS },
      { name: QUEUE_NAMES.REPORTS },
      { name: QUEUE_NAMES.NOTIFICATIONS },
    ),
  ],
  controllers: [QueueController],
  providers: [
    QueueService,
    AnalysisProcessor,
    ReportProcessor,
    NotificationProcessor,
  ],
  exports: [QueueService, BullModule],
})
export class QueueModule {}
