import { Injectable, NotFoundException, ForbiddenException, Inject, forwardRef } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { HashtagsService } from './hashtags.service';

@Injectable()
export class SocialService {
  constructor(
    private prisma: PrismaService,
    @Inject(forwardRef(() => HashtagsService))
    private hashtagsService: HashtagsService
  ) {}

  // Helper to transform posts with isLiked, isSaved, authorName
  private async transformPosts(posts: any[], userId: string) {
    if (posts.length === 0) return posts;

    const postIds = posts.map((p) => p.id);

    // Get user's likes and saves for these posts
    const [userLikes, userSaves] = await Promise.all([
      this.prisma.like.findMany({
        where: { userId, postId: { in: postIds } },
        select: { postId: true },
      }),
      this.prisma.savedPost.findMany({
        where: { userId, postId: { in: postIds } },
        select: { postId: true },
      }),
    ]);

    const likedPostIds = new Set(userLikes.map((l) => l.postId));
    const savedPostIds = new Set(userSaves.map((s) => s.postId));

    return posts.map((post) => ({
      ...post,
      authorName: `${post.author.firstName} ${post.author.lastName}`,
      authorPhotoUrl: post.author.avatarUrl,
      isLiked: likedPostIds.has(post.id),
      isSaved: savedPostIds.has(post.id),
      likeCount: post._count?.likes || post.likeCount || 0,
      commentCount: post._count?.comments || post.commentCount || 0,
    }));
  }

  // ==================== FEED ====================

  async getForYouFeed(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const posts = await this.prisma.socialPost.findMany({
      where: {
        visibility: 'public',
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
        _count: {
          select: {
            comments: true,
            likes: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });

    return this.transformPosts(posts, userId);
  }

  async getFollowingFeed(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    // Get users the current user is following
    const following = await this.prisma.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });

    const followingIds = following.map((f) => f.followingId);

    const posts = await this.prisma.socialPost.findMany({
      where: {
        authorId: { in: followingIds },
        visibility: { in: ['public', 'followers'] },
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
        _count: {
          select: {
            comments: true,
            likes: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });

    return this.transformPosts(posts, userId);
  }

  async getTrendingPosts(page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    // Get posts from last 7 days sorted by engagement
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);

    return this.prisma.socialPost.findMany({
      where: {
        visibility: 'public',
        createdAt: { gte: weekAgo },
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
        _count: {
          select: {
            comments: true,
            likes: true,
          },
        },
      },
      orderBy: [{ likeCount: 'desc' }, { commentCount: 'desc' }, { createdAt: 'desc' }],
      skip,
      take: limit,
    });
  }

  // ==================== ENHANCED FEED WITH SCORING ====================

  /**
   * Calculate feed score for a post based on multiple factors:
   * - Recency (30%): How recent is the post
   * - Engagement (25%): Likes + comments + shares
   * - Affinity (20%): User's relationship with the author
   * - Media Quality (15%): Posts with media score higher
   * - Content Type (10%): Different content types have different weights
   */
  private calculatePostScore(
    post: any,
    userId: string,
    userInteractions: Map<string, { likedCount: number; commentedCount: number }>
  ): number {
    const now = Date.now();
    const postAge = now - new Date(post.createdAt).getTime();
    const hoursSincePost = postAge / (1000 * 60 * 60);

    // Recency score (30%) - exponential decay over 48 hours
    const recencyScore = Math.max(0, 1 - hoursSincePost / 48) * 0.3;

    // Engagement score (25%) - normalized engagement
    const totalEngagement =
      (post.likeCount || 0) + (post.commentCount || 0) * 2 + (post.shareCount || 0) * 3;
    const engagementScore = Math.min(1, totalEngagement / 100) * 0.25;

    // Affinity score (20%) - based on past interactions with the author
    let affinityScore = 0;
    const interactions = userInteractions.get(post.authorId);
    if (interactions) {
      const interactionScore =
        (interactions.likedCount * 1 + interactions.commentedCount * 2) / 10;
      affinityScore = Math.min(1, interactionScore) * 0.2;
    }

    // Media quality score (15%)
    let mediaScore = 0;
    if (post.mediaUrls && Array.isArray(post.mediaUrls) && post.mediaUrls.length > 0) {
      mediaScore = 0.15;
      if (post.mediaType === 'video') {
        mediaScore *= 1.2; // Videos score slightly higher
      }
    }

    // Content type score (10%)
    let contentTypeScore = 0.05; // Default for regular posts
    switch (post.type) {
      case 'achievement':
        contentTypeScore = 0.1;
        break;
      case 'competition':
        contentTypeScore = 0.08;
        break;
      case 'sale':
        contentTypeScore = 0.03;
        break;
    }

    return recencyScore + engagementScore + affinityScore + mediaScore + contentTypeScore;
  }

  /**
   * Get personalized "For You" feed with scoring algorithm
   */
  async getPersonalizedFeed(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    // Get blocked users to exclude
    const blockedUsers = await this.prisma.userBlock.findMany({
      where: {
        OR: [{ blockerId: userId }, { blockedId: userId }],
      },
      select: { blockerId: true, blockedId: true },
    });
    const blockedUserIds = new Set<string>();
    blockedUsers.forEach((b) => {
      blockedUserIds.add(b.blockerId);
      blockedUserIds.add(b.blockedId);
    });
    blockedUserIds.delete(userId); // Don't block self

    // Get user's past interactions for affinity calculation
    const [userLikes, userComments] = await Promise.all([
      this.prisma.like.findMany({
        where: { userId },
        include: { post: { select: { authorId: true } } },
        take: 100,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.comment.findMany({
        where: { authorId: userId },
        include: { post: { select: { authorId: true } } },
        take: 100,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    // Build interaction map
    const userInteractions = new Map<
      string,
      { likedCount: number; commentedCount: number }
    >();
    userLikes.forEach((like) => {
      const authorId = like.post.authorId;
      const existing = userInteractions.get(authorId) || {
        likedCount: 0,
        commentedCount: 0,
      };
      existing.likedCount++;
      userInteractions.set(authorId, existing);
    });
    userComments.forEach((comment) => {
      const authorId = comment.post.authorId;
      const existing = userInteractions.get(authorId) || {
        likedCount: 0,
        commentedCount: 0,
      };
      existing.commentedCount++;
      userInteractions.set(authorId, existing);
    });

    // Get candidate posts (more than needed for scoring)
    const candidatePosts = await this.prisma.socialPost.findMany({
      where: {
        visibility: 'public',
        authorId: { notIn: Array.from(blockedUserIds) },
        createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }, // Last 7 days
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
        _count: {
          select: {
            comments: true,
            likes: true,
          },
        },
      },
      take: 200, // Get more posts for scoring
    });

    // Score and sort posts
    const scoredPosts = candidatePosts
      .map((post) => ({
        ...post,
        score: this.calculatePostScore(post, userId, userInteractions),
      }))
      .sort((a, b) => b.score - a.score)
      .slice(skip, skip + limit);

    return this.transformPosts(scoredPosts, userId);
  }

  /**
   * Get discover feed - content from users you don't follow
   * Great for discovering new content and users
   */
  async getDiscoverFeed(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    // Get users the current user is following
    const following = await this.prisma.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });
    const followingIds = new Set(following.map((f) => f.followingId));
    followingIds.add(userId); // Exclude own posts

    // Get blocked users
    const blockedUsers = await this.prisma.userBlock.findMany({
      where: {
        OR: [{ blockerId: userId }, { blockedId: userId }],
      },
      select: { blockerId: true, blockedId: true },
    });
    const blockedUserIds = new Set<string>();
    blockedUsers.forEach((b) => {
      blockedUserIds.add(b.blockerId);
      blockedUserIds.add(b.blockedId);
    });

    // Combine excluded users
    const excludedUserIds = new Set([...followingIds, ...blockedUserIds]);

    // Get trending posts from users not followed
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 14); // Last 2 weeks for discover

    const posts = await this.prisma.socialPost.findMany({
      where: {
        visibility: 'public',
        authorId: { notIn: Array.from(excludedUserIds) },
        createdAt: { gte: weekAgo },
        OR: [
          { likeCount: { gte: 5 } },
          { commentCount: { gte: 2 } },
          { mediaUrls: { not: [] } },
        ],
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
            followersCount: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
        _count: {
          select: {
            comments: true,
            likes: true,
          },
        },
      },
      orderBy: [{ likeCount: 'desc' }, { commentCount: 'desc' }, { createdAt: 'desc' }],
      skip,
      take: limit,
    });

    return this.transformPosts(posts, userId);
  }

  // ==================== POSTS/NOTES ====================

  async createPost(
    userId: string,
    organizationId: string,
    data: {
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
    // Note: allowComments and allowSharing are accepted from the mobile app
    // but not stored in DB (could be added to schema later)
    const post = await this.prisma.socialPost.create({
      data: {
        content: data.content,
        type: data.type || 'post',
        mediaUrls: data.mediaUrls || [],
        mediaType: data.mediaType,
        visibility: data.visibility || 'public',
        horseId: data.horseId,
        authorId: userId,
        organizationId,
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
    });

    // Extract and process hashtags from the post content
    await this.hashtagsService.processHashtagsForPost(post.id, data.content);

    return post;
  }

  async getPost(postId: string, userId?: string) {
    const post = await this.prisma.socialPost.findUnique({
      where: { id: postId },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
        _count: {
          select: {
            comments: true,
            likes: true,
          },
        },
      },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    // Check if user has liked this post
    let isLiked = false;
    if (userId) {
      const like = await this.prisma.like.findUnique({
        where: {
          userId_postId: {
            userId,
            postId,
          },
        },
      });
      isLiked = !!like;
    }

    return { ...post, isLiked };
  }

  async getUserPosts(userId: string, viewerId?: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    // Check if viewer is following the user
    let visibilityFilter = ['public'];
    if (viewerId) {
      if (viewerId === userId) {
        visibilityFilter = ['public', 'followers', 'private'];
      } else {
        const isFollowing = await this.prisma.follow.findUnique({
          where: {
            followerId_followingId: {
              followerId: viewerId,
              followingId: userId,
            },
          },
        });
        if (isFollowing) {
          visibilityFilter = ['public', 'followers'];
        }
      }
    }

    return this.prisma.socialPost.findMany({
      where: {
        authorId: userId,
        visibility: { in: visibilityFilter },
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
        _count: {
          select: {
            comments: true,
            likes: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });
  }

  async getMyPosts(userId: string, page = 1, limit = 20) {
    return this.getUserPosts(userId, userId, page, limit);
  }

  async getSavedPosts(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const savedPosts = await this.prisma.savedPost.findMany({
      where: { userId },
      include: {
        post: {
          include: {
            author: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                avatarUrl: true,
              },
            },
            horse: {
              select: {
                id: true,
                name: true,
                photoUrl: true,
              },
            },
            _count: {
              select: {
                comments: true,
                likes: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });

    const posts = savedPosts.map((sp) => sp.post);
    return this.transformPosts(posts, userId);
  }

  async deletePost(postId: string, userId: string) {
    const post = await this.prisma.socialPost.findUnique({
      where: { id: postId },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    if (post.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own posts');
    }

    // Remove hashtag associations before deleting the post
    await this.hashtagsService.removeHashtagsFromPost(postId);

    return this.prisma.socialPost.delete({
      where: { id: postId },
    });
  }

  // ==================== COMMENTS ====================

  async getComments(postId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    return this.prisma.comment.findMany({
      where: { postId, parentId: null },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        replies: {
          include: {
            author: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                avatarUrl: true,
              },
            },
          },
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });
  }

  async addComment(postId: string, userId: string, content: string, parentId?: string) {
    // Update comment count on post
    await this.prisma.socialPost.update({
      where: { id: postId },
      data: { commentCount: { increment: 1 } },
    });

    return this.prisma.comment.create({
      data: {
        content,
        postId,
        authorId: userId,
        parentId,
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
      },
    });
  }

  // ==================== LIKES ====================

  async likePost(postId: string, userId: string) {
    const existingLike = await this.prisma.like.findUnique({
      where: {
        userId_postId: {
          userId,
          postId,
        },
      },
    });

    if (existingLike) {
      // Unlike
      await this.prisma.like.delete({
        where: { id: existingLike.id },
      });
      await this.prisma.socialPost.update({
        where: { id: postId },
        data: { likeCount: { decrement: 1 } },
      });
      return { liked: false };
    } else {
      // Like
      await this.prisma.like.create({
        data: {
          userId,
          postId,
        },
      });
      await this.prisma.socialPost.update({
        where: { id: postId },
        data: { likeCount: { increment: 1 } },
      });
      return { liked: true };
    }
  }

  // ==================== FOLLOWS ====================

  async followUser(followerId: string, followingId: string) {
    if (followerId === followingId) {
      throw new ForbiddenException('You cannot follow yourself');
    }

    const existingFollow = await this.prisma.follow.findUnique({
      where: {
        followerId_followingId: {
          followerId,
          followingId,
        },
      },
    });

    if (existingFollow) {
      // Unfollow
      await this.prisma.follow.delete({
        where: { id: existingFollow.id },
      });
      await this.prisma.user.update({
        where: { id: followerId },
        data: { followingCount: { decrement: 1 } },
      });
      await this.prisma.user.update({
        where: { id: followingId },
        data: { followersCount: { decrement: 1 } },
      });
      return { following: false };
    } else {
      // Follow
      await this.prisma.follow.create({
        data: {
          followerId,
          followingId,
        },
      });
      await this.prisma.user.update({
        where: { id: followerId },
        data: { followingCount: { increment: 1 } },
      });
      await this.prisma.user.update({
        where: { id: followingId },
        data: { followersCount: { increment: 1 } },
      });
      return { following: true };
    }
  }

  async getFollowers(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const followers = await this.prisma.follow.findMany({
      where: { followingId: userId },
      include: {
        follower: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
      },
      skip,
      take: limit,
    });

    return followers.map((f) => ({
      id: f.follower.id,
      name: `${f.follower.firstName} ${f.follower.lastName}`,
      photoUrl: f.follower.avatarUrl,
      isFollowing: false, // TODO: Check if current user follows back
    }));
  }

  async getFollowing(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const following = await this.prisma.follow.findMany({
      where: { followerId: userId },
      include: {
        following: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
      },
      skip,
      take: limit,
    });

    return following.map((f) => ({
      id: f.following.id,
      name: `${f.following.firstName} ${f.following.lastName}`,
      photoUrl: f.following.avatarUrl,
      isFollowing: true,
    }));
  }

  // ==================== USER PROFILES ====================

  async getUserProfile(userId: string, viewerId?: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        avatarUrl: true,
        bio: true,
        isPublic: true,
        followersCount: true,
        followingCount: true,
        xp: true,
        level: true,
        badges: true,
        createdAt: true,
        _count: {
          select: {
            socialPosts: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    let isFollowing = false;
    if (viewerId && viewerId !== userId) {
      const follow = await this.prisma.follow.findUnique({
        where: {
          followerId_followingId: {
            followerId: viewerId,
            followingId: userId,
          },
        },
      });
      isFollowing = !!follow;
    }

    return {
      ...user,
      name: `${user.firstName} ${user.lastName}`,
      postCount: user._count.socialPosts,
      isFollowing,
    };
  }

  async searchUsers(query: string, limit = 20) {
    return this.prisma.user.findMany({
      where: {
        OR: [
          { firstName: { contains: query } },
          { lastName: { contains: query } },
          { email: { contains: query } },
        ],
        isPublic: true,
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        avatarUrl: true,
      },
      take: limit,
    });
  }

  async getSuggestedUsers(userId: string, limit = 10) {
    // Get users that the people you follow also follow
    const following = await this.prisma.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });

    const followingIds = following.map((f) => f.followingId);
    followingIds.push(userId); // Exclude self

    return this.prisma.user.findMany({
      where: {
        id: { notIn: followingIds },
        isPublic: true,
        followersCount: { gt: 0 },
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        avatarUrl: true,
        followersCount: true,
      },
      orderBy: { followersCount: 'desc' },
      take: limit,
    });
  }

  // ==================== TRENDING ====================

  async getTrendingTags(limit = 10) {
    // This is a simplified version - in production you'd have a separate tags table
    const posts = await this.prisma.socialPost.findMany({
      where: {
        visibility: 'public',
        createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
      },
      select: { content: true },
    });

    // Extract hashtags from content
    const tagCounts: Record<string, number> = {};
    posts.forEach((post) => {
      const tags = post.content.match(/#\w+/g) || [];
      tags.forEach((tag) => {
        const normalizedTag = tag.toLowerCase();
        tagCounts[normalizedTag] = (tagCounts[normalizedTag] || 0) + 1;
      });
    });

    // Sort by count and return top tags
    return Object.entries(tagCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit)
      .map(([tag, postCount]) => ({
        tag: tag.substring(1), // Remove #
        postCount,
        trendScore: postCount,
      }));
  }

  async getPostsByTag(tag: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    return this.prisma.socialPost.findMany({
      where: {
        visibility: 'public',
        content: { contains: `#${tag}` },
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
        _count: {
          select: {
            comments: true,
            likes: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });
  }

  // ==================== UNLIKE ====================

  async unlikePost(postId: string, userId: string) {
    const existingLike = await this.prisma.like.findUnique({
      where: {
        userId_postId: {
          userId,
          postId,
        },
      },
    });

    if (existingLike) {
      await this.prisma.like.delete({
        where: { id: existingLike.id },
      });
      await this.prisma.socialPost.update({
        where: { id: postId },
        data: { likeCount: { decrement: 1 } },
      });
    }

    return { liked: false };
  }

  // ==================== SAVE/UNSAVE ====================

  async savePost(postId: string, userId: string) {
    // Check if already saved
    const existingSave = await this.prisma.savedPost.findUnique({
      where: {
        userId_postId: {
          userId,
          postId,
        },
      },
    });

    if (existingSave) {
      return { saved: true, message: 'Post already saved' };
    }

    // Save post
    await this.prisma.savedPost.create({
      data: {
        userId,
        postId,
      },
    });

    return { saved: true };
  }

  async unsavePost(postId: string, userId: string) {
    const existingSave = await this.prisma.savedPost.findUnique({
      where: {
        userId_postId: {
          userId,
          postId,
        },
      },
    });

    if (existingSave) {
      await this.prisma.savedPost.delete({
        where: { id: existingSave.id },
      });
    }

    return { saved: false };
  }

  // ==================== UPDATE POST ====================

  async updatePost(
    postId: string,
    userId: string,
    data: { content?: string; visibility?: string }
  ) {
    const post = await this.prisma.socialPost.findUnique({
      where: { id: postId },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    if (post.authorId !== userId) {
      throw new ForbiddenException('You can only edit your own posts');
    }

    const updatedPost = await this.prisma.socialPost.update({
      where: { id: postId },
      data: {
        ...(data.content && { content: data.content }),
        ...(data.visibility && { visibility: data.visibility }),
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
    });

    // Update hashtags if content was changed
    if (data.content) {
      await this.hashtagsService.updateHashtagsForPost(postId, data.content);
    }

    return updatedPost;
  }

  // ==================== UNFOLLOW ====================

  async unfollowUser(followerId: string, followingId: string) {
    const existingFollow = await this.prisma.follow.findUnique({
      where: {
        followerId_followingId: {
          followerId,
          followingId,
        },
      },
    });

    if (existingFollow) {
      await this.prisma.follow.delete({
        where: { id: existingFollow.id },
      });
      await this.prisma.user.update({
        where: { id: followerId },
        data: { followingCount: { decrement: 1 } },
      });
      await this.prisma.user.update({
        where: { id: followingId },
        data: { followersCount: { decrement: 1 } },
      });
    }

    return { following: false };
  }

  // ==================== FEED STATS ====================

  async getFeedStats(userId: string) {
    const [totalPosts, totalLikes, totalComments, activeUsers] = await Promise.all([
      this.prisma.socialPost.count({
        where: { visibility: 'public' },
      }),
      this.prisma.like.count(),
      this.prisma.comment.count(),
      this.prisma.user.count({
        where: { isActive: true },
      }),
    ]);

    // Get trending tags
    const posts = await this.prisma.socialPost.findMany({
      where: {
        visibility: 'public',
        createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
      },
      select: { content: true },
      take: 100,
    });

    const tagCounts: Record<string, number> = {};
    posts.forEach((post) => {
      const tags = post.content.match(/#\w+/g) || [];
      tags.forEach((tag) => {
        const normalizedTag = tag.toLowerCase().substring(1);
        tagCounts[normalizedTag] = (tagCounts[normalizedTag] || 0) + 1;
      });
    });

    const topTags = Object.entries(tagCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([tag]) => tag);

    return {
      totalPosts,
      totalLikes,
      totalComments,
      activeUsers,
      topTags,
    };
  }

  // ==================== HORSE NOTES ====================

  async getHorseNotes(horseId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    return this.prisma.socialPost.findMany({
      where: {
        horseId,
        visibility: { in: ['public', 'followers'] },
      },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        horse: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
        _count: {
          select: {
            comments: true,
            likes: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });
  }

  // ==================== BLOCK USER ====================

  async blockUser(blockerId: string, blockedId: string) {
    if (blockerId === blockedId) {
      throw new ForbiddenException('You cannot block yourself');
    }

    // Check if already blocked
    const existingBlock = await this.prisma.userBlock.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId,
          blockedId,
        },
      },
    });

    if (existingBlock) {
      return { blocked: true, message: 'User already blocked' };
    }

    // Create block
    await this.prisma.userBlock.create({
      data: {
        blockerId,
        blockedId,
      },
    });

    // Also unfollow in both directions if following
    await this.prisma.follow.deleteMany({
      where: {
        OR: [
          { followerId: blockerId, followingId: blockedId },
          { followerId: blockedId, followingId: blockerId },
        ],
      },
    });

    return { blocked: true, message: 'User blocked successfully' };
  }

  async unblockUser(blockerId: string, blockedId: string) {
    const existingBlock = await this.prisma.userBlock.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId,
          blockedId,
        },
      },
    });

    if (existingBlock) {
      await this.prisma.userBlock.delete({
        where: { id: existingBlock.id },
      });
    }

    return { blocked: false, message: 'User unblocked successfully' };
  }

  async getBlockedUsers(userId: string) {
    const blocks = await this.prisma.userBlock.findMany({
      where: { blockerId: userId },
      include: {
        blocked: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
      },
    });

    return blocks.map((b) => ({
      id: b.blocked.id,
      name: `${b.blocked.firstName} ${b.blocked.lastName}`,
      photoUrl: b.blocked.avatarUrl,
      blockedAt: b.createdAt,
    }));
  }

  // ==================== REPORT ====================

  async reportUser(
    reporterId: string,
    reportedId: string,
    data: { reason: string; details?: string }
  ) {
    if (reporterId === reportedId) {
      throw new ForbiddenException('You cannot report yourself');
    }

    await this.prisma.userReport.create({
      data: {
        reporterId,
        reportedUserId: reportedId,
        reason: data.reason,
        details: data.details,
        type: 'user',
        status: 'pending',
      },
    });

    return { success: true, message: 'Report submitted successfully' };
  }

  async reportPost(reporterId: string, postId: string, data: { reason: string; details?: string }) {
    const post = await this.prisma.socialPost.findUnique({
      where: { id: postId },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    await this.prisma.userReport.create({
      data: {
        reporterId,
        reportedPostId: postId,
        reportedUserId: post.authorId,
        reason: data.reason,
        details: data.details,
        type: 'post',
        status: 'pending',
      },
    });

    return { success: true, message: 'Report submitted successfully' };
  }

  // ==================== SHARE POST ====================

  async sharePost(postId: string, userId: string, data: { platform?: string; message?: string }) {
    const post = await this.prisma.socialPost.findUnique({
      where: { id: postId },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    // Increment share count
    await this.prisma.socialPost.update({
      where: { id: postId },
      data: { shareCount: { increment: 1 } },
    });

    // In a real app, you'd create a share record or integrate with social platforms
    return {
      success: true,
      message: 'Post shared successfully',
      platform: data.platform || 'internal',
      shareUrl: `/notes/${postId}`,
    };
  }

  // ==================== DELETE COMMENT ====================

  async deleteComment(commentId: string, userId: string, postId: string) {
    const comment = await this.prisma.comment.findUnique({
      where: { id: commentId },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    if (comment.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own comments');
    }

    // Delete comment
    await this.prisma.comment.delete({
      where: { id: commentId },
    });

    // Decrement comment count on post
    await this.prisma.socialPost.update({
      where: { id: postId },
      data: { commentCount: { decrement: 1 } },
    });

    return { success: true, message: 'Comment deleted successfully' };
  }

  // ==================== LIKE COMMENT ====================

  async likeComment(commentId: string, userId: string) {
    const comment = await this.prisma.comment.findUnique({
      where: { id: commentId },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    // Check if already liked
    const existingLike = await this.prisma.commentLike.findUnique({
      where: {
        userId_commentId: {
          userId,
          commentId,
        },
      },
    });

    if (existingLike) {
      // Unlike
      await this.prisma.commentLike.delete({
        where: { id: existingLike.id },
      });
      await this.prisma.comment.update({
        where: { id: commentId },
        data: { likeCount: { decrement: 1 } },
      });
      return { liked: false };
    } else {
      // Like
      await this.prisma.commentLike.create({
        data: {
          userId,
          commentId,
        },
      });
      await this.prisma.comment.update({
        where: { id: commentId },
        data: { likeCount: { increment: 1 } },
      });
      return { liked: true };
    }
  }

  async unlikeComment(commentId: string, userId: string) {
    const existingLike = await this.prisma.commentLike.findUnique({
      where: {
        userId_commentId: {
          userId,
          commentId,
        },
      },
    });

    if (existingLike) {
      await this.prisma.commentLike.delete({
        where: { id: existingLike.id },
      });
      await this.prisma.comment.update({
        where: { id: commentId },
        data: { likeCount: { decrement: 1 } },
      });
    }

    return { liked: false };
  }
}
