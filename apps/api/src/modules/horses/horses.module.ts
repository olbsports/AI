import { Module } from '@nestjs/common';
import { HorsesService } from './horses.service';
import { HorsesController } from './horses.controller';
import { HealthController } from './health.controller';
import { UploadModule } from '../upload/upload.module';

@Module({
  imports: [UploadModule],
  controllers: [HorsesController, HealthController],
  providers: [HorsesService],
  exports: [HorsesService],
})
export class HorsesModule {}
