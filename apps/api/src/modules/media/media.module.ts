import { Module } from '@nestjs/common';
import { MediaController } from './media.controller';
import { UploadModule } from '../upload/upload.module';

@Module({
  imports: [UploadModule],
  controllers: [MediaController],
})
export class MediaModule {}
