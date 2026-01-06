import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CostOptimizationService } from './cost-optimization.service';
import { ProgressTrackingService } from './progress-tracking.service';
import { ComparisonService } from './comparison.service';

/**
 * Evolution Report Service
 *
 * Generates comprehensive reports on progress and evolution:
 * - Monthly/quarterly/annual progress reports
 * - Goal achievement summaries
 * - Training effectiveness analysis
 * - Predictive insights
 */
@Injectable()
export class EvolutionReportService {
  private readonly logger = new Logger(EvolutionReportService.name);

  constructor(
    private prisma: PrismaService,
    private progressTracking: ProgressTrackingService,
    private comparison: ComparisonService,
    private costOptimization: CostOptimizationService
  ) {}

  // ==================== COMPREHENSIVE REPORTS ====================

  /**
   * Generate a comprehensive evolution report for a horse
   */
  async generateHorseReport(params: {
    horseId: string;
    periodStart: Date;
    periodEnd: Date;
    includeComparisons?: boolean;
  }): Promise<HorseEvolutionReport> {
    const horse = await this.prisma.horse.findUnique({
      where: { id: params.horseId },
      include: {
        rider: true,
      },
    });

    if (!horse) throw new Error('Horse not found');

    // Get performance history
    const snapshots = await this.progressTracking.getPerformanceHistory({
      subjectType: 'horse',
      horseId: params.horseId,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    });

    // Get training sessions
    const trainingSessions = await this.progressTracking.getTrainingHistory({
      horseId: params.horseId,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    });

    // Get training stats
    const trainingStats = await this.progressTracking.getTrainingStats({
      horseId: params.horseId,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    });

    // Get goals
    const goals = await this.prisma.evolutionGoal.findMany({
      where: {
        horseId: params.horseId,
        OR: [
          { status: 'active' },
          {
            completedDate: {
              gte: params.periodStart,
              lte: params.periodEnd,
            },
          },
        ],
      },
    });

    // Calculate evolution by discipline
    const disciplines = [...new Set(snapshots.map((s) => s.discipline))];
    const evolutionByDiscipline: Record<string, DisciplineEvolution> = {};

    for (const discipline of disciplines) {
      const discSnapshots = snapshots.filter((s) => s.discipline === discipline);
      evolutionByDiscipline[discipline] = this.calculateDisciplineEvolution(discSnapshots);
    }

    // Get metric trends
    const metricTrends = await this.calculateMetricTrends({
      subjectType: 'horse',
      horseId: params.horseId,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    });

    // Get health records if available
    const healthRecords = await this.prisma.healthRecord.findMany({
      where: {
        horseId: params.horseId,
        recordDate: {
          gte: params.periodStart,
          lte: params.periodEnd,
        },
      },
      orderBy: { recordDate: 'desc' },
    });

    // Get competitions
    const competitions = await this.prisma.competitionResult.findMany({
      where: {
        horseId: params.horseId,
        competitionDate: {
          gte: params.periodStart,
          lte: params.periodEnd,
        },
      },
      orderBy: { competitionDate: 'desc' },
    });

    // Generate AI summary
    const aiSummary = await this.generateHorseSummary({
      horse,
      snapshots,
      trainingStats,
      goals,
      evolutionByDiscipline,
      metricTrends,
      competitions,
    });

    // Benchmark comparison if requested
    let benchmarkComparison = null;
    if (params.includeComparisons && horse.level && disciplines.length > 0) {
      benchmarkComparison = await this.comparison.compareToBenchmark({
        subjectType: 'horse',
        horseId: params.horseId,
        discipline: disciplines[0],
        level: horse.level,
        periodStart: params.periodStart,
        periodEnd: params.periodEnd,
      });
    }

    return {
      horse: {
        id: horse.id,
        name: horse.name,
        breed: horse.breed,
        age: horse.birthDate ? new Date().getFullYear() - horse.birthDate.getFullYear() : null,
        level: horse.level,
        disciplines: (horse.disciplines as string[]) || [],
      },
      period: {
        start: params.periodStart,
        end: params.periodEnd,
        durationDays: Math.ceil(
          (params.periodEnd.getTime() - params.periodStart.getTime()) / (1000 * 60 * 60 * 24)
        ),
      },
      summary: aiSummary,
      performance: {
        totalSnapshots: snapshots.length,
        evolutionByDiscipline,
        overallTrend: this.calculateOverallTrend(evolutionByDiscipline),
        metricTrends,
      },
      training: {
        stats: trainingStats,
        totalSessions: trainingSessions.length,
        mostFrequentType: this.getMostFrequent(trainingSessions.map((s) => s.sessionType)),
        avgSessionsPerWeek:
          trainingSessions.length /
          Math.max(
            1,
            (params.periodEnd.getTime() - params.periodStart.getTime()) / (1000 * 60 * 60 * 24 * 7)
          ),
      },
      goals: {
        active: goals.filter((g) => g.status === 'active').length,
        achieved: goals.filter((g) => g.status === 'achieved').length,
        failed: goals.filter((g) => g.status === 'failed').length,
        details: goals.map((g) => ({
          title: g.title,
          status: g.status,
          progress: g.progress,
          targetDate: g.targetDate,
        })),
      },
      health: {
        recordCount: healthRecords.length,
        lastCheckDate: healthRecords[0]?.recordDate || null,
        issues: healthRecords.filter((h) => (h.data as any)?.hasIssue).length,
      },
      competitions: {
        count: competitions.length,
        results: competitions.map((c) => ({
          date: c.competitionDate,
          discipline: c.discipline,
          level: c.level,
          ranking: c.ranking,
          score: c.score,
        })),
        bestResult: competitions.reduce(
          (best, c) => (c.ranking && (!best || c.ranking < best.ranking) ? c : best),
          null as any
        ),
      },
      benchmarkComparison,
      recommendations: aiSummary.recommendations,
      nextSteps: aiSummary.nextSteps,
    };
  }

  /**
   * Generate a comprehensive evolution report for a rider
   */
  async generateRiderReport(params: {
    riderId: string;
    periodStart: Date;
    periodEnd: Date;
    includeHorseComparisons?: boolean;
  }): Promise<RiderEvolutionReport> {
    const rider = await this.prisma.rider.findUnique({
      where: { id: params.riderId },
      include: {
        horses: true,
      },
    });

    if (!rider) throw new Error('Rider not found');

    // Get performance history
    const snapshots = await this.progressTracking.getPerformanceHistory({
      subjectType: 'rider',
      riderId: params.riderId,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    });

    // Get training sessions
    const trainingSessions = await this.progressTracking.getTrainingHistory({
      riderId: params.riderId,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    });

    // Get training stats
    const trainingStats = await this.progressTracking.getTrainingStats({
      riderId: params.riderId,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    });

    // Get goals
    const goals = await this.prisma.evolutionGoal.findMany({
      where: {
        riderId: params.riderId,
        OR: [
          { status: 'active' },
          {
            completedDate: {
              gte: params.periodStart,
              lte: params.periodEnd,
            },
          },
        ],
      },
    });

    // Calculate evolution by discipline
    const disciplines = [...new Set(snapshots.map((s) => s.discipline))];
    const evolutionByDiscipline: Record<string, DisciplineEvolution> = {};

    for (const discipline of disciplines) {
      const discSnapshots = snapshots.filter((s) => s.discipline === discipline);
      evolutionByDiscipline[discipline] = this.calculateDisciplineEvolution(discSnapshots);
    }

    // Get metric trends
    const metricTrends = await this.calculateMetricTrends({
      subjectType: 'rider',
      riderId: params.riderId,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    });

    // Performance by horse
    const performanceByHorse: Record<string, HorsePerformanceSummary> = {};
    for (const horse of rider.horses) {
      const pairSnapshots = await this.progressTracking.getPerformanceHistory({
        subjectType: 'pair',
        horseId: horse.id,
        riderId: params.riderId,
        periodStart: params.periodStart,
        periodEnd: params.periodEnd,
      });

      if (pairSnapshots.length > 0) {
        const avgScore =
          pairSnapshots.reduce((sum, s) => sum + (s.globalScore || 0), 0) / pairSnapshots.length;

        performanceByHorse[horse.id] = {
          horseName: horse.name,
          sessionsCount: pairSnapshots.length,
          averageScore: avgScore,
          bestScore: Math.max(...pairSnapshots.map((s) => s.globalScore || 0)),
          trend: this.calculateTrendFromSnapshots(pairSnapshots),
        };
      }
    }

    // Generate AI summary
    const aiSummary = await this.generateRiderSummary({
      rider,
      snapshots,
      trainingStats,
      goals,
      evolutionByDiscipline,
      metricTrends,
      performanceByHorse,
    });

    return {
      rider: {
        id: rider.id,
        name: `${rider.firstName} ${rider.lastName}`,
        level: rider.level,
        discipline: rider.discipline,
        horsesCount: rider.horses.length,
      },
      period: {
        start: params.periodStart,
        end: params.periodEnd,
        durationDays: Math.ceil(
          (params.periodEnd.getTime() - params.periodStart.getTime()) / (1000 * 60 * 60 * 24)
        ),
      },
      summary: aiSummary,
      performance: {
        totalSnapshots: snapshots.length,
        evolutionByDiscipline,
        overallTrend: this.calculateOverallTrend(evolutionByDiscipline),
        metricTrends,
        byHorse: performanceByHorse,
      },
      training: {
        stats: trainingStats,
        totalSessions: trainingSessions.length,
        avgSessionsPerWeek:
          trainingSessions.length /
          Math.max(
            1,
            (params.periodEnd.getTime() - params.periodStart.getTime()) / (1000 * 60 * 60 * 24 * 7)
          ),
      },
      goals: {
        active: goals.filter((g) => g.status === 'active').length,
        achieved: goals.filter((g) => g.status === 'achieved').length,
        failed: goals.filter((g) => g.status === 'failed').length,
        details: goals.map((g) => ({
          title: g.title,
          status: g.status,
          progress: g.progress,
          targetDate: g.targetDate,
        })),
      },
      recommendations: aiSummary.recommendations,
      nextSteps: aiSummary.nextSteps,
    };
  }

  // ==================== PERIODIC REPORTS ====================

  /**
   * Generate a monthly summary report
   */
  async generateMonthlySummary(params: {
    organizationId: string;
    year: number;
    month: number;
  }): Promise<MonthlySummaryReport> {
    const startDate = new Date(params.year, params.month - 1, 1);
    const endDate = new Date(params.year, params.month, 0, 23, 59, 59);

    // Get all horses in organization
    const horses = await this.prisma.horse.findMany({
      where: { organizationId: params.organizationId },
      select: { id: true, name: true },
    });

    // Get all snapshots for the month
    const snapshots = await this.prisma.performanceSnapshot.findMany({
      where: {
        snapshotDate: { gte: startDate, lte: endDate },
        OR: horses.map((h) => ({ horseId: h.id })),
      },
    });

    // Get training sessions
    const sessions = await this.prisma.trainingSession.findMany({
      where: {
        sessionDate: { gte: startDate, lte: endDate },
        horseId: { in: horses.map((h) => h.id) },
      },
    });

    // Get goals completed
    const goalsCompleted = await this.prisma.evolutionGoal.findMany({
      where: {
        status: 'achieved',
        completedDate: { gte: startDate, lte: endDate },
        horseId: { in: horses.map((h) => h.id) },
      },
    });

    // Calculate stats by horse
    const horseStats: HorseMonthlyStats[] = [];
    for (const horse of horses) {
      const horseSnapshots = snapshots.filter((s) => s.horseId === horse.id);
      const horseSessions = sessions.filter((s) => s.horseId === horse.id);

      if (horseSnapshots.length > 0 || horseSessions.length > 0) {
        const avgScore =
          horseSnapshots.length > 0
            ? horseSnapshots.reduce((sum, s) => sum + (s.globalScore || 0), 0) /
              horseSnapshots.length
            : null;

        horseStats.push({
          horseId: horse.id,
          horseName: horse.name,
          snapshotCount: horseSnapshots.length,
          sessionCount: horseSessions.length,
          totalTrainingMinutes: horseSessions.reduce((sum, s) => sum + s.duration, 0),
          averageScore: avgScore,
        });
      }
    }

    // AI summary
    const aiInsights = await this.generateMonthlyInsights({
      horseStats,
      totalSessions: sessions.length,
      goalsCompleted: goalsCompleted.length,
      month: params.month,
      year: params.year,
    });

    return {
      period: {
        year: params.year,
        month: params.month,
        startDate,
        endDate,
      },
      summary: {
        totalHorsesActive: horseStats.length,
        totalSnapshots: snapshots.length,
        totalSessions: sessions.length,
        totalTrainingMinutes: sessions.reduce((sum, s) => sum + s.duration, 0),
        goalsCompleted: goalsCompleted.length,
      },
      horseStats: horseStats.sort((a, b) => (b.averageScore || 0) - (a.averageScore || 0)),
      topPerformers: horseStats
        .filter((h) => h.averageScore)
        .sort((a, b) => (b.averageScore || 0) - (a.averageScore || 0))
        .slice(0, 3),
      mostImproved: [], // Would need previous month comparison
      insights: aiInsights.insights,
      recommendations: aiInsights.recommendations,
    };
  }

  // ==================== PREDICTIVE ANALYSIS ====================

  /**
   * Predict future performance based on trends
   */
  async predictProgress(params: {
    subjectType: 'horse' | 'rider';
    horseId?: string;
    riderId?: string;
    discipline: string;
    targetMetric: string;
    horizonDays: number;
  }): Promise<ProgressPrediction> {
    // Get historical data
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 90); // Last 90 days

    const metricHistory = await this.progressTracking.getMetricHistory({
      subjectType: params.subjectType,
      horseId: params.horseId,
      riderId: params.riderId,
      metricName: params.targetMetric,
      periodStart: startDate,
      periodEnd: endDate,
    });

    if (metricHistory.length < 5) {
      return {
        canPredict: false,
        reason: 'Insufficient data for prediction (need at least 5 data points)',
        currentValue: metricHistory[metricHistory.length - 1]?.value || null,
        predictedValue: null,
        confidence: 0,
        factors: [],
      };
    }

    // Calculate trend
    const trend = this.calculateLinearTrend(metricHistory);

    // Predict future value
    const currentValue = metricHistory[metricHistory.length - 1].value;
    const dailyChange = trend.slope;
    const predictedValue = currentValue + dailyChange * params.horizonDays;

    // Calculate confidence based on R-squared and data consistency
    const confidence = Math.min(100, trend.rSquared * 100);

    // Get AI analysis of factors
    const factorAnalysis = await this.analyzeProgressFactors({
      metricHistory,
      trend,
      discipline: params.discipline,
      horizonDays: params.horizonDays,
    });

    return {
      canPredict: true,
      currentValue,
      predictedValue: Math.max(0, Math.min(100, predictedValue)),
      changePerDay: dailyChange,
      totalExpectedChange: dailyChange * params.horizonDays,
      confidence,
      trend: trend.slope > 0.05 ? 'improving' : trend.slope < -0.05 ? 'declining' : 'stable',
      factors: factorAnalysis.factors,
      recommendations: factorAnalysis.recommendations,
      riskFactors: factorAnalysis.risks,
    };
  }

  // ==================== HELPER METHODS ====================

  private calculateDisciplineEvolution(snapshots: any[]): DisciplineEvolution {
    if (snapshots.length === 0) {
      return {
        snapshotCount: 0,
        startScore: null,
        endScore: null,
        averageScore: null,
        trend: 'unknown',
        improvement: 0,
      };
    }

    const sorted = [...snapshots].sort(
      (a, b) => new Date(a.snapshotDate).getTime() - new Date(b.snapshotDate).getTime()
    );

    const startScore = sorted[0].globalScore;
    const endScore = sorted[sorted.length - 1].globalScore;
    const averageScore = sorted.reduce((sum, s) => sum + (s.globalScore || 0), 0) / sorted.length;
    const improvement = endScore && startScore ? endScore - startScore : 0;

    let trend: string;
    if (improvement > 5) trend = 'strong_improvement';
    else if (improvement > 0) trend = 'improving';
    else if (improvement < -5) trend = 'strong_decline';
    else if (improvement < 0) trend = 'declining';
    else trend = 'stable';

    return {
      snapshotCount: snapshots.length,
      startScore,
      endScore,
      averageScore,
      trend,
      improvement,
    };
  }

  private calculateOverallTrend(
    evolutionByDiscipline: Record<string, DisciplineEvolution>
  ): string {
    const evolutions = Object.values(evolutionByDiscipline);
    if (evolutions.length === 0) return 'unknown';

    const improvements = evolutions.filter((e) => e.improvement > 0).length;
    const declines = evolutions.filter((e) => e.improvement < 0).length;

    if (improvements > declines) return 'positive';
    if (declines > improvements) return 'negative';
    return 'stable';
  }

  private async calculateMetricTrends(params: {
    subjectType: string;
    horseId?: string;
    riderId?: string;
    periodStart: Date;
    periodEnd: Date;
  }): Promise<MetricTrendSummary[]> {
    const metrics = await this.prisma.progressMetric.findMany({
      where: {
        subjectType: params.subjectType,
        horseId: params.horseId,
        riderId: params.riderId,
        recordedAt: { gte: params.periodStart, lte: params.periodEnd },
      },
      orderBy: { recordedAt: 'asc' },
    });

    // Group by metric name
    const byMetric = new Map<string, any[]>();
    for (const m of metrics) {
      if (!byMetric.has(m.metricName)) {
        byMetric.set(m.metricName, []);
      }
      byMetric.get(m.metricName)!.push(m);
    }

    const trends: MetricTrendSummary[] = [];
    for (const [name, metricData] of byMetric) {
      if (metricData.length < 2) continue;

      const first = metricData[0];
      const last = metricData[metricData.length - 1];
      const change = last.value - first.value;
      const percentChange = first.value !== 0 ? (change / first.value) * 100 : 0;

      trends.push({
        metricName: name,
        category: first.metricCategory,
        startValue: first.value,
        endValue: last.value,
        change,
        percentChange,
        trend: change > 0 ? 'improving' : change < 0 ? 'declining' : 'stable',
        dataPoints: metricData.length,
      });
    }

    return trends.sort((a, b) => Math.abs(b.percentChange) - Math.abs(a.percentChange));
  }

  private calculateTrendFromSnapshots(snapshots: any[]): string {
    if (snapshots.length < 2) return 'unknown';

    const sorted = [...snapshots].sort(
      (a, b) => new Date(a.snapshotDate).getTime() - new Date(b.snapshotDate).getTime()
    );

    const firstHalf = sorted.slice(0, Math.floor(sorted.length / 2));
    const secondHalf = sorted.slice(Math.floor(sorted.length / 2));

    const avgFirst = firstHalf.reduce((sum, s) => sum + (s.globalScore || 0), 0) / firstHalf.length;
    const avgSecond =
      secondHalf.reduce((sum, s) => sum + (s.globalScore || 0), 0) / secondHalf.length;

    const diff = avgSecond - avgFirst;
    if (diff > 3) return 'improving';
    if (diff < -3) return 'declining';
    return 'stable';
  }

  private getMostFrequent(items: string[]): string | null {
    if (items.length === 0) return null;

    const counts = new Map<string, number>();
    for (const item of items) {
      counts.set(item, (counts.get(item) || 0) + 1);
    }

    let maxCount = 0;
    let maxItem: string | null = null;
    for (const [item, count] of counts) {
      if (count > maxCount) {
        maxCount = count;
        maxItem = item;
      }
    }

    return maxItem;
  }

  private calculateLinearTrend(data: { date: Date; value: number }[]): {
    slope: number;
    intercept: number;
    rSquared: number;
  } {
    const n = data.length;
    if (n < 2) return { slope: 0, intercept: data[0]?.value || 0, rSquared: 0 };

    // Convert dates to days from first date
    const firstDate = data[0].date.getTime();
    const points = data.map((d) => ({
      x: (new Date(d.date).getTime() - firstDate) / (1000 * 60 * 60 * 24),
      y: d.value,
    }));

    // Calculate means
    const meanX = points.reduce((sum, p) => sum + p.x, 0) / n;
    const meanY = points.reduce((sum, p) => sum + p.y, 0) / n;

    // Calculate slope and intercept
    let numerator = 0;
    let denominator = 0;
    for (const p of points) {
      numerator += (p.x - meanX) * (p.y - meanY);
      denominator += (p.x - meanX) ** 2;
    }

    const slope = denominator !== 0 ? numerator / denominator : 0;
    const intercept = meanY - slope * meanX;

    // Calculate R-squared
    let ssRes = 0;
    let ssTot = 0;
    for (const p of points) {
      const predicted = slope * p.x + intercept;
      ssRes += (p.y - predicted) ** 2;
      ssTot += (p.y - meanY) ** 2;
    }
    const rSquared = ssTot !== 0 ? 1 - ssRes / ssTot : 0;

    return { slope, intercept, rSquared };
  }

  // ==================== AI SUMMARY GENERATION ====================

  private async generateHorseSummary(data: any): Promise<ReportSummary> {
    const prompt = `
Génère un résumé d'évolution pour le cheval ${data.horse.name}:

Performance:
- Nombre d'analyses: ${data.snapshots.length}
- Disciplines: ${Object.keys(data.evolutionByDiscipline).join(', ')}
${Object.entries(data.evolutionByDiscipline)
  .map(
    ([disc, evo]: [string, any]) =>
      `- ${disc}: ${evo.trend} (${evo.improvement > 0 ? '+' : ''}${evo.improvement?.toFixed(1) || 0} points)`
  )
  .join('\n')}

Entraînement:
- Sessions totales: ${data.trainingStats.totalSessions}
- Durée totale: ${data.trainingStats.totalDuration} min
- Moyenne/semaine: ${data.trainingStats.avgSessionDuration?.toFixed(1)} min

Objectifs:
- Actifs: ${data.goals.filter((g: any) => g.status === 'active').length}
- Atteints: ${data.goals.filter((g: any) => g.status === 'achieved').length}

Compétitions: ${data.competitions.length} participations

Fournis:
1. Un résumé en 3-4 phrases
2. Les 3 points forts
3. Les 3 axes d'amélioration
4. 4 recommandations concrètes
5. 3 prochaines étapes prioritaires

JSON: {
  "summary": "...",
  "highlights": ["..."],
  "improvements": ["..."],
  "recommendations": ["..."],
  "nextSteps": ["..."]
}
`;

    const response = await this.costOptimization.smartRequest({
      task: 'simple_analysis',
      prompt,
      useCache: false,
    });

    try {
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch {
      this.logger.debug('Failed to parse horse summary');
    }

    return {
      summary: 'Analyse en cours...',
      highlights: [],
      improvements: [],
      recommendations: [],
      nextSteps: [],
    };
  }

  private async generateRiderSummary(data: any): Promise<ReportSummary> {
    const prompt = `
Génère un résumé d'évolution pour le cavalier ${data.rider.firstName} ${data.rider.lastName}:

Performance:
- Nombre d'analyses: ${data.snapshots.length}
- Chevaux montés: ${Object.keys(data.performanceByHorse).length}
${Object.entries(data.performanceByHorse)
  .map(
    ([, info]: [string, any]) =>
      `- ${info.horseName}: ${info.averageScore?.toFixed(1) || 'N/A'}/100 (${info.trend})`
  )
  .join('\n')}

Évolution par discipline:
${Object.entries(data.evolutionByDiscipline)
  .map(([disc, evo]: [string, any]) => `- ${disc}: ${evo.trend}`)
  .join('\n')}

Entraînement:
- Sessions: ${data.trainingStats.totalSessions}

Objectifs:
- Actifs: ${data.goals.filter((g: any) => g.status === 'active').length}
- Atteints: ${data.goals.filter((g: any) => g.status === 'achieved').length}

JSON: {
  "summary": "...",
  "highlights": ["..."],
  "improvements": ["..."],
  "recommendations": ["..."],
  "nextSteps": ["..."]
}
`;

    const response = await this.costOptimization.smartRequest({
      task: 'simple_analysis',
      prompt,
      useCache: false,
    });

    try {
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch {
      this.logger.debug('Failed to parse rider summary');
    }

    return {
      summary: 'Analyse en cours...',
      highlights: [],
      improvements: [],
      recommendations: [],
      nextSteps: [],
    };
  }

  private async generateMonthlyInsights(data: any): Promise<{
    insights: string[];
    recommendations: string[];
  }> {
    const prompt = `
Résumé mensuel ${data.month}/${data.year}:

- Chevaux actifs: ${data.horseStats.length}
- Sessions d'entraînement: ${data.totalSessions}
- Objectifs atteints: ${data.goalsCompleted}

Top performers:
${data.horseStats
  .slice(0, 3)
  .map((h: any) => `- ${h.horseName}: ${h.averageScore?.toFixed(1) || 'N/A'}/100`)
  .join('\n')}

3 insights et 3 recommandations.

JSON: { "insights": ["..."], "recommendations": ["..."] }
`;

    const response = await this.costOptimization.smartRequest({
      task: 'quick_summary',
      prompt,
      useCache: true,
    });

    try {
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch {
      this.logger.debug('Failed to parse monthly insights');
    }

    return { insights: [], recommendations: [] };
  }

  private async analyzeProgressFactors(data: any): Promise<{
    factors: string[];
    recommendations: string[];
    risks: string[];
  }> {
    const prompt = `
Analyse prédictive en ${data.discipline}:

Historique (${data.metricHistory.length} points):
- Tendance: ${data.trend.slope > 0 ? 'positive' : 'négative'} (${data.trend.slope.toFixed(3)}/jour)
- R²: ${(data.trend.rSquared * 100).toFixed(1)}%

Horizon: ${data.horizonDays} jours

Identifie:
1. 3 facteurs influençant cette tendance
2. 3 recommandations pour optimiser
3. 2 risques potentiels

JSON: { "factors": ["..."], "recommendations": ["..."], "risks": ["..."] }
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
      this.logger.debug('Failed to parse progress factors');
    }

    return { factors: [], recommendations: [], risks: [] };
  }
}

// Type definitions
interface DisciplineEvolution {
  snapshotCount: number;
  startScore: number | null;
  endScore: number | null;
  averageScore: number | null;
  trend: string;
  improvement: number;
}

interface MetricTrendSummary {
  metricName: string;
  category: string;
  startValue: number;
  endValue: number;
  change: number;
  percentChange: number;
  trend: string;
  dataPoints: number;
}

interface ReportSummary {
  summary: string;
  highlights: string[];
  improvements: string[];
  recommendations: string[];
  nextSteps: string[];
}

interface HorseEvolutionReport {
  horse: {
    id: string;
    name: string;
    breed: string | null;
    age: number | null;
    level: string | null;
    disciplines: string[];
  };
  period: {
    start: Date;
    end: Date;
    durationDays: number;
  };
  summary: ReportSummary;
  performance: {
    totalSnapshots: number;
    evolutionByDiscipline: Record<string, DisciplineEvolution>;
    overallTrend: string;
    metricTrends: MetricTrendSummary[];
  };
  training: {
    stats: any;
    totalSessions: number;
    mostFrequentType: string | null;
    avgSessionsPerWeek: number;
  };
  goals: {
    active: number;
    achieved: number;
    failed: number;
    details: Array<{
      title: string;
      status: string;
      progress: number;
      targetDate: Date;
    }>;
  };
  health: {
    recordCount: number;
    lastCheckDate: Date | null;
    issues: number;
  };
  competitions: {
    count: number;
    results: Array<{
      date: Date;
      discipline: string | null;
      level: string | null;
      ranking: number | null;
      score: number | null;
    }>;
    bestResult: any;
  };
  benchmarkComparison: any;
  recommendations: string[];
  nextSteps: string[];
}

interface HorsePerformanceSummary {
  horseName: string;
  sessionsCount: number;
  averageScore: number;
  bestScore: number;
  trend: string;
}

interface RiderEvolutionReport {
  rider: {
    id: string;
    name: string;
    level: string | null;
    discipline: string | null;
    horsesCount: number;
  };
  period: {
    start: Date;
    end: Date;
    durationDays: number;
  };
  summary: ReportSummary;
  performance: {
    totalSnapshots: number;
    evolutionByDiscipline: Record<string, DisciplineEvolution>;
    overallTrend: string;
    metricTrends: MetricTrendSummary[];
    byHorse: Record<string, HorsePerformanceSummary>;
  };
  training: {
    stats: any;
    totalSessions: number;
    avgSessionsPerWeek: number;
  };
  goals: {
    active: number;
    achieved: number;
    failed: number;
    details: Array<{
      title: string;
      status: string;
      progress: number;
      targetDate: Date;
    }>;
  };
  recommendations: string[];
  nextSteps: string[];
}

interface HorseMonthlyStats {
  horseId: string;
  horseName: string;
  snapshotCount: number;
  sessionCount: number;
  totalTrainingMinutes: number;
  averageScore: number | null;
}

interface MonthlySummaryReport {
  period: {
    year: number;
    month: number;
    startDate: Date;
    endDate: Date;
  };
  summary: {
    totalHorsesActive: number;
    totalSnapshots: number;
    totalSessions: number;
    totalTrainingMinutes: number;
    goalsCompleted: number;
  };
  horseStats: HorseMonthlyStats[];
  topPerformers: HorseMonthlyStats[];
  mostImproved: HorseMonthlyStats[];
  insights: string[];
  recommendations: string[];
}

interface ProgressPrediction {
  canPredict: boolean;
  reason?: string;
  currentValue: number | null;
  predictedValue: number | null;
  changePerDay?: number;
  totalExpectedChange?: number;
  confidence: number;
  trend?: string;
  factors: string[];
  recommendations?: string[];
  riskFactors?: string[];
}
