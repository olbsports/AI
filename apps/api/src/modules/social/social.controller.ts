import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { SocialService } from './social.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('social')
@Controller()
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SocialController {
  constructor(private readonly socialService: SocialService) {}

  // ==================== FEED ENDPOINTS ====================

  @Get('feed/for-you')
  @ApiOperation({ summary: 'Get personalized feed' })
  async getForYouFeed(
    @CurrentUser() user: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.socialService.getForYouFeed(
      user.id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20
    );
  }

  @Get('feed/following')
  @ApiOperation({ summary: 'Get feed from followed users' })
  async getFollowingFeed(
    @CurrentUser() user: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.socialService.getFollowingFeed(
      user.id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20
    );
  }

  @Get('feed/trending')
  @ApiOperation({ summary: 'Get trending posts' })
  async getTrendingPosts(@Query('page') page?: string, @Query('limit') limit?: string) {
    return this.socialService.getTrendingPosts(
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20
    );
  }

  @Get('feed/trending-tags')
  @ApiOperation({ summary: 'Get trending hashtags' })
  async getTrendingTags(@Query('limit') limit?: string) {
    return this.socialService.getTrendingTags(limit ? parseInt(limit) : 10);
  }

  @Get('feed/tags/:tag')
  @ApiOperation({ summary: 'Get posts by hashtag' })
  async getPostsByTag(
    @Param('tag') tag: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.socialService.getPostsByTag(
      tag,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20
    );
  }

  // ==================== NOTES/POSTS ENDPOINTS ====================

  @Post('notes')
  @ApiOperation({ summary: 'Create a new post/note' })
  async createPost(
    @CurrentUser() user: any,
    @Body()
    body: {
      content: string;
      type?: string;
      mediaUrls?: string[];
      mediaType?: string;
      visibility?: string;
      horseId?: string;
      allowComments?: boolean;
      allowSharing?: boolean;
    }
  ) {
    return this.socialService.createPost(user.id, user.organizationId, body);
  }

  @Get('notes/my')
  @ApiOperation({ summary: 'Get current user posts' })
  async getMyPosts(
    @CurrentUser() user: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.socialService.getMyPosts(
      user.id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20
    );
  }

  @Get('notes/saved')
  @ApiOperation({ summary: 'Get saved posts' })
  async getSavedPosts(@CurrentUser() user: any) {
    // TODO: Implement saved posts feature
    return [];
  }

  @Get('notes/:id')
  @ApiOperation({ summary: 'Get post by ID' })
  async getPost(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.getPost(id, user.id);
  }

  @Delete('notes/:id')
  @ApiOperation({ summary: 'Delete a post' })
  async deletePost(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.deletePost(id, user.id);
  }

  @Get('notes/:id/comments')
  @ApiOperation({ summary: 'Get comments for a post' })
  async getComments(
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.socialService.getComments(
      id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20
    );
  }

  @Post('notes/:id/comments')
  @ApiOperation({ summary: 'Add a comment to a post' })
  async addComment(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { content: string; parentId?: string }
  ) {
    return this.socialService.addComment(id, user.id, body.content, body.parentId);
  }

  @Post('notes/:id/like')
  @ApiOperation({ summary: 'Like a post' })
  async likePost(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.likePost(id, user.id);
  }

  @Delete('notes/:id/like')
  @ApiOperation({ summary: 'Unlike a post' })
  async unlikePost(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.unlikePost(id, user.id);
  }

  @Post('notes/:id/save')
  @ApiOperation({ summary: 'Save a post' })
  async savePost(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.savePost(id, user.id);
  }

  @Delete('notes/:id/save')
  @ApiOperation({ summary: 'Unsave a post' })
  async unsavePost(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.unsavePost(id, user.id);
  }

  @Post('notes/:id/share')
  @ApiOperation({ summary: 'Share a post' })
  async sharePost(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { platform?: string; message?: string }
  ) {
    return this.socialService.sharePost(id, user.id, body);
  }

  @Delete('notes/:id/comments/:commentId')
  @ApiOperation({ summary: 'Delete a comment' })
  async deleteComment(
    @CurrentUser() user: any,
    @Param('id') postId: string,
    @Param('commentId') commentId: string
  ) {
    return this.socialService.deleteComment(commentId, user.id, postId);
  }

  @Post('notes/:id/comments/:commentId/like')
  @ApiOperation({ summary: 'Like a comment' })
  async likeComment(
    @CurrentUser() user: any,
    @Param('id') postId: string,
    @Param('commentId') commentId: string
  ) {
    return this.socialService.likeComment(commentId, user.id);
  }

  @Put('notes/:id')
  @ApiOperation({ summary: 'Update a post' })
  async updatePost(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { content?: string; visibility?: string }
  ) {
    return this.socialService.updatePost(id, user.id, body);
  }

  // ==================== USER ENDPOINTS ====================

  @Get('users/search')
  @ApiOperation({ summary: 'Search users' })
  async searchUsers(@Query('q') query: string) {
    return this.socialService.searchUsers(query || '');
  }

  @Get('users/suggested')
  @ApiOperation({ summary: 'Get suggested users to follow' })
  async getSuggestedUsers(@CurrentUser() user: any) {
    return this.socialService.getSuggestedUsers(user.id);
  }

  @Get('users/:id/profile')
  @ApiOperation({ summary: 'Get user profile' })
  async getUserProfile(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.getUserProfile(id, user.id);
  }

  @Get('users/:id/notes')
  @ApiOperation({ summary: 'Get user posts' })
  async getUserPosts(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.socialService.getUserPosts(
      id,
      user.id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20
    );
  }

  @Get('users/:id/followers')
  @ApiOperation({ summary: 'Get user followers' })
  async getFollowers(
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.socialService.getFollowers(
      id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20
    );
  }

  @Get('users/:id/following')
  @ApiOperation({ summary: 'Get users that user is following' })
  async getFollowing(
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.socialService.getFollowing(
      id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20
    );
  }

  @Post('users/:id/follow')
  @ApiOperation({ summary: 'Follow a user' })
  async followUser(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.followUser(user.id, id);
  }

  @Delete('users/:id/follow')
  @ApiOperation({ summary: 'Unfollow a user' })
  async unfollowUser(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.unfollowUser(user.id, id);
  }

  // ==================== FEED STATS ====================

  @Get('feed/stats')
  @ApiOperation({ summary: 'Get feed statistics' })
  async getFeedStats(@CurrentUser() user: any) {
    return this.socialService.getFeedStats(user.id);
  }

  // ==================== HORSE NOTES ====================

  @Get('horses/:id/notes')
  @ApiOperation({ summary: 'Get notes for a horse' })
  async getHorseNotes(
    @Param('id') horseId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.socialService.getHorseNotes(
      horseId,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20
    );
  }

  // ==================== BLOCK USER ====================

  @Post('users/:id/block')
  @ApiOperation({ summary: 'Block a user' })
  async blockUser(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.blockUser(user.id, id);
  }

  @Delete('users/:id/block')
  @ApiOperation({ summary: 'Unblock a user' })
  async unblockUser(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.unblockUser(user.id, id);
  }

  @Get('blocked-users')
  @ApiOperation({ summary: 'Get blocked users list' })
  async getBlockedUsers(@CurrentUser() user: any) {
    return this.socialService.getBlockedUsers(user.id);
  }

  // ==================== REPORT ====================

  @Post('users/:id/report')
  @ApiOperation({ summary: 'Report a user' })
  async reportUser(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { reason: string; details?: string }
  ) {
    return this.socialService.reportUser(user.id, id, body);
  }

  @Post('notes/:id/report')
  @ApiOperation({ summary: 'Report a post/note' })
  async reportPost(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { reason: string; details?: string }
  ) {
    return this.socialService.reportPost(user.id, id, body);
  }
}
