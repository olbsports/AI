import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { ClubsService } from './clubs.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('clubs')
@Controller('clubs')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ClubsController {
  constructor(private readonly clubsService: ClubsService) {}

  @Get('my')
  @ApiOperation({ summary: 'Get user clubs' })
  async getMyClubs(@CurrentUser() user: any) {
    return this.clubsService.getMyClubs(user.id);
  }

  @Get('leaderboard')
  @ApiOperation({ summary: 'Get club leaderboard' })
  async getLeaderboard(@Query('type') type?: string) {
    return this.clubsService.getLeaderboard(type);
  }

  @Get('challenges/active')
  @ApiOperation({ summary: 'Get active challenges' })
  async getActiveChallenges() {
    return this.clubsService.getActiveChallenges();
  }

  @Get('events/upcoming')
  @ApiOperation({ summary: 'Get upcoming events' })
  async getUpcomingEvents() {
    return this.clubsService.getUpcomingEvents();
  }

  @Get('invitations')
  @ApiOperation({ summary: 'Get club invitations' })
  async getInvitations(@CurrentUser() user: any) {
    return this.clubsService.getInvitations(user.id);
  }

  @Get('search')
  @ApiOperation({ summary: 'Search clubs' })
  async searchClubs(@Query('q') query: string) {
    return this.clubsService.searchClubs(query || '');
  }

  @Get('nearby')
  @ApiOperation({ summary: 'Get nearby clubs' })
  async getNearbyClubs(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radius') radius?: string,
  ) {
    return this.clubsService.getNearbyClubs(
      parseFloat(lat),
      parseFloat(lng),
      radius ? parseFloat(radius) : 50,
    );
  }

  @Post()
  @ApiOperation({ summary: 'Create a club' })
  async createClub(
    @CurrentUser() user: any,
    @Body() body: {
      name: string;
      description?: string;
      type?: string;
      location?: string;
      isPublic?: boolean;
    },
  ) {
    return this.clubsService.createClub(user.id, user.organizationId, body);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get club by ID' })
  async getClub(@Param('id') id: string) {
    return this.clubsService.getClub(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update club' })
  async updateClub(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.clubsService.updateClub(id, user.id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete club' })
  async deleteClub(@CurrentUser() user: any, @Param('id') id: string) {
    return this.clubsService.deleteClub(id, user.id);
  }

  @Get(':id/members')
  @ApiOperation({ summary: 'Get club members' })
  async getMembers(@Param('id') id: string) {
    return this.clubsService.getMembers(id);
  }

  @Post(':id/join')
  @ApiOperation({ summary: 'Join club' })
  async joinClub(@CurrentUser() user: any, @Param('id') id: string) {
    return this.clubsService.joinClub(id, user.id, user.organizationId);
  }

  @Post(':id/leave')
  @ApiOperation({ summary: 'Leave club' })
  async leaveClub(@CurrentUser() user: any, @Param('id') id: string) {
    return this.clubsService.leaveClub(id, user.id);
  }

  @Put(':id/members/:memberId')
  @ApiOperation({ summary: 'Update member role' })
  async updateMemberRole(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Param('memberId') memberId: string,
    @Body() body: { role: string },
  ) {
    return this.clubsService.updateMemberRole(id, memberId, user.id, body.role);
  }

  @Delete(':id/members/:memberId')
  @ApiOperation({ summary: 'Remove member' })
  async removeMember(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Param('memberId') memberId: string,
  ) {
    return this.clubsService.removeMember(id, memberId, user.id);
  }

  @Get(':id/challenges')
  @ApiOperation({ summary: 'Get club challenges' })
  async getChallenges(@Param('id') id: string) {
    return this.clubsService.getChallenges(id);
  }

  @Get(':id/events')
  @ApiOperation({ summary: 'Get club events' })
  async getEvents(@Param('id') id: string) {
    return this.clubsService.getEvents(id);
  }

  @Get(':id/posts')
  @ApiOperation({ summary: 'Get club posts' })
  async getPosts(@Param('id') id: string) {
    return this.clubsService.getPosts(id);
  }

  @Get(':id/stats')
  @ApiOperation({ summary: 'Get club statistics' })
  async getStats(@Param('id') id: string) {
    return this.clubsService.getStats(id);
  }
}
