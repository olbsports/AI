import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class StoriesService {
  constructor(private prisma: PrismaService) {}

  // ==================== STORIES ====================

  /**
   * Create a new story (expires in 24h)
   */
  async createStory(
    userId: string,
    data: {
      mediaUrl: string;
      mediaType?: string;
      caption?: string;
    }
  ) {
    // Calculate expiration time (24 hours from now)
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    return this.prisma.story.create({
      data: {
        mediaUrl: data.mediaUrl,
        mediaType: data.mediaType || 'image',
        caption: data.caption,
        expiresAt,
        authorId: userId,
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

  /**
   * Get a specific story by ID
   */
  async getStory(storyId: string, viewerId?: string) {
    const story = await this.prisma.story.findUnique({
      where: { id: storyId },
      include: {
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        _count: {
          select: {
            views: true,
          },
        },
      },
    });

    if (!story) {
      throw new NotFoundException('Story not found');
    }

    // Check if story has expired
    if (new Date() > story.expiresAt) {
      throw new NotFoundException('Story has expired');
    }

    // Check if viewer has already viewed this story
    let hasViewed = false;
    if (viewerId) {
      const view = await this.prisma.storyView.findUnique({
        where: {
          storyId_visitorId: {
            storyId,
            visitorId: viewerId,
          },
        },
      });
      hasViewed = !!view;
    }

    return {
      ...story,
      authorName: `${story.author.firstName} ${story.author.lastName}`,
      viewCount: story._count.views,
      hasViewed,
      isExpired: false,
      timeRemaining: story.expiresAt.getTime() - Date.now(),
    };
  }

  /**
   * Get all active stories from users the current user follows
   * Returns stories grouped by user
   */
  async getStories(userId: string) {
    const now = new Date();

    // Get users the current user is following
    const following = await this.prisma.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });

    const followingIds = following.map((f) => f.followingId);

    // Include user's own stories
    followingIds.push(userId);

    // Get active stories from followed users
    const stories = await this.prisma.story.findMany({
      where: {
        authorId: { in: followingIds },
        expiresAt: { gt: now },
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
        views: {
          where: { visitorId: userId },
          select: { id: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Group stories by author
    const storiesByUser = new Map<
      string,
      {
        user: {
          id: string;
          firstName: string;
          lastName: string;
          avatarUrl: string | null;
        };
        stories: any[];
        hasUnviewed: boolean;
      }
    >();

    for (const story of stories) {
      const authorId = story.authorId;
      if (!storiesByUser.has(authorId)) {
        storiesByUser.set(authorId, {
          user: story.author,
          stories: [],
          hasUnviewed: false,
        });
      }

      const userStories = storiesByUser.get(authorId)!;
      const hasViewed = story.views.length > 0;

      userStories.stories.push({
        id: story.id,
        mediaUrl: story.mediaUrl,
        mediaType: story.mediaType,
        caption: story.caption,
        viewsCount: story.viewsCount,
        expiresAt: story.expiresAt,
        createdAt: story.createdAt,
        hasViewed,
      });

      if (!hasViewed) {
        userStories.hasUnviewed = true;
      }
    }

    // Convert to array and sort by hasUnviewed (unviewed first), then by latest story
    return Array.from(storiesByUser.values()).sort((a, b) => {
      if (a.hasUnviewed !== b.hasUnviewed) {
        return a.hasUnviewed ? -1 : 1;
      }
      return (
        new Date(b.stories[0].createdAt).getTime() -
        new Date(a.stories[0].createdAt).getTime()
      );
    });
  }

  /**
   * Get stories by a specific user
   */
  async getUserStories(userId: string, viewerId?: string) {
    const now = new Date();

    const stories = await this.prisma.story.findMany({
      where: {
        authorId: userId,
        expiresAt: { gt: now },
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
        ...(viewerId && {
          views: {
            where: { visitorId: viewerId },
            select: { id: true },
          },
        }),
      },
      orderBy: { createdAt: 'desc' },
    });

    return stories.map((story) => ({
      ...story,
      authorName: `${story.author.firstName} ${story.author.lastName}`,
      hasViewed: viewerId ? (story as any).views?.length > 0 : undefined,
    }));
  }

  /**
   * Delete a story (only author can delete)
   */
  async deleteStory(storyId: string, userId: string) {
    const story = await this.prisma.story.findUnique({
      where: { id: storyId },
    });

    if (!story) {
      throw new NotFoundException('Story not found');
    }

    if (story.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own stories');
    }

    await this.prisma.story.delete({
      where: { id: storyId },
    });

    return { success: true, message: 'Story deleted successfully' };
  }

  /**
   * Record a story view
   */
  async viewStory(storyId: string, visitorId: string) {
    const story = await this.prisma.story.findUnique({
      where: { id: storyId },
    });

    if (!story) {
      throw new NotFoundException('Story not found');
    }

    // Check if story has expired
    if (new Date() > story.expiresAt) {
      throw new NotFoundException('Story has expired');
    }

    // Don't count views from story author
    if (story.authorId === visitorId) {
      return { viewed: true, message: 'Author view not counted' };
    }

    // Check if already viewed
    const existingView = await this.prisma.storyView.findUnique({
      where: {
        storyId_visitorId: {
          storyId,
          visitorId,
        },
      },
    });

    if (existingView) {
      return { viewed: true, message: 'Already viewed' };
    }

    // Create view and increment counter
    await this.prisma.$transaction([
      this.prisma.storyView.create({
        data: {
          storyId,
          visitorId,
        },
      }),
      this.prisma.story.update({
        where: { id: storyId },
        data: { viewsCount: { increment: 1 } },
      }),
    ]);

    return { viewed: true, message: 'View recorded' };
  }

  /**
   * Get viewers of a story (only author can see)
   */
  async getStoryViewers(storyId: string, userId: string, page = 1, limit = 50) {
    const story = await this.prisma.story.findUnique({
      where: { id: storyId },
    });

    if (!story) {
      throw new NotFoundException('Story not found');
    }

    if (story.authorId !== userId) {
      throw new ForbiddenException('Only the author can see story viewers');
    }

    const skip = (page - 1) * limit;

    const viewers = await this.prisma.storyView.findMany({
      where: { storyId },
      include: {
        visitor: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { viewedAt: 'desc' },
      skip,
      take: limit,
    });

    return viewers.map((v) => ({
      id: v.visitor.id,
      name: `${v.visitor.firstName} ${v.visitor.lastName}`,
      avatarUrl: v.visitor.avatarUrl,
      viewedAt: v.viewedAt,
    }));
  }

  /**
   * Cleanup expired stories (can be called by a cron job)
   */
  async cleanupExpiredStories() {
    const now = new Date();

    const result = await this.prisma.story.deleteMany({
      where: {
        expiresAt: { lt: now },
      },
    });

    return {
      deleted: result.count,
      message: `Cleaned up ${result.count} expired stories`,
    };
  }

  /**
   * Get story count for a user (active stories)
   */
  async getUserStoryCount(userId: string) {
    const now = new Date();

    return this.prisma.story.count({
      where: {
        authorId: userId,
        expiresAt: { gt: now },
      },
    });
  }
}
