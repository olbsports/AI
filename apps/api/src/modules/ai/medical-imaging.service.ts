import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnthropicService } from './anthropic.service';

/**
 * Medical Imaging Analysis Service
 *
 * AI-powered analysis for equine medical imaging
 * including radiographs, ultrasounds, and other diagnostic images
 */
@Injectable()
export class MedicalImagingService {
  private readonly logger = new Logger(MedicalImagingService.name);

  // Radiograph regions and common findings
  private readonly RADIOGRAPH_REGIONS: Record<string, RadiographRegion> = {
    pied: {
      name: 'Pied (Sabot)',
      views: ['latéro-médiale', 'dorso-palmaire', 'oblique'],
      commonFindings: [
        'Maladie naviculaire',
        'Ostéophytes (arthrose)',
        'Kéraphyllocèle',
        'Fracture phalange',
        'OCD (ostéochondrite)',
        'Fourbure (rotation P3)',
        'Sidebones',
      ],
      criticalAreas: [
        'Os naviculaire',
        'P3 (phalange distale)',
        'Articulation interphalangienne distale',
      ],
    },
    boulet: {
      name: 'Boulet (Métacarpo/tarso-phalangienne)',
      views: ['latéro-médiale', 'dorso-palmaire', 'obliques', 'flexion'],
      commonFindings: [
        'OCD',
        'Arthrose',
        'Fragments ostéochondraux',
        'Sésamoïdite',
        'Fractures de sésamoïdes',
        'Prolifération osseuse',
      ],
      criticalAreas: ['Condyles métacarpiens', 'Sésamoïdes proximaux', 'P1'],
    },
    canon: {
      name: 'Canon (Métacarpe/Métatarse)',
      views: ['latéro-médiale', 'dorso-palmaire'],
      commonFindings: [
        'Suros (exostose)',
        'Fracture de fatigue',
        'Périostite',
        'Fracture métacarpien rudimentaire',
      ],
      criticalAreas: ['MC3/MT3', 'MC2-MC4 (rudimentaires)', 'Ligament suspenseur'],
    },
    jarret: {
      name: 'Jarret (Tarse)',
      views: ['latéro-médiale', 'dorso-plantaire', 'obliques'],
      commonFindings: ['Éparvin', 'OCD', 'Bog spavin', 'Arthrose tarsienne', 'Fracture malléole'],
      criticalAreas: ['Articulation tibio-tarsienne', 'Petits os du tarse', 'Calcanéum'],
    },
    grasset: {
      name: 'Grasset (Genou)',
      views: ['latéro-médiale', 'caudo-crâniale'],
      commonFindings: [
        'OCD (trochlée fémorale)',
        'Kyste sous-chondral',
        'Accrochement rotule',
        'Fragmentation',
      ],
      criticalAreas: ['Trochlée fémorale', 'Rotule', 'Plateau tibial'],
    },
    dos: {
      name: 'Dos (Rachis)',
      views: ['latérale', 'oblique'],
      commonFindings: [
        'Kissing spines',
        'Spondylose',
        'Arthrose facettes',
        'Fracture processus épineux',
      ],
      criticalAreas: ['Processus épineux', 'Corps vertébraux', 'Facettes articulaires'],
    },
    encolure: {
      name: 'Encolure (Cervicales)',
      views: ['latérale', 'oblique'],
      commonFindings: [
        'Arthrose cervicale',
        'Malformation vertébrale',
        'Wobbler syndrome',
        'OCD cervicale',
      ],
      criticalAreas: ['C3-C7', 'Articulations cervicales', 'Canal médullaire'],
    },
  };

  // Ultrasound regions
  private readonly ULTRASOUND_REGIONS: Record<string, UltrasoundRegion> = {
    tendons_anterieurs: {
      name: 'Tendons antérieurs',
      structures: [
        'Tendon fléchisseur superficiel (TFSD)',
        'Tendon fléchisseur profond (TFDP)',
        'Ligament suspenseur du boulet (LSB)',
        'Bride carpienne',
        'Ligament annulaire',
      ],
      commonFindings: [
        'Tendinite TFSD',
        'Desmite LSB (corps/branches)',
        'Lésion TFDP',
        'Ténosynovite',
        'Adhérences',
      ],
      zones: ['Zone 1A-1B (sous le genou)', 'Zone 2A-2B (canon)', 'Zone 3A-3B-3C (paturon)'],
    },
    tendons_posterieurs: {
      name: 'Tendons postérieurs',
      structures: [
        'Tendon fléchisseur superficiel (TFSD)',
        'Tendon fléchisseur profond (TFDP)',
        'Ligament suspenseur du boulet (LSB)',
        'Branches du LSB',
      ],
      commonFindings: [
        'Desmite LSB postérieur',
        'Tendinite',
        'Lésions des branches',
        'Ténosynovite',
      ],
      zones: ['Zone 1 (sous jarret)', 'Zone 2 (canon)', 'Zone 3 (paturon)'],
    },
    articulations: {
      name: 'Articulations',
      structures: [
        'Capsule articulaire',
        'Membrane synoviale',
        'Cartilage articulaire',
        'Ligaments collatéraux',
      ],
      commonFindings: [
        'Synovite',
        'Épaississement capsulaire',
        'Effusion articulaire',
        'Lésion ligamentaire',
      ],
    },
    reproduction: {
      name: 'Appareil reproducteur',
      structures: [
        'Ovaires',
        'Utérus',
        'Vésicules séminales (étalon)',
        'Follicules',
        'Corps jaune',
      ],
      commonFindings: [
        'Follicule pré-ovulatoire',
        'Gestation',
        'Kyste ovarien',
        'Endométrite',
        'Liquide utérin',
      ],
    },
  };

  // Classification des lésions tendineuses
  private readonly TENDON_LESION_GRADES = {
    0: 'Normal - Pas de lésion visible',
    1: "Légère - Perte <25% échogénicité, pas d'augmentation volume",
    2: 'Modérée - Perte 25-50% échogénicité, légère augmentation volume',
    3: 'Sévère - Perte >50% échogénicité, augmentation volume marquée',
    4: 'Très sévère - Zone anéchogène (rupture partielle)',
  };

  constructor(
    private prisma: PrismaService,
    private anthropic: AnthropicService
  ) {}

  /**
   * Analyze radiograph (X-ray)
   */
  async analyzeRadiograph(params: {
    horseId: string;
    images: string[]; // Base64 images
    region: string;
    view?: string;
    context: 'achat' | 'suivi' | 'urgence' | 'performance';
    clinicalHistory?: string;
    suspectedCondition?: string;
  }): Promise<RadiographAnalysisResult> {
    this.logger.log(`Analyzing radiograph of ${params.region} for horse ${params.horseId}`);

    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        healthRecords: {
          where: { type: { in: ['radiograph', 'vet_check', 'injury'] } },
          orderBy: { date: 'desc' },
          take: 10,
        },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const regionInfo = this.RADIOGRAPH_REGIONS[params.region];
    if (!regionInfo) {
      throw new Error(`Unknown radiograph region: ${params.region}`);
    }

    // Analyze each image
    const imageAnalyses = await Promise.all(
      params.images.map(async (image, idx) => {
        const prompt = `
ANALYSE RADIOGRAPHIQUE ÉQUINE

Image ${idx + 1}/${params.images.length}
Région: ${regionInfo.name}
Vue: ${params.view || 'Non précisée'}

CHEVAL:
- Nom: ${horse.name}
- Âge: ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : 'Inconnu'} ans
- Discipline: ${(horse.disciplines as string[])?.join(', ') || 'Non précisé'}
- Niveau: ${horse.level || 'Non précisé'}

CONTEXTE: ${params.context}
${params.clinicalHistory ? `HISTORIQUE CLINIQUE: ${params.clinicalHistory}` : ''}
${params.suspectedCondition ? `SUSPICION CLINIQUE: ${params.suspectedCondition}` : ''}

ZONES CRITIQUES À EXAMINER:
${regionInfo.criticalAreas.map((a) => `- ${a}`).join('\n')}

LÉSIONS COURANTES À RECHERCHER:
${regionInfo.commonFindings.map((f) => `- ${f}`).join('\n')}

ANALYSE DEMANDÉE:
1. Qualité technique de l'image (positionnement, exposition)
2. Structures osseuses visibles - état général
3. Espaces articulaires
4. Tissus mous radio-opaques
5. Anomalies détectées (localisation précise)
6. Classification gravité (0-4)
7. Signification clinique

Format JSON:
{
  "qualiteTechnique": { "score": 85, "commentaire": "..." },
  "structuresNormales": ["...", "..."],
  "anomaliesDetectees": [
    {
      "type": "Nom de l'anomalie",
      "localisation": "...",
      "severite": 2,
      "description": "...",
      "significationClinique": "..."
    }
  ],
  "interpretationGlobale": "...",
  "pronostic": {
    "sportif": "favorable|réservé|défavorable",
    "explication": "..."
  },
  "recommandations": ["...", "..."],
  "examensComplementaires": ["...", "..."]
}
`;

        return this.anthropic.analyzeImage(image, prompt, { type: 'general' });
      })
    );

    // Synthesize findings
    const synthesisPrompt = `
Synthèse des analyses radiographiques:

${imageAnalyses.map((a, i) => `IMAGE ${i + 1}:\n${a.analysis}`).join('\n\n')}

Fournis une synthèse globale avec:
1. Diagnostic principal
2. Diagnostics différentiels
3. Grade de sévérité global (0-4)
4. Impact sur l'utilisation sportive
5. Traitement recommandé
6. Pronostic à court et long terme
7. Suivi proposé

Pour un contexte de VISITE D'ACHAT (si applicable):
- Classification A/B/C/D/E selon convention
- Points de vigilance pour l'acheteur
`;

    const synthesis = await this.anthropic.analyze(synthesisPrompt, 'health');

    // Parse results
    const findings: RadioFinding[] = [];
    let overallGrade = 0;

    try {
      for (const analysis of imageAnalyses) {
        const jsonMatch = analysis.analysis.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const parsed = JSON.parse(jsonMatch[0]);
          if (parsed.anomaliesDetectees) {
            findings.push(...parsed.anomaliesDetectees);
            const maxSeverity = Math.max(
              ...parsed.anomaliesDetectees.map((a: any) => a.severite || 0)
            );
            overallGrade = Math.max(overallGrade, maxSeverity);
          }
        }
      }
    } catch {
      this.logger.warn('Failed to parse some radiograph analyses');
    }

    // Determine purchase classification if context is 'achat'
    let purchaseClassification: string | undefined;
    if (params.context === 'achat') {
      purchaseClassification = this.getPurchaseClassification(overallGrade, findings);
    }

    return {
      horseId: params.horseId,
      horseName: horse.name,
      region: params.region,
      regionName: regionInfo.name,
      view: params.view,
      context: params.context,
      imageCount: params.images.length,
      findings,
      overallGrade,
      overallGradeDescription: this.getGradeDescription(overallGrade),
      interpretation: synthesis.analysis,
      recommendations: synthesis.recommendations,
      purchaseClassification,
      sportsPrognosis: this.getSportsPrognosis(overallGrade, params.region),
      followUpRecommended: overallGrade >= 2,
      analyzedAt: new Date(),
    };
  }

  /**
   * Analyze ultrasound
   */
  async analyzeUltrasound(params: {
    horseId: string;
    images: string[];
    region: string;
    limb?: 'AG' | 'AD' | 'PG' | 'PD'; // Antérieur/Postérieur Gauche/Droit
    zone?: string;
    context: 'achat' | 'suivi' | 'blessure' | 'controle';
    previousExam?: {
      date: Date;
      findings: string;
    };
  }): Promise<UltrasoundAnalysisResult> {
    this.logger.log(`Analyzing ultrasound of ${params.region} for horse ${params.horseId}`);

    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        healthRecords: {
          where: { type: 'ultrasound' },
          orderBy: { date: 'desc' },
          take: 5,
        },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const regionInfo = this.ULTRASOUND_REGIONS[params.region];
    if (!regionInfo) {
      throw new Error(`Unknown ultrasound region: ${params.region}`);
    }

    const imageAnalyses = await Promise.all(
      params.images.map(async (image, idx) => {
        const prompt = `
ANALYSE ÉCHOGRAPHIQUE ÉQUINE

Image ${idx + 1}/${params.images.length}
Région: ${regionInfo.name}
${params.limb ? `Membre: ${params.limb}` : ''}
${params.zone ? `Zone: ${params.zone}` : ''}

CHEVAL: ${horse.name}, ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : '?'} ans
CONTEXTE: ${params.context}
${params.previousExam ? `EXAMEN PRÉCÉDENT (${params.previousExam.date.toISOString().split('T')[0]}): ${params.previousExam.findings}` : ''}

STRUCTURES À ANALYSER:
${regionInfo.structures.map((s) => `- ${s}`).join('\n')}

LÉSIONS À RECHERCHER:
${regionInfo.commonFindings.map((f) => `- ${f}`).join('\n')}

${regionInfo.zones ? `ZONES D'EXAMEN: ${regionInfo.zones.join(', ')}` : ''}

PARAMÈTRES D'ÉVALUATION:
1. Échogénicité (normale, hypoéchogène, hyperéchogène, anéchogène)
2. Taille/Surface de section (CSA) - mesures en mm²
3. Forme et contours
4. Homogénéité
5. Vascularisation (si Doppler)

CLASSIFICATION DES LÉSIONS TENDINEUSES:
- Grade 0: Normal
- Grade 1: Légère (<25% perte échogénicité)
- Grade 2: Modérée (25-50%)
- Grade 3: Sévère (>50%)
- Grade 4: Très sévère (anéchogène/rupture)

Format JSON:
{
  "qualiteImage": { "score": 85, "plan": "transversal|longitudinal" },
  "structures": [
    {
      "nom": "TFSD",
      "echogenicite": "normale|hypo|hyper|anecho",
      "tailleMm2": 100,
      "homogeneite": "homogène|hétérogène",
      "etat": "normal|anormal",
      "gradeLesion": 0
    }
  ],
  "lesions": [
    {
      "structure": "TFSD",
      "type": "Tendinite",
      "localisation": "Zone 2B médiale",
      "tailleMm": { "longueur": 20, "largeur": 8 },
      "grade": 2,
      "anciennete": "aigue|subaigue|chronique",
      "description": "..."
    }
  ],
  "comparaisonPrecedent": "amélioration|stable|aggravation|NA",
  "interpretation": "...",
  "pronostic": {
    "retourTravail": "4-6 mois",
    "risqueRecidive": "modéré",
    "niveauSportif": "Amateur"
  },
  "protocole": {
    "repos": "3 mois",
    "traitement": ["PRP", "Ondes de choc"],
    "reprise": ["Pas 1 mois", "Trot 2 mois", "Galop 3 mois"]
  }
}
`;

        return this.anthropic.analyzeImage(image, prompt, { type: 'general' });
      })
    );

    // Parse and aggregate findings
    const allLesions: UltrasoundLesion[] = [];
    let structures: StructureAnalysis[] = [];
    let maxGrade = 0;

    for (const analysis of imageAnalyses) {
      try {
        const jsonMatch = analysis.analysis.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const parsed = JSON.parse(jsonMatch[0]);
          if (parsed.lesions) {
            allLesions.push(...parsed.lesions);
            maxGrade = Math.max(maxGrade, ...parsed.lesions.map((l: any) => l.grade || 0));
          }
          if (parsed.structures) {
            structures = parsed.structures;
          }
        }
      } catch {
        // Continue with other images
      }
    }

    // Generate rehabilitation protocol
    const protocol = this.generateRehabProtocol(maxGrade, params.region);

    return {
      horseId: params.horseId,
      horseName: horse.name,
      region: params.region,
      regionName: regionInfo.name,
      limb: params.limb,
      zone: params.zone,
      context: params.context,
      imageCount: params.images.length,
      structures,
      lesions: allLesions,
      maxGrade,
      gradeDescription:
        this.TENDON_LESION_GRADES[maxGrade as keyof typeof this.TENDON_LESION_GRADES],
      interpretation: imageAnalyses[0]?.analysis || 'Analyse non disponible',
      protocol,
      returnToWorkEstimate: this.estimateReturnToWork(maxGrade),
      followUpDate: this.calculateFollowUpDate(maxGrade),
      analyzedAt: new Date(),
    };
  }

  /**
   * Analyze reproduction ultrasound (for breeding)
   */
  async analyzeReproductionUltrasound(params: {
    horseId: string;
    images: string[];
    examType: 'suivi_chaleurs' | 'diagnostic_gestation' | 'suivi_gestation' | 'pathologie';
    cycleDay?: number;
    lastInsemination?: Date;
    protocol?: string;
  }): Promise<ReproductionUltrasoundResult> {
    this.logger.log(`Analyzing reproduction ultrasound for horse ${params.horseId}`);

    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        gestations: {
          orderBy: { breedingDate: 'desc' },
          take: 1,
        },
        breedingRecords: {
          orderBy: { year: 'desc' },
          take: 5,
        },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const daysPostInsemination = params.lastInsemination
      ? Math.floor((Date.now() - params.lastInsemination.getTime()) / (24 * 60 * 60 * 1000))
      : undefined;

    const imageAnalyses = await Promise.all(
      params.images.map(async (image, idx) => {
        let prompt = `
ANALYSE ÉCHOGRAPHIQUE REPRODUCTION ÉQUINE

Image ${idx + 1}/${params.images.length}
Type d'examen: ${params.examType}

JUMENT: ${horse.name}, ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : '?'} ans
${params.cycleDay ? `Jour du cycle: J${params.cycleDay}` : ''}
${daysPostInsemination ? `Jours post-IA: J+${daysPostInsemination}` : ''}
${params.protocol ? `Protocole: ${params.protocol}` : ''}

`;

        switch (params.examType) {
          case 'suivi_chaleurs':
            prompt += `
ÉVALUATION FOLLICULAIRE:
- Nombre de follicules par ovaire
- Taille du follicule dominant (mm)
- Forme du follicule (rond, poire, ovale)
- Échogénicité paroi
- Présence corps jaune
- État utérus (œdème 0-4)
- Présence liquide

OBJECTIF: Déterminer le moment optimal d'insémination

Format JSON:
{
  "ovaireGauche": {
    "follicules": [{ "tailleMm": 35, "forme": "rond", "ovulatoire": true }],
    "corpsJaune": false
  },
  "ovaireDroit": {
    "follicules": [{ "tailleMm": 25, "forme": "ovale", "ovulatoire": false }],
    "corpsJaune": false
  },
  "uterus": {
    "oedeme": 3,
    "liquide": false,
    "aspect": "normal"
  },
  "recommendation": "IA dans 24-48h",
  "folliculeDominant": "OG 35mm",
  "stadeEstime": "fin œstrus",
  "ovulationEstimee": "24-48h"
}
`;
            break;

          case 'diagnostic_gestation':
            prompt += `
DIAGNOSTIC DE GESTATION (J14-J45):
- Présence vésicule embryonnaire
- Taille vésicule (mm)
- Localisation (corne G/D, corps)
- Embryon visible
- Battement cardiaque
- Gestation gémellaire?

Format JSON:
{
  "gestation": true,
  "vesicule": {
    "presente": true,
    "tailleMm": 22,
    "localisation": "corne gauche",
    "forme": "ronde"
  },
  "embryon": {
    "visible": true,
    "tailleMm": 8,
    "battementCardiaque": true,
    "frequenceCardiaque": 180
  },
  "gemellaire": false,
  "viabilite": "normale",
  "stadeEstime": "J25",
  "pronostic": "favorable",
  "prochainControle": "J30"
}
`;
            break;

          case 'suivi_gestation':
            prompt += `
SUIVI DE GESTATION:
- Viabilité fœtale
- Croissance (mesures)
- Liquides fœtaux
- Placenta
- Activité fœtale

Format JSON:
{
  "viabilite": "normale",
  "foetus": {
    "tailleCm": 15,
    "mouvements": true,
    "frequenceCardiaque": 120,
    "position": "normale"
  },
  "liquidesAllantoideAmnitique": "normaux",
  "placenta": "normal",
  "stadeEstime": "4 mois",
  "dateTermeEstimee": "...",
  "anomalies": [],
  "prochainControle": "1 mois"
}
`;
            break;
        }

        return this.anthropic.analyzeImage(image, prompt, { type: 'general' });
      })
    );

    // Parse results
    let parsed: any = {};
    try {
      const jsonMatch = imageAnalyses[0]?.analysis.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        parsed = JSON.parse(jsonMatch[0]);
      }
    } catch {
      this.logger.warn('Failed to parse reproduction ultrasound');
    }

    return {
      horseId: params.horseId,
      horseName: horse.name,
      examType: params.examType,
      cycleDay: params.cycleDay,
      daysPostInsemination,
      findings: parsed,
      interpretation: imageAnalyses[0]?.analysis || 'Analyse non disponible',
      recommendation: parsed.recommendation || parsed.prochainControle || 'Consulter vétérinaire',
      nextExamDate: this.calculateNextReproExam(params.examType, parsed),
      analyzedAt: new Date(),
    };
  }

  // Helper methods

  private getPurchaseClassification(grade: number, findings: RadioFinding[]): string {
    // Convention française de classification radiographique
    if (grade === 0 && findings.length === 0) return 'A - Aucune anomalie';
    if (grade <= 1) return 'B - Anomalies mineures sans incidence prévisible';
    if (grade === 2) return 'C - Anomalies à surveiller';
    if (grade === 3) return 'D - Anomalies significatives, risque accru';
    return 'E - Anomalies sévères, contre-indication sportive';
  }

  private getGradeDescription(grade: number): string {
    const descriptions: Record<number, string> = {
      0: 'Normal - Aucune anomalie détectée',
      1: 'Anomalie légère - Variante anatomique ou changement minime',
      2: 'Anomalie modérée - Surveillance recommandée',
      3: "Anomalie significative - Impact potentiel sur l'utilisation",
      4: 'Anomalie sévère - Risque élevé',
    };
    return descriptions[grade] || 'Non classifié';
  }

  private getSportsPrognosis(grade: number, region: string): SportPrognosis {
    if (grade <= 1) {
      return {
        amateur: 'favorable',
        pro: 'favorable',
        recommendation: 'Utilisation sportive normale possible',
      };
    }
    if (grade === 2) {
      return {
        amateur: 'favorable',
        pro: 'réservé',
        recommendation: 'Surveillance régulière recommandée pour usage intensif',
      };
    }
    if (grade === 3) {
      return {
        amateur: 'réservé',
        pro: 'défavorable',
        recommendation: 'Usage modéré recommandé, éviter efforts intenses',
      };
    }
    return {
      amateur: 'défavorable',
      pro: 'contre-indiqué',
      recommendation: 'Travail sportif déconseillé',
    };
  }

  private generateRehabProtocol(grade: number, region: string): RehabProtocol {
    if (grade <= 1) {
      return {
        restDays: 7,
        phases: [
          { name: 'Repos relatif', duration: '1 semaine', activities: ['Paddock', 'Pas en main'] },
          {
            name: 'Reprise progressive',
            duration: '1 semaine',
            activities: ['Pas monté', 'Trot léger'],
          },
        ],
        treatments: ['Glaçage si nécessaire'],
        followUp: '2 semaines',
      };
    }
    if (grade === 2) {
      return {
        restDays: 30,
        phases: [
          {
            name: 'Repos strict',
            duration: '2 semaines',
            activities: ['Box', 'Pas en main 10min'],
          },
          {
            name: 'Repos modéré',
            duration: '2 semaines',
            activities: ['Paddock restreint', 'Pas en main 20min'],
          },
          { name: 'Reprise', duration: '4 semaines', activities: ['Pas monté', 'Trot progressif'] },
        ],
        treatments: ['Ondes de choc', 'Anti-inflammatoires', 'Bandes de repos'],
        followUp: '1 mois',
      };
    }
    if (grade >= 3) {
      return {
        restDays: 90,
        phases: [
          { name: 'Repos strict', duration: '1 mois', activities: ['Box strict'] },
          { name: 'Mobilisation', duration: '1 mois', activities: ['Pas en main 10min'] },
          {
            name: 'Réhabilitation',
            duration: '2 mois',
            activities: ['Pas progressif', 'Marcheur'],
          },
          {
            name: 'Remise en travail',
            duration: '2 mois',
            activities: ['Trot progressif', 'Travail plat'],
          },
        ],
        treatments: ['PRP/Cellules souches', 'Ondes de choc', 'Ferrure orthopédique'],
        followUp: '1 mois contrôle écho',
      };
    }
    return { restDays: 0, phases: [], treatments: [], followUp: '' };
  }

  private estimateReturnToWork(grade: number): string {
    switch (grade) {
      case 0:
        return 'Immédiat';
      case 1:
        return '2-4 semaines';
      case 2:
        return '2-3 mois';
      case 3:
        return '4-6 mois';
      case 4:
        return '6-12 mois ou carrière compromise';
      default:
        return 'À évaluer';
    }
  }

  private calculateFollowUpDate(grade: number): Date {
    const days = grade === 0 ? 180 : grade === 1 ? 90 : grade === 2 ? 30 : 14;
    return new Date(Date.now() + days * 24 * 60 * 60 * 1000);
  }

  private calculateNextReproExam(examType: string, findings: any): Date {
    switch (examType) {
      case 'suivi_chaleurs':
        return new Date(
          Date.now() + (findings.ovulationEstimee?.includes('24') ? 1 : 2) * 24 * 60 * 60 * 1000
        );
      case 'diagnostic_gestation':
        return new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
      case 'suivi_gestation':
        return new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      default:
        return new Date(Date.now() + 14 * 24 * 60 * 60 * 1000);
    }
  }
}

// Type definitions
interface RadiographRegion {
  name: string;
  views: string[];
  commonFindings: string[];
  criticalAreas: string[];
}

interface UltrasoundRegion {
  name: string;
  structures: string[];
  commonFindings: string[];
  zones?: string[];
}

interface RadioFinding {
  type: string;
  localisation: string;
  severite: number;
  description: string;
  significationClinique: string;
}

interface SportPrognosis {
  amateur: 'favorable' | 'réservé' | 'défavorable';
  pro: 'favorable' | 'réservé' | 'défavorable' | 'contre-indiqué';
  recommendation: string;
}

interface RehabProtocol {
  restDays: number;
  phases: { name: string; duration: string; activities: string[] }[];
  treatments: string[];
  followUp: string;
}

interface UltrasoundLesion {
  structure: string;
  type: string;
  localisation: string;
  tailleMm?: { longueur: number; largeur: number };
  grade: number;
  anciennete: string;
  description: string;
}

interface StructureAnalysis {
  nom: string;
  echogenicite: string;
  tailleMm2?: number;
  homogeneite: string;
  etat: string;
  gradeLesion: number;
}

export interface RadiographAnalysisResult {
  horseId: string;
  horseName: string;
  region: string;
  regionName: string;
  view?: string;
  context: string;
  imageCount: number;
  findings: RadioFinding[];
  overallGrade: number;
  overallGradeDescription: string;
  interpretation: string;
  recommendations: string[];
  purchaseClassification?: string;
  sportsPrognosis: SportPrognosis;
  followUpRecommended: boolean;
  analyzedAt: Date;
}

export interface UltrasoundAnalysisResult {
  horseId: string;
  horseName: string;
  region: string;
  regionName: string;
  limb?: string;
  zone?: string;
  context: string;
  imageCount: number;
  structures: StructureAnalysis[];
  lesions: UltrasoundLesion[];
  maxGrade: number;
  gradeDescription: string;
  interpretation: string;
  protocol: RehabProtocol;
  returnToWorkEstimate: string;
  followUpDate: Date;
  analyzedAt: Date;
}

export interface ReproductionUltrasoundResult {
  horseId: string;
  horseName: string;
  examType: string;
  cycleDay?: number;
  daysPostInsemination?: number;
  findings: any;
  interpretation: string;
  recommendation: string;
  nextExamDate: Date;
  analyzedAt: Date;
}
