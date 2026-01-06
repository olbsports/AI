import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnthropicService } from './anthropic.service';

/**
 * Automatic Detection Service
 *
 * AI-powered automatic detection for:
 * - Dressage figures recognition
 * - Fatigue and stress detection
 * - Behavior analysis (ears, tail, expression)
 * - Jump analysis (CSO)
 * - Gait recognition
 * - Bar/fault counting
 */
@Injectable()
export class AutoDetectionService {
  private readonly logger = new Logger(AutoDetectionService.name);

  // ==================== DRESSAGE FIGURES ====================
  private readonly DRESSAGE_FIGURES: Record<string, DressageFigure> = {
    // Figures de base
    cercle_20m: {
      id: 'cercle_20m',
      name: 'Cercle 20m',
      level: 'club',
      description: 'Cercle de 20 mètres de diamètre',
      criteria: ['Rondeur', 'Régularité', 'Incurvation'],
      difficulty: 1,
    },
    cercle_15m: {
      id: 'cercle_15m',
      name: 'Cercle 15m',
      level: 'club',
      description: 'Cercle de 15 mètres de diamètre',
      criteria: ['Rondeur', 'Équilibre', 'Incurvation'],
      difficulty: 2,
    },
    cercle_10m: {
      id: 'cercle_10m',
      name: 'Cercle 10m',
      level: 'amateur',
      description: 'Cercle de 10 mètres de diamètre',
      criteria: ['Rassembler', 'Équilibre', 'Cadence'],
      difficulty: 3,
    },
    volte_8m: {
      id: 'volte_8m',
      name: 'Volte 8m',
      level: 'amateur',
      description: 'Volte de 8 mètres',
      criteria: ['Rassembler', 'Flexion', 'Régularité'],
      difficulty: 4,
    },
    volte_6m: {
      id: 'volte_6m',
      name: 'Volte 6m',
      level: 'pro',
      description: 'Volte de 6 mètres (pirouette préparatoire)',
      criteria: ['Rassembler profond', 'Équilibre', 'Cadence'],
      difficulty: 5,
    },

    // Lignes et diagonales
    diagonale: {
      id: 'diagonale',
      name: 'Diagonale',
      level: 'club',
      description: 'Traversée en diagonale de la carrière',
      criteria: ['Rectitude', 'Impulsion', 'Régularité'],
      difficulty: 1,
    },
    doubler: {
      id: 'doubler',
      name: 'Doubler dans la longueur',
      level: 'club',
      description: 'Quitter la piste pour aller sur la ligne du milieu',
      criteria: ['Rectitude', 'Équilibre', 'Transition'],
      difficulty: 2,
    },

    // Changements de direction
    demi_volte: {
      id: 'demi_volte',
      name: 'Demi-volte',
      level: 'club',
      description: 'Demi-cercle avec retour en oblique',
      criteria: ['Incurvation', 'Changement de pli', 'Fluidité'],
      difficulty: 2,
    },
    serpentine_3: {
      id: 'serpentine_3',
      name: 'Serpentine 3 boucles',
      level: 'club',
      description: 'Serpentine à 3 boucles',
      criteria: ['Changements de pli', 'Symétrie', 'Régularité'],
      difficulty: 2,
    },
    serpentine_4: {
      id: 'serpentine_4',
      name: 'Serpentine 4 boucles',
      level: 'amateur',
      description: 'Serpentine à 4 boucles',
      criteria: ['Souplesse', 'Équilibre', 'Changements'],
      difficulty: 3,
    },
    huit_de_chiffre: {
      id: 'huit_de_chiffre',
      name: 'Huit de chiffre',
      level: 'amateur',
      description: 'Deux cercles tangents formant un 8',
      criteria: ['Changement de pli', 'Symétrie', 'Cadence'],
      difficulty: 3,
    },

    // Déplacements latéraux
    epaule_en_dedans: {
      id: 'epaule_en_dedans',
      name: 'Épaule en dedans',
      level: 'amateur',
      description: "Déplacement latéral épaules vers l'intérieur",
      criteria: ['Angle 30°', 'Croisement', 'Cadence', 'Flexion'],
      difficulty: 4,
    },
    hanche_en_dedans: {
      id: 'hanche_en_dedans',
      name: 'Hanche en dedans (travers)',
      level: 'amateur',
      description: "Hanches vers l'intérieur de la piste",
      criteria: ['Angle', 'Engagement', 'Flexion'],
      difficulty: 4,
    },
    appuyer: {
      id: 'appuyer',
      name: 'Appuyer',
      level: 'amateur',
      description: 'Déplacement latéral en diagonale',
      criteria: ['Croisement', 'Parallélisme', 'Cadence', 'Expression'],
      difficulty: 5,
    },
    cession_jambe: {
      id: 'cession_jambe',
      name: 'Cession à la jambe',
      level: 'club',
      description: 'Déplacement latéral de base',
      criteria: ['Croisement', 'Régularité', 'Réponse aux aides'],
      difficulty: 3,
    },

    // Transitions et allures
    arret: {
      id: 'arret',
      name: 'Arrêt',
      level: 'club',
      description: 'Arrêt immobile et carré',
      criteria: ['Carrure', 'Immobilité', 'Engagement'],
      difficulty: 2,
    },
    reculer: {
      id: 'reculer',
      name: 'Reculer',
      level: 'club',
      description: 'Reculer en diagonalisation',
      criteria: ['Rectitude', 'Légèreté', 'Diagonalisation'],
      difficulty: 3,
    },
    allongement_trot: {
      id: 'allongement_trot',
      name: 'Allongement au trot',
      level: 'club',
      description: 'Extension des foulées au trot',
      criteria: ['Amplitude', 'Équilibre', 'Régularité'],
      difficulty: 3,
    },
    trot_moyen: {
      id: 'trot_moyen',
      name: 'Trot moyen',
      level: 'amateur',
      description: 'Trot avec amplitude modérée',
      criteria: ['Cadence', 'Engagement', 'Expression'],
      difficulty: 3,
    },
    trot_allonge: {
      id: 'trot_allonge',
      name: 'Trot allongé',
      level: 'amateur',
      description: "Trot avec maximum d'amplitude",
      criteria: ['Extension maximale', 'Équilibre', 'Suspension'],
      difficulty: 4,
    },
    trot_rassemble: {
      id: 'trot_rassemble',
      name: 'Trot rassemblé',
      level: 'pro',
      description: 'Trot avec engagement maximum des postérieurs',
      criteria: ['Abaissement hanches', 'Cadence élevée', 'Légèreté'],
      difficulty: 5,
    },
    galop_rassemble: {
      id: 'galop_rassemble',
      name: 'Galop rassemblé',
      level: 'pro',
      description: 'Galop avec rassembler',
      criteria: ['Abaissement', 'Rebond', 'Légèreté'],
      difficulty: 5,
    },

    // Changements de pied
    changement_pied_simple: {
      id: 'changement_pied_simple',
      name: 'Changement de pied simple',
      level: 'amateur',
      description: 'Changement par le trot ou le pas',
      criteria: ['Fluidité', 'Équilibre', 'Calme'],
      difficulty: 3,
    },
    changement_pied_isole: {
      id: 'changement_pied_isole',
      name: "Changement de pied en l'air",
      level: 'amateur',
      description: 'Changement de pied au temps',
      criteria: ['Rectitude', 'Expression', 'Temps de suspension'],
      difficulty: 5,
    },
    changements_4_temps: {
      id: 'changements_4_temps',
      name: 'Changements aux 4 temps',
      level: 'pro',
      description: 'Changements de pied toutes les 4 foulées',
      criteria: ['Régularité', 'Rectitude', 'Expression'],
      difficulty: 6,
    },
    changements_3_temps: {
      id: 'changements_3_temps',
      name: 'Changements aux 3 temps',
      level: 'pro',
      description: 'Changements de pied toutes les 3 foulées',
      criteria: ['Régularité', 'Équilibre', 'Expression'],
      difficulty: 7,
    },
    changements_2_temps: {
      id: 'changements_2_temps',
      name: 'Changements aux 2 temps',
      level: 'pro',
      description: 'Changements de pied toutes les 2 foulées',
      criteria: ['Régularité parfaite', 'Légèreté', 'Expression'],
      difficulty: 8,
    },
    changements_1_temps: {
      id: 'changements_1_temps',
      name: 'Changements au temps (1 temps)',
      level: 'pro',
      description: 'Changements de pied à chaque foulée',
      criteria: ['Perfection', 'Légèreté', 'Élasticité'],
      difficulty: 9,
    },

    // Figures haute école
    pirouette_pas: {
      id: 'pirouette_pas',
      name: 'Pirouette au pas',
      level: 'amateur',
      description: 'Tour sur les hanches au pas',
      criteria: ['Pivot', 'Régularité', 'Équilibre'],
      difficulty: 4,
    },
    pirouette_galop: {
      id: 'pirouette_galop',
      name: 'Pirouette au galop',
      level: 'pro',
      description: 'Tour sur les hanches au galop',
      criteria: ['Rassembler', 'Rebond', 'Taille', 'Sortie'],
      difficulty: 8,
    },
    passage: {
      id: 'passage',
      name: 'Passage',
      level: 'pro',
      description: 'Trot très relevé avec temps de suspension marqué',
      criteria: ['Élévation', 'Cadence', 'Majesté', 'Régularité'],
      difficulty: 9,
    },
    piaffer: {
      id: 'piaffer',
      name: 'Piaffer',
      level: 'pro',
      description: 'Trot sur place avec élévation',
      criteria: ['Sur place', 'Élévation', 'Cadence', 'Légèreté'],
      difficulty: 10,
    },
    transition_passage_piaffer: {
      id: 'transition_passage_piaffer',
      name: 'Transition passage-piaffer',
      level: 'pro',
      description: 'Transition fluide entre passage et piaffer',
      criteria: ['Fluidité', 'Maintien cadence', 'Expression'],
      difficulty: 10,
    },
  };

  // ==================== FATIGUE INDICATORS ====================
  private readonly FATIGUE_INDICATORS = {
    physical: [
      {
        sign: 'Respiration accélérée persistante',
        severity: 'moderate',
        action: 'Pause récupération',
      },
      {
        sign: 'Transpiration excessive',
        severity: 'moderate',
        action: 'Hydrater, réduire intensité',
      },
      { sign: "Baisse de l'impulsion", severity: 'light', action: 'Fin de séance proche' },
      { sign: 'Trébuchements répétés', severity: 'high', action: 'Arrêt immédiat' },
      { sign: 'Raccourcissement des foulées', severity: 'moderate', action: 'Pause ou fin séance' },
      {
        sign: "Difficulté à maintenir l'allure",
        severity: 'moderate',
        action: 'Réduire les demandes',
      },
      { sign: 'Mousse blanche (sueur)', severity: 'high', action: 'Arrêt, refroidissement' },
    ],
    mental: [
      {
        sign: 'Oreilles constamment en arrière',
        severity: 'moderate',
        action: "Changer d'exercice",
      },
      { sign: 'Queue qui fouaille', severity: 'light', action: 'Simplifier les demandes' },
      { sign: 'Résistances inhabituelles', severity: 'moderate', action: 'Pause mentale' },
      { sign: 'Perte de concentration', severity: 'light', action: 'Varier le travail' },
      { sign: 'Anticipation négative', severity: 'moderate', action: 'Exercices positifs' },
      { sign: 'Refus répétés', severity: 'high', action: 'Fin de séance, analyser cause' },
    ],
  };

  // ==================== BEHAVIOR INDICATORS ====================
  private readonly BEHAVIOR_INDICATORS = {
    ears: {
      forward: { meaning: 'Attentif, intéressé', mood: 'positive' },
      pricked: { meaning: 'Alerte, curieux', mood: 'positive' },
      relaxed_sideways: { meaning: "Détendu, à l'écoute", mood: 'positive' },
      pinned_back: { meaning: 'Agacé, inconfortable', mood: 'negative' },
      one_back: { meaning: 'Écoute du cavalier', mood: 'neutral' },
      rotating: { meaning: 'Nerveux, incertain', mood: 'cautious' },
    },
    tail: {
      relaxed_swing: { meaning: 'Détendu, décontracté', mood: 'positive' },
      raised: { meaning: 'Excité, en alerte', mood: 'cautious' },
      clamped: { meaning: 'Tendu, peur', mood: 'negative' },
      swishing: { meaning: 'Irrité, agacé', mood: 'negative' },
      wringing: { meaning: 'Très inconfortable', mood: 'negative' },
    },
    head: {
      lowered_relaxed: { meaning: 'Détendu, confiant', mood: 'positive' },
      high_alert: { meaning: 'En alerte, tension', mood: 'cautious' },
      tilted: { meaning: 'Résistance mors/main', mood: 'negative' },
      shaking: { meaning: 'Irritation, inconfort', mood: 'negative' },
      behind_vertical: { meaning: 'Sur-encadrement', mood: 'cautious' },
      above_bit: { meaning: 'Fuite du contact', mood: 'negative' },
    },
    mouth: {
      soft_chewing: { meaning: 'Décontraction mâchoire', mood: 'positive' },
      open_mouth: { meaning: 'Résistance, inconfort', mood: 'negative' },
      tongue_out: { meaning: 'Stress, problème mors', mood: 'negative' },
      grinding: { meaning: 'Tension', mood: 'negative' },
    },
  };

  constructor(
    private prisma: PrismaService,
    private anthropic: AnthropicService
  ) {}

  // ==================== DRESSAGE FIGURE DETECTION ====================

  /**
   * Detect dressage figures from video frames
   */
  async detectDressageFigures(params: {
    horseId: string;
    videoFrames: string[];
    arenaSize: '20x40' | '20x60';
    expectedLevel?: string;
  }): Promise<DressageFigureDetectionResult> {
    this.logger.log(`Detecting dressage figures for horse ${params.horseId}`);

    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const level = params.expectedLevel || horse.level || 'club';
    const relevantFigures = Object.values(this.DRESSAGE_FIGURES).filter((f) =>
      this.isLevelAppropriate(f.level, level)
    );

    // Analyze video frames
    const frameAnalyses = await Promise.all(
      params.videoFrames.map(async (frame, idx) => {
        const prompt = `
DÉTECTION AUTOMATIQUE DE FIGURES DE DRESSAGE

Image ${idx + 1}/${params.videoFrames.length}
Carrière: ${params.arenaSize}
Niveau attendu: ${level}

FIGURES À DÉTECTER:
${relevantFigures.map((f) => `- ${f.name}: ${f.description}`).join('\n')}

ANALYSE DEMANDÉE:
1. Position du cheval dans la carrière (lettre approximative)
2. Direction du mouvement
3. Allure actuelle (pas/trot/galop)
4. Figure en cours d'exécution (si identifiable)
5. Qualité d'exécution

Format JSON:
{
  "position": { "lettre": "C", "zone": "ligne_mediane" },
  "direction": "main_droite",
  "allure": "trot",
  "figureDetectee": {
    "id": "cercle_20m",
    "confidence": 85,
    "phase": "milieu"
  },
  "qualite": {
    "score": 7,
    "observations": ["Bonne incurvation", "Légère perte de cadence"]
  }
}
`;
        return this.anthropic.analyzeImage(frame, prompt, { type: 'locomotion' });
      })
    );

    // Parse and aggregate detections
    const detectedFigures = this.aggregateFigureDetections(frameAnalyses);

    // Score each detected figure
    const scoredFigures = await this.scoreFigures(detectedFigures, level);

    // Generate reprise summary
    const repriseSummary = this.generateRepriseSummary(scoredFigures);

    return {
      horseId: params.horseId,
      horseName: horse.name,
      arenaSize: params.arenaSize,
      level,
      figuresDetected: scoredFigures,
      totalFigures: scoredFigures.length,
      averageScore: this.calculateAverageScore(scoredFigures),
      repriseSummary,
      timeline: this.buildTimeline(frameAnalyses),
      recommendations: this.generateFigureRecommendations(scoredFigures),
      analyzedAt: new Date(),
    };
  }

  /**
   * Score a specific dressage figure
   */
  async scoreDressageFigure(params: {
    figureId: string;
    videoFrames: string[];
    horseLevel: string;
  }): Promise<FigureScoreResult> {
    const figure = this.DRESSAGE_FIGURES[params.figureId];
    if (!figure) {
      throw new Error(`Unknown figure: ${params.figureId}`);
    }

    const prompt = `
NOTATION DE FIGURE DE DRESSAGE

Figure: ${figure.name}
Description: ${figure.description}
Niveau cheval: ${params.horseLevel}
Difficulté figure: ${figure.difficulty}/10

CRITÈRES D'ÉVALUATION:
${figure.criteria.map((c, i) => `${i + 1}. ${c}`).join('\n')}

ÉCHELLE DE NOTATION (0-10):
10 = Excellent
9 = Très bien
8 = Bien
7 = Assez bien
6 = Satisfaisant
5 = Suffisant
4 = Insuffisant
3 = Assez mal
2 = Mal
1 = Très mal
0 = Non exécuté

Analyse chaque frame et fournis:
{
  "figureId": "${figure.id}",
  "figureName": "${figure.name}",
  "noteGlobale": 7.5,
  "notesCriteres": {
    "${figure.criteria[0]}": 8,
    ...
  },
  "coefficientDifficulte": ${figure.difficulty},
  "pointsForts": ["...", "..."],
  "pointsAmeliorer": ["...", "..."],
  "conseilsSpecifiques": ["...", "..."]
}
`;

    const result = await this.anthropic.analyze(prompt, 'locomotion');
    return this.parseJsonFromAnalysis(result.analysis);
  }

  // ==================== FATIGUE & STRESS DETECTION ====================

  /**
   * Detect fatigue and stress from video
   */
  async detectFatigueStress(params: {
    horseId: string;
    videoFrames: string[];
    sessionDuration: number; // minutes
    workIntensity: 'light' | 'moderate' | 'intense';
    sessionType: string;
  }): Promise<FatigueDetectionResult> {
    this.logger.log(`Detecting fatigue/stress for horse ${params.horseId}`);

    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        healthRecords: {
          where: { type: { in: ['fatigue', 'injury', 'training'] } },
          orderBy: { date: 'desc' },
          take: 5,
        },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    // Analyze frames for fatigue indicators
    const analyses = await Promise.all(
      params.videoFrames.map(async (frame, idx) => {
        const prompt = `
DÉTECTION FATIGUE ET STRESS ÉQUIN

Image ${idx + 1}/${params.videoFrames.length}
Durée séance: ${params.sessionDuration} min
Intensité: ${params.workIntensity}
Type: ${params.sessionType}

INDICATEURS DE FATIGUE PHYSIQUE:
${this.FATIGUE_INDICATORS.physical.map((i) => `- ${i.sign}`).join('\n')}

INDICATEURS DE FATIGUE MENTALE:
${this.FATIGUE_INDICATORS.mental.map((i) => `- ${i.sign}`).join('\n')}

ANALYSE DEMANDÉE:
1. État de la respiration (visible?)
2. Transpiration (niveau)
3. Qualité des allures
4. Position des oreilles
5. Comportement de la queue
6. Expression générale
7. Signes de tension musculaire

Format JSON:
{
  "frameIndex": ${idx},
  "fatiguePhysique": {
    "niveau": "faible|modéré|élevé|critique",
    "score": 25,
    "signesDetectes": ["...", "..."]
  },
  "fatigueMentale": {
    "niveau": "faible|modéré|élevé|critique",
    "score": 30,
    "signesDetectes": ["...", "..."]
  },
  "stress": {
    "niveau": "calme|léger|modéré|élevé",
    "score": 20,
    "indicateurs": ["...", "..."]
  },
  "recommandationImmediate": "continuer|pause|réduire|arrêter"
}
`;
        return this.anthropic.analyzeImage(frame, prompt, { type: 'general' });
      })
    );

    // Aggregate fatigue data
    const fatigueProgression = this.calculateFatigueProgression(analyses);
    const currentStatus = this.determineFatigueStatus(fatigueProgression);
    const recommendations = this.generateFatigueRecommendations(currentStatus, params);

    return {
      horseId: params.horseId,
      horseName: horse.name,
      sessionDuration: params.sessionDuration,
      workIntensity: params.workIntensity,
      fatiguePhysique: currentStatus.physical,
      fatigueMentale: currentStatus.mental,
      stressLevel: currentStatus.stress,
      overallFatigueScore: currentStatus.overall,
      progression: fatigueProgression,
      alertLevel: this.determineAlertLevel(currentStatus.overall),
      immediateAction: currentStatus.action,
      recommendations,
      recoveryEstimate: this.estimateRecovery(currentStatus.overall, params.workIntensity),
      nextSessionRecommendation: this.recommendNextSession(currentStatus),
      analyzedAt: new Date(),
    };
  }

  // ==================== BEHAVIOR ANALYSIS ====================

  /**
   * Analyze horse behavior from video
   */
  async analyzeBehavior(params: {
    horseId: string;
    videoFrames: string[];
    context: 'travail' | 'repos' | 'competition' | 'transport' | 'soins';
  }): Promise<BehaviorAnalysisResult> {
    this.logger.log(`Analyzing behavior for horse ${params.horseId}`);

    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const prompt = `
ANALYSE COMPORTEMENTALE ÉQUINE

Contexte: ${params.context}
Cheval: ${horse.name}

INDICATEURS À ANALYSER:

OREILLES:
${Object.entries(this.BEHAVIOR_INDICATORS.ears)
  .map(([k, v]) => `- ${k}: ${v.meaning}`)
  .join('\n')}

QUEUE:
${Object.entries(this.BEHAVIOR_INDICATORS.tail)
  .map(([k, v]) => `- ${k}: ${v.meaning}`)
  .join('\n')}

TÊTE:
${Object.entries(this.BEHAVIOR_INDICATORS.head)
  .map(([k, v]) => `- ${k}: ${v.meaning}`)
  .join('\n')}

BOUCHE:
${Object.entries(this.BEHAVIOR_INDICATORS.mouth)
  .map(([k, v]) => `- ${k}: ${v.meaning}`)
  .join('\n')}

AUTRES INDICATEURS:
- Tension musculaire visible
- Regard (fixe, mobile, fuyant)
- Position générale du corps
- Réactivité aux stimuli
- Interactions sociales (si visible)

Format JSON:
{
  "oreilles": { "position": "forward", "interpretation": "...", "mood": "positive" },
  "queue": { "position": "relaxed_swing", "interpretation": "...", "mood": "positive" },
  "tete": { "position": "...", "interpretation": "...", "mood": "..." },
  "bouche": { "etat": "...", "interpretation": "...", "mood": "..." },
  "corpsGeneral": { "tension": "faible|modérée|élevée", "observation": "..." },
  "moodGlobal": "positif|neutre|négatif|stressé",
  "scoreConfort": 80,
  "alertes": [],
  "recommandations": ["...", "..."]
}
`;

    const analyses = await Promise.all(
      params.videoFrames
        .slice(0, 5)
        .map((frame) => this.anthropic.analyzeImage(frame, prompt, { type: 'general' }))
    );

    const aggregated = this.aggregateBehaviorAnalysis(analyses);

    return {
      horseId: params.horseId,
      horseName: horse.name,
      context: params.context,
      behaviorIndicators: aggregated.indicators,
      overallMood: aggregated.mood,
      comfortScore: aggregated.comfortScore,
      alerts: aggregated.alerts,
      recommendations: aggregated.recommendations,
      detailedAnalysis: aggregated.details,
      analyzedAt: new Date(),
    };
  }

  // ==================== JUMP ANALYSIS (CSO) ====================

  /**
   * Analyze jumps from CSO video
   */
  async analyzeJumps(params: {
    horseId: string;
    videoFrames: string[];
    jumpHeight: number; // cm
    jumpType: 'vertical' | 'oxer' | 'spa' | 'riviere' | 'combine';
    context?: string;
  }): Promise<JumpAnalysisResult> {
    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const prompt = `
ANALYSE DE SAUT - CSO

Obstacle: ${params.jumpType} à ${params.jumpHeight}cm
Cheval: ${horse.name}
${params.context ? `Contexte: ${params.context}` : ''}

PHASES DU SAUT À ANALYSER:

1. APPROCHE (3-4 dernières foulées)
   - Régularité de la cadence
   - Équilibre
   - Regard du cheval
   - Impulsion

2. BATTUE (Point d'appel)
   - Distance par rapport à l'obstacle
   - Engagement des postérieurs
   - Angle de décollage

3. PLANER (Phase ascendante)
   - Bascule du dos
   - Technique des antérieurs (pliure, symétrie)
   - Montée des épaules
   - Garrot au-dessus de la barre

4. SOMMET
   - Style au-dessus de l'obstacle
   - Arrondi du dos
   - Position de la tête

5. DESCENTE
   - Technique des postérieurs
   - Dégagement des barres
   - Préparation de la réception

6. RÉCEPTION
   - Équilibre à l'atterrissage
   - Première foulée après
   - Rétablissement

Format JSON:
{
  "scoreGlobal": 78,
  "phases": {
    "approche": { "score": 80, "observations": ["..."], "corrections": ["..."] },
    "battue": { "score": 75, "distance": "correct|court|long", "observations": ["..."] },
    "planer": { "score": 82, "bascule": "bonne", "anterieurs": "symétriques", "observations": ["..."] },
    "sommet": { "score": 80, "style": "...", "observations": ["..."] },
    "descente": { "score": 78, "posterieurs": "...", "observations": ["..."] },
    "reception": { "score": 76, "equilibre": "...", "observations": ["..."] }
  },
  "faute": null,
  "pointsForts": ["Bonne bascule", "Antérieurs bien pliés"],
  "pointsAmeliorer": ["Distance de battue variable"],
  "exercicesCorrectifs": ["Barres de réglage", "Gymnastique en ligne"],
  "potentielHauteur": "130cm"
}
`;

    const analyses = await Promise.all(
      params.videoFrames.map((frame) =>
        this.anthropic.analyzeImage(frame, prompt, { type: 'locomotion' })
      )
    );

    const result = this.synthesizeJumpAnalysis(analyses, params);

    return {
      horseId: params.horseId,
      horseName: horse.name,
      jumpType: params.jumpType,
      jumpHeight: params.jumpHeight,
      ...result,
      analyzedAt: new Date(),
    };
  }

  /**
   * Count faults in a CSO round
   */
  async countFaults(params: {
    horseId: string;
    videoFrames: string[];
    courseInfo: {
      obstacles: number;
      timeAllowed: number;
    };
  }): Promise<FaultCountResult> {
    const prompt = `
COMPTAGE DES FAUTES - PARCOURS CSO

Parcours: ${params.courseInfo.obstacles} obstacles
Temps accordé: ${params.courseInfo.timeAllowed}s

TYPES DE FAUTES À DÉTECTER:
- Barre tombée (4 points)
- Refus (4 points, éliminatoire au 3ème)
- Dérobade (4 points)
- Chute (éliminatoire)
- Faute de temps (1 point par seconde)

ANALYSE:
Pour chaque obstacle visible, indique:
1. Numéro de l'obstacle (si identifiable)
2. Type d'obstacle
3. Résultat (franchi/barre/refus/dérobade)
4. Observations

Format JSON:
{
  "obstacles": [
    { "numero": 1, "type": "vertical", "resultat": "franchi", "observation": "..." },
    { "numero": 2, "type": "oxer", "resultat": "barre", "observation": "Barre de derrière" }
  ],
  "totalBarres": 1,
  "totalRefus": 0,
  "points": 4,
  "tempsEstime": null,
  "observations": ["..."]
}
`;

    const result = await this.anthropic.analyze(prompt, 'general');
    return this.parseJsonFromAnalysis(result.analysis);
  }

  // ==================== HELPER METHODS ====================

  private isLevelAppropriate(figureLevel: string, horseLevel: string): boolean {
    const levelOrder = ['club', 'amateur', 'pro'];
    return levelOrder.indexOf(figureLevel) <= levelOrder.indexOf(horseLevel);
  }

  private aggregateFigureDetections(analyses: any[]): any[] {
    const figures: any[] = [];
    for (const analysis of analyses) {
      try {
        const parsed = this.parseJsonFromAnalysis(analysis.analysis);
        if (parsed.figureDetectee?.id) {
          figures.push(parsed.figureDetectee);
        }
      } catch {}
    }
    return figures;
  }

  private async scoreFigures(detections: any[], level: string): Promise<ScoredFigure[]> {
    return detections.map((d) => ({
      figureId: d.id,
      figureName: this.DRESSAGE_FIGURES[d.id]?.name || d.id,
      score: d.confidence ? d.confidence / 10 : 7,
      phase: d.phase,
      observations: [],
    }));
  }

  private generateRepriseSummary(figures: ScoredFigure[]): string {
    if (figures.length === 0) return 'Aucune figure détectée';
    const avg = this.calculateAverageScore(figures);
    return `${figures.length} figures détectées, moyenne: ${avg.toFixed(1)}/10`;
  }

  private buildTimeline(analyses: any[]): TimelineEntry[] {
    return analyses.map((a, idx) => ({
      frameIndex: idx,
      timestamp: idx * 2, // Assuming 2 seconds per frame
      event: 'analysis',
      details: a.analysis?.substring(0, 100) || '',
    }));
  }

  private generateFigureRecommendations(figures: ScoredFigure[]): string[] {
    const weakFigures = figures.filter((f) => f.score < 6);
    return weakFigures.map((f) => `Travailler ${f.figureName}: score ${f.score}/10`);
  }

  private calculateAverageScore(figures: ScoredFigure[]): number {
    if (figures.length === 0) return 0;
    return figures.reduce((sum, f) => sum + f.score, 0) / figures.length;
  }

  private calculateFatigueProgression(analyses: any[]): FatigueProgressionPoint[] {
    return analyses.map((a, idx) => {
      const parsed = this.parseJsonFromAnalysis(a.analysis);
      return {
        frameIndex: idx,
        physicalScore: parsed.fatiguePhysique?.score || 0,
        mentalScore: parsed.fatigueMentale?.score || 0,
        stressScore: parsed.stress?.score || 0,
      };
    });
  }

  private determineFatigueStatus(progression: FatigueProgressionPoint[]): FatigueStatus {
    const last = progression[progression.length - 1] || {
      physicalScore: 0,
      mentalScore: 0,
      stressScore: 0,
    };
    const overall = (last.physicalScore + last.mentalScore + last.stressScore) / 3;

    return {
      physical: last.physicalScore,
      mental: last.mentalScore,
      stress: last.stressScore,
      overall,
      action:
        overall > 70 ? 'arrêter' : overall > 50 ? 'réduire' : overall > 30 ? 'pause' : 'continuer',
    };
  }

  private determineAlertLevel(score: number): 'green' | 'yellow' | 'orange' | 'red' {
    if (score < 25) return 'green';
    if (score < 50) return 'yellow';
    if (score < 75) return 'orange';
    return 'red';
  }

  private generateFatigueRecommendations(status: FatigueStatus, params: any): string[] {
    const recs: string[] = [];
    if (status.physical > 50) recs.push("Réduire l'intensité physique");
    if (status.mental > 50) recs.push("Varier les exercices pour maintenir l'attention");
    if (status.stress > 50) recs.push('Environnement plus calme recommandé');
    if (status.overall > 60) recs.push('Terminer la séance par un travail léger');
    return recs;
  }

  private estimateRecovery(fatigueScore: number, intensity: string): string {
    if (fatigueScore < 30) return '24h';
    if (fatigueScore < 50) return '24-48h';
    if (fatigueScore < 70) return '48h';
    return '48-72h';
  }

  private recommendNextSession(status: FatigueStatus): string {
    if (status.overall > 60) return 'Repos ou travail léger (pas)';
    if (status.overall > 40) return 'Travail modéré, éviter haute intensité';
    return 'Travail normal possible';
  }

  private aggregateBehaviorAnalysis(analyses: any[]): any {
    // Simplified aggregation
    return {
      indicators: {},
      mood: 'positif',
      comfortScore: 75,
      alerts: [],
      recommendations: [],
      details: analyses.map((a) => a.analysis).join('\n'),
    };
  }

  private synthesizeJumpAnalysis(analyses: any[], params: any): any {
    const firstParsed = this.parseJsonFromAnalysis(analyses[0]?.analysis || '{}');
    return {
      globalScore: firstParsed.scoreGlobal || 75,
      phases: firstParsed.phases || {},
      fault: firstParsed.faute,
      strengths: firstParsed.pointsForts || [],
      improvements: firstParsed.pointsAmeliorer || [],
      correctiveExercises: firstParsed.exercicesCorrectifs || [],
      heightPotential: firstParsed.potentielHauteur || 'Non évalué',
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

interface DressageFigure {
  id: string;
  name: string;
  level: string;
  description: string;
  criteria: string[];
  difficulty: number;
}

interface ScoredFigure {
  figureId: string;
  figureName: string;
  score: number;
  phase?: string;
  observations: string[];
}

interface TimelineEntry {
  frameIndex: number;
  timestamp: number;
  event: string;
  details: string;
}

interface FatigueProgressionPoint {
  frameIndex: number;
  physicalScore: number;
  mentalScore: number;
  stressScore: number;
}

interface FatigueStatus {
  physical: number;
  mental: number;
  stress: number;
  overall: number;
  action: string;
}

export interface DressageFigureDetectionResult {
  horseId: string;
  horseName: string;
  arenaSize: string;
  level: string;
  figuresDetected: ScoredFigure[];
  totalFigures: number;
  averageScore: number;
  repriseSummary: string;
  timeline: TimelineEntry[];
  recommendations: string[];
  analyzedAt: Date;
}

export interface FigureScoreResult {
  figureId: string;
  figureName: string;
  noteGlobale: number;
  notesCriteres: Record<string, number>;
  coefficientDifficulte: number;
  pointsForts: string[];
  pointsAmeliorer: string[];
  conseilsSpecifiques: string[];
}

export interface FatigueDetectionResult {
  horseId: string;
  horseName: string;
  sessionDuration: number;
  workIntensity: string;
  fatiguePhysique: number;
  fatigueMentale: number;
  stressLevel: number;
  overallFatigueScore: number;
  progression: FatigueProgressionPoint[];
  alertLevel: string;
  immediateAction: string;
  recommendations: string[];
  recoveryEstimate: string;
  nextSessionRecommendation: string;
  analyzedAt: Date;
}

export interface BehaviorAnalysisResult {
  horseId: string;
  horseName: string;
  context: string;
  behaviorIndicators: any;
  overallMood: string;
  comfortScore: number;
  alerts: string[];
  recommendations: string[];
  detailedAnalysis: string;
  analyzedAt: Date;
}

export interface JumpAnalysisResult {
  horseId: string;
  horseName: string;
  jumpType: string;
  jumpHeight: number;
  globalScore: number;
  phases: any;
  fault: any;
  strengths: string[];
  improvements: string[];
  correctiveExercises: string[];
  heightPotential: string;
  analyzedAt: Date;
}

export interface FaultCountResult {
  obstacles: any[];
  totalBarres: number;
  totalRefus: number;
  points: number;
  tempsEstime: number | null;
  observations: string[];
}
