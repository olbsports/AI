import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { FFEService } from '../external-data/ffe.service';
import { SireWebService } from '../external-data/sireweb.service';
import { IFCEService } from '../external-data/ifce.service';
import { ScrapingService } from '../external-data/scraping.service';
import {
  EquiTraceReport,
  EquiTraceEntry,
  CreateEntryDto,
  EquiTraceTimeline,
} from './dto/equitrace.dto';

@Injectable()
export class EquiTraceService {
  private readonly logger = new Logger(EquiTraceService.name);

  constructor(
    private prisma: PrismaService,
    private ffeService: FFEService,
    private sireWebService: SireWebService,
    private ifceService: IFCEService,
    private scrapingService: ScrapingService
  ) {}

  /**
   * Generate complete EquiTrace report for a horse
   */
  async generateReport(
    horseId: string,
    userId: string,
    organizationId: string
  ): Promise<EquiTraceReport> {
    this.logger.log(`Generating EquiTrace report for horse ${horseId}`);

    // Get horse data
    const horse = await this.prisma.horse.findUnique({
      where: { id: horseId },
      include: {
        competitionResults: { orderBy: { competitionDate: 'desc' } },
        healthRecords: { orderBy: { date: 'desc' } },
        breedingRecords: { orderBy: { year: 'desc' } },
        gestations: { orderBy: { breedingDate: 'desc' } },
        equiTraceHistory: { orderBy: { date: 'desc' } },
      },
    });

    if (!horse) {
      throw new NotFoundException('Horse not found');
    }

    // Fetch external data in parallel
    const [ffeHistory, sireHistory, ifceData] = await Promise.allSettled([
      horse.ffeNumber ? this.ffeService.getCompetitionHistory(horse.ffeNumber) : null,
      horse.sireId ? this.sireWebService.getFullHistory(horse.sireId) : null,
      horse.ueln ? this.ifceService.getHorseProfile(horse.ueln) : null,
    ]);

    // Merge and deduplicate entries
    const entries: EquiTraceEntry[] = [];

    // Add manual entries from database
    for (const entry of horse.equiTraceHistory) {
      entries.push({
        id: entry.id,
        type: entry.type as any,
        date: entry.date,
        title: entry.title,
        description: entry.description,
        source: entry.source,
        sourceUrl: entry.sourceUrl,
        verified: entry.verified,
        metadata: entry.metadata as any,
      });
    }

    // Add FFE competition results
    if (ffeHistory.status === 'fulfilled' && ffeHistory.value?.competitions) {
      for (const comp of ffeHistory.value.competitions) {
        // Check if already exists
        const exists = entries.some(
          (e) =>
            e.type === 'competition' &&
            e.date.getTime() === new Date(comp.date).getTime() &&
            e.title === comp.name
        );

        if (!exists) {
          entries.push({
            id: `ffe_${comp.id}`,
            type: 'competition',
            date: new Date(comp.date),
            title: comp.name,
            description: `${comp.discipline} - ${comp.level} - Rang: ${comp.rank || 'N/C'}`,
            source: 'FFE',
            sourceUrl: comp.url,
            verified: true,
            metadata: {
              discipline: comp.discipline,
              level: comp.level,
              rank: comp.rank,
              score: comp.score,
              location: comp.location,
            },
          });
        }
      }
    }

    // Add SireWeb ownership/breeding history
    if (sireHistory.status === 'fulfilled' && sireHistory.value) {
      const sireData = sireHistory.value;

      // Ownership changes
      if (sireData.owners) {
        for (const owner of sireData.owners) {
          entries.push({
            id: `sire_owner_${owner.startDate}`,
            type: 'ownership',
            date: new Date(owner.startDate),
            title: `Changement de propriétaire`,
            description: `Nouveau propriétaire: ${owner.name}`,
            source: 'SireWeb',
            sourceUrl: sireData.url,
            verified: true,
            metadata: {
              ownerName: owner.name,
              endDate: owner.endDate,
            },
          });
        }
      }

      // Breeding records
      if (sireData.offspring) {
        for (const foal of sireData.offspring) {
          entries.push({
            id: `sire_foal_${foal.birthYear}_${foal.name}`,
            type: 'breeding',
            date: new Date(foal.birthYear, 0, 1),
            title: `Production: ${foal.name}`,
            description: `${foal.gender} - ${foal.studbook}`,
            source: 'SireWeb',
            sourceUrl: foal.url,
            verified: true,
            metadata: {
              foalName: foal.name,
              foalGender: foal.gender,
              foalStudbook: foal.studbook,
            },
          });
        }
      }
    }

    // Add health records from database
    for (const record of horse.healthRecords) {
      entries.push({
        id: record.id,
        type: 'health',
        date: record.date,
        title: record.title,
        description: record.description,
        source: 'manual',
        verified: false,
        metadata: {
          recordType: record.type,
          vetName: record.vetName,
          medication: record.medication,
        },
      });
    }

    // Sort entries by date
    entries.sort((a, b) => b.date.getTime() - a.date.getTime());

    // Build pedigree
    const pedigree = await this.buildPedigree(horse, ifceData);

    // Calculate statistics
    const stats = this.calculateStats(entries, horse);

    // Create audit log
    await this.prisma.auditLog.create({
      data: {
        organizationId,
        actorId: userId,
        action: 'equitrace_report_generated',
        details: {
          horseId,
          entriesCount: entries.length,
          sources: [...new Set(entries.map((e) => e.source))],
        },
      },
    });

    return {
      horseId,
      horseName: horse.name,
      sireNumber: horse.sireId,
      ueln: horse.ueln,
      microchip: horse.microchip,
      birthDate: horse.birthDate,
      breed: horse.breed,
      studbook: horse.studbook,
      color: horse.color,
      gender: horse.gender,
      pedigree,
      timeline: entries,
      stats,
      dataSources: this.getDataSources(ffeHistory, sireHistory, ifceData),
      generatedAt: new Date(),
    };
  }

  /**
   * Build pedigree tree
   */
  private async buildPedigree(horse: any, ifceData: PromiseSettledResult<any>): Promise<any> {
    const pedigree: any = {
      sire: null,
      dam: null,
    };

    if (horse.sireName) {
      pedigree.sire = {
        name: horse.sireName,
        ueln: horse.sireUeln,
      };

      // Try to get sire's parents from IFCE
      if (ifceData.status === 'fulfilled' && ifceData.value?.pedigree?.sire) {
        pedigree.sire.sire = ifceData.value.pedigree.sire.sire;
        pedigree.sire.dam = ifceData.value.pedigree.sire.dam;
      }
    }

    if (horse.damName) {
      pedigree.dam = {
        name: horse.damName,
        ueln: horse.damUeln,
      };

      // Dam's sire
      if (horse.damSireName) {
        pedigree.dam.sire = { name: horse.damSireName };
      }

      // Try to get dam's parents from IFCE
      if (ifceData.status === 'fulfilled' && ifceData.value?.pedigree?.dam) {
        pedigree.dam.sire = pedigree.dam.sire || ifceData.value.pedigree.dam.sire;
        pedigree.dam.dam = ifceData.value.pedigree.dam.dam;
      }
    }

    return pedigree;
  }

  /**
   * Calculate statistics from timeline
   */
  private calculateStats(entries: EquiTraceEntry[], horse: any): any {
    const competitions = entries.filter((e) => e.type === 'competition');
    const healthEvents = entries.filter((e) => e.type === 'health');

    const stats = {
      totalCompetitions: competitions.length,
      wins: competitions.filter((c) => c.metadata?.rank === 1).length,
      podiums: competitions.filter((c) => c.metadata?.rank <= 3).length,
      ownershipChanges: entries.filter((e) => e.type === 'ownership').length,
      healthEvents: healthEvents.length,
      firstCompetition: competitions.length > 0 ? competitions[competitions.length - 1].date : null,
      lastCompetition: competitions.length > 0 ? competitions[0].date : null,
      disciplines: [...new Set(competitions.map((c) => c.metadata?.discipline).filter(Boolean))],
      highestLevel: this.getHighestLevel(competitions),
      verifiedEntries: entries.filter((e) => e.verified).length,
      totalEntries: entries.length,
    };

    return stats;
  }

  /**
   * Determine highest competition level
   */
  private getHighestLevel(competitions: EquiTraceEntry[]): string | null {
    const levelOrder = [
      'Pro Elite',
      'Pro 1',
      'Pro 2',
      'Amateur Elite',
      'Amateur 1',
      'Amateur 2',
      'Amateur 3',
      'Club Elite',
      'Club 1',
      'Club 2',
      'Club 3',
      'Club 4',
    ];

    for (const level of levelOrder) {
      if (competitions.some((c) => c.metadata?.level?.includes(level))) {
        return level;
      }
    }

    return null;
  }

  /**
   * Get list of data sources used
   */
  private getDataSources(...results: PromiseSettledResult<any>[]): string[] {
    const sources: string[] = ['EquiTrace'];

    if (results[0]?.status === 'fulfilled' && results[0].value) sources.push('FFE');
    if (results[1]?.status === 'fulfilled' && results[1].value) sources.push('SireWeb');
    if (results[2]?.status === 'fulfilled' && results[2].value) sources.push('IFCE');

    return sources;
  }

  /**
   * Add manual entry to horse history
   */
  async addEntry(
    horseId: string,
    data: CreateEntryDto,
    userId: string,
    organizationId: string
  ): Promise<EquiTraceEntry> {
    const entry = await this.prisma.equiTraceEntry.create({
      data: {
        horseId,
        type: data.type,
        date: data.date,
        title: data.title,
        description: data.description,
        source: 'manual',
        verified: false,
        metadata: data.metadata,
        attachments: data.attachments || [],
      },
    });

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        organizationId,
        actorId: userId,
        action: 'equitrace_entry_added',
        details: { horseId, entryId: entry.id, type: data.type },
      },
    });

    return {
      id: entry.id,
      type: entry.type as any,
      date: entry.date,
      title: entry.title,
      description: entry.description,
      source: entry.source,
      sourceUrl: entry.sourceUrl,
      verified: entry.verified,
      metadata: entry.metadata as any,
    };
  }

  /**
   * Get timeline for a horse
   */
  async getTimeline(horseId: string): Promise<EquiTraceTimeline> {
    const entries = await this.prisma.equiTraceEntry.findMany({
      where: { horseId },
      orderBy: { date: 'desc' },
    });

    const competitions = await this.prisma.competitionResult.findMany({
      where: { horseId },
      orderBy: { competitionDate: 'desc' },
    });

    const timeline: EquiTraceEntry[] = [];

    // Add manual entries
    for (const entry of entries) {
      timeline.push({
        id: entry.id,
        type: entry.type as any,
        date: entry.date,
        title: entry.title,
        description: entry.description,
        source: entry.source,
        sourceUrl: entry.sourceUrl,
        verified: entry.verified,
        metadata: entry.metadata as any,
      });
    }

    // Add competition results
    for (const comp of competitions) {
      timeline.push({
        id: comp.id,
        type: 'competition',
        date: comp.competitionDate,
        title: comp.competitionName,
        description: `${comp.discipline} - ${comp.eventLevel} - Rang: ${comp.rank || 'N/C'}`,
        source: comp.source,
        sourceUrl: comp.sourceUrl,
        verified: comp.source === 'FFE',
        metadata: {
          discipline: comp.discipline,
          level: comp.eventLevel,
          rank: comp.rank,
          score: comp.score,
          location: comp.location,
        },
      });
    }

    // Sort by date
    timeline.sort((a, b) => b.date.getTime() - a.date.getTime());

    return {
      horseId,
      entries: timeline,
      lastUpdated: new Date(),
    };
  }

  /**
   * Sync horse data from external sources
   */
  async syncFromExternalSources(horseId: string): Promise<{
    added: number;
    updated: number;
    sources: string[];
  }> {
    const horse = await this.prisma.horse.findUnique({
      where: { id: horseId },
    });

    if (!horse) {
      throw new NotFoundException('Horse not found');
    }

    let added = 0;
    const updated = 0;
    const sources: string[] = [];

    // Sync from FFE
    if (horse.ffeNumber) {
      try {
        const ffeData = await this.ffeService.getCompetitionHistory(horse.ffeNumber);
        if (ffeData?.competitions) {
          for (const comp of ffeData.competitions) {
            const existing = await this.prisma.competitionResult.findFirst({
              where: {
                horseId,
                competitionDate: new Date(comp.date),
                competitionName: comp.name,
              },
            });

            if (!existing) {
              await this.prisma.competitionResult.create({
                data: {
                  horseId,
                  competitionName: comp.name,
                  competitionDate: new Date(comp.date),
                  location: comp.location,
                  discipline: comp.discipline,
                  eventLevel: comp.level,
                  rank: comp.rank,
                  score: comp.score,
                  source: 'FFE',
                  sourceId: comp.id,
                  sourceUrl: comp.url,
                },
              });
              added++;
            }
          }
          sources.push('FFE');
        }
      } catch (error) {
        this.logger.error(`Failed to sync FFE data for horse ${horseId}`, error);
      }
    }

    // Update horse sync status
    await this.prisma.horse.update({
      where: { id: horseId },
      data: {
        lastSyncAt: new Date(),
        syncStatus: 'synced',
      },
    });

    return { added, updated, sources };
  }
}
