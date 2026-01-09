import { Module } from '@nestjs/common';
import { SocialController } from './social.controller';
import { SocialService } from './social.service';
import { StoriesService } from './stories.service';
import { HashtagsService } from './hashtags.service';

@Module({
  controllers: [SocialController],
  providers: [
    SocialService,
    StoriesService,
    HashtagsService,
  ],
  exports: [
    SocialService,
    StoriesService,
    HashtagsService,
  ],
})
export class SocialModule {}
