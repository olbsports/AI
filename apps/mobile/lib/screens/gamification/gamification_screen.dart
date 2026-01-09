import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gamification.dart';
import '../../providers/gamification_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gamification/gamification_widgets.dart';
import 'badges_screen.dart';
import 'challenges_screen.dart';
import 'referral_screen.dart';
import 'leaderboard_screen.dart';

/// Main gamification dashboard screen
class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelAsync = ref.watch(userLevelProvider);
    final streakAsync = ref.watch(userStreakProvider);
    final badgesAsync = ref.watch(earnedBadgesProvider);
    final challengesAsync = ref.watch(activeChallengesProvider);
    final streakInDanger = ref.watch(streakInDangerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progression'),
        actions: [
          // Leaderboard button
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Classement',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
          ),
          // Rewards button
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            tooltip: 'Recompenses',
            onPressed: () => _showRewardsSheet(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final notifier = ref.read(gamificationNotifierProvider.notifier);
          await notifier.refreshAll();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streak warning banner
              if (streakInDanger) _buildStreakWarningBanner(context, ref),

              // Level & XP Card
              levelAsync.when(
                data: (level) => LevelProgressBar(
                  level: level,
                  onTap: () => _showXpHistory(context, ref),
                ),
                loading: () => const _LoadingCard(height: 200),
                error: (_, __) => const _ErrorCard(message: 'Erreur de chargement'),
              ),
              const SizedBox(height: 24),

              // Streak Card
              streakAsync.when(
                data: (streak) => StreakIndicator(
                  streak: streak,
                  onClaimDaily: () => _claimDailyLogin(context, ref),
                ),
                loading: () => const _LoadingCard(height: 150),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // Quick Stats Row
              _buildQuickStats(context, ref),
              const SizedBox(height: 24),

              // Active Challenges Section
              _buildSectionHeader(
                context,
                'Defis actifs',
                onSeeAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChallengesScreen()),
                ),
              ),
              const SizedBox(height: 12),
              challengesAsync.when(
                data: (challenges) {
                  if (challenges.isEmpty) {
                    return _buildEmptyState(
                      context,
                      'Aucun defi actif',
                      'Revenez plus tard pour de nouveaux defis !',
                    );
                  }
                  // Show top 3 challenges
                  final displayChallenges = challenges.take(3).toList();
                  return Column(
                    children: displayChallenges.map((c) => ChallengeCard(
                      challenge: c,
                      compact: true,
                      onClaim: c.isCompleted || c.progress >= 1.0
                          ? () => _claimChallengeReward(context, ref, c)
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChallengesScreen()),
                      ),
                    )).toList(),
                  );
                },
                loading: () => const _LoadingCard(height: 150),
                error: (_, __) => const _ErrorCard(message: 'Erreur'),
              ),
              const SizedBox(height: 24),

              // Badges Section
              _buildSectionHeader(
                context,
                'Badges obtenus',
                onSeeAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BadgesScreen()),
                ),
              ),
              const SizedBox(height: 12),
              badgesAsync.when(
                data: (badges) {
                  if (badges.isEmpty) {
                    return _buildEmptyState(
                      context,
                      'Aucun badge obtenu',
                      'Completez des defis pour gagner des badges !',
                    );
                  }
                  return BadgeGrid(
                    badges: badges.take(8).toList(),
                    onBadgeTap: (badge) => _showBadgeDetails(context, badge),
                    showLockedBadges: false,
                    crossAxisCount: 4,
                  );
                },
                loading: () => const _LoadingCard(height: 200),
                error: (_, __) => const _ErrorCard(message: 'Erreur'),
              ),
              const SizedBox(height: 24),

              // Referral Section
              _buildReferralSection(context, ref),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakWarningBanner(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak en danger !',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Validez votre connexion pour conserver votre serie',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => _claimDailyLogin(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    final badgeCounts = ref.watch(badgeCountsProvider);
    final levelAsync = ref.watch(userLevelProvider);
    final streakAsync = ref.watch(userStreakProvider);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.star,
            iconColor: Colors.amber,
            value: levelAsync.whenOrNull(data: (l) => '${l.level}') ?? '-',
            label: 'Niveau',
            onTap: () => _showXpHistory(context, ref),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            value: streakAsync.whenOrNull(data: (s) => '${s.currentStreak}') ?? '-',
            label: 'Streak',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.emoji_events,
            iconColor: Colors.purple,
            value: '${badgeCounts.$1}/${badgeCounts.$2}',
            label: 'Badges',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BadgesScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Voir tout'),
          ),
      ],
    );
  }

  Widget _buildReferralSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people, color: Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Parrainage',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Invitez vos amis et gagnez des recompenses',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Referral stats preview
            ref.watch(referralStatsProvider).when(
              data: (stats) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(
                      context,
                      '${stats.totalReferrals}',
                      'Filleuls',
                    ),
                    _buildMiniStat(
                      context,
                      '${stats.activeReferrals}',
                      'Actifs',
                    ),
                    _buildMiniStat(
                      context,
                      '${stats.totalTokensEarned}',
                      'Tokens',
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReferralScreen()),
                ),
                icon: const Icon(Icons.share),
                label: const Text('Inviter des amis'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
        child: BadgeDetailSheet(badge: badge),
      ),
    );
  }

  void _showRewardsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Recompenses disponibles',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final rewardsAsync = ref.watch(availableRewardsProvider);
                    return rewardsAsync.when(
                      data: (rewards) {
                        if (rewards.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.card_giftcard_outlined,
                                  size: 64,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune recompense disponible',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: rewards.length,
                          itemBuilder: (context, index) {
                            final reward = rewards[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getRewardIcon(reward.type),
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                title: Text(reward.name),
                                subtitle: Text(reward.description),
                                trailing: FilledButton(
                                  onPressed: reward.isClaimed
                                      ? null
                                      : () => _claimReward(context, ref, reward),
                                  child: Text(reward.isClaimed ? 'Reclame' : 'Reclamer'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(child: Text('Erreur de chargement')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showXpHistory(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Historique XP',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final historyAsync = ref.watch(xpTransactionsProvider);
                    return historyAsync.when(
                      data: (transactions) {
                        if (transactions.isEmpty) {
                          return Center(
                            child: Text(
                              'Aucune transaction XP',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: tx.amount > 0
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getXpSourceIcon(tx.source),
                                    color: tx.amount > 0 ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                ),
                                title: Text(tx.description),
                                subtitle: Text(_formatDate(tx.createdAt)),
                                trailing: Text(
                                  '${tx.amount > 0 ? '+' : ''}${tx.amount} XP',
                                  style: TextStyle(
                                    color: tx.amount > 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(child: Text('Erreur de chargement')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.tokens:
        return Icons.token;
      case RewardType.xp:
        return Icons.star;
      case RewardType.premiumDays:
        return Icons.workspace_premium;
      case RewardType.discount:
        return Icons.local_offer;
      case RewardType.featureUnlock:
        return Icons.lock_open;
      case RewardType.customization:
        return Icons.palette;
      case RewardType.badge:
        return Icons.emoji_events;
    }
  }

  IconData _getXpSourceIcon(XpSource source) {
    switch (source) {
      case XpSource.analysis:
        return Icons.analytics;
      case XpSource.dailyLogin:
        return Icons.login;
      case XpSource.streak:
        return Icons.local_fire_department;
      case XpSource.challengeComplete:
        return Icons.flag;
      case XpSource.badgeEarned:
        return Icons.emoji_events;
      case XpSource.horseAdded:
        return Icons.pets;
      case XpSource.reportGenerated:
        return Icons.description;
      case XpSource.socialShare:
        return Icons.share;
      case XpSource.referral:
        return Icons.people;
      case XpSource.competition:
        return Icons.sports_score;
      case XpSource.levelUp:
        return Icons.arrow_upward;
      case XpSource.achievement:
        return Icons.military_tech;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'Il y a ${diff.inMinutes} min';
      }
      return 'Il y a ${diff.inHours}h';
    }
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _claimDailyLogin(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(gamificationNotifierProvider.notifier);
    final result = await notifier.claimDailyLogin();

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 8),
              Text('+${result.amount} XP - ${result.description}'),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _claimChallengeReward(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) async {
    final notifier = ref.read(gamificationNotifierProvider.notifier);
    final result = await notifier.claimChallengeReward(challenge.id);

    if (result != null && result.success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 8),
              Text('+${result.xpEarned} XP'),
              if (result.tokensEarned != null && result.tokensEarned! > 0) ...[
                const SizedBox(width: 8),
                Text('+${result.tokensEarned} tokens'),
              ],
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );

      // Show level up dialog if applicable
      if (result.leveledUp && result.newLevel != null) {
        showDialog(
          context: context,
          builder: (context) => LevelUpDialog(
            newLevel: result.newLevel!,
            newTitle: UserLevel.getTitleForLevel(result.newLevel!),
            onContinue: () => Navigator.pop(context),
          ),
        );
      }
    }
  }

  Future<void> _claimReward(
    BuildContext context,
    WidgetRef ref,
    Reward reward,
  ) async {
    final notifier = ref.read(gamificationNotifierProvider.notifier);
    final success = await notifier.claimReward(reward.id);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recompense "${reward.name}" reclamee !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _LoadingCard extends StatelessWidget {
  final double height;

  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}
