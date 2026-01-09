import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class HashtagsService {
  constructor(private prisma: PrismaService) {}

  // Regex to extract hashtags from content
  private readonly HASHTAG_REGEX = /#([a-zA-Z0-9_\u00C0-\u024F]+)/g;

  /**
   * Extract hashtags from text content
   */
  extractHashtags(content: string): string[] {
    const matches = content.match(this.HASHTAG_REGEX) || [];
    // Normalize: remove # and lowercase
    return [...new Set(matches.map((tag) => tag.substring(1).toLowerCase()))];
  }

  /**
   * Process hashtags for a post (create/update hashtags and link them)
   * This should be called when creating or updating a post
   */
  async processHashtagsForPost(postId: string, content: string) {
    const hashtagNames = this.extractHashtags(content);

    if (hashtagNames.length === 0) {
      return [];
    }

    const now = new Date();
    const processedHashtags = [];

    for (const name of hashtagNames) {
      // Upsert hashtag
      const hashtag = await this.prisma.hashtag.upsert({
        where: { name },
        create: {
          name,
          usageCount: 1,
          lastUsedAt: now,
        },
        update: {
          usageCount: { increment: 1 },
          lastUsedAt: now,
        },
      });

      // Link hashtag to post (if not already linked)
      await this.prisma.postHashtag.upsert({
        where: {
          postId_hashtagId: {
            postId,
            hashtagId: hashtag.id,
          },
        },
        create: {
          postId,
          hashtagId: hashtag.id,
        },
        update: {},
      });

      processedHashtags.push(hashtag);
    }

    return processedHashtags;
  }

  /**
   * Remove hashtag associations when a post is deleted
   * This should be called before deleting a post
   */
  async removeHashtagsFromPost(postId: string) {
    // Get current hashtags for the post
    const postHashtags = await this.prisma.postHashtag.findMany({
      where: { postId },
      include: { hashtag: true },
    });

    // Decrement usage count for each hashtag
    for (const ph of postHashtags) {
      await this.prisma.hashtag.update({
        where: { id: ph.hashtagId },
        data: {
          usageCount: { decrement: 1 },
        },
      });
    }

    // Delete the associations
    await this.prisma.postHashtag.deleteMany({
      where: { postId },
    });
  }

  /**
   * Update hashtags when post content changes
   */
  async updateHashtagsForPost(postId: string, newContent: string) {
    const newHashtags = this.extractHashtags(newContent);

    // Get existing hashtags for the post
    const existingAssociations = await this.prisma.postHashtag.findMany({
      where: { postId },
      include: { hashtag: true },
    });

    const existingNames = existingAssociations.map((a) => a.hashtag.name);
    const now = new Date();

    // Find hashtags to add and remove
    const toAdd = newHashtags.filter((name) => !existingNames.includes(name));
    const toRemove = existingAssociations.filter(
      (a) => !newHashtags.includes(a.hashtag.name)
    );

    // Remove old hashtags
    for (const association of toRemove) {
      await this.prisma.hashtag.update({
        where: { id: association.hashtagId },
        data: { usageCount: { decrement: 1 } },
      });
      await this.prisma.postHashtag.delete({
        where: { id: association.id },
      });
    }

    // Add new hashtags
    for (const name of toAdd) {
      const hashtag = await this.prisma.hashtag.upsert({
        where: { name },
        create: {
          name,
          usageCount: 1,
          lastUsedAt: now,
        },
        update: {
          usageCount: { increment: 1 },
          lastUsedAt: now,
        },
      });

      await this.prisma.postHashtag.create({
        data: {
          postId,
          hashtagId: hashtag.id,
        },
      });
    }
  }

  // ==================== HASHTAG QUERIES ====================

  /**
   * Get trending hashtags (most used in recent posts)
   */
  async getTrendingHashtags(limit = 20, days = 7) {
    const since = new Date();
    since.setDate(since.getDate() - days);

    // Get hashtags used in recent posts, ordered by usage
    const trendingHashtags = await this.prisma.hashtag.findMany({
      where: {
        lastUsedAt: { gte: since },
        usageCount: { gt: 0 },
      },
      orderBy: [{ usageCount: 'desc' }, { lastUsedAt: 'desc' }],
      take: limit,
    });

    // Calculate trend score based on recency and usage
    return trendingHashtags.map((hashtag) => {
      const daysSinceLastUsed =
        (Date.now() - hashtag.lastUsedAt.getTime()) / (1000 * 60 * 60 * 24);
      const recencyScore = Math.max(0, 1 - daysSinceLastUsed / days);
      const trendScore = hashtag.usageCount * (0.5 + 0.5 * recencyScore);

      return {
        id: hashtag.id,
        name: hashtag.name,
        tag: `#${hashtag.name}`,
        postCount: hashtag.usageCount,
        lastUsedAt: hashtag.lastUsedAt,
        trendScore: Math.round(trendScore * 100) / 100,
      };
    });
  }

  /**
   * Get posts by hashtag
   */
  async getPostsByHashtag(
    hashtagName: string,
    userId?: string,
    page = 1,
    limit = 20
  ) {
    const skip = (page - 1) * limit;
    const normalizedName = hashtagName.toLowerCase().replace(/^#/, '');

    // Find the hashtag
    const hashtag = await this.prisma.hashtag.findUnique({
      where: { name: normalizedName },
    });

    if (!hashtag) {
      return {
        hashtag: { name: normalizedName, postCount: 0 },
        posts: [],
      };
    }

    // Get posts with this hashtag
    const postHashtags = await this.prisma.postHashtag.findMany({
      where: { hashtagId: hashtag.id },
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

    // Filter only public posts
    const posts = postHashtags
      .map((ph) => ph.post)
      .filter((post) => post.visibility === 'public');

    // Add user interaction data if userId provided
    let enrichedPosts = posts;
    if (userId && posts.length > 0) {
      const postIds = posts.map((p) => p.id);

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

      enrichedPosts = posts.map((post) => ({
        ...post,
        authorName: `${post.author.firstName} ${post.author.lastName}`,
        isLiked: likedPostIds.has(post.id),
        isSaved: savedPostIds.has(post.id),
        likeCount: (post as any)._count?.likes || post.likeCount || 0,
        commentCount: (post as any)._count?.comments || post.commentCount || 0,
      }));
    }

    return {
      hashtag: {
        id: hashtag.id,
        name: hashtag.name,
        tag: `#${hashtag.name}`,
        postCount: hashtag.usageCount,
      },
      posts: enrichedPosts,
    };
  }

  /**
   * Search hashtags by name
   */
  async searchHashtags(query: string, limit = 10) {
    const normalizedQuery = query.toLowerCase().replace(/^#/, '');

    return this.prisma.hashtag.findMany({
      where: {
        name: { contains: normalizedQuery },
        usageCount: { gt: 0 },
      },
      orderBy: { usageCount: 'desc' },
      take: limit,
      select: {
        id: true,
        name: true,
        usageCount: true,
      },
    });
  }

  /**
   * Get hashtag details
   */
  async getHashtag(name: string) {
    const normalizedName = name.toLowerCase().replace(/^#/, '');

    const hashtag = await this.prisma.hashtag.findUnique({
      where: { name: normalizedName },
    });

    if (!hashtag) {
      throw new NotFoundException(`Hashtag #${normalizedName} not found`);
    }

    return {
      id: hashtag.id,
      name: hashtag.name,
      tag: `#${hashtag.name}`,
      postCount: hashtag.usageCount,
      lastUsedAt: hashtag.lastUsedAt,
      createdAt: hashtag.createdAt,
    };
  }

  /**
   * Get related hashtags (hashtags often used together)
   */
  async getRelatedHashtags(hashtagName: string, limit = 10) {
    const normalizedName = hashtagName.toLowerCase().replace(/^#/, '');

    const hashtag = await this.prisma.hashtag.findUnique({
      where: { name: normalizedName },
    });

    if (!hashtag) {
      return [];
    }

    // Get posts with this hashtag
    const postHashtags = await this.prisma.postHashtag.findMany({
      where: { hashtagId: hashtag.id },
      select: { postId: true },
      take: 100,
    });

    const postIds = postHashtags.map((ph) => ph.postId);

    if (postIds.length === 0) {
      return [];
    }

    // Get other hashtags used in these posts
    const relatedHashtags = await this.prisma.postHashtag.groupBy({
      by: ['hashtagId'],
      where: {
        postId: { in: postIds },
        hashtagId: { not: hashtag.id },
      },
      _count: {
        hashtagId: true,
      },
      orderBy: {
        _count: {
          hashtagId: 'desc',
        },
      },
      take: limit,
    });

    // Get hashtag details
    const hashtagIds = relatedHashtags.map((rh) => rh.hashtagId);
    const hashtagDetails = await this.prisma.hashtag.findMany({
      where: { id: { in: hashtagIds } },
    });

    const hashtagMap = new Map(hashtagDetails.map((h) => [h.id, h]));

    return relatedHashtags.map((rh) => {
      const h = hashtagMap.get(rh.hashtagId)!;
      return {
        id: h.id,
        name: h.name,
        tag: `#${h.name}`,
        postCount: h.usageCount,
        coOccurrences: rh._count.hashtagId,
      };
    });
  }

  /**
   * Cleanup unused hashtags (hashtags with 0 usage count)
   */
  async cleanupUnusedHashtags() {
    const result = await this.prisma.hashtag.deleteMany({
      where: {
        usageCount: { lte: 0 },
      },
    });

    return {
      deleted: result.count,
      message: `Cleaned up ${result.count} unused hashtags`,
    };
  }
}
