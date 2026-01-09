import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gamification.dart';
import '../../providers/gamification_provider.dart';
import '../../theme/app_theme.dart';

/// Leaderboard screen with period and scope filters
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final filter = ref.watch(leaderboardFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(context, ref, filter),
          const Divider(height: 1),

          // Leaderboard content
          Expanded(
            child: leaderboardAsync.when(
              data: (response) {
                if (response.entries.isEmpty) {
                  return _buildEmptyState(context);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(leaderboardProvider);
                  },
                  child: CustomScrollView(
                    slivers: [
                      // Top 3 podium
                      if (response.entries.length >= 3)
                        SliverToBoxAdapter(
                          child: _buildPodium(context, response.entries.take(3).toList()),
                        ),

                      // Current user position (if not in top 10)
                      if (response.currentUserEntry != null &&
                          !response.entries.take(10).any((e) => e.isCurrentUser))
                        SliverToBoxAdapter(
                          child: _buildCurrentUserCard(context, response.currentUserEntry!),
                        ),

                      // Full rankings list
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              // Skip top 3 if showing podium
                              final entryIndex = response.entries.length >= 3 ? index + 3 : index;
                              if (entryIndex >= response.entries.length) return null;

                              final entry = response.entries[entryIndex];
                              return _buildLeaderboardItem(context, entry, entryIndex + 1);
                            },
                            childCount: response.entries.length >= 3
                                ? response.entries.length - 3
                                : response.entries.length,
                          ),
                        ),
                      ),
                    ],
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
                      onPressed: () => ref.invalidate(leaderboardProvider),
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

  Widget _buildFilters(BuildContext context, WidgetRef ref, LeaderboardFilter filter) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LeaderboardPeriod.values.map((period) {
                final isSelected = filter.period == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(period.displayName),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(leaderboardFilterProvider.notifier).state =
                          filter.copyWith(period: period);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Scope filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LeaderboardScope.values.map((scope) {
                final isSelected = filter.scope == scope;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(scope.displayName),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(leaderboardFilterProvider.notifier).state =
                          filter.copyWith(scope: scope);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<LeaderboardEntry> top3) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (top3.length > 1)
            _buildPodiumItem(context, top3[1], 2, 100)
          else
            const SizedBox(width: 100),

          // 1st place
          _buildPodiumItem(context, top3[0], 1, 130),

          // 3rd place
          if (top3.length > 2)
            _buildPodiumItem(context, top3[2], 3, 80)
          else
            const SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    BuildContext context,
    LeaderboardEntry entry,
    int position,
    double height,
  ) {
    final theme = Theme.of(context);
    final colors = {
      1: Colors.amber,
      2: Colors.grey.shade400,
      3: Colors.brown.shade400,
    };
    final color = colors[position] ?? Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for 1st place
        if (position == 1)
          const Text('👑', style: TextStyle(fontSize: 24)),

        // Avatar
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: position == 1 ? 40 : 32,
              backgroundColor: color.withValues(alpha: 0.2),
              backgroundImage: entry.userAvatarUrl != null
                  ? NetworkImage(entry.userAvatarUrl!)
                  : null,
              child: entry.userAvatarUrl == null
                  ? Text(
                      entry.userName.isNotEmpty
                          ? entry.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: position == 1 ? 28 : 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    )
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '$position',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Name
        SizedBox(
          width: 100,
          child: Text(
            entry.userName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: entry.isCurrentUser ? AppColors.primary : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // XP
        Text(
          '${_formatNumber(entry.totalXp)} XP',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),

        // Level
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Niv. ${entry.level}',
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Podium base
        const SizedBox(height: 8),
        Container(
          width: position == 1 ? 90 : 70,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              _getPositionEmoji(position),
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentUserCard(BuildContext context, LeaderboardEntry entry) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre position',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  entry.userName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatNumber(entry.totalXp)} XP',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Niveau ${entry.level}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(
    BuildContext context,
    LeaderboardEntry entry,
    int position,
  ) {
    final theme = Theme.of(context);
    final isCurrentUser = entry.isCurrentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrentUser ? AppColors.primary.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentUser
            ? const BorderSide(color: AppColors.primary, width: 1)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank
            SizedBox(
              width: 32,
              child: Text(
                '#$position',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),

            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: entry.userAvatarUrl != null
                  ? NetworkImage(entry.userAvatarUrl!)
                  : null,
              child: entry.userAvatarUrl == null
                  ? Text(
                      entry.userName.isNotEmpty
                          ? entry.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
        title: Text(
          entry.userName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isCurrentUser ? AppColors.primary : null,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Niv. ${entry.level}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (entry.badgeCount > 0)
              Row(
                children: [
                  const Icon(Icons.emoji_events, size: 12, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    '${entry.badgeCount}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_formatNumber(entry.totalXp)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? AppColors.primary : null,
              ),
            ),
            Text(
              'XP',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun classement disponible',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier a gagner des XP !',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _getPositionEmoji(int position) {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
