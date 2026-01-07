import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/report.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../theme/app_theme.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(reportsNotifierProvider.notifier).loadReports();
        },
        child: reportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return EmptyState(
                icon: Icons.description,
                title: 'Aucun rapport',
                subtitle: 'Créez votre premier rapport de suivi',
                actionLabel: 'Nouveau rapport',
                onAction: () => context.push('/reports/new'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                return _ReportCard(
                  report: reports[index],
                  onTap: () => context.push('/reports/${reports[index].id}'),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () =>
                ref.read(reportsNotifierProvider.notifier).loadReports(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reports/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau rapport'),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getTypeColor(report.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(report.type),
                  color: _getTypeColor(report.type),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.title.isNotEmpty ? report.title : _typeLabel(report.type),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _buildStatusChip(context, report.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (report.horseName != null)
                      Text(
                        report.horseName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(report.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(ReportType type) {
    switch (type) {
      case ReportType.radiological:
        return AppColors.info;
      case ReportType.locomotion:
        return AppColors.secondary;
      case ReportType.courseAnalysis:
        return AppColors.primary;
      case ReportType.purchaseExam:
        return AppColors.warning;
      case ReportType.progress:
        return AppColors.primary;
      case ReportType.veterinary:
        return AppColors.error;
      case ReportType.training:
        return AppColors.secondary;
      case ReportType.competition:
        return AppColors.warning;
      case ReportType.health:
        return AppColors.success;
    }
  }

  IconData _getTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.radiological:
        return Icons.medical_information;
      case ReportType.locomotion:
        return Icons.directions_walk;
      case ReportType.courseAnalysis:
        return Icons.analytics;
      case ReportType.purchaseExam:
        return Icons.fact_check;
      case ReportType.progress:
        return Icons.trending_up;
      case ReportType.veterinary:
        return Icons.medical_services;
      case ReportType.training:
        return Icons.fitness_center;
      case ReportType.competition:
        return Icons.emoji_events;
      case ReportType.health:
        return Icons.favorite;
    }
  }

  String _typeLabel(ReportType type) {
    switch (type) {
      case ReportType.radiological:
        return 'Rapport radiologique';
      case ReportType.locomotion:
        return 'Rapport locomotion';
      case ReportType.courseAnalysis:
        return 'Analyse de parcours';
      case ReportType.purchaseExam:
        return 'Visite d\'achat';
      case ReportType.progress:
        return 'Rapport de progression';
      case ReportType.veterinary:
        return 'Rapport vétérinaire';
      case ReportType.training:
        return 'Rapport d\'entraînement';
      case ReportType.competition:
        return 'Rapport de compétition';
      case ReportType.health:
        return 'Bilan de santé';
    }
  }

  Widget _buildStatusChip(BuildContext context, ReportStatus status) {
    Color color;
    String label;

    switch (status) {
      case ReportStatus.draft:
        color = AppColors.textSecondary;
        label = 'Brouillon';
        break;
      case ReportStatus.submitted:
        color = AppColors.info;
        label = 'Soumis';
        break;
      case ReportStatus.approved:
        color = AppColors.success;
        label = 'Approuvé';
        break;
      case ReportStatus.rejected:
        color = AppColors.error;
        label = 'Rejeté';
        break;
      case ReportStatus.archived:
        color = AppColors.textTertiary;
        label = 'Archivé';
        break;
      case ReportStatus.generating:
        color = AppColors.warning;
        label = 'Génération';
        break;
      case ReportStatus.ready:
        color = AppColors.success;
        label = 'Prêt';
        break;
      case ReportStatus.failed:
        color = AppColors.error;
        label = 'Erreur';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
