import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ExternalDataCacheService } from './cache.service';
import { firstValueFrom } from 'rxjs';

/**
 * FFE (Fédération Française d'Équitation) API Service
 *
 * Provides access to:
 * - Competition results
 * - Horse licenses
 * - Rider information
 * - Event calendars
 *
 * Note: FFE API requires authentication and partner agreement
 * Documentation: https://www.ffe.com/partenaires
 */
@Injectable()
export class FFEService {
  private readonly logger = new Logger(FFEService.name);
  private readonly baseUrl = process.env.FFE_API_URL || 'https://api.ffe.com/v1';
  private readonly apiKey = process.env.FFE_API_KEY;

  constructor(
    private http: HttpService,
    private cache: ExternalDataCacheService,
  ) {}

  /**
   * Get horse profile from FFE database
   */
  async getHorseProfile(ffeNumber: string): Promise<FFEHorseProfile | null> {
    // Check cache first
    const cached = await this.cache.get('FFE', ffeNumber, 'horse_profile');
    if (cached) return cached as FFEHorseProfile;

    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/horses/${ffeNumber}`, {
          headers: this.getHeaders(),
        }),
      );

      const profile = this.mapHorseProfile(response.data);

      // Cache for 24 hours
      await this.cache.set('FFE', ffeNumber, 'horse_profile', profile, 24 * 60 * 60 * 1000);

      return profile;
    } catch (error) {
      this.logger.error(`Failed to fetch FFE horse profile for ${ffeNumber}`, error);
      return null;
    }
  }

  /**
   * Get competition history for a horse
   */
  async getCompetitionHistory(ffeNumber: string, years: number = 3): Promise<FFECompetitionHistory | null> {
    const cacheKey = `${ffeNumber}_competitions_${years}y`;
    const cached = await this.cache.get('FFE', cacheKey, 'competition');
    if (cached) return cached as FFECompetitionHistory;

    try {
      const startDate = new Date();
      startDate.setFullYear(startDate.getFullYear() - years);

      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/horses/${ffeNumber}/competitions`, {
          headers: this.getHeaders(),
          params: {
            from: startDate.toISOString().split('T')[0],
            limit: 100,
          },
        }),
      );

      const history = this.mapCompetitionHistory(response.data);

      // Cache for 6 hours
      await this.cache.set('FFE', cacheKey, 'competition', history, 6 * 60 * 60 * 1000);

      return history;
    } catch (error) {
      this.logger.error(`Failed to fetch FFE competition history for ${ffeNumber}`, error);
      return null;
    }
  }

  /**
   * Search horses by name, SIRE number, or owner
   */
  async searchHorses(query: string, limit: number = 20): Promise<FFEHorseSearchResult[]> {
    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/horses/search`, {
          headers: this.getHeaders(),
          params: { q: query, limit },
        }),
      );

      return response.data.results?.map(this.mapSearchResult) || [];
    } catch (error) {
      this.logger.error(`FFE horse search failed for query: ${query}`, error);
      return [];
    }
  }

  /**
   * Get rider profile and results
   */
  async getRiderProfile(licenseNumber: string): Promise<FFERiderProfile | null> {
    const cached = await this.cache.get('FFE', licenseNumber, 'rider_profile');
    if (cached) return cached as FFERiderProfile;

    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/riders/${licenseNumber}`, {
          headers: this.getHeaders(),
        }),
      );

      const profile = this.mapRiderProfile(response.data);

      // Cache for 24 hours
      await this.cache.set('FFE', licenseNumber, 'rider_profile', profile, 24 * 60 * 60 * 1000);

      return profile;
    } catch (error) {
      this.logger.error(`Failed to fetch FFE rider profile for ${licenseNumber}`, error);
      return null;
    }
  }

  /**
   * Get upcoming competitions
   */
  async getCompetitionCalendar(params: {
    region?: string;
    discipline?: string;
    level?: string;
    from?: Date;
    to?: Date;
  }): Promise<FFECompetition[]> {
    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/competitions`, {
          headers: this.getHeaders(),
          params: {
            region: params.region,
            discipline: params.discipline,
            level: params.level,
            from: params.from?.toISOString().split('T')[0],
            to: params.to?.toISOString().split('T')[0],
            limit: 50,
          },
        }),
      );

      return response.data.competitions?.map(this.mapCompetition) || [];
    } catch (error) {
      this.logger.error('Failed to fetch FFE competition calendar', error);
      return [];
    }
  }

  /**
   * Get real-time competition results
   */
  async getLiveResults(competitionId: string): Promise<FFELiveResults | null> {
    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/competitions/${competitionId}/live`, {
          headers: this.getHeaders(),
        }),
      );

      return this.mapLiveResults(response.data);
    } catch (error) {
      this.logger.error(`Failed to fetch live results for competition ${competitionId}`, error);
      return null;
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

  private mapHorseProfile(data: any): FFEHorseProfile {
    return {
      ffeNumber: data.numero_ffe || data.id,
      name: data.nom,
      sireNumber: data.numero_sire,
      ueln: data.ueln,
      birthDate: data.date_naissance ? new Date(data.date_naissance) : null,
      breed: data.race,
      robe: data.robe,
      gender: data.sexe,
      height: data.taille,
      sireName: data.pere?.nom,
      damName: data.mere?.nom,
      ownerName: data.proprietaire?.nom,
      currentLevel: data.niveau_actuel,
      disciplines: data.disciplines || [],
      lastActivity: data.derniere_activite ? new Date(data.derniere_activite) : null,
    };
  }

  private mapCompetitionHistory(data: any): FFECompetitionHistory {
    return {
      ffeNumber: data.numero_ffe,
      competitions: data.resultats?.map((r: any) => ({
        id: r.id,
        name: r.concours?.nom || r.nom_concours,
        date: new Date(r.date),
        location: r.lieu,
        discipline: r.discipline,
        level: r.niveau,
        eventName: r.epreuve?.nom || r.nom_epreuve,
        rank: r.classement,
        score: r.note,
        penalties: r.penalites,
        time: r.temps,
        prizeMoney: r.gains,
        riderName: r.cavalier?.nom,
        url: r.url,
      })) || [],
      totalCount: data.total || data.resultats?.length || 0,
    };
  }

  private mapSearchResult(data: any): FFEHorseSearchResult {
    return {
      ffeNumber: data.numero_ffe,
      name: data.nom,
      sireNumber: data.numero_sire,
      birthYear: data.annee_naissance,
      breed: data.race,
      gender: data.sexe,
    };
  }

  private mapRiderProfile(data: any): FFERiderProfile {
    return {
      licenseNumber: data.numero_licence,
      firstName: data.prenom,
      lastName: data.nom,
      club: data.club?.nom,
      region: data.region,
      level: data.niveau,
      disciplines: data.disciplines || [],
      horses: data.chevaux?.map((h: any) => ({
        ffeNumber: h.numero_ffe,
        name: h.nom,
      })) || [],
    };
  }

  private mapCompetition(data: any): FFECompetition {
    return {
      id: data.id,
      name: data.nom,
      startDate: new Date(data.date_debut),
      endDate: new Date(data.date_fin),
      location: data.lieu,
      address: data.adresse,
      discipline: data.discipline,
      level: data.niveau,
      organizer: data.organisateur,
      status: data.statut,
      url: data.url,
    };
  }

  private mapLiveResults(data: any): FFELiveResults {
    return {
      competitionId: data.id_concours,
      eventName: data.epreuve,
      status: data.statut,
      currentRider: data.cavalier_actuel,
      results: data.resultats?.map((r: any) => ({
        rank: r.classement,
        riderName: r.cavalier,
        horseName: r.cheval,
        score: r.note,
        penalties: r.penalites,
        time: r.temps,
      })) || [],
      lastUpdate: new Date(data.derniere_maj),
    };
  }
}

// Type definitions
export interface FFEHorseProfile {
  ffeNumber: string;
  name: string;
  sireNumber?: string;
  ueln?: string;
  birthDate?: Date;
  breed?: string;
  robe?: string;
  gender?: string;
  height?: number;
  sireName?: string;
  damName?: string;
  ownerName?: string;
  currentLevel?: string;
  disciplines: string[];
  lastActivity?: Date;
}

export interface FFECompetitionHistory {
  ffeNumber: string;
  competitions: FFECompetitionResult[];
  totalCount: number;
}

export interface FFECompetitionResult {
  id: string;
  name: string;
  date: Date;
  location?: string;
  discipline: string;
  level: string;
  eventName?: string;
  rank?: number;
  score?: number;
  penalties?: number;
  time?: number;
  prizeMoney?: number;
  riderName?: string;
  url?: string;
}

export interface FFEHorseSearchResult {
  ffeNumber: string;
  name: string;
  sireNumber?: string;
  birthYear?: number;
  breed?: string;
  gender?: string;
}

export interface FFERiderProfile {
  licenseNumber: string;
  firstName: string;
  lastName: string;
  club?: string;
  region?: string;
  level?: string;
  disciplines: string[];
  horses: { ffeNumber: string; name: string }[];
}

export interface FFECompetition {
  id: string;
  name: string;
  startDate: Date;
  endDate: Date;
  location: string;
  address?: string;
  discipline: string;
  level: string;
  organizer?: string;
  status: string;
  url?: string;
}

export interface FFELiveResults {
  competitionId: string;
  eventName: string;
  status: string;
  currentRider?: string;
  results: {
    rank: number;
    riderName: string;
    horseName: string;
    score?: number;
    penalties?: number;
    time?: number;
  }[];
  lastUpdate: Date;
}
