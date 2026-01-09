import 'package:flutter/material.dart' hide Badge;
import '../../models/gamification.dart';
import '../../theme/app_theme.dart';

/// Challenge card widget showing progress and rewards
class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onClaim;
  final VoidCallback? onTap;
  final bool compact;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onClaim,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClaimable = challenge.isCompleted || challenge.progress >= 1.0;

    if (compact) {
      return _buildCompactCard(context, theme, isClaimable);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with type badge and reward
              Row(
                children: [
                  _buildTypeBadge(context),
                  if (challenge.difficulty != ChallengeDifficulty.medium) ...[
                    const SizedBox(width: 8),
                    _buildDifficultyBadge(context),
                  ],
                  const Spacer(),
                  _buildRewardBadge(context),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                challenge.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Description
              Text(
                challenge.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Progress bar
              _buildProgressBar(context, theme),
              const SizedBox(height: 8),

              // Footer with time remaining and claim button
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: _getTimeColor(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatTimeRemaining(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getTimeColor(),
                      ),
                    ),
                  ),
                  if (isClaimable)
                    FilledButton.icon(
                      onPressed: onClaim,
                      icon: const Icon(Icons.card_giftcard, size: 18),
                      label: const Text('Reclamer'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: AppColors.success,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, ThemeData theme, bool isClaimable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon based on challenge type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getChallengeTypeColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    challenge.iconUrl ?? _getDefaultIcon(),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: challenge.progress.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: Colors.grey.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isClaimable ? AppColors.success : _getChallengeTypeColor(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${challenge.currentValue}/${challenge.targetValue}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // XP reward or claim button
              if (isClaimable)
                IconButton(
                  onPressed: onClaim,
                  icon: const Icon(Icons.card_giftcard),
                  color: AppColors.success,
                  tooltip: 'Reclamer',
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${challenge.xpReward}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getChallengeTypeColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        challenge.type.displayName,
        style: TextStyle(
          color: _getChallengeTypeColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDifficultyColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDifficultyIcon(),
            size: 12,
            color: _getDifficultyColor(),
          ),
          const SizedBox(width: 4),
          Text(
            challenge.difficulty.displayName,
            style: TextStyle(
              color: _getDifficultyColor(),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardBadge(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '+${challenge.xpReward} XP',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (challenge.tokenReward != null && challenge.tokenReward! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.token, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '+${challenge.tokenReward}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, ThemeData theme) {
    final progress = challenge.progress.clamp(0.0, 1.0);
    final isComplete = progress >= 1.0;

    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? AppColors.success : _getChallengeTypeColor(),
                  ),
                ),
              ),
              if (isComplete)
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.check,
                      size: 8,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${challenge.currentValue}/${challenge.targetValue}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getChallengeTypeColor() {
    switch (challenge.type) {
      case ChallengeType.daily:
        return Colors.green;
      case ChallengeType.weekly:
        return Colors.blue;
      case ChallengeType.monthly:
        return Colors.purple;
      case ChallengeType.special:
        return Colors.orange;
      case ChallengeType.seasonal:
        return Colors.red;
    }
  }

  Color _getDifficultyColor() {
    switch (challenge.difficulty) {
      case ChallengeDifficulty.easy:
        return Colors.green;
      case ChallengeDifficulty.medium:
        return Colors.orange;
      case ChallengeDifficulty.hard:
        return Colors.red;
      case ChallengeDifficulty.extreme:
        return Colors.purple;
    }
  }

  IconData _getDifficultyIcon() {
    switch (challenge.difficulty) {
      case ChallengeDifficulty.easy:
        return Icons.sentiment_satisfied;
      case ChallengeDifficulty.medium:
        return Icons.sentiment_neutral;
      case ChallengeDifficulty.hard:
        return Icons.local_fire_department;
      case ChallengeDifficulty.extreme:
        return Icons.whatshot;
    }
  }

  String _getDefaultIcon() {
    switch (challenge.type) {
      case ChallengeType.daily:
        return '📅';
      case ChallengeType.weekly:
        return '📆';
      case ChallengeType.monthly:
        return '🗓️';
      case ChallengeType.special:
        return '⭐';
      case ChallengeType.seasonal:
        return '🎄';
    }
  }

  Color _getTimeColor() {
    final remaining = challenge.timeRemaining;
    if (remaining.isNegative) return Colors.red;
    if (remaining.inHours < 2) return Colors.orange;
    if (remaining.inHours < 24) return Colors.amber;
    return AppColors.textSecondary;
  }

  String _formatTimeRemaining() {
    final duration = challenge.timeRemaining;
    if (duration.isNegative) return 'Expire';
    if (duration.inDays > 0) {
      return '${duration.inDays}j ${duration.inHours % 24}h restant';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m restant';
    }
    return '${duration.inMinutes}m restant';
  }
}

/// Challenge list with grouped sections
class ChallengeListSection extends StatelessWidget {
  final String title;
  final List<Challenge> challenges;
  final Function(Challenge)? onChallengeTap;
  final Function(Challenge)? onClaimReward;
  final bool compact;

  const ChallengeListSection({
    super.key,
    required this.title,
    required this.challenges,
    this.onChallengeTap,
    this.onClaimReward,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${challenges.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...challenges.map((challenge) => ChallengeCard(
          challenge: challenge,
          compact: compact,
          onTap: onChallengeTap != null ? () => onChallengeTap!(challenge) : null,
          onClaim: onClaimReward != null ? () => onClaimReward!(challenge) : null,
        )),
      ],
    );
  }
}
