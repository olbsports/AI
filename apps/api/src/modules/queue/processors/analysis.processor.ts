import { Process, Processor, OnQueueCompleted, OnQueueFailed } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import { Job } from 'bull';

import { PrismaService } from '../../../prisma/prisma.service';
import { QUEUE_NAMES } from '../queue.constants';
import { AnalysisJobData } from '../queue.service';

@Processor(QUEUE_NAMES.ANALYSIS)
export class AnalysisProcessor {
  private readonly logger = new Logger(AnalysisProcessor.name);

  constructor(private readonly prisma: PrismaService) {}

  @Process('process')
  async handleAnalysis(job: Job<AnalysisJobData>) {
    this.logger.log(`Processing analysis: ${job.data.analysisId}`);

    const { analysisId, type, inputMediaUrls } = job.data;

    try {
      // Update status to processing
      await this.prisma.analysisSession.update({
        where: { id: analysisId },
        data: {
          status: 'processing',
          startedAt: new Date(),
        },
      });

      // Update progress
      await job.progress(10);

      // Simulate AI analysis (in production, call actual AI service)
      const results = await this.simulateAnalysis(type, inputMediaUrls, job);

      await job.progress(90);

      // Update analysis with results
      const completedAnalysis = await this.prisma.analysisSession.update({
        where: { id: analysisId },
        data: {
          status: 'completed',
          completedAt: new Date(),
          processingTimeMs: Date.now() - job.processedOn!,
          scores: results.scores,
          obstacles: results.obstacles,
          issues: results.issues,
          recommendations: results.recommendations,
          aiAnalysis: results.aiAnalysis,
          confidenceScore: results.confidenceScore,
        },
      });

      await job.progress(100);

      this.logger.log(`Analysis completed: ${analysisId}`);
      return completedAnalysis;
    } catch (error) {
      this.logger.error(`Analysis failed: ${analysisId}`, error);

      await this.prisma.analysisSession.update({
        where: { id: analysisId },
        data: {
          status: 'failed',
          errorMessage: error instanceof Error ? error.message : 'Unknown error',
        },
      });

      throw error;
    }
  }

  private async simulateAnalysis(
    type: string,
    _mediaUrls: string[],
    job: Job,
  ) {
    // Simulate processing time based on type
    const processingTime = {
      radiological: 5000,
      locomotion: 8000,
      video_performance: 15000,
      video_course: 20000,
    }[type] || 10000;

    // Simulate progress updates
    const steps = 8;
    for (let i = 1; i <= steps; i++) {
      await new Promise((resolve) => setTimeout(resolve, processingTime / steps));
      await job.progress(10 + (80 * i) / steps);
    }

    // Generate mock results based on type
    if (type === 'radiological') {
      return this.generateRadiologicalResults();
    } else if (type === 'locomotion') {
      return this.generateLocomotionResults();
    } else {
      return this.generateVideoResults();
    }
  }

  private generateRadiologicalResults() {
    const categories = ['A', 'A-', 'B+', 'B', 'B-', 'C', 'D'];
    const category = categories[Math.floor(Math.random() * 3)]; // Bias towards good results

    return {
      scores: {
        global: 75 + Math.random() * 25,
      },
      obstacles: null,
      issues: [
        { region: 'Boulet AG', severity: 'minor', description: 'Légère irrégularité' },
      ],
      recommendations: [
        'Contrôle dans 6 mois recommandé',
        'Ferrage adapté conseillé',
      ],
      aiAnalysis: {
        category,
        regions: {
          bouletAG: { score: 85, findings: [] },
          bouletAD: { score: 90, findings: [] },
          canonAG: { score: 88, findings: [] },
          canonAD: { score: 92, findings: [] },
        },
      },
      confidenceScore: 0.92,
    };
  }

  private generateLocomotionResults() {
    return {
      scores: {
        global: 80 + Math.random() * 15,
        symmetry: 85 + Math.random() * 10,
        regularity: 82 + Math.random() * 12,
      },
      obstacles: null,
      issues: [],
      recommendations: [
        'Échauffement prolongé recommandé',
        'Travail sur la souplesse latérale',
      ],
      aiAnalysis: {
        gaits: {
          walk: { score: 88, symmetry: 92 },
          trot: { score: 85, symmetry: 88 },
          canter: { score: 82, symmetry: 85 },
        },
        asymmetries: [],
      },
      confidenceScore: 0.89,
    };
  }

  private generateVideoResults() {
    return {
      scores: {
        global: 75 + Math.random() * 20,
        horse: 78 + Math.random() * 15,
        rider: 72 + Math.random() * 20,
        harmony: 76 + Math.random() * 18,
        technique: 74 + Math.random() * 20,
      },
      obstacles: [
        { number: 1, score: 8.5, faults: 0, time: 4.2 },
        { number: 2, score: 7.8, faults: 0, time: 5.1 },
        { number: 3, score: 9.0, faults: 0, time: 4.8 },
      ],
      issues: [
        { type: 'approach', obstacle: 2, description: 'Approche légèrement longue' },
      ],
      recommendations: [
        'Travailler les abords sur des lignes courtes',
        'Améliorer le galop de travail',
      ],
      aiAnalysis: {
        courseAnalysis: {
          pace: 'good',
          lines: 'excellent',
          timing: 'good',
        },
      },
      confidenceScore: 0.87,
    };
  }

  @OnQueueCompleted()
  onCompleted(job: Job<AnalysisJobData>) {
    this.logger.log(`Job ${job.id} completed for analysis ${job.data.analysisId}`);
  }

  @OnQueueFailed()
  onFailed(job: Job<AnalysisJobData>, error: Error) {
    this.logger.error(
      `Job ${job.id} failed for analysis ${job.data.analysisId}: ${error.message}`,
    );
  }
}
