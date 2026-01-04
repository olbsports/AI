import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { ExportsService } from './exports.service';
import { ExportsController } from './exports.controller';

@Module({
  imports: [ConfigModule],
  controllers: [ExportsController],
  providers: [ExportsService],
  exports: [ExportsService],
})
export class ExportsModule {}
