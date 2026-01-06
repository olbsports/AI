import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnthropicService } from './anthropic.service';

/**
 * Video Analysis Service
 *
 * Specialized AI analysis for equestrian videos
 * with discipline-specific evaluation criteria
 */
@Injectable()
export class VideoAnalysisService {
  private readonly logger = new Logger(VideoAnalysisService.name);

  // Discipline-specific evaluation criteria
  private readonly DISCIPLINE_CRITERIA: Record<string, DisciplineCriteria> = {
    CSO: {
      name: 'Saut d\'obstacles',
      criteria: [
        { name: 'Bascule', weight: 20, description: 'Arrondi du dos au-dessus de l\'obstacle' },
        { name: 'Technique antérieurs', weight: 15, description: 'Pliure et symétrie des antérieurs' },
        { name: 'Technique postérieurs', weight: 15, description: 'Propulsion et dégagement' },
        { name: 'Battue', weight: 15, description: 'Distance et timing de l\'appel' },
        { name: 'Réception', weight: 10, description: 'Équilibre à la réception' },
        { name: 'Cadence', weight: 10, description: 'Régularité de la cadence d\'approche' },
        { name: 'Équilibre général', weight: 10, description: 'Équilibre sur le parcours' },
        { name: 'Mental', weight: 5, description: 'Attitude et franchise' },
      ],
      levels: {
        club: { minHeight: 60, maxHeight: 105, description: 'Club 4 à Club Élite' },
        amateur: { minHeight: 105, maxHeight: 130, description: 'Amateur 3 à Amateur Élite' },
        pro: { minHeight: 130, maxHeight: 165, description: 'Pro 3 à Pro Élite/GP' },
      },
    },
    Dressage: {
      name: 'Dressage',
      criteria: [
        { name: 'Régularité des allures', weight: 20, description: 'Qualité et régularité des 3 allures' },
        { name: 'Impulsion', weight: 15, description: 'Désir d\'aller en avant, énergie' },
        { name: 'Soumission', weight: 15, description: 'Légèreté, décontraction, perméabilité aux aides' },
        { name: 'Rectitude', weight: 10, description: 'Alignement du cheval' },
        { name: 'Rassembler', weight: 15, description: 'Engagement des postérieurs, abaissement des hanches' },
        { name: 'Position du cavalier', weight: 10, description: 'Assiette, position, discrétion des aides' },
        { name: 'Transitions', weight: 10, description: 'Fluidité et promptitude des transitions' },
        { name: 'Figures', weight: 5, description: 'Précision géométrique des figures' },
      ],
      levels: {
        club: { description: 'Club 4 à Club Élite - Figures simples' },
        amateur: { description: 'Amateur 3 à Amateur Élite - Figures moyennes' },
        pro: { description: 'Pro 3 à Grand Prix - Figures avancées (piaffer, passage)' },
      },
    },
    CCE: {
      name: 'Concours Complet',
      criteria: [
        { name: 'Cross - Galop', weight: 15, description: 'Qualité et régularité du galop' },
        { name: 'Cross - Franchise', weight: 20, description: 'Courage et initiative devant les obstacles' },
        { name: 'Cross - Équilibre', weight: 15, description: 'Équilibre en terrain varié' },
        { name: 'CSO - Technique', weight: 15, description: 'Technique de saut en CSO' },
        { name: 'Dressage - Souplesse', weight: 10, description: 'Qualité du dressage' },
        { name: 'Endurance', weight: 10, description: 'Capacité de récupération' },
        { name: 'Mental', weight: 10, description: 'Sang-froid et gestion du stress' },
        { name: 'Polyvalence', weight: 5, description: 'Adaptabilité aux 3 tests' },
      ],
      levels: {
        club: { description: 'Club 3 à Club Élite' },
        amateur: { description: 'Amateur 3 à Amateur Élite' },
        pro: { description: 'Pro 3 à CCI5*' },
      },
    },
    Hunter: {
      name: 'Hunter',
      criteria: [
        { name: 'Style', weight: 25, description: 'Élégance et fluidité du parcours' },
        { name: 'Régularité', weight: 20, description: 'Constance des foulées et du rythme' },
        { name: 'Attitude', weight: 20, description: 'Port de tête, engagement' },
        { name: 'Douceur', weight: 15, description: 'Discrétion des aides cavalier' },
        { name: 'Trajectoires', weight: 10, description: 'Qualité des courbes et lignes' },
        { name: 'Saut', weight: 10, description: 'Technique et style sur l\'obstacle' },
      ],
      levels: {
        club: { description: 'Épreuves Club' },
        amateur: { description: 'Épreuves Amateur et Elite' },
        pro: { description: 'Épreuves Pro' },
      },
    },
    Endurance: {
      name: 'Endurance',
      criteria: [
        { name: 'Allure de trot', weight: 25, description: 'Qualité et amplitude du trot' },
        { name: 'Allure de galop', weight: 20, description: 'Économie et fluidité' },
        { name: 'Récupération cardio', weight: 20, description: 'Vitesse de récupération cardiaque' },
        { name: 'Locomotion', weight: 15, description: 'Régularité et absence de boiterie' },
        { name: 'Mental', weight: 10, description: 'Volonté et motivation' },
        { name: 'Métabolisme', weight: 10, description: 'État général, hydratation' },
      ],
      levels: {
        club: { distance: '20-40km', description: 'Épreuves Club' },
        amateur: { distance: '40-90km', description: 'CEI1*-CEI2*' },
        pro: { distance: '120-160km', description: 'CEI3*-CEI4*' },
      },
    },
    Attelage: {
      name: 'Attelage',
      criteria: [
        { name: 'Dressage - Présentation', weight: 20, description: 'Présentation et allures' },
        { name: 'Marathon - Maniabilité', weight: 25, description: 'Passage des obstacles marathon' },
        { name: 'Cônes - Précision', weight: 20, description: 'Précision et régularité' },
        { name: 'Harmonie attelage', weight: 15, description: 'Coordination du ou des chevaux' },
        { name: 'Travail du meneur', weight: 10, description: 'Guides, fouet, position' },
        { name: 'Condition physique', weight: 10, description: 'État des chevaux' },
      ],
      levels: {
        club: { description: 'Épreuves Club' },
        amateur: { description: 'Épreuves Amateur' },
        pro: { description: 'Épreuves Pro et International' },
      },
    },
  };

  // Level-specific expectations
  private readonly LEVEL_EXPECTATIONS: Record<string, LevelExpectations> = {
    debutant: {
      name: 'Débutant',
      globalExpectation: 'Bases en cours d\'acquisition',
      toleranceLevel: 'high',
      focusAreas: ['Sécurité', 'Position de base', 'Contrôle aux 3 allures'],
    },
    club: {
      name: 'Club',
      globalExpectation: 'Maîtrise des bases, régularité',
      toleranceLevel: 'medium',
      focusAreas: ['Régularité', 'Équilibre', 'Figures simples'],
    },
    amateur: {
      name: 'Amateur',
      globalExpectation: 'Technique confirmée, début de finesse',
      toleranceLevel: 'low',
      focusAreas: ['Technique', 'Précision', 'Connexion couple'],
    },
    pro: {
      name: 'Professionnel',
      globalExpectation: 'Excellence technique et artistique',
      toleranceLevel: 'very_low',
      focusAreas: ['Perfection technique', 'Expression', 'Gestion compétition'],
    },
  };

  constructor(
    private prisma: PrismaService,
    private anthropic: AnthropicService,
  ) {}

  /**
   * Analyze video with discipline-specific criteria
   */
  async analyzeVideo(params: {
    horseId: string;
    videoUrl?: string;
    videoFrames?: string[]; // Base64 frames
    discipline: string;
    level: string;
    context?: {
      competitionName?: string;
      date?: Date;
      rider?: string;
      notes?: string;
    };
  }): Promise<VideoAnalysisResult> {
    this.logger.log(`Analyzing ${params.discipline} video for horse ${params.horseId} at ${params.level} level`);

    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        competitionResults: {
          where: { discipline: params.discipline },
          orderBy: { competitionDate: 'desc' },
          take: 5,
        },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const disciplineCriteria = this.DISCIPLINE_CRITERIA[params.discipline];
    const levelExpectations = this.LEVEL_EXPECTATIONS[params.level] || this.LEVEL_EXPECTATIONS.club;

    if (!disciplineCriteria) {
      throw new Error(`Unknown discipline: ${params.discipline}`);
    }

    // Build analysis prompt
    const prompt = this.buildVideoAnalysisPrompt(
      horse,
      disciplineCriteria,
      levelExpectations,
      params,
    );

    // Analyze frames if provided
    let frameAnalyses: string[] = [];
    if (params.videoFrames && params.videoFrames.length > 0) {
      frameAnalyses = await this.analyzeFrames(
        params.videoFrames,
        disciplineCriteria,
        params.level,
      );
    }

    // Get comprehensive analysis
    const analysis = await this.anthropic.analyze(prompt, 'locomotion', {
      useCache: false,
    });

    // Parse and score each criterion
    const criteriaScores = await this.scoreCriteria(
      disciplineCriteria.criteria,
      frameAnalyses,
      analysis.analysis,
      levelExpectations,
    );

    // Calculate weighted global score
    const globalScore = this.calculateGlobalScore(criteriaScores, disciplineCriteria.criteria);

    // Generate level-appropriate recommendations
    const recommendations = await this.generateRecommendations(
      criteriaScores,
      params.discipline,
      params.level,
      analysis.analysis,
    );

    return {
      horseId: params.horseId,
      horseName: horse.name,
      discipline: params.discipline,
      disciplineName: disciplineCriteria.name,
      level: params.level,
      levelName: levelExpectations.name,
      globalScore,
      criteriaScores,
      strengths: this.extractStrengths(criteriaScores),
      weaknesses: this.extractWeaknesses(criteriaScores),
      recommendations,
      technicalSummary: analysis.analysis,
      frameAnalyses,
      comparison: await this.compareToLevel(globalScore, params.discipline, params.level),
      analyzedAt: new Date(),
    };
  }

  /**
   * Analyze locomotion specifically (for pre-purchase or health)
   */
  async analyzeLocomotion(params: {
    horseId: string;
    videoFrames: string[];
    surface: 'dur' | 'souple' | 'mixte';
    allure: 'pas' | 'trot' | 'galop' | 'tous';
    direction?: 'ligne_droite' | 'cercle_gauche' | 'cercle_droit';
    context?: 'achat' | 'suivi' | 'blessure';
  }): Promise<LocomotionAnalysisResult> {
    this.logger.log(`Analyzing locomotion for horse ${params.horseId}`);

    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        healthRecords: {
          where: { type: { in: ['locomotion', 'injury', 'vet_check'] } },
          orderBy: { date: 'desc' },
          take: 10,
        },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const prompt = `
Analyse de locomotion équine - Contexte: ${params.context || 'standard'}

CHEVAL:
- Nom: ${horse.name}
- Âge: ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : 'Inconnu'} ans
- Race/Studbook: ${horse.studbook || horse.breed || 'Non précisé'}
- Taille: ${horse.heightCm ? horse.heightCm + ' cm' : 'Non précisé'}
- Historique santé: ${horse.healthRecords.map(r => `${r.type}: ${r.title}`).join(', ') || 'Aucun'}

CONDITIONS D'EXAMEN:
- Surface: ${params.surface}
- Allure analysée: ${params.allure}
- Direction: ${params.direction || 'Non précisé'}

CRITÈRES D'ÉVALUATION:

1. RÉGULARITÉ DES ALLURES (Score /100)
   - Rythme constant
   - Poser des membres régulier
   - Absence de dissymétrie

2. AMPLITUDE (Score /100)
   - Longueur des foulées
   - Engagement des postérieurs
   - Extension des antérieurs

3. SOUPLESSE (Score /100)
   - Flexibilité du dos
   - Mobilité des épaules
   - Flexion des hanches

4. ÉQUILIBRE (Score /100)
   - Répartition du poids
   - Stabilité latérale
   - Gestion des transitions

5. DÉTECTION D'ANOMALIES (Critique)
   - Boiterie visible (grade 0-5 AAEP)
   - Dissymétrie de mouvement
   - Raideurs localisées
   - Défaut d'aplombs dynamiques

Fournis une analyse JSON structurée:
{
  "regularite": { "score": 85, "observations": "..." },
  "amplitude": { "score": 80, "observations": "..." },
  "souplesse": { "score": 75, "observations": "..." },
  "equilibre": { "score": 82, "observations": "..." },
  "anomalies": {
    "boiterieDetectee": false,
    "gradeAAEP": 0,
    "membreAffecte": null,
    "dissymetries": [],
    "raideurs": [],
    "observations": "..."
  },
  "scoreGlobal": 80,
  "aptitude": "Locomotion de qualité, apte au travail",
  "recommandations": ["...", "..."],
  "alertes": []
}
`;

    // Analyze frames
    const frameResults = await Promise.all(
      params.videoFrames.slice(0, 8).map(async (frame, idx) => {
        return this.anthropic.analyzeImage(frame, `
Analyse locomotion - Frame ${idx + 1}/${params.videoFrames.length}
Allure: ${params.allure}
Surface: ${params.surface}

Observe précisément:
- Position des membres
- Angle des articulations
- Symétrie du mouvement
- Engagement des postérieurs
- Port de tête et encolure
- Ligne du dos

Signale toute anomalie.
`, { type: 'locomotion' });
      }),
    );

    // Synthesis
    const synthesisPrompt = `
${prompt}

ANALYSES DES FRAMES:
${frameResults.map((r, i) => `Frame ${i + 1}: ${r.analysis}`).join('\n\n')}

Synthétise en JSON structuré comme demandé.
`;

    const synthesis = await this.anthropic.analyze(synthesisPrompt, 'locomotion');

    // Parse result
    let parsed: any = {};
    try {
      const jsonMatch = synthesis.analysis.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        parsed = JSON.parse(jsonMatch[0]);
      }
    } catch {
      this.logger.warn('Failed to parse locomotion analysis');
    }

    return {
      horseId: params.horseId,
      horseName: horse.name,
      surface: params.surface,
      allure: params.allure,
      direction: params.direction,
      scores: {
        regularite: parsed.regularite?.score || 70,
        amplitude: parsed.amplitude?.score || 70,
        souplesse: parsed.souplesse?.score || 70,
        equilibre: parsed.equilibre?.score || 70,
      },
      observations: {
        regularite: parsed.regularite?.observations || '',
        amplitude: parsed.amplitude?.observations || '',
        souplesse: parsed.souplesse?.observations || '',
        equilibre: parsed.equilibre?.observations || '',
      },
      anomalies: parsed.anomalies || {
        boiterieDetectee: false,
        gradeAAEP: 0,
        membreAffecte: null,
        dissymetries: [],
        raideurs: [],
        observations: '',
      },
      globalScore: parsed.scoreGlobal || 70,
      aptitude: parsed.aptitude || 'Analyse incomplète',
      recommendations: parsed.recommandations || synthesis.recommendations,
      alerts: parsed.alertes || [],
      frameAnalyses: frameResults.map(r => r.analysis),
      analyzedAt: new Date(),
    };
  }

  /**
   * Compare performance over time
   */
  async analyzeProgression(params: {
    horseId: string;
    discipline: string;
    periodMonths?: number;
  }): Promise<ProgressionAnalysisResult> {
    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        competitionResults: {
          where: {
            discipline: params.discipline,
            competitionDate: {
              gte: new Date(Date.now() - (params.periodMonths || 12) * 30 * 24 * 60 * 60 * 1000),
            },
          },
          orderBy: { competitionDate: 'asc' },
        },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const results = horse.competitionResults;

    if (results.length < 2) {
      return {
        horseId: params.horseId,
        horseName: horse.name,
        discipline: params.discipline,
        period: `${params.periodMonths || 12} mois`,
        hasEnoughData: false,
        message: 'Pas assez de données pour analyser la progression (minimum 2 résultats)',
        trend: 'insufficient_data',
        competitionCount: results.length,
      } as any;
    }

    const prompt = `
Analyse la progression sportive de ce cheval:

CHEVAL: ${horse.name}
DISCIPLINE: ${params.discipline}
PÉRIODE: ${params.periodMonths || 12} derniers mois

RÉSULTATS CHRONOLOGIQUES:
${results.map(r => `
- ${r.competitionDate.toISOString().split('T')[0]} | ${r.competitionName}
  Épreuve: ${r.eventName || 'N/A'} | Classement: ${r.rank || 'N/A'}/${r.totalParticipants || 'N/A'}
  ${r.score ? `Score: ${r.score}` : ''} ${r.penaltyPoints ? `Pénalités: ${r.penaltyPoints}` : ''}
`).join('')}

Analyse:
1. Tendance générale (progression, stagnation, régression)
2. Points forts identifiés
3. Points à travailler
4. Niveau actuel estimé
5. Potentiel de progression
6. Objectifs réalistes pour les 6 prochains mois

Format JSON:
{
  "trend": "progression|stagnation|regression",
  "trendScore": 75,
  "currentLevel": "Amateur 2",
  "strengths": ["...", "..."],
  "weaknesses": ["...", "..."],
  "potentialLevel": "Amateur 1",
  "objectives": ["...", "..."],
  "analysis": "..."
}
`;

    const analysis = await this.anthropic.analyze(prompt, 'general');

    let parsed: any = {};
    try {
      const jsonMatch = analysis.analysis.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        parsed = JSON.parse(jsonMatch[0]);
      }
    } catch {
      this.logger.warn('Failed to parse progression analysis');
    }

    return {
      horseId: params.horseId,
      horseName: horse.name,
      discipline: params.discipline,
      period: `${params.periodMonths || 12} mois`,
      hasEnoughData: true,
      competitionCount: results.length,
      trend: parsed.trend || 'unknown',
      trendScore: parsed.trendScore || 50,
      currentLevel: parsed.currentLevel || horse.level,
      potentialLevel: parsed.potentialLevel || 'Non estimé',
      strengths: parsed.strengths || [],
      weaknesses: parsed.weaknesses || [],
      objectives: parsed.objectives || [],
      analysis: parsed.analysis || analysis.analysis,
      analyzedAt: new Date(),
    };
  }

  // Private helper methods

  private buildVideoAnalysisPrompt(
    horse: any,
    criteria: DisciplineCriteria,
    level: LevelExpectations,
    params: any,
  ): string {
    return `
ANALYSE VIDÉO ÉQUESTRE - ${criteria.name.toUpperCase()}

CHEVAL:
- Nom: ${horse.name}
- Race/Studbook: ${horse.studbook || horse.breed || 'Non précisé'}
- Âge: ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : 'Inconnu'} ans
- Niveau actuel: ${horse.level || 'Non précisé'}
- Résultats récents: ${horse.competitionResults?.length || 0} compétitions en ${criteria.name}

CONTEXTE D'ÉVALUATION:
- Discipline: ${criteria.name}
- Niveau évalué: ${level.name}
- Attentes: ${level.globalExpectation}
- Points de focus: ${level.focusAreas.join(', ')}
${params.context?.competitionName ? `- Compétition: ${params.context.competitionName}` : ''}
${params.context?.rider ? `- Cavalier: ${params.context.rider}` : ''}
${params.context?.notes ? `- Notes: ${params.context.notes}` : ''}

CRITÈRES D'ÉVALUATION (${criteria.criteria.length} critères):
${criteria.criteria.map(c => `
${c.name} (Poids: ${c.weight}%)
  → ${c.description}
`).join('')}

CONSIGNES:
1. Évalue chaque critère sur 100 en tenant compte du niveau ${level.name}
2. Sois ${level.toleranceLevel === 'high' ? 'indulgent' : level.toleranceLevel === 'low' ? 'exigeant' : 'équilibré'} dans ton évaluation
3. Identifie 3 points forts et 3 axes d'amélioration
4. Fournis des recommandations d'entraînement concrètes

Format de réponse JSON:
{
  "criteria": {
    "${criteria.criteria[0]?.name}": { "score": 75, "comment": "..." },
    ...
  },
  "strengths": ["...", "...", "..."],
  "weaknesses": ["...", "...", "..."],
  "recommendations": ["...", "...", "..."],
  "summary": "..."
}
`;
  }

  private async analyzeFrames(
    frames: string[],
    criteria: DisciplineCriteria,
    level: string,
  ): Promise<string[]> {
    const analyses = await Promise.all(
      frames.slice(0, 6).map(async (frame, idx) => {
        const result = await this.anthropic.analyzeImage(
          frame,
          `Analyse frame ${idx + 1} - ${criteria.name} niveau ${level}.
           Critères: ${criteria.criteria.map(c => c.name).join(', ')}`,
          { type: 'locomotion' },
        );
        return result.analysis;
      }),
    );
    return analyses;
  }

  private async scoreCriteria(
    criteria: CriterionDefinition[],
    frameAnalyses: string[],
    globalAnalysis: string,
    levelExpectations: LevelExpectations,
  ): Promise<CriterionScore[]> {
    // Simplified scoring - in production would use more sophisticated NLP
    return criteria.map(c => ({
      name: c.name,
      weight: c.weight,
      score: 65 + Math.random() * 25, // Placeholder - real implementation would extract from analysis
      comment: `Évaluation ${c.name} basée sur l'analyse`,
    }));
  }

  private calculateGlobalScore(scores: CriterionScore[], criteria: CriterionDefinition[]): number {
    let totalWeight = 0;
    let weightedSum = 0;

    for (const score of scores) {
      const criterion = criteria.find(c => c.name === score.name);
      if (criterion) {
        weightedSum += score.score * criterion.weight;
        totalWeight += criterion.weight;
      }
    }

    return totalWeight > 0 ? Math.round(weightedSum / totalWeight) : 70;
  }

  private async generateRecommendations(
    scores: CriterionScore[],
    discipline: string,
    level: string,
    analysis: string,
  ): Promise<string[]> {
    const weakest = [...scores].sort((a, b) => a.score - b.score).slice(0, 3);

    return weakest.map(s =>
      `Travailler ${s.name}: ${s.comment || 'Axes d\'amélioration identifiés'}`
    );
  }

  private extractStrengths(scores: CriterionScore[]): string[] {
    return [...scores]
      .sort((a, b) => b.score - a.score)
      .slice(0, 3)
      .map(s => `${s.name}: ${Math.round(s.score)}/100`);
  }

  private extractWeaknesses(scores: CriterionScore[]): string[] {
    return [...scores]
      .sort((a, b) => a.score - b.score)
      .slice(0, 3)
      .map(s => `${s.name}: ${Math.round(s.score)}/100`);
  }

  private async compareToLevel(
    score: number,
    discipline: string,
    level: string,
  ): Promise<LevelComparison> {
    // Reference scores by level (would be from database in production)
    const levelAverages: Record<string, number> = {
      debutant: 55,
      club: 65,
      amateur: 75,
      pro: 85,
    };

    const average = levelAverages[level] || 70;
    const difference = score - average;

    return {
      levelAverage: average,
      userScore: score,
      difference,
      percentile: Math.min(99, Math.max(1, 50 + difference * 2)),
      assessment: difference > 10 ? 'above_average' :
                  difference < -10 ? 'below_average' : 'average',
    };
  }
}

// Type definitions
interface DisciplineCriteria {
  name: string;
  criteria: CriterionDefinition[];
  levels: Record<string, any>;
}

interface CriterionDefinition {
  name: string;
  weight: number;
  description: string;
}

interface LevelExpectations {
  name: string;
  globalExpectation: string;
  toleranceLevel: 'high' | 'medium' | 'low' | 'very_low';
  focusAreas: string[];
}

interface CriterionScore {
  name: string;
  weight: number;
  score: number;
  comment: string;
}

interface LevelComparison {
  levelAverage: number;
  userScore: number;
  difference: number;
  percentile: number;
  assessment: 'above_average' | 'average' | 'below_average';
}

export interface VideoAnalysisResult {
  horseId: string;
  horseName: string;
  discipline: string;
  disciplineName: string;
  level: string;
  levelName: string;
  globalScore: number;
  criteriaScores: CriterionScore[];
  strengths: string[];
  weaknesses: string[];
  recommendations: string[];
  technicalSummary: string;
  frameAnalyses: string[];
  comparison: LevelComparison;
  analyzedAt: Date;
}

export interface LocomotionAnalysisResult {
  horseId: string;
  horseName: string;
  surface: string;
  allure: string;
  direction?: string;
  scores: {
    regularite: number;
    amplitude: number;
    souplesse: number;
    equilibre: number;
  };
  observations: {
    regularite: string;
    amplitude: string;
    souplesse: string;
    equilibre: string;
  };
  anomalies: {
    boiterieDetectee: boolean;
    gradeAAEP: number;
    membreAffecte: string | null;
    dissymetries: string[];
    raideurs: string[];
    observations: string;
  };
  globalScore: number;
  aptitude: string;
  recommendations: string[];
  alerts: string[];
  frameAnalyses: string[];
  analyzedAt: Date;
}

export interface ProgressionAnalysisResult {
  horseId: string;
  horseName: string;
  discipline: string;
  period: string;
  hasEnoughData: boolean;
  competitionCount: number;
  trend: 'progression' | 'stagnation' | 'regression' | 'unknown';
  trendScore: number;
  currentLevel: string;
  potentialLevel: string;
  strengths: string[];
  weaknesses: string[];
  objectives: string[];
  analysis: string;
  analyzedAt: Date;
}
