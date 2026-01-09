import { Module, OnModuleInit } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { GamificationController } from './gamification.controller';
import { GamificationService } from './gamification.service';
import { ChallengesService } from './challenges.service';
import { StreaksService } from './streaks.service';
import { ReferralsService } from './referrals.service';

@Module({
  imports: [ScheduleModule.forRoot()],
  controllers: [GamificationController],
  providers: [
    GamificationService,
    ChallengesService,
    StreaksService,
    ReferralsService,
  ],
  exports: [
    GamificationService,
    ChallengesService,
    StreaksService,
    ReferralsService,
  ],
})
export class GamificationModule implements OnModuleInit {
  constructor(private readonly challengesService: ChallengesService) {}

  /**
   * Initialize challenges on module startup if none exist
   */
  async onModuleInit() {
    await this.challengesService.initializeChallenges();
  }
}
