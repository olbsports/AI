import 'package:flutter/material.dart' hide Badge;
import '../../models/gamification.dart';
import '../../theme/app_theme.dart';

/// Badge grid widget showing locked/unlocked states
class BadgeGrid extends StatelessWidget {
  final List<Badge> badges;
  final Function(Badge)? onBadgeTap;
  final int crossAxisCount;
  final bool showProgress;
  final bool showLockedBadges;

  const BadgeGrid({
    super.key,
    required this.badges,
    this.onBadgeTap,
    this.crossAxisCount = 4,
    this.showProgress = true,
    this.showLockedBadges = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayBadges = showLockedBadges
        ? badges
        : badges.where((b) => b.isEarned).toList();

    if (displayBadges.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aucun badge a afficher',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: displayBadges.length,
      itemBuilder: (context, index) {
        final badge = displayBadges[index];
        return BadgeItem(
          badge: badge,
          onTap: onBadgeTap != null ? () => onBadgeTap!(badge) : null,
          showProgress: showProgress,
        );
      },
    );
  }
}

/// Individual badge item
class BadgeItem extends StatelessWidget {
  final Badge badge;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool large;

  const BadgeItem({
    super.key,
    required this.badge,
    this.onTap,
    this.showProgress = true,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEarned = badge.isEarned;
    final rarityColor = Color(badge.rarity.color);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isEarned
              ? rarityColor.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned ? rarityColor : Colors.grey.withValues(alpha: 0.2),
            width: isEarned ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: large ? 64 : 48,
                  height: large ? 64 : 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEarned
                        ? rarityColor.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: isEarned
                        ? Text(
                            badge.iconUrl,
                            style: TextStyle(fontSize: large ? 28 : 22),
                          )
                        : Icon(
                            Icons.lock_outline,
                            size: large ? 24 : 18,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                  ),
                ),
                // Progress ring if not earned
                if (!isEarned && showProgress && badge.progress != null)
                  SizedBox(
                    width: large ? 64 : 48,
                    height: large ? 64 : 48,
                    child: CircularProgressIndicator(
                      value: badge.progress!.clamp(0.0, 1.0),
                      strokeWidth: 3,
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        rarityColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Badge name
            if (large || !badge.isSecret || isEarned)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  isEarned || !badge.isSecret ? badge.name : '???',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isEarned ? null : AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Rarity indicator
            if (large && isEarned) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge.rarity.displayName,
                  style: TextStyle(
                    fontSize: 9,
                    color: rarityColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge detail bottom sheet
class BadgeDetailSheet extends StatelessWidget {
  final Badge badge;
  final VoidCallback? onShare;

  const BadgeDetailSheet({
    super.key,
    required this.badge,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rarityColor = Color(badge.rarity.color);
    final isEarned = badge.isEarned;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge icon with glow effect
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEarned
                  ? rarityColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
              border: Border.all(
                color: isEarned ? rarityColor : Colors.grey,
                width: 3,
              ),
            ),
            child: Center(
              child: isEarned
                  ? Text(badge.iconUrl, style: const TextStyle(fontSize: 48))
                  : Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Badge name
          Text(
            isEarned || !badge.isSecret ? badge.name : '??? Badge Secret ???',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Rarity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge.rarity.displayName,
              style: TextStyle(
                color: rarityColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            isEarned || !badge.isSecret
                ? badge.description
                : 'Continuez a jouer pour decouvrir ce badge secret!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Category
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(badge.category),
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                badge.category.displayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // XP reward
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 18, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '+${badge.xpReward} XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Progress or earned date
          const SizedBox(height: 20),
          if (isEarned && badge.earnedAt != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Obtenu le ${_formatDate(badge.earnedAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            )
          else if (!isEarned && badge.progress != null)
            Column(
              children: [
                Text(
                  'Progression',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: badge.progress!.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(badge.progress! * 100).toInt()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

          // Share button if earned
          if (isEarned && onShare != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share),
              label: const Text('Partager'),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.analysis:
        return Icons.analytics;
      case BadgeCategory.training:
        return Icons.fitness_center;
      case BadgeCategory.social:
        return Icons.people;
      case BadgeCategory.competition:
        return Icons.emoji_events;
      case BadgeCategory.streak:
        return Icons.local_fire_department;
      case BadgeCategory.collection:
        return Icons.collections;
      case BadgeCategory.breeding:
        return Icons.favorite;
      case BadgeCategory.health:
        return Icons.healing;
      case BadgeCategory.general:
        return Icons.star;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Badge category filter chips
class BadgeCategoryFilter extends StatelessWidget {
  final BadgeCategory? selectedCategory;
  final ValueChanged<BadgeCategory?> onCategoryChanged;
  final bool showAllOption;

  const BadgeCategoryFilter({
    super.key,
    this.selectedCategory,
    required this.onCategoryChanged,
    this.showAllOption = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showAllOption)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Tous'),
                selected: selectedCategory == null,
                onSelected: (_) => onCategoryChanged(null),
              ),
            ),
          ...BadgeCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category.displayName),
                selected: selectedCategory == category,
                onSelected: (_) => onCategoryChanged(
                  selectedCategory == category ? null : category,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
