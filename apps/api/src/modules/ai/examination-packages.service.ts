import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnthropicService } from './anthropic.service';
import { VideoAnalysisService } from './video-analysis.service';
import { MedicalImagingService } from './medical-imaging.service';

/**
 * Examination Packages Service
 *
 * Comprehensive AI analysis packages with token-based pricing
 * Different levels of analysis depth and recommendations
 */
@Injectable()
export class ExaminationPackagesService {
  private readonly logger = new Logger(ExaminationPackagesService.name);

  // ==================== PACKAGES DEFINITION ====================
  private readonly PACKAGES: Record<string, Package> = {
    ESSENTIEL: {
      id: 'essentiel',
      name: 'Essentiel',
      description: 'Analyse de base rapide',
      tokens: 5,
      color: '#4CAF50',
      includes: ['locomotion_basic', 'health_summary'],
      features: [
        'Analyse locomotion de base',
        'Résumé état de santé',
        'Score global',
        '3 recommandations',
      ],
      deliveryTime: '< 2 minutes',
    },
    STANDARD: {
      id: 'standard',
      name: 'Standard',
      description: 'Analyse complète pour cavaliers',
      tokens: 15,
      color: '#2196F3',
      includes: ['locomotion_full', 'health_detailed', 'training_basic', 'nutrition_basic'],
      features: [
        'Analyse locomotion complète',
        'Bilan de santé détaillé',
        "Plan d'entraînement 4 semaines",
        'Conseils nutrition de base',
        'Score par critère',
        '10 recommandations personnalisées',
      ],
      deliveryTime: '< 5 minutes',
    },
    PREMIUM: {
      id: 'premium',
      name: 'Premium',
      description: 'Analyse approfondie avec plans personnalisés',
      tokens: 30,
      color: '#9C27B0',
      includes: [
        'locomotion_full',
        'health_detailed',
        'training_full',
        'nutrition_full',
        'mental_assessment',
        'competition_prep',
      ],
      features: [
        'Toutes les analyses Standard',
        "Plan d'entraînement 12 semaines",
        'Plan nutritionnel complet',
        'Évaluation comportementale',
        'Préparation compétition',
        'Suivi progression',
        'Support prioritaire',
      ],
      deliveryTime: '< 10 minutes',
    },
    EXPERT: {
      id: 'expert',
      name: 'Expert Pro',
      description: 'Package complet pour professionnels',
      tokens: 50,
      color: '#FF9800',
      includes: [
        'locomotion_biomechanics',
        'health_complete',
        'training_periodization',
        'nutrition_performance',
        'mental_full',
        'competition_strategy',
        'breeding_assessment',
        'career_planning',
      ],
      features: [
        'Toutes les analyses Premium',
        'Analyse biomécanique avancée',
        'Périodisation annuelle',
        'Nutrition performance',
        'Stratégie compétition',
        'Conseils breeding',
        'Planification carrière',
        'Rapports exportables PDF',
        'Consultation vidéo 15min',
      ],
      deliveryTime: '< 15 minutes',
    },
    VISITE_ACHAT: {
      id: 'visite_achat',
      name: "Visite d'Achat",
      description: 'Analyse complète pré-achat',
      tokens: 40,
      color: '#F44336',
      includes: [
        'locomotion_full',
        'health_complete',
        'radios_analysis',
        'conformation',
        'career_potential',
        'value_estimation',
      ],
      features: [
        'Analyse locomotion toutes allures',
        'Bilan radiographique',
        'Examen conformation',
        'Potentiel sportif',
        'Estimation valeur EquiCote',
        'Points de vigilance acheteur',
        'Classification A-E',
        'Rapport détaillé PDF',
      ],
      deliveryTime: '< 20 minutes',
    },
  };

  // ==================== MODULES À LA CARTE ====================
  private readonly MODULES: Record<string, Module> = {
    // Locomotion & Performance
    locomotion_basic: {
      id: 'locomotion_basic',
      name: 'Locomotion - Basique',
      category: 'performance',
      tokens: 3,
      description: 'Analyse rapide des 3 allures',
      outputs: ['score_global', 'anomalies_majeures', 'recommendations_3'],
    },
    locomotion_full: {
      id: 'locomotion_full',
      name: 'Locomotion - Complète',
      category: 'performance',
      tokens: 8,
      description: 'Analyse détaillée locomotion + biomécanique',
      outputs: ['scores_detailles', 'analyse_allures', 'anomalies', 'recommendations_10'],
    },
    locomotion_biomechanics: {
      id: 'locomotion_biomechanics',
      name: 'Analyse Biomécanique Pro',
      category: 'performance',
      tokens: 15,
      description: 'Étude biomécanique complète avec angles articulaires',
      outputs: ['angles_articulaires', 'amplitude_mouvement', 'symetrie', 'points_amelioration'],
    },

    // Santé
    health_summary: {
      id: 'health_summary',
      name: 'Santé - Résumé',
      category: 'health',
      tokens: 2,
      description: 'Résumé état de santé général',
      outputs: ['etat_general', 'alertes', 'rappels_vaccins'],
    },
    health_detailed: {
      id: 'health_detailed',
      name: 'Santé - Détaillé',
      category: 'health',
      tokens: 6,
      description: 'Bilan de santé complet',
      outputs: ['bilan_complet', 'historique_analyse', 'tendances', 'recommendations'],
    },
    health_complete: {
      id: 'health_complete',
      name: 'Santé - Complet',
      category: 'health',
      tokens: 12,
      description: 'Dossier médical complet avec prédictions',
      outputs: ['dossier_medical', 'risques_predits', 'prevention', 'planning_veterinaire'],
    },

    // Imagerie médicale
    radios_analysis: {
      id: 'radios_analysis',
      name: 'Analyse Radiographique',
      category: 'medical',
      tokens: 15,
      description: 'Analyse complète des radiographies',
      outputs: ['interpretation', 'classification', 'pronostic', 'recommendations'],
    },
    echo_analysis: {
      id: 'echo_analysis',
      name: 'Analyse Échographique',
      category: 'medical',
      tokens: 12,
      description: 'Analyse échographie tendons/articulations',
      outputs: ['structures', 'lesions', 'grade', 'protocole_rehab'],
    },

    // Entraînement
    training_basic: {
      id: 'training_basic',
      name: 'Plan Entraînement - 4 semaines',
      category: 'training',
      tokens: 5,
      description: "Programme d'entraînement sur 4 semaines",
      outputs: ['planning_4sem', 'exercices', 'intensite', 'repos'],
    },
    training_full: {
      id: 'training_full',
      name: 'Plan Entraînement - 12 semaines',
      category: 'training',
      tokens: 10,
      description: 'Programme complet 12 semaines avec progression',
      outputs: ['planning_12sem', 'cycles', 'exercices_detailles', 'tests_validation'],
    },
    training_periodization: {
      id: 'training_periodization',
      name: 'Périodisation Annuelle',
      category: 'training',
      tokens: 20,
      description: 'Planification annuelle avec pics de forme',
      outputs: ['macrocycles', 'mesocycles', 'microcycles', 'objectifs_competition'],
    },

    // Nutrition
    nutrition_basic: {
      id: 'nutrition_basic',
      name: 'Nutrition - Conseils',
      category: 'nutrition',
      tokens: 3,
      description: 'Conseils nutritionnels de base',
      outputs: ['besoins_base', 'ration_type', 'complements'],
    },
    nutrition_full: {
      id: 'nutrition_full',
      name: 'Nutrition - Plan Complet',
      category: 'nutrition',
      tokens: 8,
      description: 'Plan nutritionnel personnalisé',
      outputs: ['ration_detaillee', 'complements', 'hydratation', 'ajustements_saison'],
    },
    nutrition_performance: {
      id: 'nutrition_performance',
      name: 'Nutrition Performance',
      category: 'nutrition',
      tokens: 15,
      description: 'Nutrition optimisée pour la performance',
      outputs: ['ration_competition', 'pre_post_effort', 'recuperation', 'supplements_legaux'],
    },

    // Mental & Comportement
    mental_assessment: {
      id: 'mental_assessment',
      name: 'Évaluation Comportementale',
      category: 'mental',
      tokens: 6,
      description: 'Analyse comportement et tempérament',
      outputs: ['profil_mental', 'points_forts', 'axes_travail', 'techniques_gestion'],
    },
    mental_full: {
      id: 'mental_full',
      name: 'Programme Mental Complet',
      category: 'mental',
      tokens: 12,
      description: 'Programme complet gestion mental',
      outputs: ['analyse_complete', 'programme_desensibilisation', 'exercices_confiance', 'suivi'],
    },

    // Compétition
    competition_prep: {
      id: 'competition_prep',
      name: 'Préparation Compétition',
      category: 'competition',
      tokens: 8,
      description: 'Préparation pour une compétition',
      outputs: ['planning_semaine_avant', 'echauffement', 'gestion_stress', 'checklist'],
    },
    competition_strategy: {
      id: 'competition_strategy',
      name: 'Stratégie Compétition',
      category: 'competition',
      tokens: 15,
      description: 'Stratégie complète saison compétition',
      outputs: [
        'calendrier_optimise',
        'objectifs',
        'preparation_specifique',
        'analyse_adversaires',
      ],
    },

    // Élevage
    breeding_assessment: {
      id: 'breeding_assessment',
      name: 'Analyse Breeding',
      category: 'breeding',
      tokens: 10,
      description: 'Évaluation pour la reproduction',
      outputs: [
        'potentiel_genetique',
        'compatibilites',
        'recommandations_etalons',
        'produits_attendus',
      ],
    },

    // Carrière
    career_potential: {
      id: 'career_potential',
      name: 'Potentiel de Carrière',
      category: 'career',
      tokens: 8,
      description: 'Évaluation du potentiel sportif',
      outputs: ['niveau_actuel', 'potentiel_max', 'disciplines_adaptees', 'timeline'],
    },
    career_planning: {
      id: 'career_planning',
      name: 'Planification Carrière',
      category: 'career',
      tokens: 15,
      description: 'Plan de carrière complet',
      outputs: ['objectifs_annuels', 'etapes_progression', 'competitions_cibles', 'reconversion'],
    },

    // Valeur
    value_estimation: {
      id: 'value_estimation',
      name: 'Estimation Valeur EquiCote',
      category: 'value',
      tokens: 5,
      description: 'Estimation de la valeur marchande',
      outputs: ['fourchette_prix', 'facteurs', 'tendance_marche', 'recommandations'],
    },

    // Conformation
    conformation: {
      id: 'conformation',
      name: 'Analyse Conformation',
      category: 'physical',
      tokens: 8,
      description: 'Analyse morphologique complète',
      outputs: ['modele', 'aplombs', 'points_forts', 'points_faibles'],
    },
  };

  constructor(
    private prisma: PrismaService,
    private anthropic: AnthropicService,
    private videoAnalysis: VideoAnalysisService,
    private medicalImaging: MedicalImagingService
  ) {}

  // ==================== PACKAGE OPERATIONS ====================

  /**
   * Get all available packages
   */
  getAvailablePackages(): Package[] {
    return Object.values(this.PACKAGES);
  }

  /**
   * Get all available modules
   */
  getAvailableModules(): Module[] {
    return Object.values(this.MODULES);
  }

  /**
   * Get modules by category
   */
  getModulesByCategory(category: string): Module[] {
    return Object.values(this.MODULES).filter((m) => m.category === category);
  }

  /**
   * Calculate total tokens for custom selection
   */
  calculateTokens(moduleIds: string[]): {
    total: number;
    breakdown: { id: string; tokens: number }[];
  } {
    const breakdown = moduleIds
      .filter((id) => this.MODULES[id])
      .map((id) => ({ id, tokens: this.MODULES[id].tokens }));

    return {
      total: breakdown.reduce((sum, m) => sum + m.tokens, 0),
      breakdown,
    };
  }

  /**
   * Execute a package analysis
   */
  async executePackage(params: {
    horseId: string;
    userId: string;
    organizationId: string;
    packageId: string;
    data: PackageInputData;
  }): Promise<PackageResult> {
    const pkg = this.PACKAGES[params.packageId.toUpperCase()];
    if (!pkg) {
      throw new Error(`Unknown package: ${params.packageId}`);
    }

    // Check token balance
    const org = await this.prisma.organization.findUnique({
      where: { id: params.organizationId },
    });

    if (!org || org.tokenBalance < pkg.tokens) {
      throw new Error(
        `Insufficient tokens. Required: ${pkg.tokens}, Available: ${org?.tokenBalance || 0}`
      );
    }

    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        competitionResults: { take: 10, orderBy: { competitionDate: 'desc' } },
        healthRecords: { take: 10, orderBy: { date: 'desc' } },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    this.logger.log(`Executing package ${pkg.id} for horse ${horse.name}`);

    // Execute all modules in package
    const moduleResults: Record<string, any> = {};

    for (const moduleId of pkg.includes) {
      try {
        moduleResults[moduleId] = await this.executeModule(moduleId, horse, params.data);
      } catch (error) {
        this.logger.warn(`Module ${moduleId} failed: ${error}`);
        moduleResults[moduleId] = { error: 'Module execution failed' };
      }
    }

    // Deduct tokens
    await this.prisma.organization.update({
      where: { id: params.organizationId },
      data: { tokenBalance: { decrement: pkg.tokens } },
    });

    // Log transaction
    await this.prisma.tokenTransaction.create({
      data: {
        organizationId: params.organizationId,
        amount: -pkg.tokens,
        type: 'consumption',
        description: `Package ${pkg.name} - ${horse.name}`,
        metadata: { packageId: pkg.id, horseId: params.horseId },
      },
    });

    // Generate global summary
    const summary = await this.generatePackageSummary(horse, pkg, moduleResults);

    return {
      packageId: pkg.id,
      packageName: pkg.name,
      horseId: params.horseId,
      horseName: horse.name,
      tokensConsumed: pkg.tokens,
      moduleResults,
      summary,
      recommendations: this.aggregateRecommendations(moduleResults),
      generatedAt: new Date(),
    };
  }

  /**
   * Execute custom module selection
   */
  async executeCustomAnalysis(params: {
    horseId: string;
    userId: string;
    organizationId: string;
    moduleIds: string[];
    data: PackageInputData;
  }): Promise<CustomAnalysisResult> {
    const { total, breakdown } = this.calculateTokens(params.moduleIds);

    // Check balance
    const org = await this.prisma.organization.findUnique({
      where: { id: params.organizationId },
    });

    if (!org || org.tokenBalance < total) {
      throw new Error(
        `Insufficient tokens. Required: ${total}, Available: ${org?.tokenBalance || 0}`
      );
    }

    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        competitionResults: { take: 10, orderBy: { competitionDate: 'desc' } },
        healthRecords: { take: 10, orderBy: { date: 'desc' } },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const moduleResults: Record<string, any> = {};

    for (const moduleId of params.moduleIds) {
      if (this.MODULES[moduleId]) {
        try {
          moduleResults[moduleId] = await this.executeModule(moduleId, horse, params.data);
        } catch (error) {
          moduleResults[moduleId] = { error: 'Module execution failed' };
        }
      }
    }

    // Deduct tokens
    await this.prisma.organization.update({
      where: { id: params.organizationId },
      data: { tokenBalance: { decrement: total } },
    });

    await this.prisma.tokenTransaction.create({
      data: {
        organizationId: params.organizationId,
        amount: -total,
        type: 'consumption',
        description: `Analyse personnalisée - ${horse.name}`,
        metadata: { modules: params.moduleIds, horseId: params.horseId },
      },
    });

    return {
      horseId: params.horseId,
      horseName: horse.name,
      modulesExecuted: params.moduleIds,
      tokensConsumed: total,
      breakdown,
      moduleResults,
      recommendations: this.aggregateRecommendations(moduleResults),
      generatedAt: new Date(),
    };
  }

  // ==================== MODULE EXECUTION ====================

  private async executeModule(moduleId: string, horse: any, data: PackageInputData): Promise<any> {
    const module = this.MODULES[moduleId];
    if (!module) return { error: 'Unknown module' };

    switch (moduleId) {
      // Locomotion modules
      case 'locomotion_basic':
        return this.analyzeLocomotionBasic(horse, data);
      case 'locomotion_full':
        return this.analyzeLocomotionFull(horse, data);
      case 'locomotion_biomechanics':
        return this.analyzeLocomotionBiomechanics(horse, data);

      // Health modules
      case 'health_summary':
        return this.getHealthSummary(horse);
      case 'health_detailed':
        return this.getHealthDetailed(horse);
      case 'health_complete':
        return this.getHealthComplete(horse);

      // Training modules
      case 'training_basic':
        return this.generateTrainingPlan(horse, data, 4);
      case 'training_full':
        return this.generateTrainingPlan(horse, data, 12);
      case 'training_periodization':
        return this.generatePeriodization(horse, data);

      // Nutrition modules
      case 'nutrition_basic':
        return this.generateNutritionBasic(horse, data);
      case 'nutrition_full':
        return this.generateNutritionFull(horse, data);
      case 'nutrition_performance':
        return this.generateNutritionPerformance(horse, data);

      // Mental modules
      case 'mental_assessment':
        return this.assessMental(horse, data);
      case 'mental_full':
        return this.generateMentalProgram(horse, data);

      // Competition modules
      case 'competition_prep':
        return this.generateCompetitionPrep(horse, data);
      case 'competition_strategy':
        return this.generateCompetitionStrategy(horse, data);

      // Other modules
      case 'breeding_assessment':
        return this.assessBreeding(horse);
      case 'career_potential':
        return this.assessCareerPotential(horse);
      case 'career_planning':
        return this.generateCareerPlan(horse, data);
      case 'value_estimation':
        return this.estimateValue(horse);
      case 'conformation':
        return this.analyzeConformation(horse, data);

      default:
        return { message: 'Module en cours de développement' };
    }
  }

  // ==================== MODULE IMPLEMENTATIONS ====================

  private async analyzeLocomotionBasic(horse: any, data: PackageInputData): Promise<any> {
    const prompt = `
Analyse locomotion rapide pour ${horse.name}:
- Race: ${horse.studbook || horse.breed}
- Âge: ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : '?'} ans
- Discipline: ${(horse.disciplines as string[])?.join(', ') || 'Non précisé'}

Fournis en JSON:
{
  "scoreGlobal": 75,
  "pas": { "score": 80, "commentaire": "..." },
  "trot": { "score": 75, "commentaire": "..." },
  "galop": { "score": 70, "commentaire": "..." },
  "anomalies": [],
  "recommandations": ["...", "...", "..."]
}
`;
    const result = await this.anthropic.analyze(prompt, 'locomotion');
    return this.parseJsonFromAnalysis(result.analysis);
  }

  private async analyzeLocomotionFull(horse: any, data: PackageInputData): Promise<any> {
    if (data.videoFrames?.length) {
      return this.videoAnalysis.analyzeLocomotion({
        horseId: horse.id,
        videoFrames: data.videoFrames,
        surface: (data.surface || 'souple') as 'souple' | 'dur' | 'mixte',
        allure: (data.allure || 'tous') as 'tous' | 'pas' | 'trot' | 'galop',
        context: data.context as any,
      });
    }

    const prompt = `
Analyse locomotion complète pour ${horse.name}:
- Race: ${horse.studbook || horse.breed}
- Âge: ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : '?'} ans
- Niveau: ${horse.level || 'Non précisé'}
- Discipline: ${(horse.disciplines as string[])?.join(', ') || 'Non précisé'}

CRITÈRES D'ÉVALUATION:
1. Régularité des allures
2. Amplitude/Engagement
3. Souplesse dorsale
4. Équilibre
5. Réactivité
6. Qualité des transitions
7. Symétrie
8. Impulsion

Fournis en JSON:
{
  "scoreGlobal": 78,
  "criteres": {
    "regularite": { "score": 80, "detail": "..." },
    "amplitude": { "score": 75, "detail": "..." },
    "souplesse": { "score": 78, "detail": "..." },
    "equilibre": { "score": 80, "detail": "..." },
    "reactivite": { "score": 76, "detail": "..." },
    "transitions": { "score": 74, "detail": "..." },
    "symetrie": { "score": 82, "detail": "..." },
    "impulsion": { "score": 77, "detail": "..." }
  },
  "pointsForts": ["...", "..."],
  "axesAmelioration": ["...", "..."],
  "recommandations": ["...", "...", "...", "..."]
}
`;
    const result = await this.anthropic.analyze(prompt, 'locomotion');
    return this.parseJsonFromAnalysis(result.analysis);
  }

  private async analyzeLocomotionBiomechanics(horse: any, data: PackageInputData): Promise<any> {
    const prompt = `
ANALYSE BIOMÉCANIQUE AVANCÉE - ${horse.name}

Données cheval:
- Race: ${horse.studbook || horse.breed}
- Taille: ${horse.heightCm ? horse.heightCm + ' cm' : 'Non mesurée'}
- Poids: ${horse.weightKg ? horse.weightKg + ' kg' : 'Non mesuré'}
- Discipline principale: ${(horse.disciplines as string[])?.[0] || 'Polyvalent'}
- Niveau: ${horse.level || 'Amateur'}

ANALYSE DEMANDÉE:
1. Angles articulaires au repos et en mouvement
2. Amplitude de mouvement par articulation
3. Phase de suspension/appui
4. Report de poids
5. Analyse asymétries
6. Recommandations spécifiques par articulation

Format JSON structuré avec scores et mesures.
`;
    const result = await this.anthropic.analyze(prompt, 'locomotion');
    return {
      ...this.parseJsonFromAnalysis(result.analysis),
      rawAnalysis: result.analysis,
    };
  }

  private async getHealthSummary(horse: any): Promise<any> {
    return {
      etatGeneral: horse.healthStatus,
      dernierControle: horse.lastVetCheck,
      vaccinations: horse.vaccinations,
      alertes: horse.healthStatus !== 'healthy' ? ['Suivi recommandé'] : [],
      rappels: this.getUpcomingReminders(horse),
    };
  }

  private async getHealthDetailed(horse: any): Promise<any> {
    const prompt = `
Bilan de santé détaillé pour ${horse.name}:

DONNÉES:
- État déclaré: ${horse.healthStatus}
- Âge: ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : '?'} ans
- Discipline: ${(horse.disciplines as string[])?.join(', ') || 'Non précisé'}
- Historique: ${horse.healthRecords?.map((r: any) => `${r.type}: ${r.title}`).join(', ') || 'Aucun'}

Fournis:
1. Synthèse état de santé
2. Points de vigilance
3. Risques par rapport à la discipline
4. Planning vétérinaire recommandé
5. Conseils prévention
`;
    const result = await this.anthropic.analyze(prompt, 'health');
    return {
      synthese: result.analysis,
      recommandations: result.recommendations,
    };
  }

  private async getHealthComplete(horse: any): Promise<any> {
    const prompt = `
Dossier médical complet avec analyse prédictive pour ${horse.name}:

Fournis:
1. Bilan complet par système (locomoteur, respiratoire, digestif, etc.)
2. Analyse de l'historique médical
3. Facteurs de risque identifiés
4. Probabilités de pathologies futures
5. Plan de prévention personnalisé
6. Planning examens sur 12 mois
`;
    const result = await this.anthropic.analyze(prompt, 'health');
    return {
      dossierComplet: result.analysis,
      planPrevention: result.recommendations,
    };
  }

  private async generateTrainingPlan(
    horse: any,
    data: PackageInputData,
    weeks: number
  ): Promise<TrainingPlan> {
    const discipline = data.discipline || (horse.disciplines as string[])?.[0] || 'CSO';
    const level = data.level || horse.level || 'club';
    const objective = data.objective || 'Progression générale';

    const prompt = `
PLAN D'ENTRAÎNEMENT ${weeks} SEMAINES

CHEVAL: ${horse.name}
- Âge: ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : '?'} ans
- Discipline: ${discipline}
- Niveau actuel: ${level}
- Objectif: ${objective}

CONTRAINTES:
- Jours d'entraînement: ${data.trainingDaysPerWeek || 5}/semaine
- Compétition prévue: ${data.nextCompetition || 'Non définie'}

Génère un plan détaillé en JSON:
{
  "objectifGlobal": "...",
  "semaines": [
    {
      "numero": 1,
      "theme": "...",
      "intensite": "légère|modérée|intense",
      "seances": [
        {
          "jour": "Lundi",
          "type": "Plat|Obstacle|Dressage|Récup|Repos",
          "duree": 45,
          "exercices": [
            { "nom": "...", "duree": 10, "description": "...", "objectif": "..." }
          ],
          "points_cles": ["...", "..."]
        }
      ],
      "conseil_semaine": "..."
    }
  ],
  "progressionAttendue": "...",
  "signesAlerte": ["...", "..."],
  "ajustements": "..."
}
`;

    const result = await this.anthropic.analyze(prompt, 'general');
    const parsed = this.parseJsonFromAnalysis(result.analysis);

    return {
      discipline,
      level,
      objective,
      durationWeeks: weeks,
      plan: parsed,
      generatedAt: new Date(),
    };
  }

  private async generatePeriodization(horse: any, data: PackageInputData): Promise<any> {
    const prompt = `
PÉRIODISATION ANNUELLE - ${horse.name}

Données:
- Discipline: ${(horse.disciplines as string[])?.[0] || 'CSO'}
- Niveau: ${horse.level || 'Amateur'}
- Âge: ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : '?'} ans
- Objectifs saison: ${data.seasonObjectives || 'Progression niveau supérieur'}
- Compétitions cibles: ${data.targetCompetitions || 'À définir'}

Génère une périodisation complète:
1. Macrocycles (préparation générale, spécifique, compétition, transition)
2. Mésocycles par mois
3. Points de forme ciblés
4. Volumes d'entraînement
5. Tests de validation
6. Périodes de repos programmées
`;

    const result = await this.anthropic.analyze(prompt, 'general');
    return {
      planAnnuel: result.analysis,
      recommandations: result.recommendations,
    };
  }

  private async generateNutritionBasic(horse: any, data: PackageInputData): Promise<NutritionPlan> {
    const prompt = `
Conseils nutrition de base pour ${horse.name}:
- Poids estimé: ${horse.weightKg || 500} kg
- Activité: ${horse.level || 'modérée'}
- Discipline: ${(horse.disciplines as string[])?.[0] || 'Loisir'}

Fournis:
{
  "besoinsJournaliers": {
    "foin": "kg/jour",
    "concentres": "kg/jour",
    "eau": "litres/jour"
  },
  "rationType": {
    "matin": "...",
    "midi": "...",
    "soir": "..."
  },
  "complementsRecommandes": ["...", "..."],
  "erreursCourantes": ["...", "..."]
}
`;
    const result = await this.anthropic.analyze(prompt, 'general');
    return {
      type: 'basic',
      plan: this.parseJsonFromAnalysis(result.analysis),
      generatedAt: new Date(),
    };
  }

  private async generateNutritionFull(horse: any, data: PackageInputData): Promise<NutritionPlan> {
    const prompt = `
Plan nutritionnel complet pour ${horse.name}:

Données:
- Poids: ${horse.weightKg || 500} kg
- Taille: ${horse.heightCm || 165} cm
- Âge: ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : 8} ans
- Discipline: ${(horse.disciplines as string[])?.[0] || 'CSO'}
- Niveau: ${horse.level || 'Amateur'}
- État corporel actuel: ${data.bodyConditionScore || '5/9'}
- Problèmes connus: ${data.healthIssues || 'Aucun'}

Génère en JSON:
{
  "evaluation": {
    "poidsIdeal": 520,
    "etatActuel": "correct",
    "objectif": "maintien"
  },
  "rationJournaliere": {
    "fourrage": {
      "type": "Foin de prairie",
      "quantite": "10-12 kg",
      "qualite": "1ère coupe, bien séché",
      "repartition": "Matin 4kg, Midi 3kg, Soir 5kg"
    },
    "concentres": {
      "type": "Granulés sport",
      "quantite": "3-4 kg",
      "marqueRecommandee": "...",
      "repartition": "..."
    },
    "complements": [
      { "nom": "CMV", "dose": "50g/jour", "raison": "..." }
    ]
  },
  "ajustementsSaisonniers": {
    "hiver": "...",
    "ete": "..."
  },
  "hydratation": {
    "minimum": "30-40 litres/jour",
    "electrolytes": "En période chaude ou effort"
  },
  "erreurAEviter": ["...", "..."],
  "signesCarence": ["...", "..."]
}
`;
    const result = await this.anthropic.analyze(prompt, 'health');
    return {
      type: 'full',
      plan: this.parseJsonFromAnalysis(result.analysis),
      generatedAt: new Date(),
    };
  }

  private async generateNutritionPerformance(
    horse: any,
    data: PackageInputData
  ): Promise<NutritionPlan> {
    const prompt = `
Nutrition PERFORMANCE pour ${horse.name} - Niveau ${horse.level || 'Pro'}

Objectif: Optimiser la performance sportive en ${(horse.disciplines as string[])?.[0] || 'CSO'}

Génère un plan incluant:
1. Ration de base optimisée
2. Ajustements J-7 avant compétition
3. Nutrition jour de compétition (avant, pendant, après)
4. Récupération post-effort
5. Supplémentation légale performance
6. Périodisation nutritionnelle selon entraînement
7. Gestion du poids de forme
8. Protocoles spéciaux (chaleur, altitude, transport)
`;
    const result = await this.anthropic.analyze(prompt, 'health');
    return {
      type: 'performance',
      plan: result.analysis,
      recommendations: result.recommendations,
      generatedAt: new Date(),
    };
  }

  private async assessMental(horse: any, data: PackageInputData): Promise<any> {
    const prompt = `
Évaluation comportementale pour ${horse.name}:

Contexte:
- Discipline: ${(horse.disciplines as string[])?.[0] || 'CSO'}
- Niveau: ${horse.level || 'Amateur'}
- Notes comportement: ${data.behaviorNotes || 'Non renseigné'}

Évalue:
1. Tempérament général (sang-froid, réactivité)
2. Sensibilité aux aides
3. Gestion du stress/nouveauté
4. Motivation au travail
5. Relations avec humains/congénères
6. Points à travailler
7. Techniques de gestion recommandées
`;
    const result = await this.anthropic.analyze(prompt, 'general');
    return {
      evaluation: result.analysis,
      recommandations: result.recommendations,
    };
  }

  private async generateMentalProgram(horse: any, data: PackageInputData): Promise<any> {
    const prompt = `
Programme de travail mental complet pour ${horse.name}:

Problématiques identifiées: ${data.mentalIssues || 'Gestion du stress en compétition'}

Génère:
1. Analyse du profil psychologique
2. Programme de désensibilisation
3. Exercices de confiance
4. Routine de préparation mentale
5. Gestion des situations stressantes
6. Suivi sur 8 semaines
`;
    const result = await this.anthropic.analyze(prompt, 'general');
    return {
      programme: result.analysis,
      exercices: result.recommendations,
    };
  }

  private async generateCompetitionPrep(horse: any, data: PackageInputData): Promise<any> {
    const competition = data.competitionDetails || {
      name: 'Prochaine compétition',
      date: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
      discipline: (horse.disciplines as string[])?.[0] || 'CSO',
      level: horse.level || 'Amateur',
    };

    const prompt = `
Préparation compétition pour ${horse.name}:
- Compétition: ${competition.name}
- Date: ${competition.date}
- Discipline: ${competition.discipline}
- Niveau: ${competition.level}

Génère:
1. Planning semaine avant
2. Checklist matériel
3. Protocole d'échauffement
4. Gestion du stress (cheval + cavalier)
5. Plan de reconnaissance
6. Récupération post-compétition
`;
    const result = await this.anthropic.analyze(prompt, 'general');
    return {
      preparation: result.analysis,
      checklist: result.recommendations,
    };
  }

  private async generateCompetitionStrategy(horse: any, data: PackageInputData): Promise<any> {
    const prompt = `
Stratégie compétition saison pour ${horse.name}:

Données:
- Niveau actuel: ${horse.level || 'Amateur 2'}
- Objectif saison: ${data.seasonObjective || 'Passage Amateur 1'}
- Points forts: ${data.strengths || 'À déterminer'}
- Points faibles: ${data.weaknesses || 'À déterminer'}

Génère:
1. Calendrier optimisé de compétitions
2. Objectifs par compétition
3. Préparation spécifique
4. Analyse concurrents type
5. Stratégie de points/classement
6. Plan B en cas de contre-performance
`;
    const result = await this.anthropic.analyze(prompt, 'general');
    return {
      strategie: result.analysis,
      calendrier: result.recommendations,
    };
  }

  private async assessBreeding(horse: any): Promise<any> {
    const prompt = `
Évaluation breeding pour ${horse.name}:

Données:
- Studbook: ${horse.studbook}
- Père: ${horse.sireName || 'Inconnu'}
- Mère: ${horse.damName || 'Inconnu'}
- Performances: ${horse.competitionResults?.length || 0} compétitions
- Niveau max: ${horse.level || 'Non précisé'}

Analyse:
1. Valeur génétique estimée
2. Points forts à transmettre
3. Points faibles potentiels
4. Compatibilités recommandées
5. Étalons/Juments suggérés
6. Potentiel des produits
`;
    const result = await this.anthropic.analyze(prompt, 'breeding_match');
    return {
      evaluation: result.analysis,
      recommandations: result.recommendations,
    };
  }

  private async assessCareerPotential(horse: any): Promise<any> {
    const age = horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : null;

    const prompt = `
Évaluation potentiel de carrière pour ${horse.name}:

Données:
- Âge: ${age || '?'} ans
- Race: ${horse.studbook || horse.breed}
- Niveau actuel: ${horse.level || 'Débutant'}
- Disciplines pratiquées: ${(horse.disciplines as string[])?.join(', ') || 'Non précisé'}
- Résultats: ${horse.competitionResults?.length || 0} compétitions

Analyse:
1. Niveau actuel objectif
2. Potentiel maximum estimé
3. Disciplines les plus adaptées
4. Timeline de progression
5. Facteurs limitants
6. Recommandations de développement
`;
    const result = await this.anthropic.analyze(prompt, 'general');
    return {
      potentiel: result.analysis,
      recommandations: result.recommendations,
    };
  }

  private async generateCareerPlan(horse: any, data: PackageInputData): Promise<any> {
    const prompt = `
Plan de carrière complet pour ${horse.name}:

Horizon: ${data.careerHorizon || '5 ans'}
Objectif ultime: ${data.ultimateGoal || 'Niveau Pro'}

Génère:
1. Objectifs par année
2. Étapes de progression
3. Compétitions cibles par saison
4. Formation continue (stages, etc.)
5. Planification reconversion
6. Budget prévisionnel
`;
    const result = await this.anthropic.analyze(prompt, 'general');
    return {
      planCarriere: result.analysis,
      etapes: result.recommendations,
    };
  }

  private async estimateValue(horse: any): Promise<any> {
    const prompt = `
Estimation valeur EquiCote pour ${horse.name}:

Données:
- Race: ${horse.studbook || horse.breed}
- Âge: ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : '?'} ans
- Niveau: ${horse.level || 'Non précisé'}
- Résultats: ${horse.competitionResults?.length || 0} compétitions
- État: ${horse.healthStatus}
- Origines: ${horse.sireName || 'Inconnu'} x ${horse.damName || 'Inconnu'}

Fournis:
{
  "estimationBasse": 15000,
  "estimationHaute": 25000,
  "estimationMoyenne": 20000,
  "facteurs": {
    "age": { "impact": "+10%", "raison": "..." },
    "niveau": { "impact": "+20%", "raison": "..." },
    "origines": { "impact": "+5%", "raison": "..." }
  },
  "tendanceMarche": "stable",
  "conseilVente": "..."
}
`;
    const result = await this.anthropic.analyze(prompt, 'valuation');
    return this.parseJsonFromAnalysis(result.analysis);
  }

  private async analyzeConformation(horse: any, data: PackageInputData): Promise<any> {
    const prompt = `
Analyse conformation pour ${horse.name}:

Données:
- Race: ${horse.studbook || horse.breed}
- Taille: ${horse.heightCm ? horse.heightCm + ' cm' : 'Non mesurée'}
- Discipline: ${(horse.disciplines as string[])?.[0] || 'Polyvalent'}

Analyse:
1. Modèle général
2. Avant-main (tête, encolure, épaules)
3. Corps (dos, rein, côtes)
4. Arrière-main (croupe, cuisses, jarrets)
5. Membres et aplombs
6. Pieds
7. Adéquation avec la discipline
8. Points forts/faibles morphologiques
`;
    const result = await this.anthropic.analyze(prompt, 'general');
    return {
      analyse: result.analysis,
      pointsCles: result.recommendations,
    };
  }

  // ==================== HELPER METHODS ====================

  private parseJsonFromAnalysis(analysis: string): any {
    try {
      const jsonMatch = analysis.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch {
      // Return as text if not JSON
    }
    return { rawAnalysis: analysis };
  }

  private getUpcomingReminders(horse: any): string[] {
    const reminders: string[] = [];
    // Logic to check vaccination dates, etc.
    return reminders;
  }

  private async generatePackageSummary(
    horse: any,
    pkg: Package,
    results: Record<string, any>
  ): Promise<string> {
    const summaryPrompt = `
Résume les résultats du package ${pkg.name} pour ${horse.name}:

${Object.entries(results)
  .map(([k, v]) => `${k}: ${JSON.stringify(v).slice(0, 200)}`)
  .join('\n')}

Fournis un résumé exécutif de 3-4 phrases.
`;
    const result = await this.anthropic.analyze(summaryPrompt, 'general');
    return result.analysis;
  }

  private aggregateRecommendations(results: Record<string, any>): string[] {
    const allRecs: string[] = [];
    for (const result of Object.values(results)) {
      if (result?.recommandations) allRecs.push(...result.recommandations);
      if (result?.recommendations) allRecs.push(...result.recommendations);
    }
    return [...new Set(allRecs)].slice(0, 15);
  }
}

// ==================== TYPE DEFINITIONS ====================

interface Package {
  id: string;
  name: string;
  description: string;
  tokens: number;
  color: string;
  includes: string[];
  features: string[];
  deliveryTime: string;
}

interface Module {
  id: string;
  name: string;
  category: string;
  tokens: number;
  description: string;
  outputs: string[];
}

interface PackageInputData {
  videoFrames?: string[];
  images?: string[];
  discipline?: string;
  level?: string;
  objective?: string;
  context?: string;
  surface?: string;
  allure?: string;
  trainingDaysPerWeek?: number;
  nextCompetition?: string;
  seasonObjectives?: string;
  targetCompetitions?: string;
  bodyConditionScore?: string;
  healthIssues?: string;
  behaviorNotes?: string;
  mentalIssues?: string;
  competitionDetails?: any;
  seasonObjective?: string;
  strengths?: string;
  weaknesses?: string;
  careerHorizon?: string;
  ultimateGoal?: string;
}

interface PackageResult {
  packageId: string;
  packageName: string;
  horseId: string;
  horseName: string;
  tokensConsumed: number;
  moduleResults: Record<string, any>;
  summary: string;
  recommendations: string[];
  generatedAt: Date;
}

interface CustomAnalysisResult {
  horseId: string;
  horseName: string;
  modulesExecuted: string[];
  tokensConsumed: number;
  breakdown: { id: string; tokens: number }[];
  moduleResults: Record<string, any>;
  recommendations: string[];
  generatedAt: Date;
}

interface TrainingPlan {
  discipline: string;
  level: string;
  objective: string;
  durationWeeks: number;
  plan: any;
  generatedAt: Date;
}

interface NutritionPlan {
  type: 'basic' | 'full' | 'performance';
  plan: any;
  recommendations?: string[];
  generatedAt: Date;
}
