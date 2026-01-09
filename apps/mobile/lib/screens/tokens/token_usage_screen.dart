import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/tokens.dart';
import '../../providers/tokens_provider.dart';
import '../../theme/app_theme.dart';

class TokenUsageScreen extends ConsumerWidget {
  const TokenUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(tokenUsageStatsProvider);
    final balanceAsync = ref.watch(tokenBalanceDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques d\'utilisation'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tokenUsageStatsProvider);
          ref.invalidate(tokenBalanceDataProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              balanceAsync.when(
                data: (balance) => _buildSummaryCards(context, balance),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Usage stats
              usageAsync.when(
                data: (stats) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthlyChart(context, stats),
                    const SizedBox(height: 24),
                    _buildServiceBreakdown(context, stats),
                    const SizedBox(height: 24),
                    _buildConsumptionTrend(context, stats),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => _buildErrorState(context, error, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, TokenBalance balance) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            title: 'Solde actuel',
            value: '${balance.totalBalance}',
            subtitle: 'tokens disponibles',
            icon: Icons.account_balance_wallet,
            color: _getStatusColor(balance.balanceStatus),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            title: 'Total consomme',
            value: '${balance.totalConsumed}',
            subtitle: 'tokens utilises',
            icon: Icons.trending_down,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(BuildContext context, TokenUsageStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Consommation mensuelle',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (stats.monthlyUsage.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pas encore de donnees',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _MonthlyBarChart(monthlyUsage: stats.monthlyUsage),

            // Legend
            if (stats.monthlyUsage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(context, 'Consomme', AppColors.error),
                  const SizedBox(width: 24),
                  _buildLegendItem(context, 'Achete', AppColors.success),
                  const SizedBox(width: 24),
                  _buildLegendItem(context, 'Inclus', AppColors.secondary),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildServiceBreakdown(BuildContext context, TokenUsageStats stats) {
    if (stats.byServiceType.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by usage amount
    final sortedServices = stats.byServiceType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total =
        stats.totalConsumed > 0 ? stats.totalConsumed : 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Repartition par service',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pie chart visualization
            SizedBox(
              height: 200,
              child: _ServicePieChart(
                services: sortedServices,
                total: total,
              ),
            ),
            const SizedBox(height: 16),

            // Service list
            ...sortedServices.take(5).map((entry) {
              final percentage = (entry.value / total * 100).round();
              final color = _getServiceColor(entry.key);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getServiceDisplayName(entry.key),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.value} tokens ($percentage%)',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),

            if (sortedServices.length > 5)
              TextButton(
                onPressed: () => _showAllServices(context, sortedServices, total),
                child: Text('Voir les ${sortedServices.length - 5} autres'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionTrend(BuildContext context, TokenUsageStats stats) {
    if (stats.monthlyUsage.length < 2) {
      return const SizedBox.shrink();
    }

    // Calculate trend
    final recentMonths = stats.monthlyUsage.take(2).toList();
    final currentMonth = recentMonths.isNotEmpty ? recentMonths.first.consumed : 0;
    final previousMonth = recentMonths.length > 1 ? recentMonths[1].consumed : 0;

    final trend = previousMonth > 0
        ? ((currentMonth - previousMonth) / previousMonth * 100).round()
        : 0;

    final isIncreasing = trend > 0;
    final trendColor = isIncreasing ? AppColors.error : AppColors.success;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tendance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Par rapport au mois dernier',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isIncreasing
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: trendColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${trend.abs()}%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: trendColor,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Ce mois',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      '$currentMonth tokens',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isIncreasing
                  ? 'Votre consommation a augmente ce mois-ci.'
                  : 'Votre consommation a diminue ce mois-ci.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(tokenUsageStatsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllServices(
    BuildContext context,
    List<MapEntry<String, int>> services,
    int total,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tous les services',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final entry = services[index];
                      final percentage = (entry.value / total * 100).round();
                      final color = _getServiceColor(entry.key);

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getServiceIcon(entry.key),
                            color: color,
                          ),
                        ),
                        title: Text(_getServiceDisplayName(entry.key)),
                        subtitle: Text('$percentage% du total'),
                        trailing: Text(
                          '${entry.value}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'good':
        return AppColors.success;
      case 'low':
        return AppColors.warning;
      case 'critical':
        return AppColors.error;
      case 'empty':
        return AppColors.textTertiary;
      default:
        return AppColors.primary;
    }
  }

  String _getServiceDisplayName(String serviceType) {
    switch (serviceType) {
      case 'VIDEO_BASIC':
        return 'Analyse video simple';
      case 'VIDEO_STANDARD':
        return 'Analyse video complete';
      case 'VIDEO_PARCOURS':
        return 'Analyse parcours';
      case 'VIDEO_ADVANCED':
        return 'Analyse avancee';
      case 'LOCOMOTION':
        return 'Analyse locomotion';
      case 'RADIO_SIMPLE':
        return 'Radio simple';
      case 'RADIO_COMPLETE':
        return 'Radio complete';
      case 'RADIO_EXPERT':
        return 'Radio expert';
      case 'HORSE_PROFILE':
        return 'Fiche cheval';
      case 'ANALYSIS_REPORT':
        return 'Rapport analyse';
      case 'HEALTH_REPORT':
        return 'Rapport sante';
      case 'PROGRESSION_REPORT':
        return 'Rapport progression';
      case 'SALE_REPORT':
        return 'Dossier vente';
      case 'BREEDING_REPORT':
        return 'Rapport elevage';
      case 'EQUICOTE_STANDARD':
        return 'EquiCote standard';
      case 'EQUICOTE_PREMIUM':
        return 'EquiCote premium';
      case 'BREEDING_RECOMMEND':
        return 'Recommandations elevage';
      case 'BREEDING_MATCH':
        return 'Match elevage';
      default:
        return serviceType;
    }
  }

  Color _getServiceColor(String serviceType) {
    if (serviceType.startsWith('VIDEO') || serviceType == 'LOCOMOTION') {
      return AppColors.primary;
    } else if (serviceType.startsWith('RADIO')) {
      return AppColors.error;
    } else if (serviceType.contains('REPORT') || serviceType.contains('PROFILE')) {
      return AppColors.secondary;
    } else if (serviceType.startsWith('EQUICOTE')) {
      return AppColors.tertiary;
    } else if (serviceType.startsWith('BREEDING')) {
      return AppColors.categoryEcurie;
    }
    return AppColors.info;
  }

  IconData _getServiceIcon(String serviceType) {
    if (serviceType.startsWith('VIDEO') || serviceType == 'LOCOMOTION') {
      return Icons.videocam;
    } else if (serviceType.startsWith('RADIO')) {
      return Icons.medical_services;
    } else if (serviceType.contains('REPORT') || serviceType.contains('PROFILE')) {
      return Icons.description;
    } else if (serviceType.startsWith('EQUICOTE')) {
      return Icons.euro;
    } else if (serviceType.startsWith('BREEDING')) {
      return Icons.favorite;
    }
    return Icons.analytics;
  }
}

/// Custom monthly bar chart widget
class _MonthlyBarChart extends StatelessWidget {
  final List<MonthlyUsage> monthlyUsage;

  const _MonthlyBarChart({required this.monthlyUsage});

  @override
  Widget build(BuildContext context) {
    // Take last 6 months and reverse to show oldest first
    final displayData = monthlyUsage.take(6).toList().reversed.toList();

    if (displayData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find max value for scaling
    final maxValue = displayData.fold<int>(
      1,
      (max, item) => math.max(max, math.max(item.consumed, item.purchased)),
    );

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: displayData.map((month) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bars
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Consumed bar
                        _buildBar(
                          context,
                          value: month.consumed,
                          maxValue: maxValue,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 2),
                        // Purchased bar
                        _buildBar(
                          context,
                          value: month.purchased,
                          maxValue: maxValue,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Month label
                  Text(
                    DateFormat('MMM', 'fr_FR').format(
                      DateTime(month.year, month.month),
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBar(
    BuildContext context, {
    required int value,
    required int maxValue,
    required Color color,
  }) {
    final height = value > 0 ? (value / maxValue * 120).clamp(4.0, 120.0) : 4.0;

    return Tooltip(
      message: '$value tokens',
      child: Container(
        width: 16,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}

/// Custom pie chart widget for service breakdown
class _ServicePieChart extends StatelessWidget {
  final List<MapEntry<String, int>> services;
  final int total;

  const _ServicePieChart({
    required this.services,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _PieChartPainter(
        services: services,
        total: total,
        getColor: _getServiceColor,
      ),
    );
  }

  Color _getServiceColor(String serviceType) {
    if (serviceType.startsWith('VIDEO') || serviceType == 'LOCOMOTION') {
      return AppColors.primary;
    } else if (serviceType.startsWith('RADIO')) {
      return AppColors.error;
    } else if (serviceType.contains('REPORT') || serviceType.contains('PROFILE')) {
      return AppColors.secondary;
    } else if (serviceType.startsWith('EQUICOTE')) {
      return AppColors.tertiary;
    } else if (serviceType.startsWith('BREEDING')) {
      return AppColors.categoryEcurie;
    }
    return AppColors.info;
  }
}

class _PieChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> services;
  final int total;
  final Color Function(String) getColor;

  _PieChartPainter({
    required this.services,
    required this.total,
    required this.getColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    var startAngle = -math.pi / 2;

    for (final entry in services) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = getColor(entry.key)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Add a white border between segments
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle (donut effect)
    final centerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
