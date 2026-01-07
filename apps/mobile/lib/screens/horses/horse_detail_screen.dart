import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/horse.dart';
import '../../providers/horses_provider.dart';
import '../../providers/analyses_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';

class HorseDetailScreen extends ConsumerWidget {
  final String horseId;

  const HorseDetailScreen({super.key, required this.horseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horseAsync = ref.watch(horseProvider(horseId));
    final analysesAsync = ref.watch(horseAnalysesProvider(horseId));

    return horseAsync.when(
      data: (horse) => _buildContent(context, ref, horse, analysesAsync),
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(horseProvider(horseId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Horse horse,
    AsyncValue analysesAsync,
  ) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with photo
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(horse.name),
              background: horse.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: horse.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.pets,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push('/horses/$horseId/edit'),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    _showDeleteDialog(context, ref, horse);
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

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status chip
                  _buildStatusChip(context, horse.status),
                  const SizedBox(height: 24),

                  // Info section
                  _buildInfoSection(context, horse),
                  const SizedBox(height: 24),

                  // Quick actions
                  _buildQuickActions(context, horse),
                  const SizedBox(height: 24),

                  // Analyses section
                  _buildAnalysesSection(context, analysesAsync),
                  const SizedBox(height: 24),

                  // Notes
                  if (horse.notes != null && horse.notes!.isNotEmpty) ...[
                    _buildNotesSection(context, horse),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/analyses/new?horseId=$horseId'),
        icon: const Icon(Icons.analytics),
        label: const Text('Nouvelle analyse'),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, HorseStatus status) {
    Color color;
    String label;

    switch (status) {
      case HorseStatus.active:
        color = AppColors.success;
        label = 'Actif';
        break;
      case HorseStatus.retired:
        color = AppColors.warning;
        label = 'Retraité';
        break;
      case HorseStatus.sold:
        color = AppColors.textSecondary;
        label = 'Vendu';
        break;
      case HorseStatus.deceased:
        color = AppColors.error;
        label = 'Décédé';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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

  Widget _buildInfoSection(BuildContext context, Horse horse) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.pets, 'Race', horse.breed ?? '-'),
            _buildInfoRow(
              context,
              Icons.male,
              'Sexe',
              _genderLabel(horse.gender),
            ),
            _buildInfoRow(
              context,
              Icons.cake,
              'Date de naissance',
              horse.birthDate != null
                  ? '${horse.birthDate!.day}/${horse.birthDate!.month}/${horse.birthDate!.year}'
                  : '-',
            ),
            _buildInfoRow(
              context,
              Icons.palette,
              'Robe',
              horse.color ?? '-',
            ),
            _buildInfoRow(
              context,
              Icons.straighten,
              'Taille',
              horse.heightCm != null ? '${horse.heightCm} cm' : '-',
            ),
            if (horse.microchip != null)
              _buildInfoRow(context, Icons.qr_code, 'Puce', horse.microchip!),
            if (horse.sireId != null)
              _buildInfoRow(context, Icons.numbers, 'SIRE', horse.sireId!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Horse horse) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/analyses/new?horseId=${horse.id}'),
            icon: const Icon(Icons.videocam),
            label: const Text('Analyser'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/reports/new?horseId=${horse.id}'),
            icon: const Icon(Icons.description),
            label: const Text('Rapport'),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysesSection(BuildContext context, AsyncValue analysesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyses récentes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        analysesAsync.when(
          data: (analyses) {
            if (analyses.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucune analyse',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: analyses.take(5).map((analysis) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.analytics,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    title: Text(
                      analysis.type.toString().split('.').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${analysis.createdAt.day}/${analysis.createdAt.month}/${analysis.createdAt.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/analyses/${analysis.id}'),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Erreur de chargement',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, Horse horse) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              horse.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _genderLabel(HorseGender gender) {
    switch (gender) {
      case HorseGender.male:
        return 'Mâle';
      case HorseGender.female:
        return 'Femelle';
      case HorseGender.gelding:
        return 'Hongre';
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Horse horse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le cheval'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${horse.name} ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await ref
                  .read(horsesNotifierProvider.notifier)
                  .deleteHorse(horse.id);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  context.go('/horses');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cheval supprimé')),
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
