import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/report.dart';
import '../../providers/reports_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';

class ReportDetailScreen extends ConsumerWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportProvider(reportId));

    return reportAsync.when(
      data: (report) => _buildContent(context, ref, report),
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(reportProvider(reportId)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Report report) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report.title ?? _typeLabel(report.type)),
        actions: [
          if (report.status == ReportStatus.ready) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareReport(context, report),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadReport(context, report),
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                _showDeleteDialog(context, ref, report);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status section
            _buildStatusSection(context, report),
            const SizedBox(height: 24),

            // Horse info
            if (report.horseName != null) ...[
              _buildHorseSection(context, report),
              const SizedBox(height: 24),
            ],

            // Report content
            if (report.status == ReportStatus.ready) ...[
              _buildReportContent(context, report),
              const SizedBox(height: 24),
            ],

            // Generating status
            if (report.status == ReportStatus.generating) ...[
              _buildGeneratingSection(context),
              const SizedBox(height: 24),
            ],

            // Analyses used
            if (report.analyses != null && report.analyses!.isNotEmpty) ...[
              _buildAnalysesSection(context, report),
              const SizedBox(height: 24),
            ],

            // Date info
            _buildDateSection(context, report),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, Report report) {
    return Row(
      children: [
        _buildStatusChip(context, report.status),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getTypeColor(report.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTypeIcon(report.type),
                size: 16,
                color: _getTypeColor(report.type),
              ),
              const SizedBox(width: 4),
              Text(
                _typeLabel(report.type),
                style: TextStyle(
                  color: _getTypeColor(report.type),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorseSection(BuildContext context, Report report) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.pets,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(report.horseName!),
        subtitle: const Text('Cheval concerné'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (report.horseId != null) {
            context.push('/horses/${report.horseId}');
          }
        },
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, Report report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contenu du rapport',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (report.content != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  if (report.content!['summary'] != null) ...[
                    Text(
                      'Résumé',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(report.content!['summary']),
                    const Divider(height: 24),
                  ],

                  // Key findings
                  if (report.content!['keyFindings'] != null) ...[
                    Text(
                      'Points clés',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...List<String>.from(report.content!['keyFindings'])
                        .map((finding) => _buildBulletPoint(context, finding)),
                    const Divider(height: 24),
                  ],

                  // Recommendations
                  if (report.content!['recommendations'] != null) ...[
                    Text(
                      'Recommandations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...List<String>.from(report.content!['recommendations'])
                        .map((rec) => _buildBulletPoint(context, rec, icon: Icons.lightbulb_outline)),
                  ],
                ],
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Contenu non disponible',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.check_circle_outline,
            size: 20,
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildGeneratingSection(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Génération en cours...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Le rapport est en cours de génération. Veuillez patienter.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysesSection(BuildContext context, Report report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyses utilisées',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...report.analyses!.map((analysis) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              title: Text(analysis.type.toString().split('.').last),
              subtitle: Text(
                '${analysis.createdAt.day}/${analysis.createdAt.month}/${analysis.createdAt.year}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/analyses/${analysis.id}'),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDateSection(BuildContext context, Report report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(context, 'Créé le', _formatDate(report.createdAt)),
            if (report.generatedAt != null)
              _buildInfoRow(context, 'Généré le', _formatDate(report.generatedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, ReportStatus status) {
    Color color;
    String label;

    switch (status) {
      case ReportStatus.draft:
        color = AppColors.textSecondary;
        label = 'Brouillon';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getTypeColor(ReportType type) {
    switch (type) {
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
      case ReportType.progress:
        return 'Progression';
      case ReportType.veterinary:
        return 'Vétérinaire';
      case ReportType.training:
        return 'Entraînement';
      case ReportType.competition:
        return 'Compétition';
      case ReportType.health:
        return 'Santé';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _shareReport(BuildContext context, Report report) {
    if (report.pdfUrl != null) {
      Share.share(
        'Rapport ${report.title ?? _typeLabel(report.type)}: ${report.pdfUrl}',
        subject: 'Rapport Horse Vision AI',
      );
    }
  }

  void _downloadReport(BuildContext context, Report report) {
    // TODO: Implement PDF download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Téléchargement en cours...')),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rapport'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce rapport ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await ref
                  .read(reportsNotifierProvider.notifier)
                  .deleteReport(report.id);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  context.go('/reports');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rapport supprimé')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
