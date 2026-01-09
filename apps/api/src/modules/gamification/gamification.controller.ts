import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
  Body,
  Query,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
  ApiParam,
  ApiBody,
} from '@nestjs/swagger';

import { GamificationService } from './gamification.service';
import { ChallengesService } from './challenges.service';
import { StreaksService } from './streaks.service';
import { ReferralsService } from './referrals.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('gamification')
@Controller('gamification')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class GamificationController {
  constructor(
    private readonly gamificationService: GamificationService,
    private readonly challengesService: ChallengesService,
    private readonly streaksService: StreaksService,
    private readonly referralsService: ReferralsService,
  ) {}

  // ==================== LEVEL & XP ====================

  @Get('level')
  @ApiOperation({ summary: 'Get user level and XP' })
  async getLevel(@CurrentUser() user: any) {
    return this.gamificationService.getLevel(user.id);
  }

  @Get('xp-history')
  @ApiOperation({ summary: 'Get XP transaction history' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'offset', required: false, type: Number })
  async getXpHistory(
    @CurrentUser() user: any,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.gamificationService.getXpHistory(
      user.id,
      limit ? Number(limit) : 50,
      offset ? Number(offset) : 0,
    );
  }

  // ==================== BADGES ====================

  @Get('badges')
  @ApiOperation({ summary: 'Get all available badges' })
  async getAllBadges() {
    return this.gamificationService.getAllBadges();
  }

  @Get('badges/earned')
  @ApiOperation({ summary: 'Get earned badges' })
  async getEarnedBadges(@CurrentUser() user: any) {
    return this.gamificationService.getEarnedBadges(user.id);
  }

  // ==================== CHALLENGES ====================

  @Get('challenges')
  @ApiOperation({ summary: 'Get all active challenges with user progress' })
  async getChallenges(@CurrentUser() user: any) {
    return this.challengesService.getActiveChallenges(user.id);
  }

  @Get('challenges/progress')
  @ApiOperation({ summary: 'Get challenge progress summary' })
  async getChallengeProgress(@CurrentUser() user: any) {
    return this.challengesService.getChallengeProgress(user.id);
  }

  @Get('challenges/active')
  @ApiOperation({ summary: 'Get active challenges (alias)' })
  async getActiveChallenges(@CurrentUser() user: any) {
    return this.challengesService.getActiveChallenges(user.id);
  }

  @Post('challenges/:id/claim')
  @ApiOperation({ summary: 'Claim reward for a completed challenge' })
  @ApiParam({ name: 'id', description: 'Challenge ID' })
  async claimChallengeReward(
    @CurrentUser() user: any,
    @Param('id') challengeId: string,
  ) {
    return this.challengesService.claimReward(user.id, challengeId);
  }

  @Post('challenges/:id/complete')
  @ApiOperation({ summary: 'Complete a challenge (deprecated, use claim)' })
  @ApiParam({ name: 'id', description: 'Challenge ID' })
  async completeChallenge(
    @CurrentUser() user: any,
    @Param('id') challengeId: string,
  ) {
    return this.challengesService.claimReward(user.id, challengeId);
  }

  // ==================== STREAKS ====================

  @Get('streak')
  @ApiOperation({ summary: 'Get user streak information' })
  async getStreak(@CurrentUser() user: any) {
    return this.streaksService.getStreak(user.id);
  }

  @Get('streak/leaderboard')
  @ApiOperation({ summary: 'Get streak leaderboard for organization' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getStreakLeaderboard(
    @CurrentUser() user: any,
    @Query('limit') limit?: number,
  ) {
    return this.streaksService.getStreakLeaderboard(
      user.organizationId,
      limit ? Number(limit) : 10,
    );
  }

  // ==================== REFERRALS ====================

  @Get('referrals')
  @ApiOperation({ summary: 'Get list of referrals made by user' })
  async getReferrals(@CurrentUser() user: any) {
    return this.referralsService.getReferrals(user.id);
  }

  @Get('referrals/stats')
  @ApiOperation({ summary: 'Get referral statistics' })
  async getReferralStats(@CurrentUser() user: any) {
    return this.referralsService.getReferralStats(user.id);
  }

  @Get('referral-code')
  @ApiOperation({ summary: 'Get user referral code and share URL' })
  async getReferralCode(@CurrentUser() user: any) {
    return this.referralsService.getReferralCode(user.id);
  }

  @Post('referrals/invite')
  @ApiOperation({ summary: 'Send referral invitation by email' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        email: { type: 'string', format: 'email' },
        message: { type: 'string' },
      },
      required: ['email'],
    },
  })
  async sendReferralInvite(
    @CurrentUser() user: any,
    @Body() body: { email: string; message?: string },
  ) {
    return this.referralsService.sendInvitation(user.id, body.email, body.message);
  }

  @Get('referrals/validate/:code')
  @ApiOperation({ summary: 'Validate a referral code' })
  @ApiParam({ name: 'code', description: 'Referral code to validate' })
  async validateReferralCode(@Param('code') code: string) {
    return this.referralsService.validateCode(code);
  }

  // ==================== REWARDS ====================

  @Get('rewards')
  @ApiOperation({ summary: 'Get available rewards' })
  async getRewards(@CurrentUser() user: any) {
    return this.gamificationService.getRewards(user.id);
  }

  @Post('rewards/:id/claim')
  @ApiOperation({ summary: 'Claim a reward using XP' })
  @ApiParam({ name: 'id', description: 'Reward ID' })
  async claimReward(@CurrentUser() user: any, @Param('id') rewardId: string) {
    return this.gamificationService.claimReward(user.id, rewardId);
  }

  // ==================== LEADERBOARD ====================

  @Get('leaderboard')
  @ApiOperation({ summary: 'Get XP leaderboard' })
  async getLeaderboard(@CurrentUser() user: any) {
    return this.gamificationService.getLeaderboard(user.organizationId);
  }

  // ==================== DAILY LOGIN ====================

  @Post('daily-login')
  @ApiOperation({ summary: 'Claim daily login XP and update streak' })
  async claimDailyLogin(@CurrentUser() user: any) {
    return this.gamificationService.claimDailyLogin(user.id);
  }

  // ==================== ACTION TRACKING ====================

  @Post('action')
  @ApiOperation({ summary: 'Record an action and award XP' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        action: {
          type: 'string',
          enum: [
            'daily_login',
            'publish_post',
            'comment',
            'like',
            'add_horse',
            'analyze_horse',
            'complete_profile',
            'first_follow',
          ],
        },
        metadata: { type: 'object' },
      },
      required: ['action'],
    },
  })
  async recordAction(
    @CurrentUser() user: any,
    @Body() body: { action: string; metadata?: Record<string, any> },
  ) {
    return this.gamificationService.recordAction(
      user.id,
      body.action as any,
      body.metadata,
    );
  }

  // ==================== SUMMARY ====================

  @Get('summary')
  @ApiOperation({ summary: 'Get complete gamification summary for user' })
  async getSummary(@CurrentUser() user: any) {
    const [level, streak, challengeProgress, referralStats] = await Promise.all([
      this.gamificationService.getLevel(user.id),
      this.streaksService.getStreak(user.id),
      this.challengesService.getChallengeProgress(user.id),
      this.referralsService.getReferralStats(user.id),
    ]);

    return {
      level,
      streak,
      challenges: challengeProgress,
      referrals: referralStats,
    };
  }
}
