import 'package:flutter/material.dart';
import '../../models/gamification.dart';
import '../../theme/app_theme.dart';

/// Streak indicator widget with fire animation
class StreakIndicator extends StatelessWidget {
  final UserStreak streak;
  final VoidCallback? onClaimDaily;
  final bool showClaimButton;
  final bool compact;

  const StreakIndicator({
    super.key,
    required this.streak,
    this.onClaimDaily,
    this.showClaimButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactIndicator(context);
    }
    return _buildFullIndicator(context);
  }

  Widget _buildCompactIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final hasStreak = streak.currentStreak > 0;
    final isAtRisk = _isStreakAtRisk();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasStreak
            ? (isAtRisk ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1))
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: isAtRisk
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFireIcon(hasStreak, isAtRisk),
          const SizedBox(width: 6),
          Text(
            '${streak.currentStreak}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasStreak ? Colors.orange : AppColors.textSecondary,
            ),
          ),
          if (isAtRisk) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final hasStreak = streak.currentStreak > 0;
    final isAtRisk = _isStreakAtRisk();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildFireIconLarge(hasStreak, isAtRisk),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${streak.currentStreak}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: hasStreak ? Colors.orange : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            streak.currentStreak == 1 ? 'jour' : 'jours consecutifs',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Record: ${streak.longestStreak} jours',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showClaimButton && !streak.isActiveToday)
                  FilledButton(
                    onPressed: onClaimDaily,
                    style: FilledButton.styleFrom(
                      backgroundColor: isAtRisk ? Colors.orange : AppColors.primary,
                    ),
                    child: const Text('Valider'),
                  )
                else if (streak.isActiveToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Valide',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Warning message if at risk
            if (isAtRisk) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attention ! Votre streak est en danger. Validez votre connexion pour le conserver.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Weekly calendar visualization
            const SizedBox(height: 16),
            _buildWeekCalendar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFireIcon(bool hasStreak, bool isAtRisk) {
    if (!hasStreak) {
      return const Text('💤', style: TextStyle(fontSize: 20));
    }
    if (isAtRisk) {
      return const Text('🔥', style: TextStyle(fontSize: 20));
    }
    return const Text('🔥', style: TextStyle(fontSize: 20));
  }

  Widget _buildFireIconLarge(bool hasStreak, bool isAtRisk) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: hasStreak
            ? (isAtRisk ? Colors.orange.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.1))
            : Colors.grey.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: isAtRisk
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          hasStreak ? '🔥' : '💤',
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildWeekCalendar(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    // Get the start of the current week (Monday)
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final day = startOfWeek.add(Duration(days: index));
        final isToday = _isSameDay(day, today);
        final isActive = _isActivityDay(day);
        final isFuture = day.isAfter(today);

        return Column(
          children: [
            Text(
              weekDays[index],
              style: theme.textTheme.labelSmall?.copyWith(
                color: isToday ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getDayColor(isActive, isToday, isFuture),
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: isActive
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : Text(
                        '${day.day}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isFuture
                              ? AppColors.textTertiary
                              : AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getDayColor(bool isActive, bool isToday, bool isFuture) {
    if (isActive) return AppColors.success;
    if (isFuture) return Colors.transparent;
    if (isToday) return Colors.transparent;
    return Colors.grey.withValues(alpha: 0.1);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isActivityDay(DateTime day) {
    return streak.activityDates.any((d) => _isSameDay(d, day));
  }

  bool _isStreakAtRisk() {
    if (streak.isActiveToday) return false;
    if (streak.currentStreak == 0) return false;
    if (streak.lastActivityDate == null) return false;
    final hoursSinceLastActivity = DateTime.now().difference(streak.lastActivityDate!).inHours;
    return hoursSinceLastActivity >= 20;
  }
}

/// Mini streak badge for displaying in headers/nav
class StreakBadge extends StatelessWidget {
  final int streakDays;
  final bool isActive;
  final double size;

  const StreakBadge({
    super.key,
    required this.streakDays,
    this.isActive = true,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isActive ? '🔥' : '💤',
            style: TextStyle(fontSize: size * 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            '$streakDays',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.orange : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
