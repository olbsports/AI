import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DataSyncService } from './data-sync.service';
import { ScrapingService } from '../external-data/scraping.service';

/**
 * Sync Scheduler Service
 *
 * Schedules periodic data synchronization tasks:
 * - Horse data sync from external sources
 * - Market data refresh
 * - Cache cleanup
 * - Scraping job processing
 */
@Injectable()
export class SyncScheduler {
  private readonly logger = new Logger(SyncScheduler.name);
  private isRunning = false;

  constructor(
    private dataSyncService: DataSyncService,
    private scrapingService: ScrapingService,
  ) {}

  /**
   * Sync horses every 6 hours
   * Runs at 00:00, 06:00, 12:00, 18:00
   */
  @Cron('0 0,6,12,18 * * *')
  async syncHorses(): Promise<void> {
    if (this.isRunning) {
      this.logger.warn('Sync already running, skipping');
      return;
    }

    this.isRunning = true;
    this.logger.log('Starting scheduled horse sync');

    try {
      const result = await this.dataSyncService.syncPendingHorses(100);
      this.logger.log(`Scheduled sync completed: ${result.successful}/${result.totalHorses} horses`);
    } catch (error) {
      this.logger.error('Scheduled sync failed', error);
    } finally {
      this.isRunning = false;
    }
  }

  /**
   * Refresh market data daily at 3 AM
   */
  @Cron('0 3 * * *')
  async refreshMarketData(): Promise<void> {
    this.logger.log('Starting market data refresh');

    try {
      const result = await this.dataSyncService.refreshMarketData();
      this.logger.log(`Market refresh: ${result.jobsCreated} jobs created`);
    } catch (error) {
      this.logger.error('Market refresh failed', error);
    }
  }

  /**
   * Process pending scraping jobs every 30 minutes
   */
  @Cron(CronExpression.EVERY_30_MINUTES)
  async processScrapingJobs(): Promise<void> {
    this.logger.debug('Checking for pending scraping jobs');

    try {
      const pendingJobs = await this.scrapingService.getPendingJobs();

      for (const job of pendingJobs) {
        this.logger.log(`Processing scraping job ${job.id} (${job.source})`);
        await this.scrapingService.processJob(job.id);

        // Delay between jobs to avoid rate limits
        await new Promise((r) => setTimeout(r, 2000));
      }

      if (pendingJobs.length > 0) {
        this.logger.log(`Processed ${pendingJobs.length} scraping jobs`);
      }
    } catch (error) {
      this.logger.error('Scraping job processing failed', error);
    }
  }

  /**
   * Cleanup old data weekly on Sunday at 4 AM
   */
  @Cron('0 4 * * 0')
  async cleanup(): Promise<void> {
    this.logger.log('Starting weekly cleanup');

    try {
      const result = await this.dataSyncService.cleanup();
      this.logger.log(`Cleanup completed: ${result.expiredCache} cache, ${result.oldScrapingJobs} jobs, ${result.staleData} stale`);
    } catch (error) {
      this.logger.error('Cleanup failed', error);
    }
  }

  /**
   * Log sync status every hour
   */
  @Cron(CronExpression.EVERY_HOUR)
  async logStatus(): Promise<void> {
    try {
      const status = await this.dataSyncService.getSyncStatus();
      this.logger.log(`Sync status: ${status.horses.synced}/${status.horses.total} synced, ${status.cache.totalEntries} cached`);
    } catch (error) {
      this.logger.error('Failed to get sync status', error);
    }
  }
}
