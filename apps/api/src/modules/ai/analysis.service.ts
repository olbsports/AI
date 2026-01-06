import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AnthropicService } from './anthropic.service';

/**
 * AI Analysis Service
 *
 * High-level analysis operations combining
 * AI capabilities with domain knowledge
 */
@Injectable()
export class AIAnalysisService {
  private readonly logger = new Logger(AIAnalysisService.name);

  constructor(
    private prisma: PrismaService,
    private anthropic: AnthropicService,
  ) {}

  /**
   * Analyze horse video for performance assessment
   */
  async analyzePerformanceVideo(params: {
    horseId: string;
    videoFrames: string[]; // Base64 encoded frames
    context?: {
      discipline: string;
      level: string;
      competitionName?: string;
    };
  }): Promise<PerformanceAnalysis> {
    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    // Analyze key frames
    const frameAnalyses = await Promise.all(
      params.videoFrames.slice(0, 5).map(async (frame, idx) => {
        const result = await this.anthropic.analyzeImage(frame, `
Analyse l'image ${idx + 1} de cette séquence.
Cheval: ${horse.name}
${params.context?.discipline ? `Discipline: ${params.context.discipline}` : ''}
${params.context?.level ? `Niveau: ${params.context.level}` : ''}

Observe:
- La position du cheval
- L'attitude du couple cavalier/cheval
- La qualité du geste technique
`, { type: 'locomotion' });
        return result;
      }),
    );

    // Synthesize analysis
    const synthPrompt = `
Synthétise les analyses suivantes d'une vidéo équestre:

${frameAnalyses.map((a, i) => `Frame ${i + 1}: ${a.analysis}`).join('\n\n')}

Fournis:
1. Un score global sur 100
2. Points forts
3. Points à améliorer
4. Recommandations d'entraînement

Format JSON:
{
  "globalScore": 75,
  "horseScore": 78,
  "techniqueScore": 72,
  "strengths": ["...", "..."],
  "improvements": ["...", "..."],
  "recommendations": ["...", "..."],
  "summary": "..."
}`;

    const synthesis = await this.anthropic.analyze(synthPrompt, 'general', {
      useCache: false,
    });

    // Parse synthesis
    let parsed: any = {};
    try {
      const jsonMatch = synthesis.analysis.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        parsed = JSON.parse(jsonMatch[0]);
      }
    } catch {
      this.logger.warn('Failed to parse synthesis');
    }

    return {
      horseId: params.horseId,
      horseName: horse.name,
      globalScore: parsed.globalScore || 70,
      horseScore: parsed.horseScore || 70,
      techniqueScore: parsed.techniqueScore || 70,
      strengths: parsed.strengths || [],
      improvements: parsed.improvements || [],
      recommendations: parsed.recommendations || synthesis.recommendations,
      summary: parsed.summary || synthesis.analysis,
      frameAnalyses: frameAnalyses.map(a => a.analysis),
      analyzedAt: new Date(),
    };
  }

  /**
   * Generate breeding compatibility report
   */
  async analyzeBreedingCompatibility(params: {
    mareId: string;
    stallionId: string;
    targetDisciplines?: string[];
  }): Promise<BreedingCompatibilityReport> {
    const [mare, stallion] = await Promise.all([
      this.prisma.horse.findUnique({
        where: { id: params.mareId },
        include: {
          competitionResults: { take: 10 },
          breedingRecords: true,
        },
      }),
      this.prisma.horse.findUnique({
        where: { id: params.stallionId },
        include: {
          competitionResults: { take: 10 },
          breedingRecords: true,
        },
      }),
    ]);

    if (!mare || !stallion) {
      throw new Error('Mare or stallion not found');
    }

    const prompt = `
Analyse la compatibilité pour l'accouplement:

JUMENT:
- Nom: ${mare.name}
- Studbook: ${mare.studbook}
- Année de naissance: ${mare.birthDate?.getFullYear()}
- Père: ${mare.sireName || 'Inconnu'}
- Mère: ${mare.damName || 'Inconnu'}
- Niveau: ${mare.level || 'Non précisé'}
- Résultats: ${mare.competitionResults.length} compétitions

ÉTALON:
- Nom: ${stallion.name}
- Studbook: ${stallion.studbook}
- Année de naissance: ${stallion.birthDate?.getFullYear()}
- Père: ${stallion.sireName || 'Inconnu'}
- Mère: ${stallion.damName || 'Inconnu'}
- Niveau: ${stallion.level || 'Non précisé'}
- Produits: ${stallion.breedingRecords.length} enregistrements

OBJECTIFS: ${params.targetDisciplines?.join(', ') || 'Non précisé'}

Analyse:
1. Compatibilité des origines (consanguinité potentielle)
2. Complémentarité des modèles
3. Potentiel sportif des produits
4. Recommandations
`;

    const analysis = await this.anthropic.analyze(prompt, 'breeding_match');

    return {
      mareId: mare.id,
      mareName: mare.name,
      stallionId: stallion.id,
      stallionName: stallion.name,
      compatibilityScore: analysis.confidence || 70,
      analysis: analysis.analysis,
      strengths: analysis.recommendations.filter((_, i) => i < 3),
      weaknesses: [],
      recommendations: analysis.recommendations,
      predictedOffspring: {
        disciplines: params.targetDisciplines || [],
        potentialLevel: 'Amateur',
      },
      analyzedAt: new Date(),
    };
  }

  /**
   * Generate health summary from records
   */
  async generateHealthSummary(horseId: string): Promise<HealthSummary> {
    const horse = await this.prisma.horse.findUnique({
      where: { id: horseId },
      include: {
        healthRecords: {
          orderBy: { date: 'desc' },
          take: 20,
        },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const recordsSummary = horse.healthRecords.map(r =>
      `${r.date.toISOString().split('T')[0]} - ${r.type}: ${r.title}${r.description ? ` (${r.description})` : ''}`
    ).join('\n');

    const prompt = `
Analyse le dossier de santé de ce cheval:

CHEVAL:
- Nom: ${horse.name}
- Âge: ${horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : 'Inconnu'} ans
- État actuel déclaré: ${horse.healthStatus}

HISTORIQUE DE SANTÉ:
${recordsSummary || 'Aucun enregistrement'}

Fournis:
1. Résumé de l'état de santé général
2. Points de vigilance
3. Rappels à planifier (vaccins, vermifuges, etc.)
4. Recommandations
`;

    const analysis = await this.anthropic.analyze(prompt, 'health');

    // Extract upcoming reminders
    const upcomingReminders = await this.prisma.healthRecord.findMany({
      where: {
        horseId,
        nextDueDate: {
          gte: new Date(),
          lte: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // Next 90 days
        },
      },
      orderBy: { nextDueDate: 'asc' },
    });

    return {
      horseId,
      horseName: horse.name,
      overallStatus: horse.healthStatus,
      summary: analysis.analysis,
      concerns: analysis.recommendations.slice(0, 3),
      recommendations: analysis.recommendations,
      upcomingReminders: upcomingReminders.map(r => ({
        type: r.type,
        title: r.title,
        dueDate: r.nextDueDate!,
      })),
      lastUpdated: new Date(),
    };
  }

  /**
   * Chat with AI about a specific horse
   */
  async chatAboutHorse(params: {
    horseId: string;
    messages: Array<{ role: 'user' | 'assistant'; content: string }>;
  }): Promise<string> {
    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        competitionResults: { take: 5 },
        healthRecords: { take: 5 },
      },
    });

    if (!horse) {
      throw new Error('Horse not found');
    }

    const context = `
Informations sur le cheval:
- Nom: ${horse.name}
- Race: ${horse.breed || 'Non précisé'}
- Studbook: ${horse.studbook || 'Non précisé'}
- Né en: ${horse.birthDate?.getFullYear() || 'Inconnu'}
- Niveau: ${horse.level || 'Non précisé'}
- Disciplines: ${(horse.disciplines as string[])?.join(', ') || 'Non précisé'}
- État de santé: ${horse.healthStatus}
- Dernières compétitions: ${horse.competitionResults.map(r => r.competitionName).join(', ') || 'Aucune'}
`;

    return this.anthropic.chat(params.messages, context);
  }
}

// Type definitions
export interface PerformanceAnalysis {
  horseId: string;
  horseName: string;
  globalScore: number;
  horseScore: number;
  techniqueScore: number;
  strengths: string[];
  improvements: string[];
  recommendations: string[];
  summary: string;
  frameAnalyses: string[];
  analyzedAt: Date;
}

export interface BreedingCompatibilityReport {
  mareId: string;
  mareName: string;
  stallionId: string;
  stallionName: string;
  compatibilityScore: number;
  analysis: string;
  strengths: string[];
  weaknesses: string[];
  recommendations: string[];
  predictedOffspring: {
    disciplines: string[];
    potentialLevel: string;
  };
  analyzedAt: Date;
}

export interface HealthSummary {
  horseId: string;
  horseName: string;
  overallStatus: string;
  summary: string;
  concerns: string[];
  recommendations: string[];
  upcomingReminders: {
    type: string;
    title: string;
    dueDate: Date;
  }[];
  lastUpdated: Date;
}
