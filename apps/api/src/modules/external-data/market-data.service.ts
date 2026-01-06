import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ScrapingService } from './scraping.service';
import { ExternalDataCacheService } from './cache.service';

/**
 * Market Data Service
 *
 * Aggregates pricing data from:
 * - Internal marketplace listings
 * - External marketplaces (scraped)
 * - Historical sales data
 *
 * Used by EquiCote for valuation
 */
@Injectable()
export class MarketDataService {
  private readonly logger = new Logger(MarketDataService.name);

  constructor(
    private prisma: PrismaService,
    private scrapingService: ScrapingService,
    private cache: ExternalDataCacheService,
  ) {}

  /**
   * Get comparable horses for valuation
   */
  async getComparables(horse: any): Promise<MarketComparables> {
    const cacheKey = `comparables_${horse.id}`;
    const cached = await this.cache.get<MarketComparables>('Market', cacheKey, 'comparables');
    if (cached) return cached;

    // Find similar horses in our marketplace
    const internalComparables = await this.getInternalComparables(horse);

    // Find from scraped data
    const externalComparables = await this.getExternalComparables(horse);

    // Calculate market statistics
    const allPrices = [
      ...internalComparables.map(c => c.price),
      ...externalComparables.map(c => c.price),
    ].filter(p => p > 0);

    const result: MarketComparables = {
      comparables: [...internalComparables, ...externalComparables],
      statistics: this.calculateStatistics(allPrices),
      averagePrice: allPrices.length > 0 ? Math.round(allPrices.reduce((a, b) => a + b, 0) / allPrices.length) : null,
      priceTrend: await this.calculatePriceTrend(horse),
      lastUpdated: new Date(),
    };

    // Cache for 6 hours
    await this.cache.set('Market', cacheKey, 'comparables', result, 6 * 60 * 60 * 1000);

    return result;
  }

  /**
   * Find comparable horses in internal marketplace
   */
  private async getInternalComparables(horse: any): Promise<ComparableHorse[]> {
    const listings = await this.prisma.marketplaceListing.findMany({
      where: {
        status: { in: ['sold', 'active'] },
        horse: {
          studbook: horse.studbook,
          birthDate: horse.birthDate ? {
            gte: new Date(horse.birthDate.getFullYear() - 3, 0, 1),
            lte: new Date(horse.birthDate.getFullYear() + 3, 11, 31),
          } : undefined,
          level: horse.level,
        },
        id: { not: horse.marketplaceListing?.id }, // Exclude self
      },
      include: {
        horse: true,
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });

    return listings.map(l => ({
      id: l.id,
      source: 'internal',
      name: l.horse?.name || l.title,
      studbook: l.horse?.studbook,
      birthYear: l.horse?.birthDate?.getFullYear(),
      level: l.horse?.level,
      disciplines: l.horse?.disciplines as string[],
      price: l.soldPrice || l.price || 0,
      status: l.status,
      location: l.location,
      listedDate: l.createdAt,
      soldDate: l.soldAt,
      url: null,
    }));
  }

  /**
   * Find comparable horses from external sources
   */
  private async getExternalComparables(horse: any): Promise<ComparableHorse[]> {
    // Get scraped listings
    const scrapedData = await this.prisma.externalDataCache.findMany({
      where: {
        source: { in: ['Equirodi', 'Cheval-Annonce', 'Horsetelex'] },
        dataType: 'listing',
        isStale: false,
      },
      take: 50,
    });

    // Filter by similarity
    return scrapedData
      .map(d => d.data as any)
      .filter(d => this.isSimilar(d, horse))
      .map(d => ({
        id: d.id,
        source: d.source,
        name: d.name,
        studbook: d.studbook,
        birthYear: d.birthYear,
        level: d.level,
        disciplines: d.disciplines,
        price: d.price,
        status: d.status,
        location: d.location,
        listedDate: d.listedDate ? new Date(d.listedDate) : null,
        soldDate: null,
        url: d.url,
      }));
  }

  /**
   * Check if two horses are similar for comparison
   */
  private isSimilar(listing: any, horse: any): boolean {
    // Must be same or similar studbook
    if (horse.studbook && listing.studbook && horse.studbook !== listing.studbook) {
      return false;
    }

    // Age within 5 years
    if (horse.birthDate && listing.birthYear) {
      const horseYear = horse.birthDate.getFullYear();
      if (Math.abs(horseYear - listing.birthYear) > 5) {
        return false;
      }
    }

    // Similar level (if available)
    if (horse.level && listing.level) {
      const levelSimilarity = this.getLevelSimilarity(horse.level, listing.level);
      if (levelSimilarity < 0.5) return false;
    }

    return true;
  }

  /**
   * Calculate level similarity score (0-1)
   */
  private getLevelSimilarity(level1: string, level2: string): number {
    const levels = ['loisir', 'club_4', 'club_3', 'club_2', 'club_1', 'amateur_3', 'amateur_2', 'amateur_1', 'pro_2', 'pro_1', 'pro_elite'];
    const idx1 = levels.findIndex(l => level1.toLowerCase().includes(l.replace('_', ' ')));
    const idx2 = levels.findIndex(l => level2.toLowerCase().includes(l.replace('_', ' ')));

    if (idx1 === -1 || idx2 === -1) return 0.5;

    const diff = Math.abs(idx1 - idx2);
    return Math.max(0, 1 - diff * 0.2);
  }

  /**
   * Calculate price statistics
   */
  private calculateStatistics(prices: number[]): MarketStatistics {
    if (prices.length === 0) {
      return {
        count: 0,
        min: 0,
        max: 0,
        mean: 0,
        median: 0,
        stdDev: 0,
      };
    }

    const sorted = [...prices].sort((a, b) => a - b);
    const mean = prices.reduce((a, b) => a + b, 0) / prices.length;
    const median = sorted.length % 2 === 0
      ? (sorted[sorted.length / 2 - 1] + sorted[sorted.length / 2]) / 2
      : sorted[Math.floor(sorted.length / 2)];

    const squareDiffs = prices.map(p => Math.pow(p - mean, 2));
    const avgSquareDiff = squareDiffs.reduce((a, b) => a + b, 0) / prices.length;
    const stdDev = Math.sqrt(avgSquareDiff);

    return {
      count: prices.length,
      min: sorted[0],
      max: sorted[sorted.length - 1],
      mean: Math.round(mean),
      median: Math.round(median),
      stdDev: Math.round(stdDev),
    };
  }

  /**
   * Calculate price trend (% change over 12 months)
   */
  private async calculatePriceTrend(horse: any): Promise<number | null> {
    const twelveMonthsAgo = new Date();
    twelveMonthsAgo.setMonth(twelveMonthsAgo.getMonth() - 12);

    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    // Get average prices for last 6 months and 6-12 months ago
    const recentSales = await this.prisma.marketplaceListing.aggregate({
      where: {
        status: 'sold',
        soldAt: { gte: sixMonthsAgo },
        horse: {
          studbook: horse.studbook,
          level: horse.level,
        },
      },
      _avg: { soldPrice: true },
      _count: true,
    });

    const olderSales = await this.prisma.marketplaceListing.aggregate({
      where: {
        status: 'sold',
        soldAt: {
          gte: twelveMonthsAgo,
          lt: sixMonthsAgo,
        },
        horse: {
          studbook: horse.studbook,
          level: horse.level,
        },
      },
      _avg: { soldPrice: true },
      _count: true,
    });

    if (!recentSales._avg.soldPrice || !olderSales._avg.soldPrice) {
      return null;
    }

    if (recentSales._count < 3 || olderSales._count < 3) {
      return null; // Not enough data
    }

    const trend = ((recentSales._avg.soldPrice - olderSales._avg.soldPrice) / olderSales._avg.soldPrice) * 100;
    return Math.round(trend * 10) / 10;
  }

  /**
   * Get market price history for a studbook/level combination
   */
  async getPriceHistory(params: {
    studbook?: string;
    level?: string;
    discipline?: string;
    months?: number;
  }): Promise<PriceHistoryPoint[]> {
    const monthsBack = params.months || 24;
    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - monthsBack);

    const sales = await this.prisma.marketplaceListing.findMany({
      where: {
        status: 'sold',
        soldAt: { gte: startDate },
        soldPrice: { not: null },
        horse: {
          studbook: params.studbook,
          level: params.level,
          disciplines: params.discipline ? { has: params.discipline } : undefined,
        },
      },
      select: {
        soldAt: true,
        soldPrice: true,
      },
      orderBy: { soldAt: 'asc' },
    });

    // Group by month
    const byMonth = new Map<string, number[]>();
    for (const sale of sales) {
      const monthKey = sale.soldAt!.toISOString().slice(0, 7);
      if (!byMonth.has(monthKey)) {
        byMonth.set(monthKey, []);
      }
      byMonth.get(monthKey)!.push(sale.soldPrice!);
    }

    // Calculate monthly averages
    const history: PriceHistoryPoint[] = [];
    byMonth.forEach((prices, month) => {
      history.push({
        month,
        averagePrice: Math.round(prices.reduce((a, b) => a + b, 0) / prices.length),
        count: prices.length,
        minPrice: Math.min(...prices),
        maxPrice: Math.max(...prices),
      });
    });

    return history.sort((a, b) => a.month.localeCompare(b.month));
  }
}

// Type definitions
export interface ComparableHorse {
  id: string;
  source: string;
  name: string;
  studbook?: string;
  birthYear?: number;
  level?: string;
  disciplines?: string[];
  price: number;
  status: string;
  location?: string;
  listedDate?: Date;
  soldDate?: Date;
  url?: string;
}

export interface MarketStatistics {
  count: number;
  min: number;
  max: number;
  mean: number;
  median: number;
  stdDev: number;
}

export interface MarketComparables {
  comparables: ComparableHorse[];
  statistics: MarketStatistics;
  averagePrice: number | null;
  priceTrend: number | null;
  lastUpdated: Date;
}

export interface PriceHistoryPoint {
  month: string;
  averagePrice: number;
  count: number;
  minPrice: number;
  maxPrice: number;
}
