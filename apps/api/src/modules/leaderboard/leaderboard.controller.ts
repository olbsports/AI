import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { LeaderboardService } from './leaderboard.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('leaderboard')
@Controller('leaderboard')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class LeaderboardController {
  constructor(private readonly leaderboardService: LeaderboardService) {}

  @Get('riders')
  @ApiOperation({ summary: 'Get rider leaderboard' })
  async getRiderLeaderboard(
    @Query('period') period?: string,
    @Query('galopLevel') galopLevel?: string,
  ) {
    return this.leaderboardService.getRiderLeaderboard(
      period || 'weekly',
      galopLevel ? parseInt(galopLevel) : undefined,
    );
  }

  @Get('horses')
  @ApiOperation({ summary: 'Get horse leaderboard' })
  async getHorseLeaderboard(
    @Query('period') period?: string,
    @Query('discipline') discipline?: string,
    @Query('category') category?: string,
  ) {
    return this.leaderboardService.getHorseLeaderboard(
      period || 'weekly',
      discipline,
      category,
    );
  }

  @Get('riders/me')
  @ApiOperation({ summary: 'Get current user rider ranking' })
  async getMyRiderRanking(@CurrentUser() user: any) {
    return this.leaderboardService.getMyRiderRanking(user.id);
  }

  @Get('horses/mine')
  @ApiOperation({ summary: 'Get current user horse rankings' })
  async getMyHorseRankings(@CurrentUser() user: any) {
    return this.leaderboardService.getMyHorseRankings(user.id, user.organizationId);
  }

  @Get('riders/top')
  @ApiOperation({ summary: 'Get top riders overall' })
  async getTopRiders() {
    return this.leaderboardService.getTopRiders();
  }

  @Get('horses/top')
  @ApiOperation({ summary: 'Get top horses overall' })
  async getTopHorses() {
    return this.leaderboardService.getTopHorses();
  }

  @Get('riders/rising')
  @ApiOperation({ summary: 'Get rising riders (most improved)' })
  async getRisingRiders() {
    return this.leaderboardService.getRisingRiders();
  }

  @Get('horses/rising')
  @ApiOperation({ summary: 'Get rising horses (most improved)' })
  async getRisingHorses() {
    return this.leaderboardService.getRisingHorses();
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get leaderboard statistics' })
  async getStats() {
    return this.leaderboardService.getStats();
  }

  @Get('regional/:region')
  @ApiOperation({ summary: 'Get regional leaderboard' })
  async getRegionalLeaderboard(@Param('region') region: string) {
    return this.leaderboardService.getRegionalLeaderboard(region);
  }

  @Get('clubs')
  @ApiOperation({ summary: 'Get club leaderboard' })
  async getClubLeaderboard() {
    return this.leaderboardService.getClubLeaderboard();
  }

  @Get('weekly-rewards')
  @ApiOperation({ summary: 'Get weekly rewards' })
  async getWeeklyRewards(@CurrentUser() user: any) {
    return this.leaderboardService.getWeeklyRewards(user.id);
  }

  @Post('challenge')
  @ApiOperation({ summary: 'Challenge another rider' })
  async challengeRider(
    @CurrentUser() user: any,
    @Body() body: { riderId: string },
  ) {
    return this.leaderboardService.challengeRider(user.id, body.riderId);
  }

  @Post('share')
  @ApiOperation({ summary: 'Share ranking' })
  async shareRanking(@Body() body: { type: string; id: string }) {
    return this.leaderboardService.shareRanking(body.type, body.id);
  }

  @Post('claim-reward')
  @ApiOperation({ summary: 'Claim weekly reward' })
  async claimWeeklyReward(@CurrentUser() user: any) {
    return this.leaderboardService.claimWeeklyReward(user.id);
  }
}
