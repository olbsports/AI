import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gamification.dart';
import '../../providers/gamification_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gamification/badge_grid.dart';

/// Screen showing all badges in a collection grid with category filters
class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen>
    with SingleTickerProviderStateMixin {
  BadgeCategory? _selectedCategory;
  bool _showOnlyEarned = false;

  @override
  Widget build(BuildContext context) {
    final allBadgesAsync = ref.watch(badgesWithProgressProvider);
    final earnedBadgesAsync = ref.watch(earnedBadgesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
        actions: [
          // Toggle earned/all
          IconButton(
            icon: Icon(
              _showOnlyEarned ? Icons.star : Icons.star_border,
              color: _showOnlyEarned ? Colors.amber : null,
            ),
            tooltip: _showOnlyEarned ? 'Afficher tous' : 'Afficher obtenus',
            onPressed: () {
              setState(() {
                _showOnlyEarned = !_showOnlyEarned;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          earnedBadgesAsync.when(
            data: (earnedBadges) => allBadgesAsync.when(
              data: (allBadges) => _buildStatsHeader(
                context,
                earnedBadges.length,
                allBadges.length,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Category filter
          BadgeCategoryFilter(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          const SizedBox(height: 16),

          // Badges grid
          Expanded(
            child: allBadgesAsync.when(
              data: (badges) {
                // Filter badges
                var filteredBadges = badges;

                if (_selectedCategory != null) {
                  filteredBadges = filteredBadges
                      .where((b) => b.category == _selectedCategory)
                      .toList();
                }

                if (_showOnlyEarned) {
                  filteredBadges =
                      filteredBadges.where((b) => b.isEarned).toList();
                }

                // Sort: earned first, then by rarity
                filteredBadges.sort((a, b) {
                  if (a.isEarned != b.isEarned) {
                    return a.isEarned ? -1 : 1;
                  }
                  return b.rarity.index.compareTo(a.rarity.index);
                });

                if (filteredBadges.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showOnlyEarned
                              ? 'Aucun badge obtenu dans cette categorie'
                              : 'Aucun badge dans cette categorie',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(badgesWithProgressProvider);
                    ref.invalidate(earnedBadgesProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: BadgeGrid(
                      badges: filteredBadges,
                      onBadgeTap: (badge) => _showBadgeDetails(context, badge),
                      showProgress: true,
                      showLockedBadges: !_showOnlyEarned,
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erreur: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(badgesWithProgressProvider),
                      child: const Text('Reessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, int earned, int total) {
    final theme = Theme.of(context);
    final progress = total > 0 ? earned / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.purple.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collection de badges',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$earned / $total badges',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, Badge badge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: BadgeDetailSheet(
          badge: badge,
          onShare: badge.isEarned
              ? () {
                  Navigator.pop(context);
                  // TODO: Implement share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Partage du badge...')),
                  );
                }
              : null,
        ),
      ),
    );
  }
}
