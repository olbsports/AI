import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../models/performance.dart';
import '../../providers/horses_provider.dart';
import '../../theme/app_theme.dart';

/// Performance chart widget displaying horse performance metrics over time
/// Shows competition results, training progress, and various performance indicators
class PerformanceChartWidget extends ConsumerStatefulWidget {
  final String horseId;
  final PerformanceMetricType initialMetric;

  const PerformanceChartWidget({
    super.key,
    required this.horseId,
    this.initialMetric = PerformanceMetricType.competitionRank,
  });

  @override
  ConsumerState<PerformanceChartWidget> createState() => _PerformanceChartWidgetState();
}

class _PerformanceChartWidgetState extends ConsumerState<PerformanceChartWidget> {
  late PerformanceMetricType _selectedMetric;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric;
    // Default to last 12 months
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 365)),
      end: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final competitionsAsync = ref.watch(competitionResultsProvider(widget.horseId));
    final trainingAsync = ref.watch(trainingSessionsProvider(widget.horseId));
    final summaryAsync = ref.watch(performanceSummaryProvider(widget.horseId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and metric selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _buildMetricSelector(context),
              ],
            ),
            const SizedBox(height: 8),

            // Summary stats
            summaryAsync.when(
              data: (summary) => _buildSummaryStats(context, summary),
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox(height: 40),
            ),
            const SizedBox(height: 16),

            // Chart
            SizedBox(
              height: 220,
              child: _buildChartContent(context, competitionsAsync, trainingAsync),
            ),

            // Date range selector
            const SizedBox(height: 12),
            _buildDateRangeSelector(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSelector(BuildContext context) {
    return PopupMenuButton<PerformanceMetricType>(
      initialValue: _selectedMetric,
      onSelected: (value) => setState(() => _selectedMetric = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _selectedMetric.icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              _selectedMetric.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => PerformanceMetricType.values
          .map((metric) => PopupMenuItem(
                value: metric,
                child: Row(
                  children: [
                    Icon(metric.icon, size: 18),
                    const SizedBox(width: 8),
                    Text(metric.displayName),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSummaryStats(BuildContext context, PerformanceSummary summary) {
    return Row(
      children: [
        _buildStatItem(
          context,
          label: 'Competitions',
          value: '${summary.totalCompetitions}',
          icon: Icons.emoji_events,
          color: AppColors.tertiary,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          context,
          label: 'Victoires',
          value: '${summary.victories}',
          icon: Icons.military_tech,
          color: AppColors.success,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          context,
          label: 'Podiums',
          value: '${summary.podiums}',
          icon: Icons.workspace_premium,
          color: AppColors.info,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          context,
          label: 'Entrainements',
          value: '${summary.totalTrainingSessions}',
          icon: Icons.fitness_center,
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartContent(
    BuildContext context,
    AsyncValue<List<CompetitionResult>> competitionsAsync,
    AsyncValue<List<TrainingSession>> trainingAsync,
  ) {
    return competitionsAsync.when(
      data: (competitions) => trainingAsync.when(
        data: (training) => _buildChart(context, competitions, training),
        loading: () => _buildLoadingChart(context),
        error: (e, _) => _buildErrorChart(context, e.toString()),
      ),
      loading: () => _buildLoadingChart(context),
      error: (e, _) => _buildErrorChart(context, e.toString()),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<CompetitionResult> competitions,
    List<TrainingSession> training,
  ) {
    final spots = _getChartData(competitions, training);

    if (spots.isEmpty) {
      return _buildEmptyChart(context);
    }

    final minY = _getMinY(spots);
    final maxY = _getMaxY(spots);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (maxY - minY) / 4,
              getTitlesWidget: (value, meta) => Text(
                _formatYAxisValue(value),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getXInterval(spots),
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM').format(date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: _selectedMetric.color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: _selectedMetric.color,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _selectedMetric.color.withValues(alpha: 0.3),
                  _selectedMetric.color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                Theme.of(context).colorScheme.inverseSurface,
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              return LineTooltipItem(
                '${DateFormat('dd/MM/yy').format(date)}\n${_formatTooltipValue(spot.y)}',
                TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        minY: minY,
        maxY: maxY,
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  List<FlSpot> _getChartData(
    List<CompetitionResult> competitions,
    List<TrainingSession> training,
  ) {
    switch (_selectedMetric) {
      case PerformanceMetricType.competitionRank:
        return _getCompetitionRankData(competitions);
      case PerformanceMetricType.competitionScore:
        return _getCompetitionScoreData(competitions);
      case PerformanceMetricType.trainingDuration:
        return _getTrainingDurationData(training);
      case PerformanceMetricType.trainingIntensity:
        return _getTrainingIntensityData(training);
      case PerformanceMetricType.trainingQuality:
        return _getTrainingQualityData(training);
    }
  }

  List<FlSpot> _getCompetitionRankData(List<CompetitionResult> competitions) {
    final filtered = _filterByDateRange(competitions, (c) => c.date)
        .where((c) => c.rank != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return filtered
        .map((c) => FlSpot(
              c.date.millisecondsSinceEpoch.toDouble(),
              c.rank!.toDouble(),
            ))
        .toList();
  }

  List<FlSpot> _getCompetitionScoreData(List<CompetitionResult> competitions) {
    final filtered = _filterByDateRange(competitions, (c) => c.date)
        .where((c) => c.score != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return filtered
        .map((c) => FlSpot(
              c.date.millisecondsSinceEpoch.toDouble(),
              c.score!,
            ))
        .toList();
  }

  List<FlSpot> _getTrainingDurationData(List<TrainingSession> training) {
    final filtered = _filterByDateRange(training, (t) => t.date).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Group by week and average
    final Map<int, List<int>> weeklyDurations = {};
    for (final session in filtered) {
      final weekStart = _getWeekStart(session.date);
      weeklyDurations.putIfAbsent(weekStart.millisecondsSinceEpoch, () => []);
      weeklyDurations[weekStart.millisecondsSinceEpoch]!.add(session.durationMinutes);
    }

    return weeklyDurations.entries
        .map((e) => FlSpot(
              e.key.toDouble(),
              e.value.reduce((a, b) => a + b) / e.value.length,
            ))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  List<FlSpot> _getTrainingIntensityData(List<TrainingSession> training) {
    final filtered = _filterByDateRange(training, (t) => t.date).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return filtered
        .map((t) => FlSpot(
              t.date.millisecondsSinceEpoch.toDouble(),
              _intensityToValue(t.intensity),
            ))
        .toList();
  }

  List<FlSpot> _getTrainingQualityData(List<TrainingSession> training) {
    final filtered = _filterByDateRange(training, (t) => t.date)
        .where((t) => t.qualityRating != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return filtered
        .map((t) => FlSpot(
              t.date.millisecondsSinceEpoch.toDouble(),
              t.qualityRating!.toDouble(),
            ))
        .toList();
  }

  List<T> _filterByDateRange<T>(List<T> items, DateTime Function(T) getDate) {
    if (_dateRange == null) return items;
    return items.where((item) {
      final date = getDate(item);
      return date.isAfter(_dateRange!.start) && date.isBefore(_dateRange!.end);
    }).toList();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  double _intensityToValue(TrainingIntensity intensity) {
    switch (intensity) {
      case TrainingIntensity.rest:
        return 1;
      case TrainingIntensity.light:
        return 2;
      case TrainingIntensity.moderate:
        return 3;
      case TrainingIntensity.intense:
        return 4;
      case TrainingIntensity.maximum:
        return 5;
    }
  }

  double _getMinY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    final min = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    switch (_selectedMetric) {
      case PerformanceMetricType.competitionRank:
        return 1; // Rank starts at 1
      case PerformanceMetricType.competitionScore:
        return (min - 5).clamp(0, double.infinity);
      case PerformanceMetricType.trainingDuration:
        return 0;
      case PerformanceMetricType.trainingIntensity:
        return 1;
      case PerformanceMetricType.trainingQuality:
        return 1;
    }
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 10;
    final max = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    switch (_selectedMetric) {
      case PerformanceMetricType.competitionRank:
        return (max + 2).clamp(5, 50); // Show some range above worst rank
      case PerformanceMetricType.competitionScore:
        return (max + 5).clamp(0, 100);
      case PerformanceMetricType.trainingDuration:
        return (max * 1.2).clamp(30, 180);
      case PerformanceMetricType.trainingIntensity:
        return 5;
      case PerformanceMetricType.trainingQuality:
        return 5;
    }
  }

  double _getXInterval(List<FlSpot> spots) {
    if (spots.length < 2) return 1;
    final range = spots.last.x - spots.first.x;
    return range / 4;
  }

  String _formatYAxisValue(double value) {
    switch (_selectedMetric) {
      case PerformanceMetricType.competitionRank:
        return value.toInt().toString();
      case PerformanceMetricType.competitionScore:
        return '${value.toInt()}%';
      case PerformanceMetricType.trainingDuration:
        return '${value.toInt()}m';
      case PerformanceMetricType.trainingIntensity:
        return _intensityLabel(value.toInt());
      case PerformanceMetricType.trainingQuality:
        return '${value.toInt()}/5';
    }
  }

  String _formatTooltipValue(double value) {
    switch (_selectedMetric) {
      case PerformanceMetricType.competitionRank:
        final rank = value.toInt();
        if (rank == 1) return '1er';
        if (rank == 2) return '2e';
        if (rank == 3) return '3e';
        return '${rank}e';
      case PerformanceMetricType.competitionScore:
        return '${value.toStringAsFixed(1)}%';
      case PerformanceMetricType.trainingDuration:
        return '${value.toInt()} min';
      case PerformanceMetricType.trainingIntensity:
        return _intensityLabel(value.toInt());
      case PerformanceMetricType.trainingQuality:
        return '${value.toInt()}/5 etoiles';
    }
  }

  String _intensityLabel(int value) {
    switch (value) {
      case 1:
        return 'Repos';
      case 2:
        return 'Leger';
      case 3:
        return 'Modere';
      case 4:
        return 'Intense';
      case 5:
        return 'Max';
      default:
        return '-';
    }
  }

  Widget _buildLoadingChart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Chargement des donnees...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorChart(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Pas de donnees disponibles',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ajoutez des competitions ou entrainements',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDateRangeChip(context, '3M', 90),
        const SizedBox(width: 8),
        _buildDateRangeChip(context, '6M', 180),
        const SizedBox(width: 8),
        _buildDateRangeChip(context, '1A', 365),
        const SizedBox(width: 8),
        _buildDateRangeChip(context, 'Tout', 0),
      ],
    );
  }

  Widget _buildDateRangeChip(BuildContext context, String label, int days) {
    final isSelected = days == 0
        ? _dateRange == null
        : _dateRange != null &&
            _dateRange!.start.difference(DateTime.now()).inDays.abs() <= days + 10;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (days == 0) {
            _dateRange = null;
          } else {
            _dateRange = DateTimeRange(
              start: DateTime.now().subtract(Duration(days: days)),
              end: DateTime.now(),
            );
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}

/// Types of performance metrics to display
enum PerformanceMetricType {
  competitionRank,
  competitionScore,
  trainingDuration,
  trainingIntensity,
  trainingQuality;

  String get displayName {
    switch (this) {
      case PerformanceMetricType.competitionRank:
        return 'Classement';
      case PerformanceMetricType.competitionScore:
        return 'Score';
      case PerformanceMetricType.trainingDuration:
        return 'Duree';
      case PerformanceMetricType.trainingIntensity:
        return 'Intensite';
      case PerformanceMetricType.trainingQuality:
        return 'Qualite';
    }
  }

  IconData get icon {
    switch (this) {
      case PerformanceMetricType.competitionRank:
        return Icons.emoji_events;
      case PerformanceMetricType.competitionScore:
        return Icons.score;
      case PerformanceMetricType.trainingDuration:
        return Icons.timer;
      case PerformanceMetricType.trainingIntensity:
        return Icons.speed;
      case PerformanceMetricType.trainingQuality:
        return Icons.star;
    }
  }

  Color get color {
    switch (this) {
      case PerformanceMetricType.competitionRank:
        return AppColors.tertiary;
      case PerformanceMetricType.competitionScore:
        return AppColors.info;
      case PerformanceMetricType.trainingDuration:
        return AppColors.secondary;
      case PerformanceMetricType.trainingIntensity:
        return AppColors.error;
      case PerformanceMetricType.trainingQuality:
        return AppColors.categoryEcurie;
    }
  }
}

/// A compact performance summary card
class PerformanceSummaryCard extends ConsumerWidget {
  final String horseId;

  const PerformanceSummaryCard({super.key, required this.horseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(performanceSummaryProvider(horseId));

    return summaryAsync.when(
      data: (summary) => _buildSummaryCard(context, summary),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryCard(BuildContext context, PerformanceSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resume Performance',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  context,
                  value: '${summary.totalCompetitions}',
                  label: 'Compet.',
                  icon: Icons.emoji_events,
                ),
                _buildMiniStat(
                  context,
                  value: '${summary.victoryRate.toStringAsFixed(0)}%',
                  label: 'Victoires',
                  icon: Icons.military_tech,
                ),
                _buildMiniStat(
                  context,
                  value: '${summary.totalTrainingSessions}',
                  label: 'Sessions',
                  icon: Icons.fitness_center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
