import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../models/horse.dart';
import '../../models/health.dart';
import '../../providers/horses_provider.dart';
import '../../providers/analyses_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';
import '../../widgets/horses/pedigree_tree_widget.dart';
import '../../widgets/horses/performance_chart_widget.dart';
import '../../widgets/horses/body_condition_slider_widget.dart';
import '../../widgets/horses/health_timeline_widget.dart';

class HorseDetailScreen extends ConsumerStatefulWidget {
  final String horseId;

  const HorseDetailScreen({super.key, required this.horseId});

  @override
  ConsumerState<HorseDetailScreen> createState() => _HorseDetailScreenState();
}

class _HorseDetailScreenState extends ConsumerState<HorseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horseAsync = ref.watch(horseProvider(widget.horseId));

    return horseAsync.when(
      data: (horse) => _buildContent(context, horse),
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(horseProvider(widget.horseId)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Horse horse) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context, horse),
          SliverToBoxAdapter(
            child: _buildQuickInfo(context, horse),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Apercu'),
                  Tab(text: 'Origines'),
                  Tab(text: 'Performance'),
                  Tab(text: 'Sante'),
                  Tab(text: 'Poids & BCS'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(context, horse),
            _buildPedigreeTab(context, horse),
            _buildPerformanceTab(context, horse),
            _buildHealthTab(context, horse),
            _buildWeightBCSTab(context, horse),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/analyses/new?horseId=${widget.horseId}'),
        icon: const Icon(Icons.analytics),
        label: const Text('Analyser'),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Horse horse) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          horse.name,
          style: const TextStyle(
            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            horse.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: horse.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, size: 64),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      Icons.pets,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => context.push('/horses/${widget.horseId}/edit'),
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              _showDeleteDialog(context, horse);
            } else if (value == 'archive') {
              _archiveHorse(context, horse);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive_outlined),
                  SizedBox(width: 8),
                  Text('Archiver'),
                ],
              ),
            ),
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
    );
  }

  Widget _buildQuickInfo(BuildContext context, Horse horse) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatusChip(context, horse.status),
          const SizedBox(width: 12),
          if (horse.breed != null)
            _buildInfoChip(context, Icons.pets, horse.breed!),
          const SizedBox(width: 8),
          _buildInfoChip(context, Icons.male, horse.genderLabel),
          if (horse.age != null) ...[
            const SizedBox(width: 8),
            _buildInfoChip(context, Icons.cake, '${horse.age} ans'),
          ],
        ],
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
        label = 'Retraite';
        break;
      case HorseStatus.sold:
        color = AppColors.textSecondary;
        label = 'Vendu';
        break;
      case HorseStatus.deceased:
        color = AppColors.error;
        label = 'Decede';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================

  Widget _buildOverviewTab(BuildContext context, Horse horse) {
    final analysesAsync = ref.watch(horseAnalysesProvider(widget.horseId));
    final healthSummaryAsync = ref.watch(healthSummaryProvider(widget.horseId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General info card
          _buildInfoCard(context, horse),
          const SizedBox(height: 16),

          // Health summary
          healthSummaryAsync.when(
            data: (summary) => HealthSummaryWidget(summary: summary),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Performance summary
          PerformanceSummaryCard(horseId: widget.horseId),
          const SizedBox(height: 16),

          // Quick actions
          _buildQuickActions(context, horse),
          const SizedBox(height: 16),

          // Recent analyses
          _buildAnalysesSection(context, analysesAsync),
          const SizedBox(height: 16),

          // Notes
          if (horse.notes != null && horse.notes!.isNotEmpty)
            _buildNotesSection(context, horse),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Horse horse) {
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
            _buildInfoRow(context, Icons.male, 'Sexe', horse.genderLabel),
            _buildInfoRow(
              context,
              Icons.cake,
              'Naissance',
              horse.birthDate != null
                  ? DateFormat('dd/MM/yyyy').format(horse.birthDate!)
                  : '-',
            ),
            _buildInfoRow(context, Icons.palette, 'Robe', horse.color ?? '-'),
            _buildInfoRow(
              context,
              Icons.straighten,
              'Taille',
              horse.heightCm != null ? '${horse.heightCm} cm' : '-',
            ),
            _buildInfoRow(
              context,
              Icons.monitor_weight,
              'Poids',
              horse.weight != null ? '${horse.weight} kg' : '-',
            ),
            if (horse.ueln != null)
              _buildInfoRow(context, Icons.tag, 'UELN', horse.ueln!),
            if (horse.microchip != null)
              _buildInfoRow(context, Icons.qr_code, 'Puce', horse.microchip!),
            if (horse.discipline != HorseDiscipline.none)
              _buildInfoRow(context, Icons.sports, 'Discipline', horse.disciplineLabel),
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
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Analyses recentes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(2),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucune analyse',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: analyses.take(3).map((analysis) {
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
                    title: Text(
                      analysis.type.toString().split('.').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(analysis.createdAt),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/analyses/${analysis.id}'),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Erreur de chargement'),
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

  // ==================== PEDIGREE TAB ====================

  Widget _buildPedigreeTab(BuildContext context, Horse horse) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pedigree tree
          PedigreeTreeWidget(
            horseId: widget.horseId,
            showOffspring: true,
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  // ==================== PERFORMANCE TAB ====================

  Widget _buildPerformanceTab(BuildContext context, Horse horse) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance chart
          PerformanceChartWidget(horseId: widget.horseId),
          const SizedBox(height: 16),

          // Competition results section
          _buildCompetitionResults(context),
          const SizedBox(height: 16),

          // Training sessions section
          _buildTrainingSessions(context),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildCompetitionResults(BuildContext context) {
    final competitionsAsync = ref.watch(competitionResultsProvider(widget.horseId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Competitions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showAddCompetitionDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        competitionsAsync.when(
          data: (competitions) {
            if (competitions.isEmpty) {
              return _buildEmptySection(
                context,
                icon: Icons.emoji_events_outlined,
                message: 'Aucune competition enregistree',
              );
            }
            return Column(
              children: competitions.take(5).map((c) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: _buildRankBadge(context, c.rank),
                    title: Text(c.competitionName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${c.discipline.displayName} - ${DateFormat('dd/MM/yy').format(c.date)}',
                    ),
                    trailing: c.score != null
                        ? Text(
                            '${c.score!.toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Erreur de chargement'),
        ),
      ],
    );
  }

  Widget _buildRankBadge(BuildContext context, int? rank) {
    Color color;
    if (rank == null) {
      color = Colors.grey;
    } else if (rank == 1) {
      color = const Color(0xFFFFD700);
    } else if (rank == 2) {
      color = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32);
    } else {
      color = Theme.of(context).colorScheme.primary;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          rank?.toString() ?? '-',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingSessions(BuildContext context) {
    final trainingAsync = ref.watch(trainingSessionsProvider(widget.horseId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Entrainements recents',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showAddTrainingDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        trainingAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return _buildEmptySection(
                context,
                icon: Icons.fitness_center_outlined,
                message: 'Aucun entrainement enregistre',
              );
            }
            return Column(
              children: sessions.take(5).map((s) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(s.intensity.color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(s.type.icon, color: Color(s.intensity.color)),
                    ),
                    title: Text(s.type.displayName),
                    subtitle: Text(
                      '${s.durationText} - ${DateFormat('dd/MM/yy').format(s.date)}',
                    ),
                    trailing: s.qualityRating != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < s.qualityRating! ? Icons.star : Icons.star_border,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Erreur de chargement'),
        ),
      ],
    );
  }

  // ==================== HEALTH TAB ====================

  Widget _buildHealthTab(BuildContext context, Horse horse) {
    final healthRecordsAsync = ref.watch(healthRecordsProvider(widget.horseId));

    return healthRecordsAsync.when(
      data: (records) => HealthTimelineWidget(
        records: records,
        onAddRecord: () => _showAddHealthRecordSheet(context, horse),
        onRecordTap: (record) => _showHealthRecordDetails(context, record),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erreur de chargement')),
    );
  }

  // ==================== WEIGHT & BCS TAB ====================

  Widget _buildWeightBCSTab(BuildContext context, Horse horse) {
    final weightRecordsAsync = ref.watch(weightRecordsProvider(widget.horseId));
    final bcsRecordsAsync = ref.watch(bodyConditionRecordsProvider(widget.horseId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current BCS
          bcsRecordsAsync.when(
            data: (records) {
              final latestScore = records.isNotEmpty ? records.last.score : 5;
              return BodyConditionSliderWidget(
                initialScore: latestScore,
                onScoreChanged: (score) => _addBodyConditionRecord(context, score),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => BodyConditionSliderWidget(
              initialScore: 5,
              onScoreChanged: (score) => _addBodyConditionRecord(context, score),
            ),
          ),
          const SizedBox(height: 16),

          // BCS History
          bcsRecordsAsync.when(
            data: (records) => BodyConditionHistoryWidget(
              horseId: widget.horseId,
              records: records,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Weight section
          _buildWeightSection(context, horse, weightRecordsAsync),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildWeightSection(
    BuildContext context,
    Horse horse,
    AsyncValue<List<WeightRecord>> weightRecordsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historique de poids',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showAddWeightDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        weightRecordsAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return _buildEmptySection(
                context,
                icon: Icons.monitor_weight_outlined,
                message: 'Aucune pesee enregistree',
              );
            }
            final sortedRecords = [...records]..sort((a, b) => b.date.compareTo(a.date));
            return Column(
              children: sortedRecords.take(5).map((r) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.monitor_weight,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      '${r.weight.toStringAsFixed(0)} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(r.date)),
                    trailing: Text(
                      r.method.displayName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Erreur de chargement'),
        ),
      ],
    );
  }

  Widget _buildEmptySection(BuildContext context, {required IconData icon, required String message}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _showDeleteDialog(BuildContext context, Horse horse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le cheval'),
        content: Text(
          'Etes-vous sur de vouloir supprimer ${horse.name} ? Cette action est irreversible.',
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
                    const SnackBar(content: Text('Cheval supprime')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la suppression'),
                      backgroundColor: Colors.red,
                    ),
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

  void _archiveHorse(BuildContext context, Horse horse) async {
    final success = await ref
        .read(horsesNotifierProvider.notifier)
        .updateHorse(horse.id, {'status': 'retired'});
    if (context.mounted) {
      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cheval archive')),
        );
      }
    }
  }

  void _showAddHealthRecordSheet(BuildContext context, Horse horse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddHealthRecordBottomSheet(
        horseId: horse.id,
        horseName: horse.name,
        onSave: (data) async {
          await ref.read(healthNotifierProvider.notifier).addHealthRecord(horse.id, data);
        },
      ),
    );
  }

  void _showHealthRecordDetails(BuildContext context, HealthRecord record) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              record.type.displayName,
              style: TextStyle(color: Color(record.type.color)),
            ),
            if (record.description != null) ...[
              const SizedBox(height: 16),
              Text(record.description!),
            ],
            const SizedBox(height: 16),
            Text('Date: ${DateFormat('dd/MM/yyyy').format(record.date)}'),
            if (record.veterinarian != null)
              Text('Veterinaire: ${record.veterinarian}'),
            if (record.cost != null)
              Text('Cout: ${record.cost!.toStringAsFixed(0)} EUR'),
          ],
        ),
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context) {
    final weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une pesee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Poids (kg)',
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final weight = double.tryParse(weightController.text);
              if (weight != null) {
                await ref.read(healthNotifierProvider.notifier).addWeightRecord(
                  widget.horseId,
                  {
                    'weight': weight,
                    'date': selectedDate.toIso8601String(),
                    'method': 'scale',
                  },
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _addBodyConditionRecord(BuildContext context, int score) {
    ref.read(healthNotifierProvider.notifier).addBodyConditionRecord(
      widget.horseId,
      {
        'score': score,
        'date': DateTime.now().toIso8601String(),
      },
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Score BCS $score enregistre')),
    );
  }

  void _showAddCompetitionDialog(BuildContext context) {
    // TODO: Implement competition dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalite a venir')),
    );
  }

  void _showAddTrainingDialog(BuildContext context) {
    // TODO: Implement training dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalite a venir')),
    );
  }
}

// ==================== HELPER CLASSES ====================

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
