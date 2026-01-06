import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { FFEService } from '../external-data/ffe.service';
import { SireWebService } from '../external-data/sireweb.service';
import { IFCEService } from '../external-data/ifce.service';
import { MarketDataService } from '../external-data/market-data.service';
import { AnthropicService } from '../ai/anthropic.service';
import { CreateValuationDto, QuickEstimateDto, ValuationResponse, ValuationFactors } from './dto/equicote.dto';

@Injectable()
export class EquiCoteService {
  private readonly logger = new Logger(EquiCoteService.name);

  // Base prices by studbook (EUR)
  private readonly BASE_PRICES: Record<string, number> = {
    SF: 15000,     // Selle Français
    KWPN: 25000,   // Dutch Warmblood
    BWP: 20000,    // Belgian Warmblood
    HOLST: 22000,  // Holsteiner
    HANN: 20000,   // Hanoverian
    OLD: 18000,    // Oldenburg
    WEST: 17000,   // Westphalian
    AA: 12000,     // Anglo-Arabe
    PS: 30000,     // Pur-Sang (Thoroughbred)
    AR: 8000,      // Arabe
    PFS: 5000,     // Poney Français de Selle
    CO: 6000,      // Connemara
    WEL: 7000,     // Welsh
    ISH: 16000,    // Irish Sport Horse
    ZANG: 19000,   // Zangersheide
    DSP: 18000,    // German Sport Horse
  };

  // Level multipliers
  private readonly LEVEL_MULTIPLIERS: Record<string, number> = {
    pro_elite: 5.0,
    pro_1: 3.5,
    pro_2: 2.5,
    amateur_elite: 2.0,
    amateur_1: 1.6,
    amateur_2: 1.4,
    amateur_3: 1.2,
    club_elite: 1.1,
    club_1: 1.0,
    club_2: 0.9,
    club_3: 0.8,
    club_4: 0.7,
    debutant: 0.6,
    loisir: 0.5,
    jeune: 0.7,
  };

  // Discipline demand factors
  private readonly DISCIPLINE_FACTORS: Record<string, number> = {
    CSO: 1.2,      // Show Jumping - High demand
    CCE: 1.15,     // Eventing
    Dressage: 1.1,
    Hunter: 1.05,
    Endurance: 0.9,
    Attelage: 0.85,
    Voltige: 0.8,
    TREC: 0.75,
    Polo: 1.3,
    Course: 1.5,   // Racing
  };

  constructor(
    private prisma: PrismaService,
    private ffeService: FFEService,
    private sireWebService: SireWebService,
    private ifceService: IFCEService,
    private marketDataService: MarketDataService,
    private anthropicService: AnthropicService,
  ) {}

  /**
   * Create a new valuation for a horse
   */
  async createValuation(
    horseId: string,
    userId: string,
    organizationId: string,
  ): Promise<ValuationResponse> {
    this.logger.log(`Creating EquiCote valuation for horse ${horseId}`);

    // Get horse data
    const horse = await this.prisma.horse.findUnique({
      where: { id: horseId },
      include: {
        competitionResults: {
          orderBy: { competitionDate: 'desc' },
          take: 20,
        },
        healthRecords: {
          orderBy: { date: 'desc' },
          take: 10,
        },
        breedingRecords: true,
      },
    });

    if (!horse) {
      throw new NotFoundException('Horse not found');
    }

    // Gather external data
    const [ffeData, sireData, ifceData, marketData] = await Promise.allSettled([
      horse.ffeNumber ? this.ffeService.getHorseProfile(horse.ffeNumber) : null,
      horse.sireId ? this.sireWebService.getHorseData(horse.sireId) : null,
      horse.ueln ? this.ifceService.getGeneticIndices(horse.ueln) : null,
      this.marketDataService.getComparables(horse),
    ]);

    // Calculate age
    const age = horse.birthDate
      ? Math.floor((Date.now() - horse.birthDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000))
      : null;

    // Calculate factors
    const factors = this.calculateFactors(horse, age, {
      ffe: ffeData.status === 'fulfilled' ? ffeData.value : null,
      sire: sireData.status === 'fulfilled' ? sireData.value : null,
      ifce: ifceData.status === 'fulfilled' ? ifceData.value : null,
      market: marketData.status === 'fulfilled' ? marketData.value : null,
    });

    // Calculate base price
    const basePrice = this.calculateBasePrice(horse, factors);

    // Calculate price range
    const { minPrice, maxPrice, averagePrice } = this.calculatePriceRange(basePrice, factors);

    // Calculate confidence score
    const confidence = this.calculateConfidence(horse, factors);

    // Get AI analysis if confidence is low or for premium valuations
    let aiAnalysis: string | null = null;
    let aiRecommendations: string[] = [];

    if (confidence < 70) {
      const aiResult = await this.getAIAnalysis(horse, factors, {
        ffe: ffeData.status === 'fulfilled' ? ffeData.value : null,
        sire: sireData.status === 'fulfilled' ? sireData.value : null,
      });
      aiAnalysis = aiResult.analysis;
      aiRecommendations = aiResult.recommendations;
    }

    // Determine market trend
    const marketTrend = this.determineMarketTrend(
      marketData.status === 'fulfilled' ? marketData.value : null,
    );

    // Save valuation
    const valuation = await this.prisma.equiCoteValuation.create({
      data: {
        horseId,
        minPrice,
        maxPrice,
        averagePrice,
        confidence,
        factors: factors as any,
        comparableCount: marketData.status === 'fulfilled' ? marketData.value?.comparables?.length || 0 : 0,
        marketTrend,
        demandIndex: factors.demand * 100,
        aiAnalysis,
        aiRecommendations: aiRecommendations,
        dataSources: this.getDataSources(ffeData, sireData, ifceData, marketData),
        validUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
        requestedById: userId,
        tokensConsumed: 5, // Base cost
      },
    });

    // Create audit log
    await this.prisma.auditLog.create({
      data: {
        organizationId,
        userId,
        action: 'equicote_valuation_created',
        details: {
          horseId,
          valuationId: valuation.id,
          averagePrice,
          confidence,
        },
      },
    });

    return {
      id: valuation.id,
      horseId,
      horseName: horse.name,
      minPrice,
      maxPrice,
      averagePrice,
      confidence,
      factors,
      marketTrend,
      demandIndex: factors.demand * 100,
      aiAnalysis,
      aiRecommendations,
      dataSources: this.getDataSources(ffeData, sireData, ifceData, marketData),
      validUntil: valuation.validUntil,
      createdAt: valuation.createdAt,
    };
  }

  /**
   * Calculate all valuation factors
   */
  private calculateFactors(
    horse: any,
    age: number | null,
    externalData: any,
  ): ValuationFactors {
    // Age factor (0.4 - 1.2)
    let ageFactor = 1.0;
    if (age !== null) {
      if (age < 3) ageFactor = 0.5;
      else if (age >= 3 && age <= 5) ageFactor = 0.8; // Young, potential
      else if (age >= 6 && age <= 8) ageFactor = 1.2; // Prime age
      else if (age >= 9 && age <= 12) ageFactor = 1.0; // Experienced
      else if (age >= 13 && age <= 16) ageFactor = 0.7; // Aging
      else ageFactor = 0.4; // Senior
    }

    // Level factor
    const levelFactor = this.LEVEL_MULTIPLIERS[horse.level?.toLowerCase()] || 1.0;

    // Competition factor (based on results)
    let competitionFactor = 1.0;
    if (horse.competitionResults?.length > 0) {
      const wins = horse.competitionResults.filter((r: any) => r.rank === 1).length;
      const podiums = horse.competitionResults.filter((r: any) => r.rank <= 3).length;
      const classedCount = horse.competitionResults.filter((r: any) => r.rank <= 10).length;

      competitionFactor = 1.0 + (wins * 0.05) + (podiums * 0.03) + (classedCount * 0.01);
      competitionFactor = Math.min(competitionFactor, 2.0); // Cap at 2x
    }

    // Health factor
    let healthFactor = 1.0;
    if (horse.healthStatus === 'injured') healthFactor = 0.5;
    else if (horse.healthStatus === 'recovering') healthFactor = 0.7;
    else if (horse.healthStatus === 'retired') healthFactor = 0.3;

    // Lineage factor (from genetic indices)
    let lineageFactor = 1.0;
    if (externalData.ifce?.indices) {
      const iso = externalData.ifce.indices.ISO || 100;
      lineageFactor = 0.8 + (iso / 500); // ISO 100 = 1.0, ISO 150 = 1.1
      lineageFactor = Math.min(Math.max(lineageFactor, 0.8), 1.5);
    } else if (horse.sireName && horse.damName) {
      lineageFactor = 1.1; // Known pedigree bonus
    }

    // Discipline demand factor
    const primaryDiscipline = (horse.disciplines as string[])?.[0] || 'CSO';
    const demandFactor = this.DISCIPLINE_FACTORS[primaryDiscipline] || 1.0;

    // Market factor (from comparable sales)
    let marketFactor = 1.0;
    if (externalData.market?.averagePrice) {
      const basePrice = this.BASE_PRICES[horse.studbook] || 10000;
      marketFactor = externalData.market.averagePrice / basePrice;
      marketFactor = Math.min(Math.max(marketFactor, 0.7), 1.5); // Constrain
    }

    // Studbook factor
    let studbookFactor = 1.0;
    if (horse.studbook && this.BASE_PRICES[horse.studbook]) {
      studbookFactor = this.BASE_PRICES[horse.studbook] / 15000; // Normalize to SF
    }

    // Physical attributes factor
    let physicalFactor = 1.0;
    if (horse.heightCm) {
      if (horse.heightCm >= 165 && horse.heightCm <= 175) physicalFactor = 1.1; // Ideal height
      else if (horse.heightCm < 155 || horse.heightCm > 180) physicalFactor = 0.9;
    }

    return {
      age: ageFactor,
      level: levelFactor,
      competition: competitionFactor,
      health: healthFactor,
      lineage: lineageFactor,
      demand: demandFactor,
      market: marketFactor,
      studbook: studbookFactor,
      physical: physicalFactor,
    };
  }

  /**
   * Calculate base price from factors
   */
  private calculateBasePrice(horse: any, factors: ValuationFactors): number {
    const baseStudbookPrice = this.BASE_PRICES[horse.studbook] || 10000;

    const price = baseStudbookPrice *
      factors.age *
      factors.level *
      factors.competition *
      factors.health *
      factors.lineage *
      factors.demand *
      factors.market *
      factors.physical;

    return Math.round(price / 500) * 500; // Round to nearest 500
  }

  /**
   * Calculate price range based on confidence
   */
  private calculatePriceRange(
    basePrice: number,
    factors: ValuationFactors,
  ): { minPrice: number; maxPrice: number; averagePrice: number } {
    // Variance depends on data completeness
    const dataCompleteness = Object.values(factors).filter((v) => v !== 1.0).length / 9;
    const variance = 0.25 - (dataCompleteness * 0.1); // 15-25% variance

    const minPrice = Math.round((basePrice * (1 - variance)) / 500) * 500;
    const maxPrice = Math.round((basePrice * (1 + variance)) / 500) * 500;
    const averagePrice = Math.round(((minPrice + maxPrice) / 2) / 500) * 500;

    return { minPrice, maxPrice, averagePrice };
  }

  /**
   * Calculate confidence score
   */
  private calculateConfidence(horse: any, factors: ValuationFactors): number {
    let confidence = 50; // Base confidence

    // Data completeness bonuses
    if (horse.birthDate) confidence += 5;
    if (horse.studbook) confidence += 5;
    if (horse.level) confidence += 5;
    if (horse.sireId || horse.ueln) confidence += 10;
    if (horse.competitionResults?.length > 0) confidence += 10;
    if (horse.competitionResults?.length > 5) confidence += 5;
    if (horse.healthRecords?.length > 0) confidence += 5;
    if (horse.sireName && horse.damName) confidence += 5;

    // External data bonuses
    if (factors.market !== 1.0) confidence += 10; // Market data available
    if (factors.lineage !== 1.0) confidence += 5; // Genetic indices available

    return Math.min(confidence, 95); // Max 95%
  }

  /**
   * Get AI analysis for complex valuations
   */
  private async getAIAnalysis(
    horse: any,
    factors: ValuationFactors,
    externalData: any,
  ): Promise<{ analysis: string; recommendations: string[] }> {
    try {
      const prompt = `
Analyse cette valorisation de cheval pour EquiCote:

CHEVAL:
- Nom: ${horse.name}
- Race/Studbook: ${horse.studbook || 'Inconnu'}
- Né: ${horse.birthDate ? new Date(horse.birthDate).getFullYear() : 'Inconnu'}
- Niveau: ${horse.level || 'Non précisé'}
- Disciplines: ${(horse.disciplines as string[])?.join(', ') || 'Non précisé'}
- État de santé: ${horse.healthStatus}

FACTEURS DE VALORISATION:
${Object.entries(factors).map(([k, v]) => `- ${k}: ${v.toFixed(2)}`).join('\n')}

DONNÉES EXTERNES:
- FFE: ${externalData.ffe ? 'Disponible' : 'Non disponible'}
- SireWeb: ${externalData.sire ? 'Disponible' : 'Non disponible'}

Fournis:
1. Une analyse courte (2-3 phrases) de la valorisation
2. 3 recommandations pour améliorer la valeur ou la fiabilité de l'estimation
`;

      const response = await this.anthropicService.analyze(prompt, 'valuation');

      return {
        analysis: response.analysis || 'Analyse non disponible',
        recommendations: response.recommendations || [],
      };
    } catch (error) {
      this.logger.error('AI analysis failed', error);
      return { analysis: null, recommendations: [] };
    }
  }

  /**
   * Determine market trend
   */
  private determineMarketTrend(marketData: any): string {
    if (!marketData?.priceTrend) return 'stable';

    const trend = marketData.priceTrend;
    if (trend > 5) return 'up';
    if (trend < -5) return 'down';
    return 'stable';
  }

  /**
   * Get list of data sources used
   */
  private getDataSources(...results: PromiseSettledResult<any>[]): string[] {
    const sources: string[] = ['EquiCote'];

    if (results[0]?.status === 'fulfilled' && results[0].value) sources.push('FFE');
    if (results[1]?.status === 'fulfilled' && results[1].value) sources.push('SireWeb');
    if (results[2]?.status === 'fulfilled' && results[2].value) sources.push('IFCE');
    if (results[3]?.status === 'fulfilled' && results[3].value) sources.push('Marketplace');

    return sources;
  }

  /**
   * Get valuation by ID
   */
  async getValuation(valuationId: string): Promise<ValuationResponse | null> {
    const valuation = await this.prisma.equiCoteValuation.findUnique({
      where: { id: valuationId },
      include: { horse: true },
    });

    if (!valuation) return null;

    return {
      id: valuation.id,
      horseId: valuation.horseId,
      horseName: valuation.horse.name,
      minPrice: valuation.minPrice,
      maxPrice: valuation.maxPrice,
      averagePrice: valuation.averagePrice,
      confidence: valuation.confidence,
      factors: valuation.factors as unknown as ValuationFactors,
      marketTrend: valuation.marketTrend,
      demandIndex: valuation.demandIndex,
      aiAnalysis: valuation.aiAnalysis,
      aiRecommendations: valuation.aiRecommendations as string[],
      dataSources: valuation.dataSources as string[],
      validUntil: valuation.validUntil,
      createdAt: valuation.createdAt,
    };
  }

  /**
   * Get all valuations for a horse
   */
  async getHorseValuations(horseId: string): Promise<ValuationResponse[]> {
    const valuations = await this.prisma.equiCoteValuation.findMany({
      where: { horseId },
      include: { horse: true },
      orderBy: { createdAt: 'desc' },
    });

    return valuations.map((v) => ({
      id: v.id,
      horseId: v.horseId,
      horseName: v.horse.name,
      minPrice: v.minPrice,
      maxPrice: v.maxPrice,
      averagePrice: v.averagePrice,
      confidence: v.confidence,
      factors: v.factors as unknown as ValuationFactors,
      marketTrend: v.marketTrend,
      demandIndex: v.demandIndex,
      aiAnalysis: v.aiAnalysis,
      aiRecommendations: v.aiRecommendations as string[],
      dataSources: v.dataSources as string[],
      validUntil: v.validUntil,
      createdAt: v.createdAt,
    }));
  }

  /**
   * Quick estimate without external data (for previews)
   */
  async quickEstimate(data: QuickEstimateDto): Promise<{
    minPrice: number;
    maxPrice: number;
    confidence: number;
  }> {
    const basePrice = this.BASE_PRICES[data.studbook] || 10000;
    const ageFactor = this.calculateAgeFactor(data.age);
    const levelFactor = this.LEVEL_MULTIPLIERS[data.level?.toLowerCase()] || 1.0;
    const disciplineFactor = this.DISCIPLINE_FACTORS[data.discipline] || 1.0;

    const estimated = basePrice * ageFactor * levelFactor * disciplineFactor;
    const minPrice = Math.round((estimated * 0.8) / 500) * 500;
    const maxPrice = Math.round((estimated * 1.2) / 500) * 500;

    return {
      minPrice,
      maxPrice,
      confidence: 40, // Low confidence for quick estimates
    };
  }

  private calculateAgeFactor(age: number | undefined): number {
    if (!age) return 1.0;
    if (age < 3) return 0.5;
    if (age >= 3 && age <= 5) return 0.8;
    if (age >= 6 && age <= 8) return 1.2;
    if (age >= 9 && age <= 12) return 1.0;
    if (age >= 13 && age <= 16) return 0.7;
    return 0.4;
  }
}
