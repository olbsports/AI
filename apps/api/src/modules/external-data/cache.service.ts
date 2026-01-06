import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * External Data Cache Service
 *
 * Caches API responses from external sources to:
 * - Reduce API calls and costs
 * - Improve response times
 * - Handle rate limits gracefully
 * - Provide offline fallback
 */
@Injectable()
export class ExternalDataCacheService {
  private readonly logger = new Logger(ExternalDataCacheService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Get cached data
   */
  async get<T>(
    source: string,
    sourceId: string,
    dataType: string,
  ): Promise<T | null> {
    try {
      const cached = await this.prisma.externalDataCache.findUnique({
        where: {
          source_sourceId_dataType: { source, sourceId, dataType },
        },
      });

      if (!cached) return null;

      // Check if expired
      if (cached.expiresAt < new Date()) {
        // Mark as stale but still return data
        await this.prisma.externalDataCache.update({
          where: { id: cached.id },
          data: { isStale: true },
        });
        this.logger.debug(`Cache stale for ${source}/${sourceId}/${dataType}`);
      }

      return cached.data as T;
    } catch (error) {
      this.logger.error(`Cache get error for ${source}/${sourceId}`, error);
      return null;
    }
  }

  /**
   * Set cached data
   */
  async set(
    source: string,
    sourceId: string,
    dataType: string,
    data: any,
    ttlMs: number,
    horseId?: string,
  ): Promise<void> {
    try {
      const expiresAt = new Date(Date.now() + ttlMs);

      await this.prisma.externalDataCache.upsert({
        where: {
          source_sourceId_dataType: { source, sourceId, dataType },
        },
        create: {
          source,
          sourceId,
          dataType,
          data,
          expiresAt,
          horseId,
          isStale: false,
        },
        update: {
          data,
          expiresAt,
          fetchedAt: new Date(),
          isStale: false,
        },
      });

      this.logger.debug(`Cache set for ${source}/${sourceId}/${dataType}, TTL: ${ttlMs}ms`);
    } catch (error) {
      this.logger.error(`Cache set error for ${source}/${sourceId}`, error);
    }
  }

  /**
   * Invalidate cache entry
   */
  async invalidate(source: string, sourceId: string, dataType?: string): Promise<void> {
    try {
      if (dataType) {
        await this.prisma.externalDataCache.delete({
          where: {
            source_sourceId_dataType: { source, sourceId, dataType },
          },
        });
      } else {
        await this.prisma.externalDataCache.deleteMany({
          where: { source, sourceId },
        });
      }

      this.logger.debug(`Cache invalidated for ${source}/${sourceId}${dataType ? `/${dataType}` : ''}`);
    } catch (error) {
      this.logger.error(`Cache invalidation error for ${source}/${sourceId}`, error);
    }
  }

  /**
   * Invalidate all cache for a horse
   */
  async invalidateForHorse(horseId: string): Promise<void> {
    try {
      await this.prisma.externalDataCache.deleteMany({
        where: { horseId },
      });

      this.logger.debug(`Cache invalidated for horse ${horseId}`);
    } catch (error) {
      this.logger.error(`Cache invalidation error for horse ${horseId}`, error);
    }
  }

  /**
   * Get all stale entries for refresh
   */
  async getStaleEntries(source?: string, limit: number = 100): Promise<{
    id: string;
    source: string;
    sourceId: string;
    dataType: string;
    horseId?: string;
  }[]> {
    const entries = await this.prisma.externalDataCache.findMany({
      where: {
        source,
        OR: [
          { isStale: true },
          { expiresAt: { lt: new Date() } },
        ],
      },
      select: {
        id: true,
        source: true,
        sourceId: true,
        dataType: true,
        horseId: true,
      },
      take: limit,
      orderBy: { fetchedAt: 'asc' }, // Oldest first
    });

    return entries;
  }

  /**
   * Clean up expired entries
   */
  async cleanup(olderThanDays: number = 30): Promise<number> {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - olderThanDays);

    const result = await this.prisma.externalDataCache.deleteMany({
      where: {
        expiresAt: { lt: cutoff },
      },
    });

    this.logger.log(`Cleaned up ${result.count} expired cache entries`);
    return result.count;
  }

  /**
   * Get cache statistics
   */
  async getStats(): Promise<{
    totalEntries: number;
    staleEntries: number;
    bySource: Record<string, number>;
    oldestEntry: Date | null;
  }> {
    const [total, stale, bySource] = await Promise.all([
      this.prisma.externalDataCache.count(),
      this.prisma.externalDataCache.count({ where: { isStale: true } }),
      this.prisma.externalDataCache.groupBy({
        by: ['source'],
        _count: true,
      }),
    ]);

    const oldest = await this.prisma.externalDataCache.findFirst({
      orderBy: { fetchedAt: 'asc' },
      select: { fetchedAt: true },
    });

    return {
      totalEntries: total,
      staleEntries: stale,
      bySource: bySource.reduce((acc, item) => {
        acc[item.source] = item._count;
        return acc;
      }, {} as Record<string, number>),
      oldestEntry: oldest?.fetchedAt || null,
    };
  }
}
