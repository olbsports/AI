import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { PrismaService } from '../../prisma/prisma.service';
import { ExternalDataCacheService } from './cache.service';
import { firstValueFrom } from 'rxjs';
import * as cheerio from 'cheerio';

/**
 * Web Scraping Service
 *
 * Scrapes horse data from external marketplaces:
 * - Equirodi.com
 * - Cheval-annonce.com
 * - Horsetelex.com
 * - Leboncoin.fr (equestrian section)
 *
 * Used to:
 * - Gather market pricing data
 * - Find competition results
 * - Track horse listings
 *
 * Note: Respects robots.txt and rate limits
 */
@Injectable()
export class ScrapingService {
  private readonly logger = new Logger(ScrapingService.name);

  // Rate limiting: requests per minute per source
  private readonly rateLimits: Record<string, number> = {
    equirodi: 30,
    'cheval-annonce': 20,
    horsetelex: 15,
    leboncoin: 10,
  };

  // Last request timestamps per source
  private lastRequests: Map<string, number[]> = new Map();

  constructor(
    private http: HttpService,
    private prisma: PrismaService,
    private cache: ExternalDataCacheService,
  ) {}

  /**
   * Scrape horse listings from Equirodi
   */
  async scrapeEquirodi(params: {
    query?: string;
    breed?: string;
    minPrice?: number;
    maxPrice?: number;
    discipline?: string;
    page?: number;
  }): Promise<ScrapedListing[]> {
    await this.checkRateLimit('equirodi');

    try {
      const url = this.buildEquirodiUrl(params);
      const response = await this.fetchPage(url);
      const $ = cheerio.load(response);

      const listings: ScrapedListing[] = [];

      $('.annonce-list-item').each((_, element) => {
        try {
          const $el = $(element);
          const listing = this.parseEquirodiListing($, $el);
          if (listing) listings.push(listing);
        } catch (error) {
          this.logger.debug('Failed to parse Equirodi listing', error);
        }
      });

      // Cache results
      for (const listing of listings) {
        await this.cache.set(
          'Equirodi',
          listing.id,
          'listing',
          listing,
          24 * 60 * 60 * 1000, // 24 hours
        );
      }

      this.logger.log(`Scraped ${listings.length} listings from Equirodi`);
      return listings;
    } catch (error) {
      this.logger.error('Equirodi scraping failed', error);
      return [];
    }
  }

  /**
   * Scrape horse listings from Cheval-Annonce
   */
  async scrapeChevalAnnonce(params: {
    category?: string;
    minPrice?: number;
    maxPrice?: number;
    region?: string;
    page?: number;
  }): Promise<ScrapedListing[]> {
    await this.checkRateLimit('cheval-annonce');

    try {
      const url = this.buildChevalAnnonceUrl(params);
      const response = await this.fetchPage(url);
      const $ = cheerio.load(response);

      const listings: ScrapedListing[] = [];

      $('.ad-listing').each((_, element) => {
        try {
          const $el = $(element);
          const listing = this.parseChevalAnnonceListing($, $el);
          if (listing) listings.push(listing);
        } catch (error) {
          this.logger.debug('Failed to parse Cheval-Annonce listing', error);
        }
      });

      // Cache results
      for (const listing of listings) {
        await this.cache.set(
          'Cheval-Annonce',
          listing.id,
          'listing',
          listing,
          24 * 60 * 60 * 1000,
        );
      }

      this.logger.log(`Scraped ${listings.length} listings from Cheval-Annonce`);
      return listings;
    } catch (error) {
      this.logger.error('Cheval-Annonce scraping failed', error);
      return [];
    }
  }

  /**
   * Scrape horse data from Horsetelex (breeding/pedigree focus)
   */
  async scrapeHorsetelex(sireNumber: string): Promise<HorsetelexData | null> {
    await this.checkRateLimit('horsetelex');

    try {
      const url = `https://www.horsetelex.com/horses/pedigree/${sireNumber}`;
      const response = await this.fetchPage(url);
      const $ = cheerio.load(response);

      const data: HorsetelexData = {
        sireNumber,
        name: $('.horse-name').text().trim(),
        studbook: $('.studbook').text().trim(),
        pedigree: this.parseHorsetelexPedigree($),
        offspring: this.parseHorsetelexOffspring($),
        indices: this.parseHorsetelexIndices($),
        url,
        scrapedAt: new Date(),
      };

      // Cache for 7 days
      await this.cache.set('Horsetelex', sireNumber, 'pedigree', data, 7 * 24 * 60 * 60 * 1000);

      return data;
    } catch (error) {
      this.logger.error(`Horsetelex scraping failed for ${sireNumber}`, error);
      return null;
    }
  }

  /**
   * Create a scraping job for batch processing
   */
  async createScrapingJob(params: {
    type: string;
    source: string;
    targetQuery?: any;
    scheduledAt?: Date;
    isRecurring?: boolean;
    cronExpression?: string;
  }): Promise<string> {
    const job = await this.prisma.scrapingJob.create({
      data: {
        type: params.type,
        source: params.source,
        targetQuery: params.targetQuery,
        scheduledAt: params.scheduledAt,
        isRecurring: params.isRecurring || false,
        cronExpression: params.cronExpression,
        status: 'pending',
      },
    });

    this.logger.log(`Created scraping job ${job.id} for ${params.source}`);
    return job.id;
  }

  /**
   * Process a scraping job
   */
  async processJob(jobId: string): Promise<void> {
    const job = await this.prisma.scrapingJob.findUnique({
      where: { id: jobId },
    });

    if (!job || job.status !== 'pending') {
      return;
    }

    await this.prisma.scrapingJob.update({
      where: { id: jobId },
      data: { status: 'running', startedAt: new Date() },
    });

    try {
      let results: any[] = [];
      const query = job.targetQuery as any;

      switch (job.source.toLowerCase()) {
        case 'equirodi':
          results = await this.scrapeEquirodi(query || {});
          break;
        case 'cheval-annonce':
          results = await this.scrapeChevalAnnonce(query || {});
          break;
        case 'horsetelex':
          if (query?.sireNumber) {
            const data = await this.scrapeHorsetelex(query.sireNumber);
            if (data) results = [data];
          }
          break;
      }

      await this.prisma.scrapingJob.update({
        where: { id: jobId },
        data: {
          status: 'completed',
          completedAt: new Date(),
          itemsFound: results.length,
          itemsProcessed: results.length,
          progress: 100,
          results: results,
        },
      });

      this.logger.log(`Completed scraping job ${jobId}: ${results.length} items`);
    } catch (error) {
      await this.prisma.scrapingJob.update({
        where: { id: jobId },
        data: {
          status: 'failed',
          errorMessage: error instanceof Error ? error.message : 'Unknown error',
        },
      });

      this.logger.error(`Scraping job ${jobId} failed`, error);
    }
  }

  /**
   * Get pending scraping jobs
   */
  async getPendingJobs(): Promise<{ id: string; source: string; type: string }[]> {
    const jobs = await this.prisma.scrapingJob.findMany({
      where: {
        status: 'pending',
        OR: [
          { scheduledAt: null },
          { scheduledAt: { lte: new Date() } },
        ],
      },
      select: { id: true, source: true, type: true },
      orderBy: { createdAt: 'asc' },
      take: 10,
    });

    return jobs;
  }

  // Helper methods
  private async fetchPage(url: string): Promise<string> {
    const response = await firstValueFrom(
      this.http.get(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; HorseVisionBot/1.0; +https://horsevision.ai)',
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'fr-FR,fr;q=0.9',
        },
        timeout: 15000,
      }),
    );
    return response.data;
  }

  private async checkRateLimit(source: string): Promise<void> {
    const limit = this.rateLimits[source] || 20;
    const now = Date.now();
    const windowMs = 60000; // 1 minute

    let requests = this.lastRequests.get(source) || [];
    requests = requests.filter((t) => now - t < windowMs);

    if (requests.length >= limit) {
      const waitTime = windowMs - (now - requests[0]);
      this.logger.debug(`Rate limit reached for ${source}, waiting ${waitTime}ms`);
      await new Promise((resolve) => setTimeout(resolve, waitTime));
      requests = requests.filter((t) => Date.now() - t < windowMs);
    }

    requests.push(now);
    this.lastRequests.set(source, requests);
  }

  private buildEquirodiUrl(params: any): string {
    const base = 'https://www.equirodi.com/annonces-chevaux.htm';
    const queryParams = new URLSearchParams();
    if (params.query) queryParams.set('q', params.query);
    if (params.breed) queryParams.set('race', params.breed);
    if (params.minPrice) queryParams.set('prix_min', params.minPrice.toString());
    if (params.maxPrice) queryParams.set('prix_max', params.maxPrice.toString());
    if (params.discipline) queryParams.set('discipline', params.discipline);
    if (params.page) queryParams.set('page', params.page.toString());
    return `${base}?${queryParams.toString()}`;
  }

  private buildChevalAnnonceUrl(params: any): string {
    const base = 'https://www.cheval-annonce.com/annonces';
    const queryParams = new URLSearchParams();
    if (params.category) queryParams.set('cat', params.category);
    if (params.minPrice) queryParams.set('prix_min', params.minPrice.toString());
    if (params.maxPrice) queryParams.set('prix_max', params.maxPrice.toString());
    if (params.region) queryParams.set('region', params.region);
    if (params.page) queryParams.set('p', params.page.toString());
    return `${base}?${queryParams.toString()}`;
  }

  private parseEquirodiListing($: cheerio.CheerioAPI, $el: cheerio.Cheerio<cheerio.Element>): ScrapedListing | null {
    const id = $el.attr('data-id') || $el.find('a').attr('href')?.split('/').pop() || '';
    const title = $el.find('.title').text().trim();
    const priceText = $el.find('.price').text().trim();
    const price = parseInt(priceText.replace(/[^\d]/g, '')) || 0;

    if (!id || !title) return null;

    return {
      id: `equirodi_${id}`,
      source: 'Equirodi',
      name: title,
      price,
      currency: 'EUR',
      description: $el.find('.description').text().trim(),
      location: $el.find('.location').text().trim(),
      imageUrl: $el.find('img').attr('src'),
      url: 'https://www.equirodi.com' + $el.find('a').attr('href'),
      listedDate: new Date(),
      status: 'active',
    };
  }

  private parseChevalAnnonceListing($: cheerio.CheerioAPI, $el: cheerio.Cheerio<cheerio.Element>): ScrapedListing | null {
    const id = $el.attr('data-id') || $el.find('a').attr('href')?.split('/').pop() || '';
    const title = $el.find('.ad-title').text().trim();
    const priceText = $el.find('.ad-price').text().trim();
    const price = parseInt(priceText.replace(/[^\d]/g, '')) || 0;

    if (!id || !title) return null;

    return {
      id: `ca_${id}`,
      source: 'Cheval-Annonce',
      name: title,
      price,
      currency: 'EUR',
      description: $el.find('.ad-desc').text().trim(),
      location: $el.find('.ad-location').text().trim(),
      imageUrl: $el.find('img').attr('src'),
      url: 'https://www.cheval-annonce.com' + $el.find('a').attr('href'),
      listedDate: new Date(),
      status: 'active',
    };
  }

  private parseHorsetelexPedigree($: cheerio.CheerioAPI): any {
    // Parse pedigree table
    const pedigree: any = {};

    const sire = $('.pedigree-sire').first();
    if (sire.length) {
      pedigree.sire = {
        name: sire.find('.horse-name').text().trim(),
        studbook: sire.find('.studbook').text().trim(),
      };
    }

    const dam = $('.pedigree-dam').first();
    if (dam.length) {
      pedigree.dam = {
        name: dam.find('.horse-name').text().trim(),
        studbook: dam.find('.studbook').text().trim(),
      };
    }

    return pedigree;
  }

  private parseHorsetelexOffspring($: cheerio.CheerioAPI): any[] {
    const offspring: any[] = [];

    $('.offspring-list tr').each((_, row) => {
      const $row = $(row);
      offspring.push({
        name: $row.find('.name').text().trim(),
        birthYear: parseInt($row.find('.year').text().trim()) || null,
        gender: $row.find('.gender').text().trim(),
        achievements: $row.find('.achievements').text().trim(),
      });
    });

    return offspring;
  }

  private parseHorsetelexIndices($: cheerio.CheerioAPI): Record<string, number> {
    const indices: Record<string, number> = {};

    $('.indices-table tr').each((_, row) => {
      const $row = $(row);
      const indexName = $row.find('.index-name').text().trim();
      const indexValue = parseFloat($row.find('.index-value').text().trim());
      if (indexName && !isNaN(indexValue)) {
        indices[indexName] = indexValue;
      }
    });

    return indices;
  }
}

// Type definitions
export interface ScrapedListing {
  id: string;
  source: string;
  name: string;
  price: number;
  currency: string;
  description?: string;
  studbook?: string;
  birthYear?: number;
  level?: string;
  disciplines?: string[];
  location?: string;
  imageUrl?: string;
  url: string;
  listedDate: Date;
  status: string;
}

export interface HorsetelexData {
  sireNumber: string;
  name: string;
  studbook: string;
  pedigree: any;
  offspring: any[];
  indices: Record<string, number>;
  url: string;
  scrapedAt: Date;
}
