import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SocialService {
  constructor(private prisma: PrismaService) {}

  // ==================== FEED ====================

  async getForYouFeed(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    return this.prisma.socialPost.findMany({
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
  }

  async getFollowingFeed(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    // Get users the current user is following
    const following = await this.prisma.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });

    const followingIds = following.map(f => f.followingId);

    return this.prisma.socialPost.findMany({
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
      orderBy: [
        { likeCount: 'desc' },
        { commentCount: 'desc' },
        { createdAt: 'desc' },
      ],
      skip,
      take: limit,
    });
  }

  // ==================== POSTS/NOTES ====================

  async createPost(userId: string, organizationId: string, data: {
    content: string;
    type?: string;
    mediaUrls?: string[];
    mediaType?: string;
    visibility?: string;
    horseId?: string;
  }) {
    return this.prisma.socialPost.create({
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

    return followers.map(f => ({
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

    return following.map(f => ({
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

    const followingIds = following.map(f => f.followingId);
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
    posts.forEach(post => {
      const tags = post.content.match(/#\w+/g) || [];
      tags.forEach(tag => {
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
}
