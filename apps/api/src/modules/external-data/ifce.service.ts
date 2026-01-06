import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ExternalDataCacheService } from './cache.service';
import { firstValueFrom } from 'rxjs';

/**
 * IFCE (Institut Français du Cheval et de l'Équitation) Service
 *
 * Provides access to:
 * - Genetic indices (ISO, IDR, ICC, etc.)
 * - Official valuations
 * - Breeding recommendations
 * - Statistical data
 *
 * Note: IFCE is the official French horse breeding authority
 * Info: https://www.ifce.fr
 */
@Injectable()
export class IFCEService {
  private readonly logger = new Logger(IFCEService.name);
  private readonly baseUrl = process.env.IFCE_API_URL || 'https://opendata.ifce.fr/api';
  private readonly apiKey = process.env.IFCE_API_KEY;

  constructor(
    private http: HttpService,
    private cache: ExternalDataCacheService,
  ) {}

  /**
   * Get genetic indices for a horse
   */
  async getGeneticIndices(ueln: string): Promise<IFCEGeneticIndices | null> {
    const cached = await this.cache.get('IFCE', ueln, 'indices');
    if (cached) return cached as IFCEGeneticIndices;

    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/indices/${ueln}`, {
          headers: this.getHeaders(),
        }),
      );

      const indices = this.mapIndices(response.data);

      // Cache for 30 days (indices update monthly)
      await this.cache.set('IFCE', ueln, 'indices', indices, 30 * 24 * 60 * 60 * 1000);

      return indices;
    } catch (error) {
      this.logger.error(`Failed to fetch IFCE indices for ${ueln}`, error);
      return null;
    }
  }

  /**
   * Get horse profile with pedigree
   */
  async getHorseProfile(ueln: string): Promise<IFCEHorseProfile | null> {
    const cached = await this.cache.get('IFCE', ueln, 'horse_profile');
    if (cached) return cached as IFCEHorseProfile;

    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/equides/${ueln}`, {
          headers: this.getHeaders(),
        }),
      );

      const profile = this.mapHorseProfile(response.data);

      // Cache for 7 days
      await this.cache.set('IFCE', ueln, 'horse_profile', profile, 7 * 24 * 60 * 60 * 1000);

      return profile;
    } catch (error) {
      this.logger.error(`Failed to fetch IFCE profile for ${ueln}`, error);
      return null;
    }
  }

  /**
   * Get breeding recommendations for a mare
   */
  async getBreedingRecommendations(mareUeln: string, criteria: {
    discipline?: string;
    targetIndices?: string[];
    maxInbreeding?: number;
  } = {}): Promise<IFCEBreedingRecommendation[]> {
    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/breeding/recommendations`, {
          headers: this.getHeaders(),
          params: {
            mare: mareUeln,
            discipline: criteria.discipline,
            indices: criteria.targetIndices?.join(','),
            max_consanguinite: criteria.maxInbreeding || 6.25, // Default 6.25%
          },
        }),
      );

      return response.data.recommendations?.map(this.mapBreedingRecommendation) || [];
    } catch (error) {
      this.logger.error(`Failed to fetch breeding recommendations for ${mareUeln}`, error);
      return [];
    }
  }

  /**
   * Calculate predicted offspring indices
   */
  async predictOffspringIndices(
    mareUeln: string,
    stallionUeln: string,
  ): Promise<IFCEOffspringPrediction | null> {
    try {
      const response = await firstValueFrom(
        this.http.post(`${this.baseUrl}/breeding/predict`, {
          mare: mareUeln,
          stallion: stallionUeln,
        }, {
          headers: this.getHeaders(),
        }),
      );

      return {
        mareUeln,
        stallionUeln,
        predictedIndices: response.data.indices,
        inbreedingCoefficient: response.data.consanguinite,
        commonAncestors: response.data.ancetres_communs || [],
        confidence: response.data.fiabilite,
      };
    } catch (error) {
      this.logger.error('Failed to predict offspring indices', error);
      return null;
    }
  }

  /**
   * Get studbook statistics
   */
  async getStudbookStatistics(studbook: string, year?: number): Promise<IFCEStudbookStats | null> {
    const cacheKey = `${studbook}_${year || 'latest'}`;
    const cached = await this.cache.get('IFCE', cacheKey, 'studbook_stats');
    if (cached) return cached as IFCEStudbookStats;

    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/studbooks/${studbook}/statistics`, {
          headers: this.getHeaders(),
          params: { year },
        }),
      );

      const stats = this.mapStudbookStats(response.data);

      // Cache for 30 days
      await this.cache.set('IFCE', cacheKey, 'studbook_stats', stats, 30 * 24 * 60 * 60 * 1000);

      return stats;
    } catch (error) {
      this.logger.error(`Failed to fetch studbook stats for ${studbook}`, error);
      return null;
    }
  }

  /**
   * Get top stallions by index
   */
  async getTopStallions(params: {
    studbook?: string;
    index: 'ISO' | 'IDR' | 'ICC';
    discipline?: string;
    limit?: number;
  }): Promise<IFCEStallionRanking[]> {
    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/rankings/stallions`, {
          headers: this.getHeaders(),
          params: {
            studbook: params.studbook,
            index: params.index,
            discipline: params.discipline,
            limit: params.limit || 50,
          },
        }),
      );

      return response.data.stallions?.map((s: any) => ({
        ueln: s.ueln,
        sireNumber: s.sire,
        name: s.nom,
        studbook: s.studbook,
        birthYear: s.annee_naissance,
        indices: s.indices,
        rank: s.rang,
        offspring: s.nb_produits,
        topOffspring: s.meilleurs_produits || [],
      })) || [];
    } catch (error) {
      this.logger.error('Failed to fetch top stallions', error);
      return [];
    }
  }

  /**
   * Search horses in IFCE database
   */
  async searchHorses(query: string, filters?: {
    studbook?: string;
    minIndex?: number;
    indexType?: string;
  }): Promise<IFCESearchResult[]> {
    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/equides/search`, {
          headers: this.getHeaders(),
          params: {
            q: query,
            studbook: filters?.studbook,
            min_index: filters?.minIndex,
            index_type: filters?.indexType,
            limit: 50,
          },
        }),
      );

      return response.data.results?.map((r: any) => ({
        ueln: r.ueln,
        sireNumber: r.sire,
        name: r.nom,
        gender: r.sexe,
        birthYear: r.annee_naissance,
        studbook: r.studbook,
        indices: r.indices,
      })) || [];
    } catch (error) {
      this.logger.error(`IFCE search failed for: ${query}`, error);
      return [];
    }
  }

  // Helper methods
  private getHeaders(): Record<string, string> {
    return {
      'Authorization': `Bearer ${this.apiKey}`,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  private mapIndices(data: any): IFCEGeneticIndices {
    return {
      ueln: data.ueln,
      name: data.nom,
      // CSO (Show Jumping) indices
      ISO: data.ISO, // Indice de Sélection Obstacle
      BSO: data.BSO, // Blup Saut d'Obstacles
      // Dressage indices
      IDR: data.IDR, // Indice Dressage
      BDR: data.BDR, // Blup Dressage
      // CCE (Eventing) indices
      ICC: data.ICC, // Indice Complet
      BCC: data.BCC, // Blup CCE
      // Endurance
      IEN: data.IEN, // Indice Endurance
      // Morphology
      IMO: data.IMO, // Indice Morphologie
      // Reliability
      reliability: {
        ISO: data.fiabilite_ISO,
        IDR: data.fiabilite_IDR,
        ICC: data.fiabilite_ICC,
      },
      // Trend
      trend: data.evolution,
      lastUpdate: data.derniere_maj ? new Date(data.derniere_maj) : null,
    };
  }

  private mapHorseProfile(data: any): IFCEHorseProfile {
    return {
      ueln: data.ueln,
      sireNumber: data.sire,
      name: data.nom,
      gender: data.sexe,
      birthYear: data.annee_naissance,
      studbook: data.studbook,
      color: data.robe,
      indices: this.mapIndices(data.indices || {}),
      pedigree: {
        sire: data.pere ? {
          ueln: data.pere.ueln,
          name: data.pere.nom,
          studbook: data.pere.studbook,
          indices: data.pere.indices,
          sire: data.pere.pere ? { name: data.pere.pere.nom } : undefined,
          dam: data.pere.mere ? { name: data.pere.mere.nom } : undefined,
        } : undefined,
        dam: data.mere ? {
          ueln: data.mere.ueln,
          name: data.mere.nom,
          studbook: data.mere.studbook,
          indices: data.mere.indices,
          sire: data.mere.pere ? { name: data.mere.pere.nom } : undefined,
          dam: data.mere.mere ? { name: data.mere.mere.nom } : undefined,
        } : undefined,
      },
      offspringCount: data.nb_produits,
      bestOffspring: data.meilleurs_produits?.map((p: any) => ({
        name: p.nom,
        ueln: p.ueln,
        indices: p.indices,
        achievements: p.performances,
      })) || [],
    };
  }

  private mapBreedingRecommendation(data: any): IFCEBreedingRecommendation {
    return {
      stallionUeln: data.etalon_ueln,
      stallionName: data.etalon_nom,
      stallionStudbook: data.etalon_studbook,
      compatibilityScore: data.score_compatibilite,
      predictedIndices: data.indices_predits,
      inbreedingCoefficient: data.consanguinite,
      strengths: data.points_forts || [],
      weaknesses: data.points_faibles || [],
      recommendation: data.avis,
    };
  }

  private mapStudbookStats(data: any): IFCEStudbookStats {
    return {
      studbook: data.studbook,
      year: data.annee,
      totalHorses: data.effectif_total,
      breeders: data.nb_naisseurs,
      avgIndices: {
        ISO: data.moyenne_ISO,
        IDR: data.moyenne_IDR,
        ICC: data.moyenne_ICC,
      },
      topPerformers: data.meilleurs_chevaux || [],
      trends: data.tendances,
    };
  }
}

// Type definitions
export interface IFCEGeneticIndices {
  ueln: string;
  name: string;
  ISO?: number;  // Show Jumping
  BSO?: number;
  IDR?: number;  // Dressage
  BDR?: number;
  ICC?: number;  // Eventing
  BCC?: number;
  IEN?: number;  // Endurance
  IMO?: number;  // Morphology
  reliability: {
    ISO?: number;
    IDR?: number;
    ICC?: number;
  };
  trend?: string;
  lastUpdate?: Date;
}

export interface IFCEHorseProfile {
  ueln: string;
  sireNumber?: string;
  name: string;
  gender: string;
  birthYear: number;
  studbook: string;
  color?: string;
  indices: IFCEGeneticIndices;
  pedigree: {
    sire?: {
      ueln?: string;
      name: string;
      studbook?: string;
      indices?: any;
      sire?: { name: string };
      dam?: { name: string };
    };
    dam?: {
      ueln?: string;
      name: string;
      studbook?: string;
      indices?: any;
      sire?: { name: string };
      dam?: { name: string };
    };
  };
  offspringCount?: number;
  bestOffspring: {
    name: string;
    ueln: string;
    indices?: any;
    achievements?: string[];
  }[];
}

export interface IFCEBreedingRecommendation {
  stallionUeln: string;
  stallionName: string;
  stallionStudbook: string;
  compatibilityScore: number;
  predictedIndices: Record<string, number>;
  inbreedingCoefficient: number;
  strengths: string[];
  weaknesses: string[];
  recommendation: string;
}

export interface IFCEOffspringPrediction {
  mareUeln: string;
  stallionUeln: string;
  predictedIndices: Record<string, number>;
  inbreedingCoefficient: number;
  commonAncestors: string[];
  confidence: number;
}

export interface IFCEStallionRanking {
  ueln: string;
  sireNumber?: string;
  name: string;
  studbook: string;
  birthYear: number;
  indices: Record<string, number>;
  rank: number;
  offspring: number;
  topOffspring: { name: string; achievements: string[] }[];
}

export interface IFCEStudbookStats {
  studbook: string;
  year: number;
  totalHorses: number;
  breeders: number;
  avgIndices: Record<string, number>;
  topPerformers: any[];
  trends: any;
}

export interface IFCESearchResult {
  ueln: string;
  sireNumber?: string;
  name: string;
  gender: string;
  birthYear: number;
  studbook: string;
  indices?: Record<string, number>;
}
