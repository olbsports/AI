import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { FFEService } from '../external-data/ffe.service';
import { SireWebService } from '../external-data/sireweb.service';
import { IFCEService } from '../external-data/ifce.service';
import { ExternalDataCacheService } from '../external-data/cache.service';
import { ScrapingService } from '../external-data/scraping.service';

/**
 * Data Synchronization Service
 *
 * Handles:
 * - Periodic sync of horse data from external sources
 * - Competition results updates
 * - Market data refresh
 * - Cache management
 */
@Injectable()
export class DataSyncService {
  private readonly logger = new Logger(DataSyncService.name);

  constructor(
    private prisma: PrismaService,
    private ffeService: FFEService,
    private sireWebService: SireWebService,
    private ifceService: IFCEService,
    private cacheService: ExternalDataCacheService,
    private scrapingService: ScrapingService,
  ) {}

  /**
   * Sync a single horse from all sources
   */
  async syncHorse(horseId: string): Promise<SyncResult> {
    const startTime = Date.now();
    const result: SyncResult = {
      horseId,
      success: true,
      sources: [],
      addedRecords: 0,
      updatedRecords: 0,
      errors: [],
    };

    const horse = await this.prisma.horse.findUnique({
      where: { id: horseId },
    });

    if (!horse) {
      return { ...result, success: false, errors: ['Horse not found'] };
    }

    // Sync from FFE
    if (horse.ffeNumber) {
      try {
        const ffeResult = await this.syncFromFFE(horse);
        result.sources.push('FFE');
        result.addedRecords += ffeResult.added;
        result.updatedRecords += ffeResult.updated;
      } catch (error) {
        result.errors.push(`FFE: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    // Sync from SireWeb
    if (horse.sireId) {
      try {
        const sireResult = await this.syncFromSireWeb(horse);
        result.sources.push('SireWeb');
        result.addedRecords += sireResult.added;
        result.updatedRecords += sireResult.updated;
      } catch (error) {
        result.errors.push(`SireWeb: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    // Sync from IFCE
    if (horse.ueln) {
      try {
        const ifceResult = await this.syncFromIFCE(horse);
        result.sources.push('IFCE');
        result.addedRecords += ifceResult.added;
        result.updatedRecords += ifceResult.updated;
      } catch (error) {
        result.errors.push(`IFCE: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    // Update horse sync status
    await this.prisma.horse.update({
      where: { id: horseId },
      data: {
        lastSyncAt: new Date(),
        syncStatus: result.errors.length === 0 ? 'synced' : 'error',
      },
    });

    result.success = result.errors.length === 0;
    result.durationMs = Date.now() - startTime;

    this.logger.log(`Synced horse ${horseId}: ${result.addedRecords} added, ${result.updatedRecords} updated from ${result.sources.join(', ')}`);

    return result;
  }

  /**
   * Sync from FFE (competition results)
   */
  private async syncFromFFE(horse: any): Promise<{ added: number; updated: number }> {
    let added = 0;
    let updated = 0;

    const ffeData = await this.ffeService.getCompetitionHistory(horse.ffeNumber, 2);
    if (!ffeData?.competitions) return { added, updated };

    for (const comp of ffeData.competitions) {
      const existing = await this.prisma.competitionResult.findFirst({
        where: {
          horseId: horse.id,
          competitionDate: new Date(comp.date),
          competitionName: comp.name,
          source: 'FFE',
        },
      });

      if (existing) {
        // Update if rank changed
        if (existing.rank !== comp.rank || existing.score !== comp.score) {
          await this.prisma.competitionResult.update({
            where: { id: existing.id },
            data: {
              rank: comp.rank,
              score: comp.score,
              penalties: comp.penalties,
              time: comp.time,
            },
          });
          updated++;
        }
      } else {
        await this.prisma.competitionResult.create({
          data: {
            horseId: horse.id,
            competitionName: comp.name,
            competitionDate: new Date(comp.date),
            location: comp.location,
            discipline: comp.discipline,
            eventName: comp.eventName,
            eventLevel: comp.level,
            rank: comp.rank,
            score: comp.score,
            penalties: comp.penalties,
            time: comp.time,
            prizeMoney: comp.prizeMoney,
            riderName: comp.riderName,
            source: 'FFE',
            sourceId: comp.id,
            sourceUrl: comp.url,
          },
        });
        added++;
      }
    }

    // Add to EquiTrace timeline
    if (added > 0) {
      await this.prisma.equiTraceEntry.createMany({
        data: ffeData.competitions.slice(0, added).map((comp) => ({
          horseId: horse.id,
          type: 'competition',
          date: new Date(comp.date),
          title: comp.name,
          description: `${comp.discipline} - ${comp.level}${comp.rank ? ` - Rang: ${comp.rank}` : ''}`,
          source: 'FFE',
          sourceId: comp.id,
          sourceUrl: comp.url,
          verified: true,
          metadata: {
            discipline: comp.discipline,
            level: comp.level,
            rank: comp.rank,
          },
        })),
        skipDuplicates: true,
      });
    }

    return { added, updated };
  }

  /**
   * Sync from SireWeb (pedigree, ownership)
   */
  private async syncFromSireWeb(horse: any): Promise<{ added: number; updated: number }> {
    let added = 0;
    let updated = 0;

    const sireData = await this.sireWebService.getFullHistory(horse.sireId);
    if (!sireData?.horse) return { added, updated };

    // Update horse pedigree info
    const updates: any = {};
    if (sireData.horse.sireName && !horse.sireName) {
      updates.sireName = sireData.horse.sireName;
      updates.sireUeln = sireData.horse.sireSire;
    }
    if (sireData.horse.damName && !horse.damName) {
      updates.damName = sireData.horse.damName;
      updates.damUeln = sireData.horse.damSire;
    }
    if (sireData.horse.damSireName && !horse.damSireName) {
      updates.damSireName = sireData.horse.damSireName;
    }
    if (sireData.horse.ueln && !horse.ueln) {
      updates.ueln = sireData.horse.ueln;
    }
    if (sireData.horse.microchip && !horse.microchip) {
      updates.microchip = sireData.horse.microchip;
    }

    if (Object.keys(updates).length > 0) {
      await this.prisma.horse.update({
        where: { id: horse.id },
        data: updates,
      });
      updated++;
    }

    // Add ownership changes to EquiTrace
    for (const owner of sireData.owners) {
      const existing = await this.prisma.equiTraceEntry.findFirst({
        where: {
          horseId: horse.id,
          type: 'ownership',
          date: new Date(owner.startDate),
          source: 'SireWeb',
        },
      });

      if (!existing) {
        await this.prisma.equiTraceEntry.create({
          data: {
            horseId: horse.id,
            type: 'ownership',
            date: new Date(owner.startDate),
            title: 'Changement de propriétaire',
            description: `Nouveau propriétaire: ${owner.name}`,
            source: 'SireWeb',
            sourceUrl: sireData.url,
            verified: true,
            metadata: {
              ownerName: owner.name,
              ownerType: owner.type,
              endDate: owner.endDate,
            },
          },
        });
        added++;
      }
    }

    // Add breeding records
    for (const breeding of sireData.breeding) {
      const existing = await this.prisma.breedingRecord.findFirst({
        where: {
          horseId: horse.id,
          year: breeding.year,
          partnerName: breeding.partnerName,
        },
      });

      if (!existing && breeding.partnerName) {
        await this.prisma.breedingRecord.create({
          data: {
            horseId: horse.id,
            role: horse.gender === 'male' ? 'stallion' : 'mare',
            year: breeding.year,
            partnerName: breeding.partnerName,
            partnerUeln: breeding.partnerSire,
            method: breeding.method,
            success: breeding.success,
            foalBorn: !!breeding.foalName,
            foalName: breeding.foalName,
          },
        });
        added++;
      }
    }

    return { added, updated };
  }

  /**
   * Sync from IFCE (genetic indices)
   */
  private async syncFromIFCE(horse: any): Promise<{ added: number; updated: number }> {
    let added = 0;
    let updated = 0;

    const ifceData = await this.ifceService.getGeneticIndices(horse.ueln);
    if (!ifceData) return { added, updated };

    // Store indices in cache for EquiCote
    await this.cacheService.set(
      'IFCE',
      horse.ueln,
      'indices',
      ifceData,
      30 * 24 * 60 * 60 * 1000, // 30 days
      horse.id,
    );

    // Add to EquiTrace if indices changed significantly
    const lastEntry = await this.prisma.equiTraceEntry.findFirst({
      where: {
        horseId: horse.id,
        type: 'indices_update',
        source: 'IFCE',
      },
      orderBy: { date: 'desc' },
    });

    const shouldAddEntry = !lastEntry || (
      lastEntry.metadata as any
    )?.ISO !== ifceData.ISO;

    if (shouldAddEntry && ifceData.ISO) {
      await this.prisma.equiTraceEntry.create({
        data: {
          horseId: horse.id,
          type: 'indices_update',
          date: new Date(),
          title: 'Mise à jour des indices génétiques',
          description: `ISO: ${ifceData.ISO}${ifceData.IDR ? `, IDR: ${ifceData.IDR}` : ''}${ifceData.ICC ? `, ICC: ${ifceData.ICC}` : ''}`,
          source: 'IFCE',
          verified: true,
          metadata: {
            ISO: ifceData.ISO,
            IDR: ifceData.IDR,
            ICC: ifceData.ICC,
            reliability: ifceData.reliability,
          },
        },
      });
      added++;
    }

    return { added, updated };
  }

  /**
   * Sync all horses that need updates
   */
  async syncPendingHorses(limit: number = 50): Promise<BatchSyncResult> {
    const startTime = Date.now();

    // Get horses that need sync
    const horsesToSync = await this.prisma.horse.findMany({
      where: {
        AND: [
          {
            OR: [
              { syncStatus: 'pending' },
              { lastSyncAt: null },
              {
                lastSyncAt: {
                  lt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // Older than 7 days
                },
              },
            ],
          },
          // Must have at least one external ID
          {
            OR: [
              { ffeNumber: { not: null } },
              { sireId: { not: null } },
              { ueln: { not: null } },
            ],
          },
        ],
      },
      select: { id: true },
      take: limit,
      orderBy: { lastSyncAt: 'asc' },
    });

    const results: SyncResult[] = [];

    for (const horse of horsesToSync) {
      const result = await this.syncHorse(horse.id);
      results.push(result);

      // Small delay to avoid rate limits
      await new Promise((r) => setTimeout(r, 500));
    }

    const successful = results.filter((r) => r.success).length;
    const failed = results.filter((r) => !r.success).length;
    const totalAdded = results.reduce((sum, r) => sum + r.addedRecords, 0);
    const totalUpdated = results.reduce((sum, r) => sum + r.updatedRecords, 0);

    this.logger.log(`Batch sync completed: ${successful} successful, ${failed} failed, ${totalAdded} added, ${totalUpdated} updated`);

    return {
      totalHorses: horsesToSync.length,
      successful,
      failed,
      totalAdded,
      totalUpdated,
      durationMs: Date.now() - startTime,
      results,
    };
  }

  /**
   * Refresh market data
   */
  async refreshMarketData(): Promise<{ jobsCreated: number }> {
    const jobs: string[] = [];

    // Create scraping jobs for different sources
    const sources = [
      { source: 'equirodi', type: 'market_prices' },
      { source: 'cheval-annonce', type: 'market_prices' },
    ];

    for (const { source, type } of sources) {
      const jobId = await this.scrapingService.createScrapingJob({
        type,
        source,
        scheduledAt: new Date(),
      });
      jobs.push(jobId);
    }

    this.logger.log(`Created ${jobs.length} market data refresh jobs`);

    return { jobsCreated: jobs.length };
  }

  /**
   * Clean up old data
   */
  async cleanup(): Promise<CleanupResult> {
    const result: CleanupResult = {
      expiredCache: 0,
      oldScrapingJobs: 0,
      staleData: 0,
    };

    // Clean expired cache
    result.expiredCache = await this.cacheService.cleanup(30);

    // Clean old scraping jobs
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const deletedJobs = await this.prisma.scrapingJob.deleteMany({
      where: {
        status: { in: ['completed', 'failed'] },
        completedAt: { lt: thirtyDaysAgo },
        isRecurring: false,
      },
    });
    result.oldScrapingJobs = deletedJobs.count;

    // Mark stale cache entries
    const staleEntries = await this.prisma.externalDataCache.updateMany({
      where: {
        expiresAt: { lt: new Date() },
        isStale: false,
      },
      data: { isStale: true },
    });
    result.staleData = staleEntries.count;

    this.logger.log(`Cleanup completed: ${result.expiredCache} cache, ${result.oldScrapingJobs} jobs, ${result.staleData} stale`);

    return result;
  }

  /**
   * Get sync status summary
   */
  async getSyncStatus(): Promise<SyncStatusSummary> {
    const [total, synced, pending, error, cacheStats] = await Promise.all([
      this.prisma.horse.count(),
      this.prisma.horse.count({ where: { syncStatus: 'synced' } }),
      this.prisma.horse.count({ where: { syncStatus: 'pending' } }),
      this.prisma.horse.count({ where: { syncStatus: 'error' } }),
      this.cacheService.getStats(),
    ]);

    const oldestSync = await this.prisma.horse.findFirst({
      where: { lastSyncAt: { not: null } },
      orderBy: { lastSyncAt: 'asc' },
      select: { lastSyncAt: true },
    });

    return {
      horses: { total, synced, pending, error },
      cache: cacheStats,
      oldestSync: oldestSync?.lastSyncAt || null,
    };
  }
}

// Type definitions
export interface SyncResult {
  horseId: string;
  success: boolean;
  sources: string[];
  addedRecords: number;
  updatedRecords: number;
  errors: string[];
  durationMs?: number;
}

export interface BatchSyncResult {
  totalHorses: number;
  successful: number;
  failed: number;
  totalAdded: number;
  totalUpdated: number;
  durationMs: number;
  results: SyncResult[];
}

export interface CleanupResult {
  expiredCache: number;
  oldScrapingJobs: number;
  staleData: number;
}

export interface SyncStatusSummary {
  horses: {
    total: number;
    synced: number;
    pending: number;
    error: number;
  };
  cache: {
    totalEntries: number;
    staleEntries: number;
    bySource: Record<string, number>;
    oldestEntry: Date | null;
  };
  oldestSync: Date | null;
}
