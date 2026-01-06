import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { GamificationService } from './gamification.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('gamification')
@Controller('gamification')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class GamificationController {
  constructor(private readonly gamificationService: GamificationService) {}

  @Get('level')
  @ApiOperation({ summary: 'Get user level and XP' })
  async getLevel(@CurrentUser() user: any) {
    return this.gamificationService.getLevel(user.id);
  }

  @Get('xp/history')
  @ApiOperation({ summary: 'Get XP history' })
  async getXpHistory(@CurrentUser() user: any) {
    return this.gamificationService.getXpHistory(user.id);
  }

  @Get('badges')
  @ApiOperation({ summary: 'Get all badges' })
  async getAllBadges() {
    return this.gamificationService.getAllBadges();
  }

  @Get('badges/earned')
  @ApiOperation({ summary: 'Get earned badges' })
  async getEarnedBadges(@CurrentUser() user: any) {
    return this.gamificationService.getEarnedBadges(user.id);
  }

  @Get('challenges/active')
  @ApiOperation({ summary: 'Get active challenges' })
  async getActiveChallenges(@CurrentUser() user: any) {
    return this.gamificationService.getActiveChallenges(user.id);
  }

  @Get('streak')
  @ApiOperation({ summary: 'Get user streak' })
  async getStreak(@CurrentUser() user: any) {
    return this.gamificationService.getStreak(user.id);
  }

  @Get('rewards')
  @ApiOperation({ summary: 'Get available rewards' })
  async getRewards(@CurrentUser() user: any) {
    return this.gamificationService.getRewards(user.id);
  }

  @Get('referrals/stats')
  @ApiOperation({ summary: 'Get referral statistics' })
  async getReferralStats(@CurrentUser() user: any) {
    return this.gamificationService.getReferralStats(user.id);
  }

  @Get('referrals/code')
  @ApiOperation({ summary: 'Get referral code' })
  async getReferralCode(@CurrentUser() user: any) {
    return this.gamificationService.getReferralCode(user.id);
  }

  @Get('leaderboard')
  @ApiOperation({ summary: 'Get XP leaderboard' })
  async getLeaderboard(@CurrentUser() user: any) {
    return this.gamificationService.getLeaderboard(user.organizationId);
  }

  @Post('daily-login')
  @ApiOperation({ summary: 'Claim daily login XP' })
  async claimDailyLogin(@CurrentUser() user: any) {
    return this.gamificationService.claimDailyLogin(user.id);
  }

  @Post('challenges/:id/complete')
  @ApiOperation({ summary: 'Complete a challenge' })
  async completeChallenge(
    @CurrentUser() user: any,
    @Param('id') challengeId: string,
  ) {
    return this.gamificationService.completeChallenge(user.id, challengeId);
  }

  @Post('rewards/:id/claim')
  @ApiOperation({ summary: 'Claim a reward' })
  async claimReward(
    @CurrentUser() user: any,
    @Param('id') rewardId: string,
  ) {
    return this.gamificationService.claimReward(user.id, rewardId);
  }
}
