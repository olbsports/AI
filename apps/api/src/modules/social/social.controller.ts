import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
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
    @Query('limit') limit?: string,
  ) {
    return this.socialService.getForYouFeed(
      user.id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Get('feed/following')
  @ApiOperation({ summary: 'Get feed from followed users' })
  async getFollowingFeed(
    @CurrentUser() user: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.socialService.getFollowingFeed(
      user.id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Get('feed/trending')
  @ApiOperation({ summary: 'Get trending posts' })
  async getTrendingPosts(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.socialService.getTrendingPosts(
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
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
    @Query('limit') limit?: string,
  ) {
    return this.socialService.getPostsByTag(
      tag,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  // ==================== NOTES/POSTS ENDPOINTS ====================

  @Post('notes')
  @ApiOperation({ summary: 'Create a new post/note' })
  async createPost(
    @CurrentUser() user: any,
    @Body() body: {
      content: string;
      type?: string;
      mediaUrls?: string[];
      mediaType?: string;
      visibility?: string;
      horseId?: string;
      allowComments?: boolean;
      allowSharing?: boolean;
    },
  ) {
    return this.socialService.createPost(user.id, user.organizationId, body);
  }

  @Get('notes/my')
  @ApiOperation({ summary: 'Get current user posts' })
  async getMyPosts(
    @CurrentUser() user: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.socialService.getMyPosts(
      user.id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
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
    @Query('limit') limit?: string,
  ) {
    return this.socialService.getComments(
      id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Post('notes/:id/comments')
  @ApiOperation({ summary: 'Add a comment to a post' })
  async addComment(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { content: string; parentId?: string },
  ) {
    return this.socialService.addComment(id, user.id, body.content, body.parentId);
  }

  @Post('notes/:id/like')
  @ApiOperation({ summary: 'Like/unlike a post' })
  async likePost(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.likePost(id, user.id);
  }

  @Post('notes/:id/save')
  @ApiOperation({ summary: 'Save/unsave a post' })
  async savePost(@CurrentUser() user: any, @Param('id') id: string) {
    // TODO: Implement save feature
    return { saved: true };
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
    @Query('limit') limit?: string,
  ) {
    return this.socialService.getUserPosts(
      id,
      user.id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Get('users/:id/followers')
  @ApiOperation({ summary: 'Get user followers' })
  async getFollowers(
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.socialService.getFollowers(
      id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Get('users/:id/following')
  @ApiOperation({ summary: 'Get users that user is following' })
  async getFollowing(
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.socialService.getFollowing(
      id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Post('users/:id/follow')
  @ApiOperation({ summary: 'Follow/unfollow a user' })
  async followUser(@CurrentUser() user: any, @Param('id') id: string) {
    return this.socialService.followUser(user.id, id);
  }

  // ==================== HORSE NOTES ====================

  @Get('horses/:id/notes')
  @ApiOperation({ summary: 'Get notes for a horse' })
  async getHorseNotes(
    @Param('id') horseId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const skip = (page ? parseInt(page) - 1 : 0) * (limit ? parseInt(limit) : 20);
    // This would need to be implemented in the service
    return [];
  }
}
