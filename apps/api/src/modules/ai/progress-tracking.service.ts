import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CostOptimizationService } from './cost-optimization.service';

/**
 * Progress Tracking Service
 *
 * Stores and manages evolution data for horses and riders:
 * - Performance snapshots (periodic evaluations)
 * - Individual metric tracking
 * - Goal setting and monitoring
 * - Training session logging
 */
@Injectable()
export class ProgressTrackingService {
  private readonly logger = new Logger(ProgressTrackingService.name);

  constructor(
    private prisma: PrismaService,
    private costOptimization: CostOptimizationService
  ) {}

  // ==================== PERFORMANCE SNAPSHOTS ====================

  /**
   * Create a performance snapshot from analysis results
   */
  async createSnapshot(params: {
    subjectType: 'horse' | 'rider' | 'pair';
    horseId?: string;
    riderId?: string;
    discipline: string;
    level: string;
    periodType: 'daily' | 'weekly' | 'monthly' | 'competition';
    scores: {
      global?: number;
      technique?: number;
      physical?: number;
      mental?: number;
      harmony?: number;
    };
    metrics: Record<string, number>;
    analysisSessionId?: string;
    competitionId?: string;
  }): Promise<PerformanceSnapshot> {
    // Get AI analysis for strengths/weaknesses
    const aiAnalysis = await this.analyzePerformance(params);

    const snapshot = await this.prisma.performanceSnapshot.create({
      data: {
        subjectType: params.subjectType,
        horseId: params.horseId,
        riderId: params.riderId,
        discipline: params.discipline,
        level: params.level,
        periodType: params.periodType,
        globalScore: params.scores.global,
        techniqueScore: params.scores.technique,
        physicalScore: params.scores.physical,
        mentalScore: params.scores.mental,
        harmonyScore: params.scores.harmony,
        metrics: params.metrics,
        aiAnalysis: aiAnalysis.analysis,
        strengths: aiAnalysis.strengths,
        weaknesses: aiAnalysis.weaknesses,
        recommendations: aiAnalysis.recommendations,
        analysisSessionId: params.analysisSessionId,
        competitionId: params.competitionId,
      },
    });

    // Update progress metrics
    await this.updateProgressMetrics(params);

    this.logger.log(`Created snapshot for ${params.subjectType} in ${params.discipline}`);

    return snapshot as PerformanceSnapshot;
  }

  /**
   * Get performance history for a subject
   */
  async getPerformanceHistory(params: {
    subjectType: 'horse' | 'rider' | 'pair';
    horseId?: string;
    riderId?: string;
    discipline?: string;
    periodStart?: Date;
    periodEnd?: Date;
    limit?: number;
  }): Promise<PerformanceSnapshot[]> {
    const where: any = {
      subjectType: params.subjectType,
    };

    if (params.horseId) where.horseId = params.horseId;
    if (params.riderId) where.riderId = params.riderId;
    if (params.discipline) where.discipline = params.discipline;

    if (params.periodStart || params.periodEnd) {
      where.snapshotDate = {};
      if (params.periodStart) where.snapshotDate.gte = params.periodStart;
      if (params.periodEnd) where.snapshotDate.lte = params.periodEnd;
    }

    const snapshots = await this.prisma.performanceSnapshot.findMany({
      where,
      orderBy: { snapshotDate: 'desc' },
      take: params.limit || 50,
    });

    return snapshots as PerformanceSnapshot[];
  }

  /**
   * Calculate evolution between two periods
   */
  async calculateEvolution(params: {
    subjectType: 'horse' | 'rider' | 'pair';
    horseId?: string;
    riderId?: string;
    discipline?: string;
    periodA: { start: Date; end: Date };
    periodB: { start: Date; end: Date };
  }): Promise<EvolutionResult> {
    // Get snapshots for both periods
    const [snapshotsA, snapshotsB] = await Promise.all([
      this.getPerformanceHistory({
        ...params,
        periodStart: params.periodA.start,
        periodEnd: params.periodA.end,
      }),
      this.getPerformanceHistory({
        ...params,
        periodStart: params.periodB.start,
        periodEnd: params.periodB.end,
      }),
    ]);

    // Calculate averages for each period
    const avgA = this.calculateAverages(snapshotsA);
    const avgB = this.calculateAverages(snapshotsB);

    // Calculate differences
    const evolution: Record<string, MetricEvolution> = {};

    for (const key of Object.keys(avgB)) {
      const oldVal = avgA[key] || 0;
      const newVal = avgB[key] || 0;
      const diff = newVal - oldVal;
      const percentChange = oldVal !== 0 ? (diff / oldVal) * 100 : 0;

      evolution[key] = {
        previousValue: oldVal,
        currentValue: newVal,
        difference: diff,
        percentChange,
        trend: diff > 0.5 ? 'improving' : diff < -0.5 ? 'declining' : 'stable',
      };
    }

    // Get AI insights
    const insights = await this.getEvolutionInsights(evolution, params);

    return {
      subjectType: params.subjectType,
      horseId: params.horseId,
      riderId: params.riderId,
      discipline: params.discipline,
      periodA: params.periodA,
      periodB: params.periodB,
      evolution,
      overallTrend: this.calculateOverallTrend(evolution),
      insights: insights.insights,
      recommendations: insights.recommendations,
    };
  }

  // ==================== PROGRESS METRICS ====================

  /**
   * Record a specific metric value
   */
  async recordMetric(params: {
    subjectType: 'horse' | 'rider' | 'pair';
    horseId?: string;
    riderId?: string;
    metricName: string;
    metricCategory: 'technique' | 'physical' | 'mental' | 'competition';
    value: number;
    targetValue?: number;
    unit?: string;
    discipline?: string;
    level?: string;
    context?: string;
  }): Promise<void> {
    // Get previous value
    const previous = await this.prisma.progressMetric.findFirst({
      where: {
        subjectType: params.subjectType,
        horseId: params.horseId,
        riderId: params.riderId,
        metricName: params.metricName,
      },
      orderBy: { recordedAt: 'desc' },
    });

    const previousValue = previous?.value || null;
    const trend = this.calculateTrend(previousValue, params.value);

    await this.prisma.progressMetric.create({
      data: {
        subjectType: params.subjectType,
        horseId: params.horseId,
        riderId: params.riderId,
        metricName: params.metricName,
        metricCategory: params.metricCategory,
        value: params.value,
        previousValue,
        targetValue: params.targetValue,
        unit: params.unit,
        discipline: params.discipline,
        level: params.level,
        context: params.context,
        trend: trend.direction,
        trendStrength: trend.strength,
      },
    });
  }

  /**
   * Get metric history
   */
  async getMetricHistory(params: {
    subjectType: 'horse' | 'rider' | 'pair';
    horseId?: string;
    riderId?: string;
    metricName: string;
    periodStart?: Date;
    periodEnd?: Date;
    limit?: number;
  }): Promise<MetricHistoryEntry[]> {
    const where: any = {
      subjectType: params.subjectType,
      metricName: params.metricName,
    };

    if (params.horseId) where.horseId = params.horseId;
    if (params.riderId) where.riderId = params.riderId;

    if (params.periodStart || params.periodEnd) {
      where.recordedAt = {};
      if (params.periodStart) where.recordedAt.gte = params.periodStart;
      if (params.periodEnd) where.recordedAt.lte = params.periodEnd;
    }

    const metrics = await this.prisma.progressMetric.findMany({
      where,
      orderBy: { recordedAt: 'asc' },
      take: params.limit || 100,
    });

    return metrics.map((m) => ({
      date: m.recordedAt,
      value: m.value,
      previousValue: m.previousValue,
      targetValue: m.targetValue,
      trend: m.trend,
      context: m.context,
    }));
  }

  // ==================== GOALS ====================

  /**
   * Create an evolution goal
   */
  async createGoal(params: {
    subjectType: 'horse' | 'rider' | 'pair';
    horseId?: string;
    riderId?: string;
    title: string;
    description?: string;
    goalType: 'performance' | 'technique' | 'competition' | 'health';
    targetMetric: string;
    startValue: number;
    targetValue: number;
    targetDate: Date;
    unit?: string;
  }): Promise<EvolutionGoal> {
    // Get AI-generated plan
    const aiPlan = await this.generateGoalPlan(params);

    const goal = await this.prisma.evolutionGoal.create({
      data: {
        subjectType: params.subjectType,
        horseId: params.horseId,
        riderId: params.riderId,
        title: params.title,
        description: params.description,
        goalType: params.goalType,
        targetMetric: params.targetMetric,
        startValue: params.startValue,
        targetValue: params.targetValue,
        currentValue: params.startValue,
        targetDate: params.targetDate,
        unit: params.unit,
        aiPlan,
        milestones: this.generateMilestones(params),
      },
    });

    this.logger.log(`Created goal: ${params.title}`);

    return goal as EvolutionGoal;
  }

  /**
   * Update goal progress
   */
  async updateGoalProgress(goalId: string, currentValue: number): Promise<EvolutionGoal> {
    const goal = await this.prisma.evolutionGoal.findUnique({
      where: { id: goalId },
    });

    if (!goal) throw new Error('Goal not found');

    const progress = this.calculateGoalProgress(goal.startValue, goal.targetValue, currentValue);

    const status =
      progress >= 100 ? 'achieved' : new Date() > goal.targetDate ? 'failed' : goal.status;

    // Update milestones
    const milestones = goal.milestones as any[];
    const now = new Date();
    for (const milestone of milestones) {
      if (!milestone.achieved && currentValue >= milestone.value) {
        milestone.achieved = true;
        milestone.achievedDate = now;
      }
    }

    const updated = await this.prisma.evolutionGoal.update({
      where: { id: goalId },
      data: {
        currentValue,
        progress,
        status,
        milestones,
        completedDate: status === 'achieved' ? now : undefined,
      },
    });

    return updated as EvolutionGoal;
  }

  /**
   * Get active goals for a subject
   */
  async getActiveGoals(params: {
    subjectType?: 'horse' | 'rider' | 'pair';
    horseId?: string;
    riderId?: string;
  }): Promise<EvolutionGoal[]> {
    const where: any = { status: 'active' };

    if (params.subjectType) where.subjectType = params.subjectType;
    if (params.horseId) where.horseId = params.horseId;
    if (params.riderId) where.riderId = params.riderId;

    const goals = await this.prisma.evolutionGoal.findMany({
      where,
      orderBy: { targetDate: 'asc' },
    });

    return goals as EvolutionGoal[];
  }

  // ==================== TRAINING SESSIONS ====================

  /**
   * Log a training session
   */
  async logTrainingSession(params: {
    horseId: string;
    riderId?: string;
    sessionDate: Date;
    duration: number;
    sessionType: string;
    discipline?: string;
    weather?: WeatherConditions;
    surface?: string;
    location?: string;
    plannedExercises?: string[];
    objectives?: string[];
    completedExercises?: string[];
    notes?: string;
    metrics?: Record<string, number>;
    horseFatigueBefore?: number;
    horseFatigueAfter?: number;
    riderFatigueBefore?: number;
    riderFatigueAfter?: number;
  }): Promise<TrainingSessionRecord> {
    // Get AI feedback if we have performance data
    let aiFeedback = null;
    let improvementAreas: string[] = [];

    if (params.completedExercises?.length || params.metrics) {
      const feedback = await this.getSessionFeedback(params);
      aiFeedback = feedback.analysis;
      improvementAreas = feedback.improvements;
    }

    const session = await this.prisma.trainingSession.create({
      data: {
        horseId: params.horseId,
        riderId: params.riderId,
        sessionDate: params.sessionDate,
        duration: params.duration,
        sessionType: params.sessionType,
        discipline: params.discipline,
        weather: params.weather as any,
        surface: params.surface,
        location: params.location,
        plannedExercises: params.plannedExercises || [],
        objectives: params.objectives || [],
        completedExercises: params.completedExercises || [],
        notes: params.notes,
        metrics: params.metrics as any,
        aiFeedback,
        improvementAreas,
        horseFatigueBefore: params.horseFatigueBefore,
        horseFatigueAfter: params.horseFatigueAfter,
        riderFatigueBefore: params.riderFatigueBefore,
        riderFatigueAfter: params.riderFatigueAfter,
      },
    });

    // Update fatigue tracking for adaptive plans
    if (params.horseFatigueAfter) {
      await this.recordMetric({
        subjectType: 'horse',
        horseId: params.horseId,
        metricName: 'fatigue_level',
        metricCategory: 'physical',
        value: params.horseFatigueAfter,
        context: 'post_training',
      });
    }

    this.logger.log(`Logged training session for horse ${params.horseId}`);

    return session as TrainingSessionRecord;
  }

  /**
   * Get training history
   */
  async getTrainingHistory(params: {
    horseId?: string;
    riderId?: string;
    sessionType?: string;
    periodStart?: Date;
    periodEnd?: Date;
    limit?: number;
  }): Promise<TrainingSessionRecord[]> {
    const where: any = {};

    if (params.horseId) where.horseId = params.horseId;
    if (params.riderId) where.riderId = params.riderId;
    if (params.sessionType) where.sessionType = params.sessionType;

    if (params.periodStart || params.periodEnd) {
      where.sessionDate = {};
      if (params.periodStart) where.sessionDate.gte = params.periodStart;
      if (params.periodEnd) where.sessionDate.lte = params.periodEnd;
    }

    const sessions = await this.prisma.trainingSession.findMany({
      where,
      orderBy: { sessionDate: 'desc' },
      take: params.limit || 50,
    });

    return sessions as TrainingSessionRecord[];
  }

  /**
   * Get training statistics
   */
  async getTrainingStats(params: {
    horseId?: string;
    riderId?: string;
    periodStart: Date;
    periodEnd: Date;
  }): Promise<TrainingStats> {
    const sessions = await this.getTrainingHistory({
      ...params,
      limit: 1000,
    });

    const totalSessions = sessions.length;
    const totalDuration = sessions.reduce((sum, s) => sum + s.duration, 0);

    // Group by type
    const byType = new Map<string, { count: number; duration: number }>();
    for (const session of sessions) {
      const existing = byType.get(session.sessionType) || { count: 0, duration: 0 };
      byType.set(session.sessionType, {
        count: existing.count + 1,
        duration: existing.duration + session.duration,
      });
    }

    // Calculate fatigue trends
    const fatigueData = sessions
      .filter((s) => s.horseFatigueAfter !== null)
      .map((s) => ({
        date: s.sessionDate,
        before: s.horseFatigueBefore,
        after: s.horseFatigueAfter,
      }));

    const avgFatigueDelta =
      fatigueData.length > 0
        ? fatigueData.reduce((sum, f) => sum + ((f.after || 0) - (f.before || 0)), 0) /
          fatigueData.length
        : 0;

    return {
      period: { start: params.periodStart, end: params.periodEnd },
      totalSessions,
      totalDuration,
      avgSessionDuration: totalSessions > 0 ? totalDuration / totalSessions : 0,
      byType: Object.fromEntries(byType),
      fatigueAnalysis: {
        avgFatigueDelta,
        trend:
          avgFatigueDelta > 0.5 ? 'increasing' : avgFatigueDelta < -0.5 ? 'decreasing' : 'stable',
        dataPoints: fatigueData.length,
      },
    };
  }

  // ==================== PRIVATE METHODS ====================

  private async analyzePerformance(params: any): Promise<{
    analysis: any;
    strengths: string[];
    weaknesses: string[];
    recommendations: string[];
  }> {
    const prompt = `
Analyse les performances en ${params.discipline} niveau ${params.level}:

Scores:
- Global: ${params.scores.global || 'N/A'}/100
- Technique: ${params.scores.technique || 'N/A'}/100
- Physique: ${params.scores.physical || 'N/A'}/100
- Mental: ${params.scores.mental || 'N/A'}/100
${params.scores.harmony ? `- Harmonie: ${params.scores.harmony}/100` : ''}

Métriques détaillées:
${JSON.stringify(params.metrics, null, 2)}

Identifie:
1. Les 3 principaux points forts
2. Les 3 principaux axes d'amélioration
3. 3 recommandations concrètes

JSON format:
{
  "analysis": { "summary": "...", "keyFindings": ["..."] },
  "strengths": ["...", "...", "..."],
  "weaknesses": ["...", "...", "..."],
  "recommendations": ["...", "...", "..."]
}
`;

    const response = await this.costOptimization.smartRequest({
      task: 'simple_analysis',
      prompt,
      useCache: true,
    });

    try {
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch {
      this.logger.debug('Failed to parse AI analysis');
    }

    return {
      analysis: { summary: response.content },
      strengths: [],
      weaknesses: [],
      recommendations: [],
    };
  }

  private async getEvolutionInsights(
    evolution: Record<string, MetricEvolution>,
    params: any
  ): Promise<{ insights: string[]; recommendations: string[] }> {
    const prompt = `
Analyse l'évolution des performances:

${Object.entries(evolution)
  .map(
    ([key, val]) =>
      `- ${key}: ${val.previousValue.toFixed(1)} → ${val.currentValue.toFixed(1)} (${val.percentChange > 0 ? '+' : ''}${val.percentChange.toFixed(1)}%)`
  )
  .join('\n')}

Discipline: ${params.discipline || 'Général'}

Fournis:
1. 3 insights clés sur l'évolution
2. 3 recommandations pour continuer la progression

JSON: { "insights": ["..."], "recommendations": ["..."] }
`;

    const response = await this.costOptimization.smartRequest({
      task: 'simple_analysis',
      prompt,
      useCache: true,
    });

    try {
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch {
      this.logger.debug('Failed to parse evolution insights');
    }

    return { insights: [], recommendations: [] };
  }

  private async generateGoalPlan(params: any): Promise<any> {
    const daysToTarget = Math.ceil(
      (params.targetDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );

    const prompt = `
Crée un plan pour atteindre cet objectif équestre:

Objectif: ${params.title}
${params.description ? `Description: ${params.description}` : ''}
Type: ${params.goalType}
Métrique: ${params.targetMetric}
Valeur actuelle: ${params.startValue}${params.unit ? ` ${params.unit}` : ''}
Objectif: ${params.targetValue}${params.unit ? ` ${params.unit}` : ''}
Délai: ${daysToTarget} jours

Fournis un plan structuré avec phases et exercices clés.

JSON: {
  "phases": [
    { "name": "...", "duration": "2 semaines", "focus": "...", "exercises": ["..."] }
  ],
  "weeklyPlan": { "sessionsPerWeek": 4, "distribution": "..." },
  "keyExercises": ["..."],
  "progressIndicators": ["..."]
}
`;

    const response = await this.costOptimization.smartRequest({
      task: 'simple_analysis',
      prompt,
      useCache: true,
    });

    try {
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch {
      this.logger.debug('Failed to parse goal plan');
    }

    return null;
  }

  private async getSessionFeedback(params: any): Promise<{
    analysis: any;
    improvements: string[];
  }> {
    const prompt = `
Feedback sur cette séance d'entraînement:

Type: ${params.sessionType}
Durée: ${params.duration} min
Discipline: ${params.discipline || 'Général'}

Exercices réalisés:
${params.completedExercises?.join('\n') || 'Non spécifié'}

${params.metrics ? `Métriques: ${JSON.stringify(params.metrics)}` : ''}
${params.notes ? `Notes: ${params.notes}` : ''}

Fatigue cheval: ${params.horseFatigueBefore || '?'} → ${params.horseFatigueAfter || '?'}

Analyse brève et 3 points d'amélioration.

JSON: { "analysis": { "quality": "bon|moyen|insuffisant", "summary": "..." }, "improvements": ["..."] }
`;

    const response = await this.costOptimization.smartRequest({
      task: 'quick_summary',
      prompt,
      useCache: false, // Session feedback should not be cached
    });

    try {
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch {
      this.logger.debug('Failed to parse session feedback');
    }

    return { analysis: null, improvements: [] };
  }

  private async updateProgressMetrics(params: any): Promise<void> {
    const metrics = params.metrics as Record<string, number>;

    for (const [name, value] of Object.entries(metrics)) {
      await this.recordMetric({
        subjectType: params.subjectType,
        horseId: params.horseId,
        riderId: params.riderId,
        metricName: name,
        metricCategory: this.categorizeMetric(name),
        value,
        discipline: params.discipline,
        level: params.level,
        context: params.periodType,
      });
    }
  }

  private calculateAverages(snapshots: PerformanceSnapshot[]): Record<string, number> {
    if (snapshots.length === 0) return {};

    const sums: Record<string, number> = {};
    const counts: Record<string, number> = {};

    for (const snapshot of snapshots) {
      // Add score fields
      if (snapshot.globalScore) {
        sums['globalScore'] = (sums['globalScore'] || 0) + snapshot.globalScore;
        counts['globalScore'] = (counts['globalScore'] || 0) + 1;
      }
      if (snapshot.techniqueScore) {
        sums['techniqueScore'] = (sums['techniqueScore'] || 0) + snapshot.techniqueScore;
        counts['techniqueScore'] = (counts['techniqueScore'] || 0) + 1;
      }
      if (snapshot.physicalScore) {
        sums['physicalScore'] = (sums['physicalScore'] || 0) + snapshot.physicalScore;
        counts['physicalScore'] = (counts['physicalScore'] || 0) + 1;
      }
      if (snapshot.mentalScore) {
        sums['mentalScore'] = (sums['mentalScore'] || 0) + snapshot.mentalScore;
        counts['mentalScore'] = (counts['mentalScore'] || 0) + 1;
      }

      // Add metrics
      const metrics = snapshot.metrics as Record<string, number>;
      for (const [key, value] of Object.entries(metrics)) {
        if (typeof value === 'number') {
          sums[key] = (sums[key] || 0) + value;
          counts[key] = (counts[key] || 0) + 1;
        }
      }
    }

    const averages: Record<string, number> = {};
    for (const key of Object.keys(sums)) {
      averages[key] = sums[key] / counts[key];
    }

    return averages;
  }

  private calculateTrend(
    previous: number | null,
    current: number
  ): { direction: string; strength: number } {
    if (previous === null) {
      return { direction: 'new', strength: 0 };
    }

    const diff = current - previous;
    const percentChange = previous !== 0 ? (diff / previous) * 100 : 0;

    let direction: string;
    if (percentChange > 5) direction = 'improving';
    else if (percentChange < -5) direction = 'declining';
    else direction = 'stable';

    // Strength: -1 to 1
    const strength = Math.max(-1, Math.min(1, percentChange / 20));

    return { direction, strength };
  }

  private calculateOverallTrend(evolution: Record<string, MetricEvolution>): string {
    const entries = Object.values(evolution);
    if (entries.length === 0) return 'unknown';

    const improving = entries.filter((e) => e.trend === 'improving').length;
    const declining = entries.filter((e) => e.trend === 'declining').length;

    if (improving > declining * 2) return 'strong_improvement';
    if (improving > declining) return 'improving';
    if (declining > improving * 2) return 'strong_decline';
    if (declining > improving) return 'declining';
    return 'stable';
  }

  private calculateGoalProgress(start: number, target: number, current: number): number {
    const totalDistance = target - start;
    if (totalDistance === 0) return current >= target ? 100 : 0;

    const currentDistance = current - start;
    const progress = (currentDistance / totalDistance) * 100;

    return Math.max(0, Math.min(100, progress));
  }

  private generateMilestones(params: any): any[] {
    const { startValue, targetValue, targetDate } = params;
    const totalDays = Math.ceil((targetDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));

    // Create 4 milestones at 25%, 50%, 75%, 100%
    const milestones = [];
    const range = targetValue - startValue;

    for (const pct of [25, 50, 75, 100]) {
      const value = startValue + range * (pct / 100);
      const daysOffset = Math.floor(totalDays * (pct / 100));
      const date = new Date();
      date.setDate(date.getDate() + daysOffset);

      milestones.push({
        percent: pct,
        value,
        targetDate: date,
        achieved: false,
        achievedDate: null,
      });
    }

    return milestones;
  }

  private categorizeMetric(name: string): 'technique' | 'physical' | 'mental' | 'competition' {
    const techniquMetrics = [
      'impulsion',
      'equilibre',
      'rectitude',
      'souplesse',
      'contact',
      'position',
      'cadence',
    ];
    const physicalMetrics = ['endurance', 'force', 'souplesse', 'fatigue', 'recuperation'];
    const mentalMetrics = ['concentration', 'calme', 'volonte', 'confiance'];

    const lowerName = name.toLowerCase();

    if (techniquMetrics.some((m) => lowerName.includes(m))) return 'technique';
    if (physicalMetrics.some((m) => lowerName.includes(m))) return 'physical';
    if (mentalMetrics.some((m) => lowerName.includes(m))) return 'mental';
    return 'competition';
  }
}

// Type definitions
export interface PerformanceSnapshot {
  id: string;
  subjectType: string;
  horseId?: string;
  riderId?: string;
  snapshotDate: Date;
  periodType: string;
  discipline: string;
  level: string;
  globalScore?: number;
  techniqueScore?: number;
  physicalScore?: number;
  mentalScore?: number;
  harmonyScore?: number;
  metrics: Record<string, number>;
  aiAnalysis?: any;
  strengths: string[];
  weaknesses: string[];
  recommendations: string[];
}

export interface MetricEvolution {
  previousValue: number;
  currentValue: number;
  difference: number;
  percentChange: number;
  trend: 'improving' | 'stable' | 'declining';
}

export interface EvolutionResult {
  subjectType: string;
  horseId?: string;
  riderId?: string;
  discipline?: string;
  periodA: { start: Date; end: Date };
  periodB: { start: Date; end: Date };
  evolution: Record<string, MetricEvolution>;
  overallTrend: string;
  insights: string[];
  recommendations: string[];
}

export interface MetricHistoryEntry {
  date: Date;
  value: number;
  previousValue?: number;
  targetValue?: number;
  trend?: string;
  context?: string;
}

export interface EvolutionGoal {
  id: string;
  subjectType: string;
  horseId?: string;
  riderId?: string;
  title: string;
  description?: string;
  goalType: string;
  targetMetric: string;
  startValue: number;
  targetValue: number;
  currentValue?: number;
  unit?: string;
  startDate: Date;
  targetDate: Date;
  completedDate?: Date;
  status: string;
  progress: number;
  milestones: any[];
  aiPlan?: any;
}

export interface WeatherConditions {
  temp?: number;
  humidity?: number;
  wind?: number;
  conditions?: string;
}

export interface TrainingSessionRecord {
  id: string;
  horseId: string;
  riderId?: string;
  sessionDate: Date;
  duration: number;
  sessionType: string;
  discipline?: string;
  weather?: WeatherConditions;
  surface?: string;
  location?: string;
  plannedExercises: string[];
  objectives: string[];
  completedExercises: string[];
  notes?: string;
  metrics?: Record<string, number>;
  aiFeedback?: any;
  improvementAreas: string[];
  horseFatigueBefore?: number;
  horseFatigueAfter?: number;
  riderFatigueBefore?: number;
  riderFatigueAfter?: number;
}

export interface TrainingStats {
  period: { start: Date; end: Date };
  totalSessions: number;
  totalDuration: number;
  avgSessionDuration: number;
  byType: Record<string, { count: number; duration: number }>;
  fatigueAnalysis: {
    avgFatigueDelta: number;
    trend: string;
    dataPoints: number;
  };
}
