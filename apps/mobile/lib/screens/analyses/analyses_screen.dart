import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/analysis.dart';
import '../../providers/analyses_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../theme/app_theme.dart';

class AnalysesScreen extends ConsumerStatefulWidget {
  const AnalysesScreen({super.key});

  @override
  ConsumerState<AnalysesScreen> createState() => _AnalysesScreenState();
}

class _AnalysesScreenState extends ConsumerState<AnalysesScreen> {
  String? _selectedType;
  String? _selectedStatus;

  void _onFilterChanged() {
    ref.read(analysesNotifierProvider.notifier).loadAnalyses(
          type: _selectedType,
          status: _selectedStatus,
        );
  }

  @override
  Widget build(BuildContext context) {
    final analysesAsync = ref.watch(analysesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(analysesNotifierProvider.notifier).loadAnalyses();
        },
        child: analysesAsync.when(
          data: (analyses) {
            if (analyses.isEmpty) {
              return EmptyState(
                icon: Icons.analytics,
                title: 'Aucune analyse',
                subtitle: 'Créez votre première analyse vidéo',
                actionLabel: 'Nouvelle analyse',
                onAction: () => context.push('/analyses/new'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: analyses.length,
              itemBuilder: (context, index) {
                return _AnalysisCard(
                  analysis: analyses[index],
                  onTap: () => context.push('/analyses/${analyses[index].id}'),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () =>
                ref.read(analysesNotifierProvider.notifier).loadAnalyses(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/analyses/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle analyse'),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtres',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),

                    // Type filter
                    Text(
                      'Type d\'analyse',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Tous'),
                          selected: _selectedType == null,
                          onSelected: (_) {
                            setModalState(() => _selectedType = null);
                          },
                        ),
                        FilterChip(
                          label: const Text('Locomotion'),
                          selected: _selectedType == 'LOCOMOTION',
                          onSelected: (_) {
                            setModalState(() => _selectedType = 'LOCOMOTION');
                          },
                        ),
                        FilterChip(
                          label: const Text('Saut'),
                          selected: _selectedType == 'JUMP',
                          onSelected: (_) {
                            setModalState(() => _selectedType = 'JUMP');
                          },
                        ),
                        FilterChip(
                          label: const Text('Posture'),
                          selected: _selectedType == 'POSTURE',
                          onSelected: (_) {
                            setModalState(() => _selectedType = 'POSTURE');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status filter
                    Text(
                      'Statut',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Tous'),
                          selected: _selectedStatus == null,
                          onSelected: (_) {
                            setModalState(() => _selectedStatus = null);
                          },
                        ),
                        FilterChip(
                          label: const Text('Terminé'),
                          selected: _selectedStatus == 'COMPLETED',
                          onSelected: (_) {
                            setModalState(() => _selectedStatus = 'COMPLETED');
                          },
                        ),
                        FilterChip(
                          label: const Text('En cours'),
                          selected: _selectedStatus == 'PROCESSING',
                          onSelected: (_) {
                            setModalState(() => _selectedStatus = 'PROCESSING');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {});
                          _onFilterChanged();
                        },
                        child: const Text('Appliquer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final Analysis analysis;
  final VoidCallback onTap;

  const _AnalysisCard({
    required this.analysis,
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
              // Thumbnail
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  image: analysis.thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(analysis.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: analysis.thumbnailUrl == null
                    ? Icon(
                        Icons.videocam,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 28,
                      )
                    : null,
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
                            _typeLabel(analysis.type),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _buildStatusChip(context, analysis.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (analysis.horseName != null)
                      Text(
                        analysis.horseName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(analysis.createdAt),
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

  String _typeLabel(AnalysisType type) {
    switch (type) {
      case AnalysisType.videoPerformance:
        return 'Performance vidéo';
      case AnalysisType.videoCourse:
        return 'Parcours CSO';
      case AnalysisType.radiological:
        return 'Radiologique';
      case AnalysisType.locomotion:
        return 'Analyse locomotion';
      case AnalysisType.jump:
        return 'Analyse saut';
      case AnalysisType.posture:
        return 'Analyse posture';
      case AnalysisType.conformation:
        return 'Analyse conformation';
      case AnalysisType.course:
        return 'Analyse parcours';
      case AnalysisType.video:
        return 'Analyse vidéo';
    }
  }

  Widget _buildStatusChip(BuildContext context, AnalysisStatus status) {
    Color color;
    String label;

    switch (status) {
      case AnalysisStatus.pending:
        color = AppColors.warning;
        label = 'En attente';
        break;
      case AnalysisStatus.processing:
        color = AppColors.secondary;
        label = 'En cours';
        break;
      case AnalysisStatus.completed:
        color = AppColors.success;
        label = 'Terminé';
        break;
      case AnalysisStatus.failed:
        color = AppColors.error;
        label = 'Erreur';
        break;
      case AnalysisStatus.cancelled:
        color = AppColors.textSecondary;
        label = 'Annulé';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
