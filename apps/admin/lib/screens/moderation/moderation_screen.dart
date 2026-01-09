import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_theme.dart';

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(contentReportsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Modération',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 24),

            // Stats
            Row(
              children: [
                _buildStatCard('En attente', ref.watch(pendingReportsCountProvider).valueOrNull ?? 0, AdminColors.warning),
                const SizedBox(width: 16),
                _buildStatCard('Résolus', ref.watch(resolvedReportsCountProvider).valueOrNull ?? 0, AdminColors.success),
                const SizedBox(width: 16),
                _buildStatCard('Escaladés', ref.watch(escalatedReportsCountProvider).valueOrNull ?? 0, AdminColors.error),
              ],
            ),
            const SizedBox(height: 24),

            // Reports list
            Expanded(
              child: Card(
                child: reportsAsync.when(
                  data: (reports) => reports.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 64, color: AdminColors.success),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun signalement en attente',
                                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: reports.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final report = reports[index];
                            return _buildReportItem(context, ref, report);
                          },
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.flag, color: color),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (ctx) => Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(ctx).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  Builder(
                    builder: (ctx) => Text(label, style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(BuildContext context, WidgetRef ref, ContentReport report) {
    return InkWell(
      onTap: () => _showReportDetails(context, ref, report),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(report.status.colorValue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getContentTypeIcon(report.contentType),
                color: Color(report.status.colorValue),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Builder(
                          builder: (ctx) => Text(
                            report.contentType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(ctx).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (ctx) => Text(
                          report.reportReason,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(ctx).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (report.contentPreview != null)
                    Builder(
                      builder: (ctx) => Text(
                        report.contentPreview!,
                        style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (ctx) => Text(
                      'Signalé par ${report.reporterName} • ${DateFormat('dd/MM HH:mm').format(report.createdAt)}',
                      style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(report.status.colorValue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                report.status.displayName,
                style: TextStyle(
                  color: Color(report.status.colorValue),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (report.status == ReportStatus.pending)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: AdminColors.success),
                    onPressed: () => _resolveReport(ref, report, 'approved'),
                    tooltip: 'Approuver',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AdminColors.error),
                    onPressed: () => _resolveReport(ref, report, 'deleted'),
                    tooltip: 'Supprimer le contenu',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AdminColors.textSecondary),
                    onPressed: () => _resolveReport(ref, report, 'dismissed'),
                    tooltip: 'Rejeter',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  IconData _getContentTypeIcon(String type) {
    switch (type) {
      case 'note':
        return Icons.article;
      case 'comment':
        return Icons.comment;
      case 'listing':
        return Icons.storefront;
      case 'user':
        return Icons.person;
      default:
        return Icons.flag;
    }
  }

  void _showReportDetails(BuildContext context, WidgetRef ref, ContentReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Signalement #${report.id.substring(0, 8)}'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Type', report.contentType),
              _buildDetailRow('Raison', report.reportReason),
              if (report.reportDetails != null)
                _buildDetailRow('Détails', report.reportDetails!),
              _buildDetailRow('Signalé par', report.reporterName),
              _buildDetailRow('Date', DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt)),
              const Divider(),
              if (report.contentPreview != null) ...[
                const Text('Contenu signalé:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.darkCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(report.contentPreview!),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (report.status == ReportStatus.pending) ...[
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _resolveReport(ref, report, 'dismissed');
              },
              child: const Text('Rejeter'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resolveReport(ref, report, 'deleted');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
              child: const Text('Supprimer'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: AdminColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AdminColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveReport(WidgetRef ref, ContentReport report, String action) async {
    await ref.read(adminActionsProvider.notifier).resolveReport(
          report.id,
          action,
          null,
        );
  }
}
