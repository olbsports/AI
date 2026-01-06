import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ExternalDataCacheService } from './cache.service';
import { firstValueFrom } from 'rxjs';

/**
 * SireWeb/France Galop Service
 *
 * Provides access to:
 * - Horse identification (SIRE numbers)
 * - Pedigree information
 * - Breeding records
 * - Ownership history
 *
 * Note: Some data requires IFCE partnership
 * Info: https://www.haras-nationaux.fr/information/infos-sire.html
 */
@Injectable()
export class SireWebService {
  private readonly logger = new Logger(SireWebService.name);
  private readonly baseUrl = process.env.SIREWEB_API_URL || 'https://info.haras-nationaux.fr/api';
  private readonly apiKey = process.env.SIREWEB_API_KEY;

  constructor(
    private http: HttpService,
    private cache: ExternalDataCacheService,
  ) {}

  /**
   * Get horse data by SIRE number
   */
  async getHorseData(sireNumber: string): Promise<SireWebHorse | null> {
    const cached = await this.cache.get('SireWeb', sireNumber, 'horse_profile');
    if (cached) return cached as SireWebHorse;

    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/equides/${sireNumber}`, {
          headers: this.getHeaders(),
        }),
      );

      const horse = this.mapHorse(response.data);

      // Cache for 7 days (SIRE data changes rarely)
      await this.cache.set('SireWeb', sireNumber, 'horse_profile', horse, 7 * 24 * 60 * 60 * 1000);

      return horse;
    } catch (error) {
      this.logger.error(`Failed to fetch SireWeb data for ${sireNumber}`, error);
      return null;
    }
  }

  /**
   * Get full history (ownership, breeding, offspring)
   */
  async getFullHistory(sireNumber: string): Promise<SireWebFullHistory | null> {
    const cached = await this.cache.get('SireWeb', sireNumber, 'full_history');
    if (cached) return cached as SireWebFullHistory;

    try {
      const [horse, owners, offspring, breeding] = await Promise.all([
        this.getHorseData(sireNumber),
        this.getOwnershipHistory(sireNumber),
        this.getOffspring(sireNumber),
        this.getBreedingHistory(sireNumber),
      ]);

      const history: SireWebFullHistory = {
        horse,
        owners,
        offspring,
        breeding,
        url: `https://www.haras-nationaux.fr/information/infos-sire/recherche-equide/${sireNumber}`,
      };

      // Cache for 24 hours
      await this.cache.set('SireWeb', sireNumber, 'full_history', history, 24 * 60 * 60 * 1000);

      return history;
    } catch (error) {
      this.logger.error(`Failed to fetch full history for ${sireNumber}`, error);
      return null;
    }
  }

  /**
   * Get pedigree (4 generations)
   */
  async getPedigree(sireNumber: string, generations: number = 4): Promise<SireWebPedigree | null> {
    const cacheKey = `${sireNumber}_pedigree_${generations}`;
    const cached = await this.cache.get('SireWeb', cacheKey, 'pedigree');
    if (cached) return cached as SireWebPedigree;

    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/equides/${sireNumber}/pedigree`, {
          headers: this.getHeaders(),
          params: { generations },
        }),
      );

      const pedigree = this.mapPedigree(response.data);

      // Cache for 30 days (pedigree never changes)
      await this.cache.set('SireWeb', cacheKey, 'pedigree', pedigree, 30 * 24 * 60 * 60 * 1000);

      return pedigree;
    } catch (error) {
      this.logger.error(`Failed to fetch pedigree for ${sireNumber}`, error);
      return null;
    }
  }

  /**
   * Get offspring list
   */
  async getOffspring(sireNumber: string): Promise<SireWebOffspring[]> {
    const cached = await this.cache.get('SireWeb', sireNumber, 'offspring');
    if (cached) return cached as SireWebOffspring[];

    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/equides/${sireNumber}/produits`, {
          headers: this.getHeaders(),
        }),
      );

      const offspring = response.data.produits?.map(this.mapOffspring) || [];

      // Cache for 7 days
      await this.cache.set('SireWeb', sireNumber, 'offspring', offspring, 7 * 24 * 60 * 60 * 1000);

      return offspring;
    } catch (error) {
      this.logger.error(`Failed to fetch offspring for ${sireNumber}`, error);
      return [];
    }
  }

  /**
   * Get ownership history
   */
  async getOwnershipHistory(sireNumber: string): Promise<SireWebOwner[]> {
    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/equides/${sireNumber}/proprietaires`, {
          headers: this.getHeaders(),
        }),
      );

      return response.data.proprietaires?.map((p: any) => ({
        name: p.nom,
        startDate: p.date_debut,
        endDate: p.date_fin,
        type: p.type, // proprietaire, naisseur, detenteur
      })) || [];
    } catch (error) {
      this.logger.error(`Failed to fetch ownership history for ${sireNumber}`, error);
      return [];
    }
  }

  /**
   * Get breeding history
   */
  async getBreedingHistory(sireNumber: string): Promise<SireWebBreeding[]> {
    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/equides/${sireNumber}/reproductions`, {
          headers: this.getHeaders(),
        }),
      );

      return response.data.reproductions?.map((r: any) => ({
        year: r.annee,
        partnerName: r.partenaire?.nom,
        partnerSire: r.partenaire?.sire,
        method: r.methode, // monte naturelle, IA fraiche, IA congelee
        success: r.reussite,
        foalName: r.produit?.nom,
        foalSire: r.produit?.sire,
      })) || [];
    } catch (error) {
      this.logger.error(`Failed to fetch breeding history for ${sireNumber}`, error);
      return [];
    }
  }

  /**
   * Search horses by name or SIRE number
   */
  async searchHorses(query: string, options?: {
    studbook?: string;
    birthYear?: number;
    gender?: string;
  }): Promise<SireWebSearchResult[]> {
    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/equides/recherche`, {
          headers: this.getHeaders(),
          params: {
            q: query,
            studbook: options?.studbook,
            annee_naissance: options?.birthYear,
            sexe: options?.gender,
            limit: 50,
          },
        }),
      );

      return response.data.resultats?.map((r: any) => ({
        sireNumber: r.sire,
        name: r.nom,
        birthYear: r.annee_naissance,
        studbook: r.studbook,
        gender: r.sexe,
        color: r.robe,
        sireName: r.pere,
        damName: r.mere,
      })) || [];
    } catch (error) {
      this.logger.error(`SireWeb search failed for: ${query}`, error);
      return [];
    }
  }

  /**
   * Get stallion station information
   */
  async getStallionStation(stationId: string): Promise<SireWebStation | null> {
    try {
      const response = await firstValueFrom(
        this.http.get(`${this.baseUrl}/stations/${stationId}`, {
          headers: this.getHeaders(),
        }),
      );

      return {
        id: response.data.id,
        name: response.data.nom,
        address: response.data.adresse,
        phone: response.data.telephone,
        email: response.data.email,
        stallions: response.data.etalons?.map((s: any) => ({
          sireNumber: s.sire,
          name: s.nom,
          studbook: s.studbook,
          indices: s.indices,
        })) || [],
      };
    } catch (error) {
      this.logger.error(`Failed to fetch station ${stationId}`, error);
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

  private mapHorse(data: any): SireWebHorse {
    return {
      sireNumber: data.sire,
      ueln: data.ueln,
      name: data.nom,
      gender: data.sexe,
      birthDate: data.date_naissance ? new Date(data.date_naissance) : null,
      birthYear: data.annee_naissance,
      studbook: data.studbook,
      breed: data.race,
      color: data.robe,
      height: data.taille,
      microchip: data.transpondeur,
      sireName: data.pere?.nom,
      sireSire: data.pere?.sire,
      damName: data.mere?.nom,
      damSire: data.mere?.sire,
      damSireName: data.mere?.pere?.nom,
      breeder: data.naisseur,
      currentOwner: data.proprietaire_actuel,
      status: data.statut, // vivant, mort, exporte, castré
      countryOfBirth: data.pays_naissance,
    };
  }

  private mapPedigree(data: any): SireWebPedigree {
    const mapAncestor = (a: any): SireWebAncestor | null => {
      if (!a) return null;
      return {
        sireNumber: a.sire,
        name: a.nom,
        studbook: a.studbook,
        color: a.robe,
        birthYear: a.annee_naissance,
        sire: mapAncestor(a.pere),
        dam: mapAncestor(a.mere),
      };
    };

    return {
      subject: {
        sireNumber: data.sire,
        name: data.nom,
        studbook: data.studbook,
      },
      sire: mapAncestor(data.pere),
      dam: mapAncestor(data.mere),
      inbreedingCoefficient: data.coefficient_consanguinite,
    };
  }

  private mapOffspring(data: any): SireWebOffspring {
    return {
      sireNumber: data.sire,
      name: data.nom,
      birthYear: data.annee_naissance,
      gender: data.sexe,
      studbook: data.studbook,
      color: data.robe,
      otherParentName: data.autre_parent?.nom,
      otherParentSire: data.autre_parent?.sire,
      status: data.statut,
      url: data.url,
    };
  }
}

// Type definitions
export interface SireWebHorse {
  sireNumber: string;
  ueln?: string;
  name: string;
  gender: string;
  birthDate?: Date;
  birthYear?: number;
  studbook?: string;
  breed?: string;
  color?: string;
  height?: number;
  microchip?: string;
  sireName?: string;
  sireSire?: string;
  damName?: string;
  damSire?: string;
  damSireName?: string;
  breeder?: string;
  currentOwner?: string;
  status?: string;
  countryOfBirth?: string;
}

export interface SireWebAncestor {
  sireNumber?: string;
  name: string;
  studbook?: string;
  color?: string;
  birthYear?: number;
  sire?: SireWebAncestor | null;
  dam?: SireWebAncestor | null;
}

export interface SireWebPedigree {
  subject: {
    sireNumber: string;
    name: string;
    studbook?: string;
  };
  sire?: SireWebAncestor | null;
  dam?: SireWebAncestor | null;
  inbreedingCoefficient?: number;
}

export interface SireWebOffspring {
  sireNumber: string;
  name: string;
  birthYear: number;
  gender: string;
  studbook?: string;
  color?: string;
  otherParentName?: string;
  otherParentSire?: string;
  status?: string;
  url?: string;
}

export interface SireWebOwner {
  name: string;
  startDate: string;
  endDate?: string;
  type: string;
}

export interface SireWebBreeding {
  year: number;
  partnerName?: string;
  partnerSire?: string;
  method: string;
  success: boolean;
  foalName?: string;
  foalSire?: string;
}

export interface SireWebFullHistory {
  horse: SireWebHorse | null;
  owners: SireWebOwner[];
  offspring: SireWebOffspring[];
  breeding: SireWebBreeding[];
  url: string;
}

export interface SireWebSearchResult {
  sireNumber: string;
  name: string;
  birthYear?: number;
  studbook?: string;
  gender?: string;
  color?: string;
  sireName?: string;
  damName?: string;
}

export interface SireWebStation {
  id: string;
  name: string;
  address?: string;
  phone?: string;
  email?: string;
  stallions: {
    sireNumber: string;
    name: string;
    studbook: string;
    indices?: Record<string, number>;
  }[];
}
