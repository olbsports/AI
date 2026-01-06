import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CostOptimizationService } from './cost-optimization.service';
import { ProgressTrackingService, PerformanceSnapshot } from './progress-tracking.service';

/**
 * Comparison Service
 *
 * Enables comparisons between:
 * - Same subject over different time periods (temporal comparison)
 * - Different horses or riders (cross-subject comparison)
 * - Subject vs benchmarks/averages (benchmark comparison)
 */
@Injectable()
export class ComparisonService {
  private readonly logger = new Logger(ComparisonService.name);

  constructor(
    private prisma: PrismaService,
    private progressTracking: ProgressTrackingService,
    private costOptimization: CostOptimizationService
  ) {}

  // ==================== TEMPORAL COMPARISON ====================

  /**
   * Compare a subject's performance across different time periods
   */
  async compareTemporalPeriods(params: {
    subjectType: 'horse' | 'rider' | 'pair';
    horseId?: string;
    riderId?: string;
    discipline?: string;
    periods: Array<{ label: string; start: Date; end: Date }>;
    metrics?: string[];
  }): Promise<TemporalComparison> {
    const periodData: PeriodData[] = [];

    // Get data for each period
    for (const period of params.periods) {
      const snapshots = await this.progressTracking.getPerformanceHistory({
        subjectType: params.subjectType,
        horseId: params.horseId,
        riderId: params.riderId,
        discipline: params.discipline,
        periodStart: period.start,
        periodEnd: period.end,
      });

      const averages = this.calculatePeriodAverages(snapshots, params.metrics);

      periodData.push({
        label: period.label,
        period: { start: period.start, end: period.end },
        snapshotCount: snapshots.length,
        averages,
        bestScores: this.getBestScores(snapshots),
        worstScores: this.getWorstScores(snapshots),
      });
    }

    // Calculate trends between consecutive periods
    const trends = this.calculatePeriodTrends(periodData);

    // Get AI insights
    const insights = await this.getTemporalInsights(periodData, trends, params);

    // Store comparison report
    const report = await this.storeComparisonReport({
      comparisonType: 'temporal',
      subjects: [
        {
          type: params.subjectType,
          horseId: params.horseId,
          riderId: params.riderId,
        },
      ],
      discipline: params.discipline,
      periodStart: params.periods[0].start,
      periodEnd: params.periods[params.periods.length - 1].end,
      metrics: params.metrics || [],
      results: { periodData, trends },
      insights: insights.insights,
      recommendations: insights.recommendations,
      chartData: this.generateTemporalChartData(periodData),
    });

    return {
      reportId: report.id,
      subjectType: params.subjectType,
      horseId: params.horseId,
      riderId: params.riderId,
      discipline: params.discipline,
      periodData,
      trends,
      overallProgress: this.calculateOverallProgress(trends),
      insights: insights.insights,
      recommendations: insights.recommendations,
      chartData: this.generateTemporalChartData(periodData),
    };
  }

  // ==================== CROSS-SUBJECT COMPARISON ====================

  /**
   * Compare multiple horses or riders
   */
  async compareSubjects(params: {
    subjects: Array<{
      type: 'horse' | 'rider';
      id: string;
      name?: string;
    }>;
    discipline: string;
    level?: string;
    periodStart: Date;
    periodEnd: Date;
    metrics?: string[];
  }): Promise<CrossSubjectComparison> {
    const subjectData: SubjectComparisonData[] = [];

    // Get data for each subject
    for (const subject of params.subjects) {
      const snapshots = await this.progressTracking.getPerformanceHistory({
        subjectType: subject.type,
        horseId: subject.type === 'horse' ? subject.id : undefined,
        riderId: subject.type === 'rider' ? subject.id : undefined,
        discipline: params.discipline,
        periodStart: params.periodStart,
        periodEnd: params.periodEnd,
      });

      // Get subject name if not provided
      let name = subject.name;
      if (!name) {
        if (subject.type === 'horse') {
          const horse = await this.prisma.horse.findUnique({
            where: { id: subject.id },
            select: { name: true },
          });
          name = horse?.name || 'Unknown';
        } else {
          const rider = await this.prisma.rider.findUnique({
            where: { id: subject.id },
            select: { firstName: true, lastName: true },
          });
          name = rider ? `${rider.firstName} ${rider.lastName}` : 'Unknown';
        }
      }

      const averages = this.calculatePeriodAverages(snapshots, params.metrics);

      subjectData.push({
        subject: { ...subject, name: name || 'Unknown' },
        snapshotCount: snapshots.length,
        averages,
        strengths: this.identifyStrengths(averages),
        weaknesses: this.identifyWeaknesses(averages),
      });
    }

    // Calculate rankings for each metric
    const rankings = this.calculateRankings(subjectData, params.metrics);

    // Get AI insights
    const insights = await this.getCrossSubjectInsights(subjectData, rankings, params);

    // Store report
    const report = await this.storeComparisonReport({
      comparisonType: 'cross_subject',
      subjects: params.subjects,
      discipline: params.discipline,
      level: params.level,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
      metrics: params.metrics || [],
      results: { subjectData },
      rankings,
      insights: insights.insights,
      recommendations: insights.recommendations,
      chartData: this.generateCrossSubjectChartData(subjectData, params.metrics),
    });

    return {
      reportId: report.id,
      discipline: params.discipline,
      level: params.level,
      period: { start: params.periodStart, end: params.periodEnd },
      subjects: subjectData,
      rankings,
      insights: insights.insights,
      recommendations: insights.recommendations,
      chartData: this.generateCrossSubjectChartData(subjectData, params.metrics),
    };
  }

  // ==================== BENCHMARK COMPARISON ====================

  /**
   * Compare a subject against level/discipline benchmarks
   */
  async compareToBenchmark(params: {
    subjectType: 'horse' | 'rider' | 'pair';
    horseId?: string;
    riderId?: string;
    discipline: string;
    level: string;
    periodStart: Date;
    periodEnd: Date;
    metrics?: string[];
  }): Promise<BenchmarkComparison> {
    // Get subject's performance
    const snapshots = await this.progressTracking.getPerformanceHistory({
      subjectType: params.subjectType,
      horseId: params.horseId,
      riderId: params.riderId,
      discipline: params.discipline,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    });

    const subjectAverages = this.calculatePeriodAverages(snapshots, params.metrics);

    // Get benchmark data (aggregate from all subjects at same level)
    const benchmarkSnapshots = await this.prisma.performanceSnapshot.findMany({
      where: {
        discipline: params.discipline,
        level: params.level,
        snapshotDate: {
          gte: params.periodStart,
          lte: params.periodEnd,
        },
        // Exclude the subject being compared
        NOT: {
          AND: [
            params.horseId ? { horseId: params.horseId } : {},
            params.riderId ? { riderId: params.riderId } : {},
          ],
        },
      },
    });

    const benchmarkAverages = this.calculatePeriodAverages(
      benchmarkSnapshots as any,
      params.metrics
    );
    const benchmarkPercentiles = this.calculatePercentiles(
      benchmarkSnapshots as any,
      params.metrics
    );

    // Calculate position vs benchmark
    const position = this.calculateBenchmarkPosition(
      subjectAverages,
      benchmarkPercentiles,
      params.metrics
    );

    // Get AI insights
    const insights = await this.getBenchmarkInsights(
      subjectAverages,
      benchmarkAverages,
      position,
      params
    );

    // Store report
    const report = await this.storeComparisonReport({
      comparisonType: 'benchmark',
      subjects: [
        {
          type: params.subjectType,
          horseId: params.horseId,
          riderId: params.riderId,
        },
      ],
      discipline: params.discipline,
      level: params.level,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
      metrics: params.metrics || [],
      results: {
        subjectAverages,
        benchmarkAverages,
        benchmarkPercentiles,
        position,
        benchmarkSampleSize: benchmarkSnapshots.length,
      },
      insights: insights.insights,
      recommendations: insights.recommendations,
      chartData: this.generateBenchmarkChartData(
        subjectAverages,
        benchmarkAverages,
        position,
        params.metrics
      ),
    });

    return {
      reportId: report.id,
      subjectType: params.subjectType,
      horseId: params.horseId,
      riderId: params.riderId,
      discipline: params.discipline,
      level: params.level,
      period: { start: params.periodStart, end: params.periodEnd },
      subjectScores: subjectAverages,
      benchmarkScores: benchmarkAverages,
      percentiles: benchmarkPercentiles,
      position,
      benchmarkSampleSize: benchmarkSnapshots.length,
      insights: insights.insights,
      recommendations: insights.recommendations,
      chartData: this.generateBenchmarkChartData(
        subjectAverages,
        benchmarkAverages,
        position,
        params.metrics
      ),
    };
  }

  // ==================== HORSE-RIDER PAIR ANALYSIS ====================

  /**
   * Analyze compatibility and harmony between horse and rider
   */
  async analyzeHorseRiderPair(params: {
    horseId: string;
    riderId: string;
    discipline: string;
    periodStart: Date;
    periodEnd: Date;
  }): Promise<PairAnalysis> {
    // Get individual performances
    const [horseSnapshots, riderSnapshots, pairSnapshots] = await Promise.all([
      this.progressTracking.getPerformanceHistory({
        subjectType: 'horse',
        horseId: params.horseId,
        discipline: params.discipline,
        periodStart: params.periodStart,
        periodEnd: params.periodEnd,
      }),
      this.progressTracking.getPerformanceHistory({
        subjectType: 'rider',
        riderId: params.riderId,
        discipline: params.discipline,
        periodStart: params.periodStart,
        periodEnd: params.periodEnd,
      }),
      this.progressTracking.getPerformanceHistory({
        subjectType: 'pair',
        horseId: params.horseId,
        riderId: params.riderId,
        discipline: params.discipline,
        periodStart: params.periodStart,
        periodEnd: params.periodEnd,
      }),
    ]);

    // Calculate compatibility scores
    const horseAvg = this.calculatePeriodAverages(horseSnapshots);
    const riderAvg = this.calculatePeriodAverages(riderSnapshots);
    const pairAvg = this.calculatePeriodAverages(pairSnapshots);

    // Calculate harmony - how well the pair performs together vs individually
    const harmonyScore = this.calculateHarmonyScore(horseAvg, riderAvg, pairAvg);

    // Identify complementary aspects
    const complementary = this.findComplementaryAspects(horseAvg, riderAvg);

    // Identify areas needing work
    const improvementAreas = this.findPairImprovementAreas(horseAvg, riderAvg, pairAvg);

    // Get AI analysis
    const aiAnalysis = await this.getPairAnalysisInsights({
      horseAvg,
      riderAvg,
      pairAvg,
      harmonyScore,
      complementary,
      improvementAreas,
      discipline: params.discipline,
    });

    // Get horse and rider info
    const [horse, rider] = await Promise.all([
      this.prisma.horse.findUnique({
        where: { id: params.horseId },
        select: { name: true },
      }),
      this.prisma.rider.findUnique({
        where: { id: params.riderId },
        select: { firstName: true, lastName: true },
      }),
    ]);

    return {
      horse: {
        id: params.horseId,
        name: horse?.name || 'Unknown',
        averageScores: horseAvg,
      },
      rider: {
        id: params.riderId,
        name: rider ? `${rider.firstName} ${rider.lastName}` : 'Unknown',
        averageScores: riderAvg,
      },
      pair: {
        averageScores: pairAvg,
        harmonyScore,
        dataPoints: pairSnapshots.length,
      },
      compatibility: {
        overall: harmonyScore,
        complementaryAspects: complementary,
        challengeAreas: improvementAreas,
      },
      insights: aiAnalysis.insights,
      recommendations: aiAnalysis.recommendations,
      trainingFocus: aiAnalysis.trainingFocus,
    };
  }

  // ==================== HELPER METHODS ====================

  private calculatePeriodAverages(
    snapshots: PerformanceSnapshot[],
    metricFilter?: string[]
  ): Record<string, number> {
    if (snapshots.length === 0) return {};

    const sums: Record<string, number> = {};
    const counts: Record<string, number> = {};

    for (const snapshot of snapshots) {
      // Standard scores
      const scoreFields = [
        'globalScore',
        'techniqueScore',
        'physicalScore',
        'mentalScore',
        'harmonyScore',
      ];
      for (const field of scoreFields) {
        const value = (snapshot as any)[field];
        if (value !== null && value !== undefined) {
          if (!metricFilter || metricFilter.includes(field)) {
            sums[field] = (sums[field] || 0) + value;
            counts[field] = (counts[field] || 0) + 1;
          }
        }
      }

      // Custom metrics
      const metrics = snapshot.metrics as Record<string, number>;
      for (const [key, value] of Object.entries(metrics)) {
        if (typeof value === 'number') {
          if (!metricFilter || metricFilter.includes(key)) {
            sums[key] = (sums[key] || 0) + value;
            counts[key] = (counts[key] || 0) + 1;
          }
        }
      }
    }

    const averages: Record<string, number> = {};
    for (const key of Object.keys(sums)) {
      averages[key] = sums[key] / counts[key];
    }

    return averages;
  }

  private getBestScores(snapshots: PerformanceSnapshot[]): Record<string, number> {
    if (snapshots.length === 0) return {};

    const best: Record<string, number> = {};

    for (const snapshot of snapshots) {
      if (
        snapshot.globalScore &&
        (!best['globalScore'] || snapshot.globalScore > best['globalScore'])
      ) {
        best['globalScore'] = snapshot.globalScore;
      }
      // Add other score fields...
    }

    return best;
  }

  private getWorstScores(snapshots: PerformanceSnapshot[]): Record<string, number> {
    if (snapshots.length === 0) return {};

    const worst: Record<string, number> = {};

    for (const snapshot of snapshots) {
      if (
        snapshot.globalScore &&
        (!worst['globalScore'] || snapshot.globalScore < worst['globalScore'])
      ) {
        worst['globalScore'] = snapshot.globalScore;
      }
    }

    return worst;
  }

  private calculatePeriodTrends(periodData: PeriodData[]): PeriodTrend[] {
    const trends: PeriodTrend[] = [];

    for (let i = 1; i < periodData.length; i++) {
      const prev = periodData[i - 1];
      const curr = periodData[i];

      const changes: Record<string, { change: number; percent: number }> = {};

      for (const key of Object.keys(curr.averages)) {
        const prevVal = prev.averages[key] || 0;
        const currVal = curr.averages[key] || 0;
        const change = currVal - prevVal;
        const percent = prevVal !== 0 ? (change / prevVal) * 100 : 0;

        changes[key] = { change, percent };
      }

      trends.push({
        from: prev.label,
        to: curr.label,
        changes,
        overallDirection: this.determineOverallDirection(changes),
      });
    }

    return trends;
  }

  private determineOverallDirection(
    changes: Record<string, { change: number; percent: number }>
  ): string {
    const values = Object.values(changes);
    const improving = values.filter((v) => v.percent > 2).length;
    const declining = values.filter((v) => v.percent < -2).length;

    if (improving > declining * 1.5) return 'improving';
    if (declining > improving * 1.5) return 'declining';
    return 'stable';
  }

  private calculateOverallProgress(trends: PeriodTrend[]): string {
    if (trends.length === 0) return 'unknown';

    const directions = trends.map((t) => t.overallDirection);
    const improving = directions.filter((d) => d === 'improving').length;
    const declining = directions.filter((d) => d === 'declining').length;

    if (improving > declining) return 'positive';
    if (declining > improving) return 'negative';
    return 'stable';
  }

  private identifyStrengths(averages: Record<string, number>): string[] {
    const entries = Object.entries(averages);
    return entries
      .filter(([, value]) => value >= 75)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(([key]) => key);
  }

  private identifyWeaknesses(averages: Record<string, number>): string[] {
    const entries = Object.entries(averages);
    return entries
      .filter(([, value]) => value < 60)
      .sort((a, b) => a[1] - b[1])
      .slice(0, 3)
      .map(([key]) => key);
  }

  private calculateRankings(
    subjectData: SubjectComparisonData[],
    metrics?: string[]
  ): Record<string, SubjectRanking[]> {
    const rankings: Record<string, SubjectRanking[]> = {};

    // Get all metrics present
    const allMetrics = new Set<string>();
    for (const data of subjectData) {
      for (const key of Object.keys(data.averages)) {
        if (!metrics || metrics.includes(key)) {
          allMetrics.add(key);
        }
      }
    }

    // Rank for each metric
    for (const metric of allMetrics) {
      const sorted = [...subjectData]
        .filter((d) => d.averages[metric] !== undefined)
        .sort((a, b) => (b.averages[metric] || 0) - (a.averages[metric] || 0));

      rankings[metric] = sorted.map((d, index) => ({
        rank: index + 1,
        subject: d.subject,
        value: d.averages[metric] || 0,
      }));
    }

    return rankings;
  }

  private calculatePercentiles(
    snapshots: PerformanceSnapshot[],
    metrics?: string[]
  ): Record<string, { p25: number; p50: number; p75: number; p90: number }> {
    const values: Record<string, number[]> = {};

    for (const snapshot of snapshots) {
      // Collect values for each metric
      const allMetrics = { ...(snapshot.metrics as any), globalScore: snapshot.globalScore };
      for (const [key, value] of Object.entries(allMetrics)) {
        if (typeof value === 'number' && (!metrics || metrics.includes(key))) {
          if (!values[key]) values[key] = [];
          values[key].push(value);
        }
      }
    }

    const percentiles: Record<string, { p25: number; p50: number; p75: number; p90: number }> = {};

    for (const [key, vals] of Object.entries(values)) {
      if (vals.length === 0) continue;

      vals.sort((a, b) => a - b);

      percentiles[key] = {
        p25: this.percentile(vals, 25),
        p50: this.percentile(vals, 50),
        p75: this.percentile(vals, 75),
        p90: this.percentile(vals, 90),
      };
    }

    return percentiles;
  }

  private percentile(arr: number[], p: number): number {
    const index = (p / 100) * (arr.length - 1);
    const lower = Math.floor(index);
    const upper = Math.ceil(index);

    if (lower === upper) return arr[lower];

    return arr[lower] + (arr[upper] - arr[lower]) * (index - lower);
  }

  private calculateBenchmarkPosition(
    subjectAverages: Record<string, number>,
    percentiles: Record<string, { p25: number; p50: number; p75: number; p90: number }>,
    metrics?: string[]
  ): Record<string, { value: number; percentile: number; rating: string }> {
    const position: Record<string, { value: number; percentile: number; rating: string }> = {};

    for (const key of Object.keys(subjectAverages)) {
      if (metrics && !metrics.includes(key)) continue;

      const value = subjectAverages[key];
      const pct = percentiles[key];

      if (!pct) continue;

      let percentilePosition: number;
      let rating: string;

      if (value >= pct.p90) {
        percentilePosition = 90 + (10 * (value - pct.p90)) / (100 - pct.p90);
        rating = 'excellent';
      } else if (value >= pct.p75) {
        percentilePosition = 75 + (15 * (value - pct.p75)) / (pct.p90 - pct.p75);
        rating = 'très bon';
      } else if (value >= pct.p50) {
        percentilePosition = 50 + (25 * (value - pct.p50)) / (pct.p75 - pct.p50);
        rating = 'bon';
      } else if (value >= pct.p25) {
        percentilePosition = 25 + (25 * (value - pct.p25)) / (pct.p50 - pct.p25);
        rating = 'moyen';
      } else {
        percentilePosition = (25 * value) / pct.p25;
        rating = 'à améliorer';
      }

      position[key] = {
        value,
        percentile: Math.min(100, Math.max(0, percentilePosition)),
        rating,
      };
    }

    return position;
  }

  private calculateHarmonyScore(
    horseAvg: Record<string, number>,
    riderAvg: Record<string, number>,
    pairAvg: Record<string, number>
  ): number {
    // Compare pair performance to expected (average of individuals)
    const metrics = Object.keys(pairAvg);
    if (metrics.length === 0) return 50;

    let totalDiff = 0;
    let count = 0;

    for (const metric of metrics) {
      const expected = ((horseAvg[metric] || 0) + (riderAvg[metric] || 0)) / 2;
      const actual = pairAvg[metric] || 0;

      // Positive diff means pair performs better than expected
      const diff = actual - expected;
      totalDiff += diff;
      count++;
    }

    // Convert to 0-100 score (50 = as expected, >50 = synergy, <50 = friction)
    const avgDiff = count > 0 ? totalDiff / count : 0;
    return Math.max(0, Math.min(100, 50 + avgDiff));
  }

  private findComplementaryAspects(
    horseAvg: Record<string, number>,
    riderAvg: Record<string, number>
  ): string[] {
    const complementary: string[] = [];

    // Find where one is strong and other is weak (they complement each other)
    const metrics = new Set([...Object.keys(horseAvg), ...Object.keys(riderAvg)]);

    for (const metric of metrics) {
      const horse = horseAvg[metric] || 0;
      const rider = riderAvg[metric] || 0;

      // One strong (>70), other weaker but pair average good
      if ((horse > 70 && rider < 60) || (rider > 70 && horse < 60)) {
        const stronger = horse > rider ? 'cheval' : 'cavalier';
        complementary.push(`${metric} (${stronger} compense)`);
      }
    }

    return complementary.slice(0, 5);
  }

  private findPairImprovementAreas(
    horseAvg: Record<string, number>,
    riderAvg: Record<string, number>,
    pairAvg: Record<string, number>
  ): string[] {
    const improvements: Array<{ metric: string; issue: string }> = [];

    for (const [metric, pairValue] of Object.entries(pairAvg)) {
      const horseValue = horseAvg[metric] || 0;
      const riderValue = riderAvg[metric] || 0;
      const expected = (horseValue + riderValue) / 2;

      // Pair underperforming compared to individuals
      if (pairValue < expected - 5) {
        improvements.push({
          metric,
          issue: 'harmonie',
        });
      }

      // Both weak in this area
      if (horseValue < 60 && riderValue < 60) {
        improvements.push({
          metric,
          issue: 'faiblesse commune',
        });
      }
    }

    return improvements
      .sort((a, b) => {
        // Priority: harmony issues first
        if (a.issue === 'harmonie' && b.issue !== 'harmonie') return -1;
        if (b.issue === 'harmonie' && a.issue !== 'harmonie') return 1;
        return 0;
      })
      .slice(0, 5)
      .map((i) => `${i.metric} (${i.issue})`);
  }

  private async storeComparisonReport(data: {
    comparisonType: string;
    subjects: any[];
    discipline?: string;
    level?: string;
    periodStart?: Date;
    periodEnd?: Date;
    metrics: string[];
    results: any;
    rankings?: any;
    insights: string[];
    recommendations: string[];
    chartData?: any;
  }): Promise<{ id: string }> {
    const report = await this.prisma.comparisonReport.create({
      data: {
        comparisonType: data.comparisonType,
        subjects: data.subjects,
        discipline: data.discipline,
        level: data.level,
        periodStart: data.periodStart,
        periodEnd: data.periodEnd,
        metrics: data.metrics,
        results: data.results,
        rankings: data.rankings,
        insights: data.insights,
        recommendations: data.recommendations,
        chartData: data.chartData,
      },
    });

    return { id: report.id };
  }

  // ==================== AI INSIGHTS METHODS ====================

  private async getTemporalInsights(
    periodData: PeriodData[],
    trends: PeriodTrend[],
    params: any
  ): Promise<{ insights: string[]; recommendations: string[] }> {
    const prompt = `
Analyse l'évolution temporelle des performances en ${params.discipline || 'équitation'}:

Périodes analysées:
${periodData.map((p) => `- ${p.label}: Score global moyen ${(p.averages['globalScore'] || 0).toFixed(1)}/100`).join('\n')}

Tendances:
${trends.map((t) => `- ${t.from} → ${t.to}: ${t.overallDirection}`).join('\n')}

Métriques principales:
${Object.entries(periodData[periodData.length - 1]?.averages || {})
  .slice(0, 5)
  .map(([k, v]) => `- ${k}: ${v.toFixed(1)}`)
  .join('\n')}

Fournis 3 insights clés et 3 recommandations concrètes.

JSON: { "insights": ["..."], "recommendations": ["..."] }
`;

    return this.parseAIResponse(prompt);
  }

  private async getCrossSubjectInsights(
    subjectData: SubjectComparisonData[],
    rankings: any,
    params: any
  ): Promise<{ insights: string[]; recommendations: string[] }> {
    const prompt = `
Comparaison de ${subjectData.length} sujets en ${params.discipline}:

${subjectData
  .map(
    (s) => `${s.subject.name}:
  - Score global: ${(s.averages['globalScore'] || 0).toFixed(1)}
  - Points forts: ${s.strengths.join(', ') || 'N/A'}
  - Points faibles: ${s.weaknesses.join(', ') || 'N/A'}`
  )
  .join('\n\n')}

Classement global: ${rankings['globalScore']?.map((r: any) => `${r.rank}. ${r.subject.name}`).join(', ') || 'N/A'}

Fournis 3 insights sur les différences et 3 recommandations.

JSON: { "insights": ["..."], "recommendations": ["..."] }
`;

    return this.parseAIResponse(prompt);
  }

  private async getBenchmarkInsights(
    subjectAverages: Record<string, number>,
    benchmarkAverages: Record<string, number>,
    position: Record<string, any>,
    params: any
  ): Promise<{ insights: string[]; recommendations: string[] }> {
    const prompt = `
Comparaison aux benchmarks ${params.discipline} niveau ${params.level}:

Performance du sujet vs moyenne du niveau:
${Object.entries(position)
  .slice(0, 5)
  .map(
    ([k, v]) =>
      `- ${k}: ${v.value.toFixed(1)} (${v.rating}, percentile ${v.percentile.toFixed(0)}%)`
  )
  .join('\n')}

Échantillon benchmark: ${params.benchmarkSampleSize || 0} sujets

Fournis 3 insights et 3 recommandations pour progresser vers le niveau supérieur.

JSON: { "insights": ["..."], "recommendations": ["..."] }
`;

    return this.parseAIResponse(prompt);
  }

  private async getPairAnalysisInsights(data: {
    horseAvg: Record<string, number>;
    riderAvg: Record<string, number>;
    pairAvg: Record<string, number>;
    harmonyScore: number;
    complementary: string[];
    improvementAreas: string[];
    discipline: string;
  }): Promise<{ insights: string[]; recommendations: string[]; trainingFocus: string[] }> {
    const prompt = `
Analyse du couple cheval-cavalier en ${data.discipline}:

Harmonie globale: ${data.harmonyScore.toFixed(1)}/100

Scores moyens:
- Cheval: ${(data.horseAvg['globalScore'] || 0).toFixed(1)}
- Cavalier: ${(data.riderAvg['globalScore'] || 0).toFixed(1)}
- Couple: ${(data.pairAvg['globalScore'] || 0).toFixed(1)}

Points de complémentarité: ${data.complementary.join(', ') || 'Aucun identifié'}
Axes d'amélioration: ${data.improvementAreas.join(', ') || 'Aucun identifié'}

Fournis:
1. 3 insights sur la compatibilité
2. 3 recommandations pour améliorer l'harmonie
3. 3 exercices prioritaires

JSON: { "insights": ["..."], "recommendations": ["..."], "trainingFocus": ["..."] }
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
      this.logger.debug('Failed to parse pair analysis');
    }

    return { insights: [], recommendations: [], trainingFocus: [] };
  }

  private async parseAIResponse(
    prompt: string
  ): Promise<{ insights: string[]; recommendations: string[] }> {
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
      this.logger.debug('Failed to parse AI response');
    }

    return { insights: [], recommendations: [] };
  }

  // ==================== CHART DATA GENERATION ====================

  private generateTemporalChartData(periodData: PeriodData[]): any {
    return {
      type: 'line',
      labels: periodData.map((p) => p.label),
      datasets: [
        {
          label: 'Score Global',
          data: periodData.map((p) => p.averages['globalScore'] || 0),
        },
        {
          label: 'Technique',
          data: periodData.map((p) => p.averages['techniqueScore'] || 0),
        },
        {
          label: 'Physique',
          data: periodData.map((p) => p.averages['physicalScore'] || 0),
        },
      ],
    };
  }

  private generateCrossSubjectChartData(
    subjectData: SubjectComparisonData[],
    metrics?: string[]
  ): any {
    const displayMetrics = metrics || ['globalScore', 'techniqueScore', 'physicalScore'];

    return {
      type: 'radar',
      labels: displayMetrics,
      datasets: subjectData.map((s) => ({
        label: s.subject.name,
        data: displayMetrics.map((m) => s.averages[m] || 0),
      })),
    };
  }

  private generateBenchmarkChartData(
    subjectAverages: Record<string, number>,
    benchmarkAverages: Record<string, number>,
    position: Record<string, any>,
    metrics?: string[]
  ): any {
    const displayMetrics = metrics || Object.keys(subjectAverages).slice(0, 6);

    return {
      type: 'bar',
      labels: displayMetrics,
      datasets: [
        {
          label: 'Sujet',
          data: displayMetrics.map((m) => subjectAverages[m] || 0),
        },
        {
          label: 'Benchmark (moyenne)',
          data: displayMetrics.map((m) => benchmarkAverages[m] || 0),
        },
      ],
      percentiles: Object.fromEntries(
        displayMetrics.map((m) => [m, position[m]?.percentile || 50])
      ),
    };
  }
}

// Type definitions
interface PeriodData {
  label: string;
  period: { start: Date; end: Date };
  snapshotCount: number;
  averages: Record<string, number>;
  bestScores: Record<string, number>;
  worstScores: Record<string, number>;
}

interface PeriodTrend {
  from: string;
  to: string;
  changes: Record<string, { change: number; percent: number }>;
  overallDirection: string;
}

interface TemporalComparison {
  reportId: string;
  subjectType: string;
  horseId?: string;
  riderId?: string;
  discipline?: string;
  periodData: PeriodData[];
  trends: PeriodTrend[];
  overallProgress: string;
  insights: string[];
  recommendations: string[];
  chartData: any;
}

interface SubjectComparisonData {
  subject: { type: string; id: string; name: string };
  snapshotCount: number;
  averages: Record<string, number>;
  strengths: string[];
  weaknesses: string[];
}

interface SubjectRanking {
  rank: number;
  subject: { type: string; id: string; name: string };
  value: number;
}

interface CrossSubjectComparison {
  reportId: string;
  discipline: string;
  level?: string;
  period: { start: Date; end: Date };
  subjects: SubjectComparisonData[];
  rankings: Record<string, SubjectRanking[]>;
  insights: string[];
  recommendations: string[];
  chartData: any;
}

interface BenchmarkComparison {
  reportId: string;
  subjectType: string;
  horseId?: string;
  riderId?: string;
  discipline: string;
  level: string;
  period: { start: Date; end: Date };
  subjectScores: Record<string, number>;
  benchmarkScores: Record<string, number>;
  percentiles: Record<string, { p25: number; p50: number; p75: number; p90: number }>;
  position: Record<string, { value: number; percentile: number; rating: string }>;
  benchmarkSampleSize: number;
  insights: string[];
  recommendations: string[];
  chartData: any;
}

interface PairAnalysis {
  horse: {
    id: string;
    name: string;
    averageScores: Record<string, number>;
  };
  rider: {
    id: string;
    name: string;
    averageScores: Record<string, number>;
  };
  pair: {
    averageScores: Record<string, number>;
    harmonyScore: number;
    dataPoints: number;
  };
  compatibility: {
    overall: number;
    complementaryAspects: string[];
    challengeAreas: string[];
  };
  insights: string[];
  recommendations: string[];
  trainingFocus: string[];
}
