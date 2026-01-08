import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/analyses_provider.dart';
import '../../providers/reports_provider.dart';

/// IA category home screen
/// Contains: Analyses, Reports, Planning, Training
class IAHomeScreen extends ConsumerWidget {
  const IAHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysesAsync = ref.watch(analysesProvider);
    final reportsAsync = ref.watch(reportsProvider);
    final theme = Theme.of(context);

    // Extract data from AsyncValue with fallback to empty list
    final analysesList = analysesAsync.valueOrNull ?? [];
    final reportsList = reportsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligence Artificielle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: History
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Banner
            _AIBanner(),

            const SizedBox(height: 24),

            // Analysis Types
            Text(
              'Types d\'analyse',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            _AnalysisTypeGrid(),

            const SizedBox(height: 24),

            // Quick actions
            Text(
              'Actions rapides',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            _SectionGrid(
              items: [
                _SectionItem(
                  icon: Icons.videocam,
                  label: 'Analyses',
                  subtitle: '${analysesList.length} effectuées',
                  color: AppColors.categoryIA,
                  onTap: () => context.go('/analyses'),
                ),
                _SectionItem(
                  icon: Icons.description,
                  label: 'Rapports',
                  subtitle: '${reportsList.length} générés',
                  color: AppColors.secondary,
                  onTap: () => context.go('/reports'),
                ),
                _SectionItem(
                  icon: Icons.calendar_month,
                  label: 'Planning',
                  subtitle: 'Plan d\'entraînement',
                  color: AppColors.tertiary,
                  onTap: () => context.go('/planning'),
                ),
                _SectionItem(
                  icon: Icons.trending_up,
                  label: 'Évolution',
                  subtitle: 'Suivi progrès',
                  color: AppColors.primary,
                  onTap: () {
                    // TODO: Evolution screen
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent analyses
            _RecentAnalysesSection(analyses: analysesList.take(3).toList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewAnalysisOptions(context),
        backgroundColor: AppColors.categoryIA,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle analyse'),
      ),
    );
  }

  void _showNewAnalysisOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nouvelle analyse IA',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                _AnalysisOption(
                  icon: Icons.videocam,
                  title: 'Analyse vidéo',
                  subtitle: 'CSO, Dressage, CCE...',
                  color: AppColors.categoryIA,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/analyses/new?type=video');
                  },
                ),
                _AnalysisOption(
                  icon: Icons.medical_services,
                  title: 'Imagerie médicale',
                  subtitle: 'Radios, échographies',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/analyses/new?type=medical');
                  },
                ),
                _AnalysisOption(
                  icon: Icons.directions_run,
                  title: 'Locomotion',
                  subtitle: 'Analyse des allures',
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/analyses/new?type=locomotion');
                  },
                ),
                _AnalysisOption(
                  icon: Icons.assignment,
                  title: 'Examen complet',
                  subtitle: 'Visite d\'achat, bilan santé',
                  color: AppColors.tertiary,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/analyses/new?type=exam');
                  },
                ),
                _AnalysisOption(
                  icon: Icons.route,
                  title: 'Créer un parcours',
                  subtitle: 'Générateur de parcours CSO',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Course designer
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AIBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.categoryIA,
            AppColors.categoryIA.withBlue(220),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Claude AI',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Analyse IA Avancée',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vidéo, imagerie médicale, locomotion et plus',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisTypeGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AnalysisTypeCard(
            icon: Icons.sports_score,
            label: 'CSO',
            color: AppColors.primary,
          ),
          _AnalysisTypeCard(
            icon: Icons.straighten,
            label: 'Dressage',
            color: AppColors.categoryEcurie,
          ),
          _AnalysisTypeCard(
            icon: Icons.terrain,
            label: 'CCE',
            color: AppColors.secondary,
          ),
          _AnalysisTypeCard(
            icon: Icons.medical_services,
            label: 'Médical',
            color: AppColors.error,
          ),
          _AnalysisTypeCard(
            icon: Icons.directions_run,
            label: 'Locomotion',
            color: AppColors.tertiary,
          ),
        ],
      ),
    );
  }
}

class _AnalysisTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AnalysisTypeCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionGrid extends StatelessWidget {
  final List<_SectionItem> items;

  const _SectionGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: items,
    );
  }
}

class _SectionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SectionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Expanded(child: SizedBox(height: 4)),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AnalysisOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _RecentAnalysesSection extends StatelessWidget {
  final List<dynamic> analyses;

  const _RecentAnalysesSection({required this.analyses});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (analyses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune analyse récente',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Commencez par analyser une vidéo ou une image',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Analyses récentes',
              style: theme.textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go('/analyses'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...analyses.map((analysis) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.categoryIA.withValues(alpha: 0.1),
                  child: const Icon(Icons.analytics, color: AppColors.categoryIA),
                ),
                title: Text(analysis.title ?? 'Analyse'),
                subtitle: Text(analysis.type ?? 'Type non spécifié'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/analyses/${analysis.id}'),
              ),
            )),
      ],
    );
  }
}
