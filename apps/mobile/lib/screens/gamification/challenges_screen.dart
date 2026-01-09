import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gamification.dart';
import '../../providers/gamification_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gamification/challenge_card.dart';

/// Screen showing all challenges organized by type (daily/weekly/monthly)
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Defis'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Quotidiens'),
            Tab(text: 'Hebdomadaires'),
            Tab(text: 'Mensuels'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllChallengesTab(),
          _ChallengesByTypeTab(type: ChallengeType.daily),
          _ChallengesByTypeTab(type: ChallengeType.weekly),
          _ChallengesByTypeTab(type: ChallengeType.monthly),
        ],
      ),
    );
  }
}

class _AllChallengesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(activeChallengesProvider);
    final theme = Theme.of(context);

    return challengesAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return _buildEmptyState(context);
        }

        // Group by type
        final daily = challenges.where((c) => c.type == ChallengeType.daily).toList();
        final weekly = challenges.where((c) => c.type == ChallengeType.weekly).toList();
        final monthly = challenges.where((c) => c.type == ChallengeType.monthly).toList();
        final special = challenges.where((c) =>
            c.type == ChallengeType.special || c.type == ChallengeType.seasonal).toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeChallengesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                _buildSummaryCard(context, challenges),
                const SizedBox(height: 24),

                // Daily challenges
                if (daily.isNotEmpty)
                  ChallengeListSection(
                    title: 'Quotidiens',
                    challenges: daily,
                    onClaimReward: (challenge) =>
                        _claimReward(context, ref, challenge),
                  ),

                // Weekly challenges
                if (weekly.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ChallengeListSection(
                    title: 'Hebdomadaires',
                    challenges: weekly,
                    onClaimReward: (challenge) =>
                        _claimReward(context, ref, challenge),
                  ),
                ],

                // Monthly challenges
                if (monthly.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ChallengeListSection(
                    title: 'Mensuels',
                    challenges: monthly,
                    onClaimReward: (challenge) =>
                        _claimReward(context, ref, challenge),
                  ),
                ],

                // Special challenges
                if (special.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ChallengeListSection(
                    title: 'Speciaux',
                    challenges: special,
                    onClaimReward: (challenge) =>
                        _claimReward(context, ref, challenge),
                  ),
                ],
              ],
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
              onPressed: () => ref.invalidate(activeChallengesProvider),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<Challenge> challenges) {
    final theme = Theme.of(context);
    final completed = challenges.where((c) => c.isCompleted).length;
    final inProgress = challenges.where((c) => !c.isCompleted && c.progress > 0).length;
    final totalXp = challenges.fold<int>(0, (sum, c) => sum + c.xpReward);
    final earnableXp = challenges
        .where((c) => !c.isCompleted)
        .fold<int>(0, (sum, c) => sum + c.xpReward);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                '$completed',
                'Completes',
                Icons.check_circle,
              ),
              _buildStatItem(
                context,
                '$inProgress',
                'En cours',
                Icons.trending_up,
              ),
              _buildStatItem(
                context,
                '${challenges.length}',
                'Total',
                Icons.flag,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$earnableXp XP a gagner',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            'Aucun defi actif',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revenez plus tard pour decouvrir de nouveaux defis !',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _claimReward(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) async {
    final notifier = ref.read(gamificationNotifierProvider.notifier);
    final result = await notifier.claimChallengeReward(challenge.id);

    if (result != null && result.success) {
      if (context.mounted) {
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
            builder: (context) => AlertDialog(
              title: const Text('Niveau superieur !'),
              content: Text('Felicitations ! Vous avez atteint le niveau ${result.newLevel}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Super !'),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}

class _ChallengesByTypeTab extends ConsumerWidget {
  final ChallengeType type;

  const _ChallengesByTypeTab({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesByTypeProvider(type));

    return challengesAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeChallengesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return ChallengeCard(
                challenge: challenge,
                onClaim: challenge.isCompleted || challenge.progress >= 1.0
                    ? () => _claimReward(context, ref, challenge)
                    : null,
              );
            },
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
              onPressed: () => ref.invalidate(activeChallengesProvider),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final String typeLabel;
    final String resetInfo;

    switch (type) {
      case ChallengeType.daily:
        typeLabel = 'quotidien';
        resetInfo = 'Nouveaux defis a minuit !';
        break;
      case ChallengeType.weekly:
        typeLabel = 'hebdomadaire';
        resetInfo = 'Nouveaux defis chaque lundi !';
        break;
      case ChallengeType.monthly:
        typeLabel = 'mensuel';
        resetInfo = 'Nouveaux defis le 1er du mois !';
        break;
      default:
        typeLabel = 'special';
        resetInfo = '';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Aucun defi $typeLabel actif',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (resetInfo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                resetInfo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _claimReward(
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
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
