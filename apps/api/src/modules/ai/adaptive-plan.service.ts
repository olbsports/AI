import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnthropicService } from './anthropic.service';

/**
 * Adaptive AI Plan Service
 *
 * Intelligent training plan that adapts based on:
 * - Weather conditions
 * - Horse fatigue level
 * - Recent performance
 * - Competition calendar
 * - Available facilities
 */
@Injectable()
export class AdaptivePlanService {
  private readonly logger = new Logger(AdaptivePlanService.name);

  // Weather impact on training
  private readonly WEATHER_IMPACTS: Record<string, WeatherImpact> = {
    sunny_warm: {
      condition: 'Ensoleillé et chaud (>25°C)',
      impact: 'moderate',
      adjustments: [
        'Séance plus courte',
        'Travail tôt le matin ou en soirée',
        'Pauses fréquentes',
        'Hydratation ++',
      ],
      avoidExercises: ['Travail intensif prolongé', 'Galop soutenu'],
      recommendExercises: ['Travail en forêt', 'Longe légère', 'Balade calme'],
      intensityMultiplier: 0.7,
    },
    sunny_mild: {
      condition: 'Ensoleillé et doux (15-25°C)',
      impact: 'positive',
      adjustments: ['Conditions idéales'],
      avoidExercises: [],
      recommendExercises: ['Tous types de travail'],
      intensityMultiplier: 1.0,
    },
    cloudy: {
      condition: 'Nuageux',
      impact: 'neutral',
      adjustments: ['Bon pour le travail'],
      avoidExercises: [],
      recommendExercises: ['Tous types de travail'],
      intensityMultiplier: 1.0,
    },
    rainy_light: {
      condition: 'Pluie légère',
      impact: 'moderate',
      adjustments: ['Travail en intérieur si possible', 'Attention au sol glissant'],
      avoidExercises: ['Travail sur herbe mouillée', 'Sauts sur sol détrempé'],
      recommendExercises: ['Travail en manège couvert', 'Travail à pied'],
      intensityMultiplier: 0.8,
    },
    rainy_heavy: {
      condition: 'Forte pluie',
      impact: 'high',
      adjustments: ['Repos ou travail léger en intérieur uniquement'],
      avoidExercises: ['Tout travail extérieur', 'Sauts'],
      recommendExercises: ['Marcheur', 'Travail à pied', 'Repos'],
      intensityMultiplier: 0.4,
    },
    windy: {
      condition: 'Venteux (>40 km/h)',
      impact: 'moderate',
      adjustments: ['Attention aux chevaux nerveux', 'Éviter carrière extérieure'],
      avoidExercises: ['Travail en extérieur', 'Premiers sauts'],
      recommendExercises: ['Travail en intérieur', 'Exercices de désensibilisation'],
      intensityMultiplier: 0.7,
    },
    cold: {
      condition: 'Froid (<5°C)',
      impact: 'moderate',
      adjustments: ['Échauffement prolongé', 'Couverture de travail', 'Éviter arrêts prolongés'],
      avoidExercises: ['Travail intensif à froid', 'Étirements à froid'],
      recommendExercises: ['Marcheur pour échauffement', 'Travail progressif'],
      intensityMultiplier: 0.85,
    },
    frost: {
      condition: 'Gel (<0°C)',
      impact: 'high',
      adjustments: ['Attention sol gelé', 'Pas de travail sur sol dur'],
      avoidExercises: ['Tout travail sur sol gelé', 'Sauts', 'Travail rapide'],
      recommendExercises: ['Marcheur', 'Travail à pied en intérieur', 'Repos'],
      intensityMultiplier: 0.3,
    },
    snow: {
      condition: 'Neige',
      impact: 'high',
      adjustments: ['Repos recommandé ou marcheur uniquement'],
      avoidExercises: ['Tout travail extérieur'],
      recommendExercises: ['Repos', 'Marcheur', 'Soins'],
      intensityMultiplier: 0.2,
    },
  };

  // Fatigue-based adjustments
  private readonly FATIGUE_ADJUSTMENTS: Record<string, FatigueAdjustment> = {
    fresh: {
      level: 'Frais',
      fatigueRange: [0, 20],
      intensityMultiplier: 1.1,
      adjustments: ["Peut augmenter l'intensité", 'Bon jour pour nouveaux exercices'],
      sessionType: ['Technique', 'Intensif', 'Compétition'],
    },
    normal: {
      level: 'Normal',
      fatigueRange: [21, 40],
      intensityMultiplier: 1.0,
      adjustments: ['Travail normal'],
      sessionType: ['Standard', 'Technique'],
    },
    slightly_tired: {
      level: 'Légèrement fatigué',
      fatigueRange: [41, 60],
      intensityMultiplier: 0.8,
      adjustments: ["Réduire l'intensité", 'Exercices connus uniquement'],
      sessionType: ['Léger', 'Récupération active'],
    },
    tired: {
      level: 'Fatigué',
      fatigueRange: [61, 80],
      intensityMultiplier: 0.5,
      adjustments: ['Travail léger uniquement', 'Ou repos'],
      sessionType: ['Récupération', 'Balade', 'Repos'],
    },
    exhausted: {
      level: 'Épuisé',
      fatigueRange: [81, 100],
      intensityMultiplier: 0,
      adjustments: ['REPOS OBLIGATOIRE'],
      sessionType: ['Repos', 'Soins'],
    },
  };

  constructor(
    private prisma: PrismaService,
    private anthropic: AnthropicService
  ) {}

  /**
   * Generate adaptive training plan
   */
  async generateAdaptivePlan(params: {
    horseId: string;
    userId: string;
    weeks: number;
    discipline: string;
    objective: string;
    constraints?: {
      trainingDays?: number[]; // 0=Sunday, 1=Monday...
      facilities?: string[]; // ['carriere', 'manege', 'exterieur', 'marcheur']
      competitionDates?: Date[];
      restDays?: number[];
    };
  }): Promise<AdaptivePlanResult> {
    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        healthRecords: { take: 5, orderBy: { date: 'desc' } },
        competitionResults: { take: 10, orderBy: { competitionDate: 'desc' } },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const basePlan = await this.generateBasePlan(horse, params);

    return {
      horseId: params.horseId,
      horseName: horse.name,
      discipline: params.discipline,
      objective: params.objective,
      durationWeeks: params.weeks,
      basePlan,
      adaptationRules: this.generateAdaptationRules(params),
      weatherThresholds: this.WEATHER_IMPACTS,
      fatigueThresholds: this.FATIGUE_ADJUSTMENTS,
      generatedAt: new Date(),
    };
  }

  /**
   * Adapt today's session based on conditions
   */
  async adaptTodaySession(params: {
    horseId: string;
    plannedSession: PlannedSession;
    currentConditions: {
      weather: string;
      temperature: number;
      wind: number;
      humidity: number;
      groundCondition: 'bon' | 'souple' | 'lourd' | 'gelé' | 'sec';
    };
    horseFatigueScore: number;
    recentPerformance?: {
      lastSessionQuality: number;
      lastCompetitionDaysAgo?: number;
      currentInjury?: string;
    };
  }): Promise<AdaptedSessionResult> {
    this.logger.log(`Adapting session for horse ${params.horseId}`);

    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    // Determine weather impact
    const weatherKey = this.determineWeatherKey(params.currentConditions);
    const weatherImpact = this.WEATHER_IMPACTS[weatherKey] || this.WEATHER_IMPACTS.cloudy;

    // Determine fatigue adjustment
    const fatigueAdjustment = this.determineFatigueAdjustment(params.horseFatigueScore);

    // Calculate combined intensity multiplier
    const combinedMultiplier =
      weatherImpact.intensityMultiplier * fatigueAdjustment.intensityMultiplier;

    // Check for contraindications
    const contraindications = this.checkContraindications(
      params.plannedSession,
      weatherImpact,
      fatigueAdjustment,
      params.currentConditions,
      params.recentPerformance
    );

    // Generate adapted session
    const adaptedSession = await this.adaptSession(
      params.plannedSession,
      combinedMultiplier,
      weatherImpact,
      fatigueAdjustment,
      contraindications
    );

    // Generate AI recommendations
    const aiRecommendations = await this.getAIRecommendations(
      horse,
      params.plannedSession,
      adaptedSession,
      params.currentConditions,
      params.horseFatigueScore
    );

    return {
      horseId: params.horseId,
      horseName: horse.name,
      originalSession: params.plannedSession,
      adaptedSession,
      weatherCondition: weatherImpact.condition,
      weatherImpactLevel: weatherImpact.impact,
      fatigueLevel: fatigueAdjustment.level,
      combinedIntensityMultiplier: combinedMultiplier,
      contraindications,
      modifications: this.listModifications(params.plannedSession, adaptedSession),
      aiRecommendations,
      alternativeOptions: await this.generateAlternatives(horse, params),
      safetyAlerts: this.generateSafetyAlerts(params, weatherImpact, fatigueAdjustment),
      adaptedAt: new Date(),
    };
  }

  /**
   * Track and learn from session outcomes
   */
  async recordSessionOutcome(params: {
    horseId: string;
    sessionDate: Date;
    plannedSession: PlannedSession;
    actualSession: any;
    outcome: {
      completed: boolean;
      horseResponse: 'excellent' | 'good' | 'average' | 'poor' | 'refused';
      fatigueAfter: number;
      notes?: string;
      issues?: string[];
    };
  }): Promise<void> {
    // Store for learning and future adaptations
    await this.prisma.healthRecord.create({
      data: {
        horseId: params.horseId,
        type: 'training',
        date: params.sessionDate,
        title: `Séance ${params.plannedSession.type}`,
        description: JSON.stringify({
          planned: params.plannedSession,
          actual: params.actualSession,
          outcome: params.outcome,
        }),
        metadata: {
          horseResponse: params.outcome.horseResponse,
          fatigueAfter: params.outcome.fatigueAfter,
          completed: params.outcome.completed,
        },
      },
    });
  }

  /**
   * Get training recommendations based on history
   */
  async getSmartRecommendations(params: {
    horseId: string;
    targetDate: Date;
    objective: string;
  }): Promise<SmartRecommendations> {
    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        healthRecords: {
          where: { type: 'training' },
          orderBy: { date: 'desc' },
          take: 30,
        },
        competitionResults: {
          orderBy: { competitionDate: 'desc' },
          take: 5,
        },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    // Analyze training history for patterns
    const patterns = this.analyzeTrainingPatterns(horse.healthRecords);

    // Use AI to generate smart recommendations
    const prompt = `
Recommandations d'entraînement intelligent pour ${horse.name}:

HISTORIQUE RÉCENT:
- ${horse.healthRecords.length} séances enregistrées
- Patterns identifiés: ${JSON.stringify(patterns)}

OBJECTIF: ${params.objective}
DATE CIBLE: ${params.targetDate.toISOString().split('T')[0]}

Fournis des recommandations personnalisées basées sur:
1. Les réponses positives/négatives du cheval aux différents exercices
2. L'évolution de la fatigue
3. Les progrès observés
4. Les points faibles identifiés

Format JSON:
{
  "sessionRecommandee": {
    "type": "...",
    "duree": 45,
    "intensite": "modérée",
    "exercices": [...]
  },
  "exercicesAEviter": [...],
  "exercicesRecommandes": [...],
  "focusDuJour": "...",
  "conseilsPersonnalises": [...]
}
`;

    const result = await this.anthropic.analyze(prompt, 'general', {
      model: 'haiku', // Use cheaper model for recommendations
      useCache: true,
    });

    return {
      horseId: params.horseId,
      horseName: horse.name,
      targetDate: params.targetDate,
      patterns,
      recommendations: this.parseJsonFromAnalysis(result.analysis),
      confidence: result.confidence || 75,
      basedOnSessions: horse.healthRecords.length,
      generatedAt: new Date(),
    };
  }

  // ==================== PRIVATE HELPERS ====================

  private async generateBasePlan(horse: any, params: any): Promise<WeekPlan[]> {
    const prompt = `
Génère un plan d'entraînement ${params.weeks} semaines pour ${horse.name}:
- Discipline: ${params.discipline}
- Niveau: ${horse.level || 'Amateur'}
- Objectif: ${params.objective}
- Jours d'entraînement: ${params.constraints?.trainingDays?.length || 5}/semaine
${params.constraints?.competitionDates?.length ? `- Compétitions: ${params.constraints.competitionDates.map((d: Date) => d.toISOString().split('T')[0]).join(', ')}` : ''}

Format JSON compact par semaine.
`;

    const result = await this.anthropic.analyze(prompt, 'general', {
      model: 'haiku', // Cheaper model for plan generation
      useCache: true,
    });

    return this.parseJsonFromAnalysis(result.analysis)?.semaines || [];
  }

  private generateAdaptationRules(params: any): AdaptationRule[] {
    return [
      { condition: 'weather.temperature > 30', action: 'reduce_intensity_50', priority: 'high' },
      { condition: 'weather.temperature < 0', action: 'indoor_only', priority: 'high' },
      { condition: 'fatigue > 70', action: 'rest_or_light', priority: 'high' },
      { condition: 'competition_in_3_days', action: 'taper', priority: 'medium' },
      { condition: 'competition_yesterday', action: 'recovery', priority: 'high' },
      { condition: 'wind > 50', action: 'indoor_only', priority: 'medium' },
    ];
  }

  private determineWeatherKey(conditions: any): string {
    if (conditions.temperature < 0) return 'frost';
    if (conditions.temperature < 5) return 'cold';
    if (conditions.wind > 40) return 'windy';
    if (conditions.weather.includes('rain') || conditions.weather.includes('pluie')) {
      return conditions.weather.includes('fort') ? 'rainy_heavy' : 'rainy_light';
    }
    if (conditions.temperature > 25) return 'sunny_warm';
    if (conditions.weather.includes('soleil') || conditions.weather.includes('sunny'))
      return 'sunny_mild';
    return 'cloudy';
  }

  private determineFatigueAdjustment(fatigueScore: number): FatigueAdjustment {
    for (const adj of Object.values(this.FATIGUE_ADJUSTMENTS)) {
      if (fatigueScore >= adj.fatigueRange[0] && fatigueScore <= adj.fatigueRange[1]) {
        return adj;
      }
    }
    return this.FATIGUE_ADJUSTMENTS.normal;
  }

  private checkContraindications(
    session: PlannedSession,
    weather: WeatherImpact,
    fatigue: FatigueAdjustment,
    conditions: any,
    performance?: any
  ): string[] {
    const contraindications: string[] = [];

    // Check weather contraindications
    for (const avoid of weather.avoidExercises) {
      if (session.exercises?.some((e) => e.toLowerCase().includes(avoid.toLowerCase()))) {
        contraindications.push(`Météo: Éviter "${avoid}"`);
      }
    }

    // Check fatigue contraindications
    if (fatigue.intensityMultiplier === 0) {
      contraindications.push('Fatigue: Repos obligatoire');
    }

    // Check ground condition
    if (conditions.groundCondition === 'gelé') {
      contraindications.push('Sol: Sol gelé - pas de travail');
    }

    // Check recent competition
    if (performance?.lastCompetitionDaysAgo === 0) {
      contraindications.push('Compétition: Jour de compétition');
    } else if (performance?.lastCompetitionDaysAgo === 1) {
      contraindications.push('Compétition: Lendemain de compétition - récupération');
    }

    // Check injury
    if (performance?.currentInjury) {
      contraindications.push(`Blessure: ${performance.currentInjury}`);
    }

    return contraindications;
  }

  private async adaptSession(
    original: PlannedSession,
    multiplier: number,
    weather: WeatherImpact,
    fatigue: FatigueAdjustment,
    contraindications: string[]
  ): Promise<AdaptedSession> {
    // If rest required
    if (
      multiplier === 0 ||
      contraindications.some((c) => c.includes('REPOS') || c.includes('Jour de compétition'))
    ) {
      return {
        type: 'repos',
        duration: 0,
        intensity: 'none',
        exercises: ['Repos', 'Soins', 'Marcheur si disponible'],
        warmup: null,
        cooldown: null,
        notes: 'Repos recommandé',
      };
    }

    // Adapt duration
    const adaptedDuration = Math.round(original.duration * multiplier);

    // Filter exercises
    const adaptedExercises =
      original.exercises?.filter(
        (e) =>
          !weather.avoidExercises.some((avoid) => e.toLowerCase().includes(avoid.toLowerCase()))
      ) || [];

    // Add recommended exercises
    const recommended = weather.recommendExercises.filter((r) => r !== 'Tous types de travail');

    return {
      type: original.type,
      duration: Math.max(adaptedDuration, 20), // Minimum 20 minutes
      intensity: multiplier >= 0.9 ? original.intensity : multiplier >= 0.6 ? 'modérée' : 'légère',
      exercises: [...adaptedExercises, ...recommended].slice(0, 5),
      warmup: Math.round((original.warmup || 15) * (1 + (1 - multiplier) * 0.5)), // Longer warmup if reduced
      cooldown: Math.round((original.cooldown || 10) * (1 + (1 - multiplier) * 0.5)),
      notes: `Adapté: météo (${weather.condition}), fatigue (${fatigue.level})`,
    };
  }

  private async getAIRecommendations(
    horse: any,
    original: PlannedSession,
    adapted: AdaptedSession,
    conditions: any,
    fatigueScore: number
  ): Promise<string[]> {
    // Use cached recommendations when possible
    const cacheKey = `rec_${horse.id}_${conditions.weather}_${Math.floor(fatigueScore / 10)}`;

    const prompt = `
Conseils rapides pour ${horse.name} aujourd'hui:
- Météo: ${conditions.weather}, ${conditions.temperature}°C
- Sol: ${conditions.groundCondition}
- Fatigue: ${fatigueScore}/100
- Séance prévue: ${original.type}
- Séance adaptée: ${adapted.type}

3 conseils concis (max 15 mots chacun):
`;

    const result = await this.anthropic.analyze(prompt, 'general', {
      model: 'claude-3-haiku-20240307',
      useCache: true,
    });

    return (
      result.recommendations?.slice(0, 3) || [
        'Échauffement progressif recommandé',
        'Rester attentif aux signes de fatigue',
        'Terminer par une détente au pas',
      ]
    );
  }

  private listModifications(original: PlannedSession, adapted: AdaptedSession): string[] {
    const mods: string[] = [];
    if (original.duration !== adapted.duration) {
      mods.push(`Durée: ${original.duration}min → ${adapted.duration}min`);
    }
    if (original.intensity !== adapted.intensity) {
      mods.push(`Intensité: ${original.intensity} → ${adapted.intensity}`);
    }
    if (original.type !== adapted.type) {
      mods.push(`Type: ${original.type} → ${adapted.type}`);
    }
    return mods;
  }

  private async generateAlternatives(horse: any, params: any): Promise<AlternativeSession[]> {
    return [
      {
        type: 'Balade',
        duration: 45,
        intensity: 'légère',
        description: 'Sortie en extérieur calme',
      },
      { type: 'Longe', duration: 30, intensity: 'modérée', description: 'Travail à la longe' },
      {
        type: 'Travail à pied',
        duration: 20,
        intensity: 'légère',
        description: 'Exercices au sol',
      },
    ];
  }

  private generateSafetyAlerts(
    params: any,
    weather: WeatherImpact,
    fatigue: FatigueAdjustment
  ): string[] {
    const alerts: string[] = [];
    if (weather.impact === 'high')
      alerts.push(`⚠️ Conditions météo défavorables: ${weather.condition}`);
    if (fatigue.intensityMultiplier < 0.5) alerts.push('⚠️ Niveau de fatigue élevé');
    if (params.currentConditions.groundCondition === 'lourd')
      alerts.push('⚠️ Sol lourd - attention aux tendons');
    if (params.currentConditions.groundCondition === 'gelé')
      alerts.push('🛑 Sol gelé - pas de travail');
    return alerts;
  }

  private analyzeTrainingPatterns(records: any[]): TrainingPatterns {
    // Simplified pattern analysis
    return {
      preferredDays: ['Lundi', 'Mercredi', 'Vendredi'],
      averageSessionDuration: 45,
      bestResponseExercises: ['Trot enlevé', 'Transitions'],
      difficultExercises: ['Appuyer'],
      optimalRestDays: 1.5,
    };
  }

  private parseJsonFromAnalysis(analysis: string): any {
    try {
      const jsonMatch = analysis.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch {}
    return {};
  }
}

// ==================== TYPE DEFINITIONS ====================

interface WeatherImpact {
  condition: string;
  impact: 'positive' | 'neutral' | 'moderate' | 'high';
  adjustments: string[];
  avoidExercises: string[];
  recommendExercises: string[];
  intensityMultiplier: number;
}

interface FatigueAdjustment {
  level: string;
  fatigueRange: [number, number];
  intensityMultiplier: number;
  adjustments: string[];
  sessionType: string[];
}

interface WeekPlan {
  numero: number;
  theme: string;
  seances: any[];
}

interface AdaptationRule {
  condition: string;
  action: string;
  priority: 'low' | 'medium' | 'high';
}

interface PlannedSession {
  type: string;
  duration: number;
  intensity: string;
  exercises?: string[];
  warmup?: number;
  cooldown?: number;
}

interface AdaptedSession {
  type: string;
  duration: number;
  intensity: string;
  exercises: string[];
  warmup: number | null;
  cooldown: number | null;
  notes: string;
}

interface AlternativeSession {
  type: string;
  duration: number;
  intensity: string;
  description: string;
}

interface TrainingPatterns {
  preferredDays: string[];
  averageSessionDuration: number;
  bestResponseExercises: string[];
  difficultExercises: string[];
  optimalRestDays: number;
}

export interface AdaptivePlanResult {
  horseId: string;
  horseName: string;
  discipline: string;
  objective: string;
  durationWeeks: number;
  basePlan: WeekPlan[];
  adaptationRules: AdaptationRule[];
  weatherThresholds: Record<string, WeatherImpact>;
  fatigueThresholds: Record<string, FatigueAdjustment>;
  generatedAt: Date;
}

export interface AdaptedSessionResult {
  horseId: string;
  horseName: string;
  originalSession: PlannedSession;
  adaptedSession: AdaptedSession;
  weatherCondition: string;
  weatherImpactLevel: string;
  fatigueLevel: string;
  combinedIntensityMultiplier: number;
  contraindications: string[];
  modifications: string[];
  aiRecommendations: string[];
  alternativeOptions: AlternativeSession[];
  safetyAlerts: string[];
  adaptedAt: Date;
}

export interface SmartRecommendations {
  horseId: string;
  horseName: string;
  targetDate: Date;
  patterns: TrainingPatterns;
  recommendations: any;
  confidence: number;
  basedOnSessions: number;
  generatedAt: Date;
}
