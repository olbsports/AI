import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnthropicService } from './anthropic.service';

/**
 * CSO Course Designer Service
 *
 * AI-powered show jumping course generation
 * Creates courses adapted to level, arena size, and objectives
 */
@Injectable()
export class CourseDesignerService {
  private readonly logger = new Logger(CourseDesignerService.name);

  // ==================== OBSTACLE TYPES ====================
  private readonly OBSTACLE_TYPES: Record<string, ObstacleType> = {
    // Verticaux
    vertical: {
      id: 'vertical',
      name: 'Vertical',
      description: "Obstacle composé d'une ou plusieurs barres superposées",
      difficulty: 1,
      minLevel: 'club4',
      technicality: 'Précision du saut, respect de la trajectoire',
      variations: ['Simple', 'Croix', 'Mur', 'Haie'],
    },
    vertical_large: {
      id: 'vertical_large',
      name: 'Vertical large',
      description: 'Vertical avec planches ou remplissage imposant',
      difficulty: 2,
      minLevel: 'club2',
      technicality: 'Respect du cheval, pas de précipitation',
      variations: ['Planches', 'Mur plein', 'Panneau'],
    },

    // Oxers
    oxer: {
      id: 'oxer',
      name: 'Oxer',
      description: 'Obstacle de largeur avec 2 plans de barres',
      difficulty: 2,
      minLevel: 'club2',
      technicality: 'Amplitude du saut, prise de distance',
      variations: ['Carré', 'Montant', 'Descendant'],
    },
    oxer_large: {
      id: 'oxer_large',
      name: 'Oxer large',
      description: 'Oxer avec grande largeur',
      difficulty: 3,
      minLevel: 'amateur3',
      technicality: 'Puissance et amplitude',
      variations: ['Très large', 'Triple barre'],
    },

    // Spa
    spa: {
      id: 'spa',
      name: 'Spa',
      description: 'Oxer avec soubassement type haie ou bidet',
      difficulty: 2,
      minLevel: 'club2',
      technicality: "Respect de l'obstacle, bascule",
      variations: ['Haie', 'Bidet', 'Talus naturel'],
    },

    // Rivière
    riviere: {
      id: 'riviere',
      name: 'Rivière',
      description: 'Obstacle de largeur plat (eau)',
      difficulty: 3,
      minLevel: 'amateur2',
      technicality: 'Amplitude, courage, lecture de la distance',
      variations: ['Simple', 'Avec chandelier'],
    },

    // Combinaisons
    double: {
      id: 'double',
      name: 'Double',
      description: 'Combinaison de 2 obstacles',
      difficulty: 3,
      minLevel: 'club1',
      technicality: 'Gestion des foulées, équilibre',
      variations: ['1 foulée', '2 foulées'],
    },
    triple: {
      id: 'triple',
      name: 'Triple',
      description: 'Combinaison de 3 obstacles',
      difficulty: 4,
      minLevel: 'amateur2',
      technicality: 'Maîtrise du galop, régularité',
      variations: ['Court-long', 'Long-court', 'Régulier'],
    },

    // Lignes
    ligne_2: {
      id: 'ligne_2',
      name: 'Ligne 2 obstacles',
      description: 'Deux obstacles sur une ligne',
      difficulty: 2,
      minLevel: 'club3',
      technicality: 'Comptage foulées, régularité',
      strides: [3, 4, 5, 6],
    },
    ligne_3: {
      id: 'ligne_3',
      name: 'Ligne 3 obstacles',
      description: 'Trois obstacles sur une ligne',
      difficulty: 3,
      minLevel: 'amateur3',
      technicality: 'Gestion complète de la ligne',
      strides: [4, 5, 6],
    },
  };

  // ==================== LEVEL SPECIFICATIONS ====================
  private readonly LEVEL_SPECS: Record<string, LevelSpec> = {
    club4: {
      name: 'Club 4',
      height: { min: 50, max: 60 },
      width: { min: 0, max: 60 },
      obstacles: { min: 6, max: 8 },
      combinations: 0,
      speed: 300, // m/min
      technicalElements: ['Verticaux simples', 'Croix'],
    },
    club3: {
      name: 'Club 3',
      height: { min: 65, max: 75 },
      width: { min: 0, max: 75 },
      obstacles: { min: 8, max: 10 },
      combinations: 1,
      speed: 325,
      technicalElements: ['Verticaux', 'Oxers carrés', 'Double'],
    },
    club2: {
      name: 'Club 2',
      height: { min: 80, max: 90 },
      width: { min: 80, max: 100 },
      obstacles: { min: 9, max: 11 },
      combinations: 1,
      speed: 325,
      technicalElements: ['Verticaux', 'Oxers', 'Spa', 'Double'],
    },
    club1: {
      name: 'Club 1',
      height: { min: 95, max: 105 },
      width: { min: 95, max: 110 },
      obstacles: { min: 10, max: 12 },
      combinations: 2,
      speed: 350,
      technicalElements: ['Tous obstacles', 'Double', 'Lignes'],
    },
    club_elite: {
      name: 'Club Élite',
      height: { min: 105, max: 110 },
      width: { min: 105, max: 115 },
      obstacles: { min: 10, max: 12 },
      combinations: 2,
      speed: 350,
      technicalElements: ['Tous obstacles', 'Triple possible'],
    },
    amateur3: {
      name: 'Amateur 3',
      height: { min: 105, max: 115 },
      width: { min: 110, max: 120 },
      obstacles: { min: 10, max: 12 },
      combinations: 2,
      speed: 350,
      technicalElements: ['Tous obstacles', 'Lignes techniques'],
    },
    amateur2: {
      name: 'Amateur 2',
      height: { min: 115, max: 120 },
      width: { min: 115, max: 125 },
      obstacles: { min: 11, max: 13 },
      combinations: 2,
      speed: 350,
      technicalElements: ['Triple', 'Rivière', 'Lignes complexes'],
    },
    amateur1: {
      name: 'Amateur 1',
      height: { min: 120, max: 125 },
      width: { min: 120, max: 130 },
      obstacles: { min: 11, max: 13 },
      combinations: 2,
      speed: 375,
      technicalElements: ['Tous obstacles techniques'],
    },
    amateur_elite: {
      name: 'Amateur Élite',
      height: { min: 125, max: 130 },
      width: { min: 125, max: 135 },
      obstacles: { min: 12, max: 14 },
      combinations: 2,
      speed: 375,
      technicalElements: ['Très technique'],
    },
    pro3: {
      name: 'Pro 3',
      height: { min: 130, max: 135 },
      width: { min: 135, max: 145 },
      obstacles: { min: 12, max: 14 },
      combinations: 2,
      speed: 375,
      technicalElements: ['Professionnel'],
    },
    pro2: {
      name: 'Pro 2',
      height: { min: 135, max: 140 },
      width: { min: 140, max: 155 },
      obstacles: { min: 12, max: 14 },
      combinations: 2,
      speed: 400,
      technicalElements: ['Haut niveau'],
    },
    pro1: {
      name: 'Pro 1',
      height: { min: 140, max: 145 },
      width: { min: 145, max: 165 },
      obstacles: { min: 13, max: 15 },
      combinations: 3,
      speed: 400,
      technicalElements: ['Très haut niveau'],
    },
    grand_prix: {
      name: 'Grand Prix',
      height: { min: 150, max: 160 },
      width: { min: 160, max: 200 },
      obstacles: { min: 13, max: 16 },
      combinations: 3,
      speed: 400,
      technicalElements: ['International'],
    },
  };

  // ==================== ARENA DIMENSIONS ====================
  private readonly ARENA_SIZES = {
    small: { width: 20, length: 40, name: 'Petite (20x40m)' },
    medium: { width: 25, length: 50, name: 'Moyenne (25x50m)' },
    standard: { width: 30, length: 60, name: 'Standard (30x60m)' },
    large: { width: 40, length: 80, name: 'Grande (40x80m)' },
    international: { width: 50, length: 100, name: 'Internationale (50x100m)' },
  };

  constructor(
    private prisma: PrismaService,
    private anthropic: AnthropicService
  ) {}

  /**
   * Generate a complete CSO course
   */
  async generateCourse(params: {
    level: string;
    arenaSize: 'small' | 'medium' | 'standard' | 'large' | 'international';
    objective: 'entrainement' | 'competition' | 'education' | 'perfectionnement';
    focus?: string[]; // ['lignes', 'tournants', 'combinaisons', 'technique']
    constraints?: {
      maxObstacles?: number;
      mustInclude?: string[]; // Types d'obstacles obligatoires
      avoid?: string[]; // Types à éviter
      bidetAvailable?: boolean;
      riverAvailable?: boolean;
    };
  }): Promise<GeneratedCourse> {
    const levelSpec = this.LEVEL_SPECS[params.level];
    if (!levelSpec) {
      throw new Error(`Unknown level: ${params.level}`);
    }

    const arena = this.ARENA_SIZES[params.arenaSize];

    // Generate course layout
    const courseLayout = await this.generateCourseLayout(levelSpec, arena, params);

    // Calculate distances and strides
    const analyzedCourse = this.analyzeCourse(courseLayout, levelSpec);

    // Generate training exercises based on course
    const exercises = await this.generateExercisesFromCourse(courseLayout, params.level);

    return {
      level: params.level,
      levelName: levelSpec.name,
      arena: arena.name,
      arenaDimensions: { width: arena.width, length: arena.length },
      objective: params.objective,
      obstacles: analyzedCourse.obstacles,
      totalObstacles: analyzedCourse.obstacles.length,
      totalJumps: analyzedCourse.totalJumps,
      courseLength: analyzedCourse.courseLength,
      timeAllowed: analyzedCourse.timeAllowed,
      speed: levelSpec.speed,
      difficulty: analyzedCourse.difficultyRating,
      keyPoints: analyzedCourse.keyPoints,
      walkingOrder: this.generateWalkingOrder(analyzedCourse.obstacles),
      exercises,
      visualData: this.generateVisualData(analyzedCourse.obstacles, arena),
      generatedAt: new Date(),
    };
  }

  /**
   * Generate training exercises for CSO
   */
  async generateExercises(params: {
    level: string;
    focus: 'technique' | 'cadence' | 'distance' | 'combinaisons' | 'tournants' | 'confiance';
    duration: number; // minutes
    horseExperience?: 'debutant' | 'confirme' | 'experimente';
  }): Promise<TrainingExercise[]> {
    const levelSpec = this.LEVEL_SPECS[params.level] || this.LEVEL_SPECS.club2;

    const prompt = `
Génère des exercices de CSO pour l'entraînement:

NIVEAU: ${levelSpec.name}
HAUTEUR: ${levelSpec.height.min}-${levelSpec.height.max}cm
FOCUS: ${params.focus}
DURÉE TOTALE: ${params.duration} minutes
EXPÉRIENCE CHEVAL: ${params.horseExperience || 'confirme'}

EXERCICES DEMANDÉS:
1. Échauffement (10-15min)
2. Exercices principaux (${params.duration - 25}min)
3. Retour au calme (5-10min)

Pour chaque exercice, fournis:
- Nom et description
- Schéma textuel simple
- Objectif pédagogique
- Points clés
- Erreurs à éviter
- Progression possible

Format JSON:
{
  "warmup": [
    {
      "name": "Cavalettis trot",
      "description": "4 cavalettis espacés de 1.30m",
      "duration": 5,
      "schema": "==|==|==|==",
      "objective": "Échauffer, cadencer",
      "keyPoints": ["Régularité", "Équilibre"],
      "errors": ["Précipiter"],
      "height": 20
    }
  ],
  "mainExercises": [...],
  "cooldown": [...]
}
`;

    const result = await this.anthropic.analyze(prompt, 'general', {
      model: 'haiku', // Cheaper for exercise generation
      useCache: true,
    });

    const parsed = this.parseJsonFromAnalysis(result.analysis);
    const allExercises: TrainingExercise[] = [
      ...(parsed.warmup || []).map((e: any) => ({ ...e, phase: 'warmup' })),
      ...(parsed.mainExercises || []).map((e: any) => ({ ...e, phase: 'main' })),
      ...(parsed.cooldown || []).map((e: any) => ({ ...e, phase: 'cooldown' })),
    ];

    return allExercises;
  }

  /**
   * Generate gymnastic lines
   */
  async generateGymnasticLine(params: {
    level: string;
    objective: 'bascule' | 'regularite' | 'amplitude' | 'reactivite' | 'confiance';
    maxJumps: number;
    progression?: boolean; // Generate easier to harder versions
  }): Promise<GymnasticLine[]> {
    const levelSpec = this.LEVEL_SPECS[params.level] || this.LEVEL_SPECS.club2;

    // Pre-defined gymnastic configurations
    const gymnastics: Record<string, GymnasticConfig[]> = {
      bascule: [
        {
          name: 'Ligne de bascule',
          config: 'Croix → 2 foulées → Vertical → 1 foulée → Oxer',
          heights: [50, 70, 80],
        },
        {
          name: 'Gymnastique éducative',
          config: 'Barre sol → Croix → 1 foulée → Vertical',
          heights: [0, 50, 70],
        },
      ],
      regularite: [
        {
          name: 'Cavalettis réguliers',
          config: '4 cavalettis → Vertical',
          heights: [20, 20, 20, 20, 60],
        },
        {
          name: 'Ligne de cadence',
          config: 'Vertical → 4 foulées → Vertical → 4 foulées → Vertical',
          heights: [70, 70, 70],
        },
      ],
      amplitude: [
        {
          name: 'Extension progressive',
          config: 'Vertical → 2 foulées → Oxer carré → 2 foulées → Oxer large',
          heights: [70, 80, 90],
        },
        { name: "Ligne d'amplitude", config: 'Oxer → 5 foulées longues → Oxer', heights: [80, 90] },
      ],
      reactivite: [
        { name: 'In and out', config: 'Vertical → 1 foulée → Vertical', heights: [60, 60] },
        { name: 'Bounce gymnastique', config: '3 verticaux sans foulée', heights: [50, 55, 60] },
      ],
      confiance: [
        {
          name: 'Progression douce',
          config: 'Croix basse → Vertical → Croix décorée',
          heights: [40, 50, 50],
        },
        {
          name: 'Ligne rassurante',
          config: 'Barres sol guidantes → Croix → Vertical avec remplissage',
          heights: [0, 40, 60],
        },
      ],
    };

    const baseGymnastics = gymnastics[params.objective] || gymnastics.regularite;

    // Adapt heights to level
    const adaptedGymnastics = baseGymnastics.map((g) => ({
      ...g,
      heights: g.heights.map((h) => Math.min(h, levelSpec.height.max)),
    }));

    // Generate progressions if requested
    if (params.progression) {
      return adaptedGymnastics.flatMap((g) => [
        { ...g, name: `${g.name} - Facile`, heights: g.heights.map((h) => Math.max(h - 20, 20)) },
        { ...g, name: `${g.name} - Standard`, heights: g.heights },
        {
          ...g,
          name: `${g.name} - Difficile`,
          heights: g.heights.map((h) => Math.min(h + 10, levelSpec.height.max)),
        },
      ]);
    }

    return adaptedGymnastics;
  }

  /**
   * Analyze an existing course
   */
  async analyzeCourseDesign(params: {
    obstacles: ObstaclePosition[];
    level: string;
    arenaSize: { width: number; length: number };
  }): Promise<CourseAnalysis> {
    const levelSpec = this.LEVEL_SPECS[params.level];

    // Calculate all distances
    const distances = this.calculateAllDistances(params.obstacles);

    // Calculate strides
    const strideAnalysis = distances.map((d) => ({
      from: d.from,
      to: d.to,
      distance: d.distance,
      strides: this.calculateStrides(d.distance, levelSpec.speed),
      ideal: this.isIdealDistance(d.distance, d.strides),
    }));

    // Identify technical challenges
    const challenges = this.identifyTechnicalChallenges(params.obstacles, strideAnalysis);

    // Overall difficulty
    const difficulty = this.calculateOverallDifficulty(
      params.obstacles,
      strideAnalysis,
      challenges
    );

    return {
      totalDistance: distances.reduce((sum, d) => sum + d.distance, 0),
      strideAnalysis,
      technicalChallenges: challenges,
      difficultyRating: difficulty,
      recommendations: this.generateDesignRecommendations(strideAnalysis, challenges),
      complianceWithLevel: this.checkLevelCompliance(params.obstacles, levelSpec),
    };
  }

  /**
   * Generate course for specific horse
   */
  async generatePersonalizedCourse(params: {
    horseId: string;
    level: string;
    arenaSize: 'small' | 'medium' | 'standard' | 'large' | 'international';
    focus?: string[];
  }): Promise<GeneratedCourse> {
    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        competitionResults: {
          where: { discipline: 'CSO' },
          orderBy: { competitionDate: 'desc' },
          take: 10,
        },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    // Analyze horse's strengths and weaknesses
    const horseAnalysis = this.analyzeHorseCSO(horse);

    // Generate course adapted to horse
    const course = await this.generateCourse({
      level: params.level,
      arenaSize: params.arenaSize,
      objective: 'entrainement',
      focus: horseAnalysis.areasToWork,
      constraints: {
        avoid: horseAnalysis.difficultElements,
        mustInclude:
          horseAnalysis.strengths.length > 0 ? horseAnalysis.strengths.slice(0, 2) : undefined,
      },
    });

    return {
      ...course,
      personalizedFor: horse.name,
      horseAnalysis,
    };
  }

  // ==================== PRIVATE HELPERS ====================

  private async generateCourseLayout(
    levelSpec: LevelSpec,
    arena: any,
    params: any
  ): Promise<CourseObstacle[]> {
    const numObstacles =
      params.constraints?.maxObstacles ||
      Math.floor((levelSpec.obstacles.min + levelSpec.obstacles.max) / 2);

    const prompt = `
Génère un parcours CSO avec placement précis:

NIVEAU: ${levelSpec.name}
CARRIÈRE: ${arena.width}x${arena.length}m
NOMBRE D'OBSTACLES: ${numObstacles}
OBJECTIF: ${params.objective}
${params.focus?.length ? `FOCUS: ${params.focus.join(', ')}` : ''}
${params.constraints?.mustInclude?.length ? `OBLIGATOIRE: ${params.constraints.mustInclude.join(', ')}` : ''}
${params.constraints?.avoid?.length ? `ÉVITER: ${params.constraints.avoid.join(', ')}` : ''}

HAUTEUR: ${levelSpec.height.min}-${levelSpec.height.max}cm
LARGEUR MAX: ${levelSpec.width.max}cm
COMBINAISONS: ${levelSpec.combinations}
VITESSE: ${levelSpec.speed} m/min

Génère JSON avec positions en mètres (origine coin bas-gauche):
{
  "obstacles": [
    {
      "numero": 1,
      "type": "vertical",
      "name": "Vertical d'entrée",
      "position": { "x": 15, "y": 10 },
      "orientation": 90,
      "height": 75,
      "width": 0,
      "description": "Vertical simple pour mise en confiance"
    },
    {
      "numero": 2,
      "type": "oxer",
      "name": "Oxer montant",
      "position": { "x": 20, "y": 25 },
      "orientation": 45,
      "height": 80,
      "width": 90,
      "description": "Oxer sur la diagonale"
    }
  ],
  "courseDescription": "Parcours fluide avec lignes sur les longueurs...",
  "keyDifficulties": ["Ligne 4-5 en 5 foulées", "Tournant serré après le 7"]
}
`;

    const result = await this.anthropic.analyze(prompt, 'general', {
      model: 'haiku',
      useCache: true,
    });

    const parsed = this.parseJsonFromAnalysis(result.analysis);
    return parsed.obstacles || this.generateDefaultLayout(levelSpec, arena, numObstacles);
  }

  private generateDefaultLayout(levelSpec: LevelSpec, arena: any, count: number): CourseObstacle[] {
    const obstacles: CourseObstacle[] = [];
    const avgHeight = Math.floor((levelSpec.height.min + levelSpec.height.max) / 2);

    // Simple default layout
    const positions = [
      { x: arena.width * 0.3, y: arena.length * 0.2 },
      { x: arena.width * 0.7, y: arena.length * 0.3 },
      { x: arena.width * 0.5, y: arena.length * 0.5 },
      { x: arena.width * 0.3, y: arena.length * 0.7 },
      { x: arena.width * 0.7, y: arena.length * 0.8 },
    ];

    for (let i = 0; i < Math.min(count, positions.length); i++) {
      obstacles.push({
        numero: i + 1,
        type: i % 2 === 0 ? 'vertical' : 'oxer',
        name: `Obstacle ${i + 1}`,
        position: positions[i],
        orientation: 90,
        height: avgHeight,
        width: i % 2 === 0 ? 0 : avgHeight,
        description: '',
      });
    }

    return obstacles;
  }

  private analyzeCourse(obstacles: CourseObstacle[], levelSpec: LevelSpec): AnalyzedCourse {
    let totalLength = 0;
    const totalJumps = obstacles.length;
    const keyPoints: string[] = [];

    // Calculate course length
    for (let i = 1; i < obstacles.length; i++) {
      const prev = obstacles[i - 1];
      const curr = obstacles[i];
      const dist = Math.sqrt(
        Math.pow(curr.position.x - prev.position.x, 2) +
          Math.pow(curr.position.y - prev.position.y, 2)
      );
      totalLength += dist;

      // Check for combinations
      if (dist < 12) {
        keyPoints.push(`Combinaison ${prev.numero}-${curr.numero}`);
      }
    }

    // Calculate time allowed
    const timeAllowed = Math.ceil((totalLength / levelSpec.speed) * 60) + 5; // +5 seconds buffer

    return {
      obstacles,
      totalJumps,
      courseLength: Math.round(totalLength),
      timeAllowed,
      difficultyRating: this.calculateDifficultyRating(obstacles, levelSpec),
      keyPoints,
    };
  }

  private calculateDifficultyRating(obstacles: CourseObstacle[], levelSpec: LevelSpec): number {
    let rating = 50; // Base rating

    // Height factor
    const avgHeight = obstacles.reduce((sum, o) => sum + o.height, 0) / obstacles.length;
    const heightRatio = avgHeight / levelSpec.height.max;
    rating += heightRatio * 20;

    // Obstacle count factor
    rating += (obstacles.length - levelSpec.obstacles.min) * 2;

    // Type complexity
    const complexTypes = obstacles.filter((o) => ['double', 'triple', 'riviere'].includes(o.type));
    rating += complexTypes.length * 5;

    return Math.min(100, Math.round(rating));
  }

  private async generateExercisesFromCourse(
    obstacles: CourseObstacle[],
    level: string
  ): Promise<TrainingExercise[]> {
    // Generate exercises that help master the course difficulties
    return [
      {
        name: 'Échauffement sur croix',
        description: 'Croix au centre, approches variées',
        duration: 10,
        phase: 'warmup',
        height: 50,
        objective: 'Mise en selle, cadence',
      },
      {
        name: 'Ligne du parcours',
        description: 'Travailler les lignes principales du parcours',
        duration: 15,
        phase: 'main',
        height: obstacles[0]?.height || 70,
        objective: 'Préparation spécifique',
      },
    ];
  }

  private generateWalkingOrder(obstacles: CourseObstacle[]): string[] {
    return obstacles.map((o, i) => {
      const next = obstacles[i + 1];
      if (!next) return `${o.numero}. ${o.name} → Arrivée`;

      const dist = Math.sqrt(
        Math.pow(next.position.x - o.position.x, 2) + Math.pow(next.position.y - o.position.y, 2)
      );

      const strides = Math.round((dist - 4) / 3.5);
      return `${o.numero}. ${o.name} → ${strides} foulées`;
    });
  }

  private generateVisualData(obstacles: CourseObstacle[], arena: any): VisualData {
    return {
      arenaWidth: arena.width,
      arenaLength: arena.length,
      obstacles: obstacles.map((o) => ({
        numero: o.numero,
        x: o.position.x,
        y: o.position.y,
        rotation: o.orientation,
        type: o.type,
        width: o.type === 'vertical' ? 3 : 3.5,
        depth: o.type === 'vertical' ? 0.3 : 1.2,
      })),
      path: obstacles.map((o) => ({ x: o.position.x, y: o.position.y })),
      startPosition: { x: 5, y: arena.length / 2 },
      finishPosition: { x: arena.width - 5, y: arena.length / 2 },
    };
  }

  private calculateAllDistances(obstacles: ObstaclePosition[]): DistanceInfo[] {
    const distances: DistanceInfo[] = [];
    for (let i = 1; i < obstacles.length; i++) {
      const prev = obstacles[i - 1];
      const curr = obstacles[i];
      const dist = Math.sqrt(Math.pow(curr.x - prev.x, 2) + Math.pow(curr.y - prev.y, 2));
      distances.push({
        from: i,
        to: i + 1,
        distance: Math.round(dist * 10) / 10,
        strides: Math.round((dist - 4) / 3.5),
      });
    }
    return distances;
  }

  private calculateStrides(distance: number, speed: number): number {
    // Standard: 3.5m per stride at 350m/min
    const strideLength = speed / 100; // Approximate
    return Math.round((distance - 4) / strideLength);
  }

  private isIdealDistance(distance: number, strides: number): boolean {
    const ideal = 4 + strides * 3.5;
    return Math.abs(distance - ideal) < 1.5;
  }

  private identifyTechnicalChallenges(obstacles: any[], strideAnalysis: any[]): string[] {
    const challenges: string[] = [];

    // Short distances
    strideAnalysis
      .filter((s) => s.strides <= 2)
      .forEach((s) => {
        challenges.push(`Distance courte ${s.from}-${s.to}: ${s.strides} foulées`);
      });

    // Angles
    // ... more challenge detection

    return challenges;
  }

  private calculateOverallDifficulty(
    obstacles: any[],
    strides: any[],
    challenges: string[]
  ): number {
    return Math.min(100, 50 + obstacles.length * 2 + challenges.length * 5);
  }

  private generateDesignRecommendations(strides: any[], challenges: string[]): string[] {
    return ['Vérifier les distances de combinaisons', "S'assurer que les virages sont faisables"];
  }

  private checkLevelCompliance(obstacles: any[], levelSpec: LevelSpec): ComplianceResult {
    const issues: string[] = [];

    obstacles.forEach((o) => {
      if (o.height > levelSpec.height.max) {
        issues.push(`Obstacle ${o.numero}: hauteur ${o.height}cm > max ${levelSpec.height.max}cm`);
      }
    });

    return {
      compliant: issues.length === 0,
      issues,
    };
  }

  private analyzeHorseCSO(horse: any): HorseAnalysis {
    // Simplified analysis
    return {
      strengths: ['Verticaux', 'Lignes droites'],
      weaknesses: ['Tournants serrés'],
      areasToWork: ['tournants', 'equilibre'],
      difficultElements: ['triple'],
      recommendedHeight: horse.level?.includes('Amateur') ? 115 : 100,
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

interface ObstacleType {
  id: string;
  name: string;
  description: string;
  difficulty: number;
  minLevel: string;
  technicality: string;
  variations?: string[];
  strides?: number[];
}

interface LevelSpec {
  name: string;
  height: { min: number; max: number };
  width: { min: number; max: number };
  obstacles: { min: number; max: number };
  combinations: number;
  speed: number;
  technicalElements: string[];
}

interface CourseObstacle {
  numero: number;
  type: string;
  name: string;
  position: { x: number; y: number };
  orientation: number;
  height: number;
  width: number;
  description: string;
}

interface AnalyzedCourse {
  obstacles: CourseObstacle[];
  totalJumps: number;
  courseLength: number;
  timeAllowed: number;
  difficultyRating: number;
  keyPoints: string[];
}

interface VisualData {
  arenaWidth: number;
  arenaLength: number;
  obstacles: any[];
  path: { x: number; y: number }[];
  startPosition: { x: number; y: number };
  finishPosition: { x: number; y: number };
}

interface ObstaclePosition {
  x: number;
  y: number;
}

interface DistanceInfo {
  from: number;
  to: number;
  distance: number;
  strides: number;
}

interface ComplianceResult {
  compliant: boolean;
  issues: string[];
}

interface HorseAnalysis {
  strengths: string[];
  weaknesses: string[];
  areasToWork: string[];
  difficultElements: string[];
  recommendedHeight: number;
}

interface GymnasticConfig {
  name: string;
  config: string;
  heights: number[];
}

export interface GeneratedCourse {
  level: string;
  levelName: string;
  arena: string;
  arenaDimensions: { width: number; length: number };
  objective: string;
  obstacles: CourseObstacle[];
  totalObstacles: number;
  totalJumps: number;
  courseLength: number;
  timeAllowed: number;
  speed: number;
  difficulty: number;
  keyPoints: string[];
  walkingOrder: string[];
  exercises: TrainingExercise[];
  visualData: VisualData;
  generatedAt: Date;
  personalizedFor?: string;
  horseAnalysis?: HorseAnalysis;
}

export interface TrainingExercise {
  name: string;
  description: string;
  duration: number;
  phase: string;
  height?: number;
  objective: string;
  schema?: string;
  keyPoints?: string[];
  errors?: string[];
}

export interface GymnasticLine extends GymnasticConfig {
  // Extended from GymnasticConfig
}

export interface CourseAnalysis {
  totalDistance: number;
  strideAnalysis: any[];
  technicalChallenges: string[];
  difficultyRating: number;
  recommendations: string[];
  complianceWithLevel: ComplianceResult;
}
