import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tokens.dart';
import '../providers/tokens_provider.dart';
import '../theme/app_theme.dart';
import '../screens/tokens/tokens_screen.dart';

/// Compact token balance widget for dashboard display
class TokenBalanceWidget extends ConsumerWidget {
  /// Whether to show detailed breakdown
  final bool showDetails;

  /// Whether tapping navigates to tokens screen
  final bool navigateOnTap;

  /// Custom onTap callback (overrides navigation)
  final VoidCallback? onTap;

  const TokenBalanceWidget({
    super.key,
    this.showDetails = false,
    this.navigateOnTap = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(tokenBalanceDataProvider);

    return balanceAsync.when(
      data: (balance) => _buildWidget(context, balance),
      loading: () => _buildLoadingWidget(context),
      error: (_, __) => _buildErrorWidget(context, ref),
    );
  }

  Widget _buildWidget(BuildContext context, TokenBalance balance) {
    final statusColor = _getStatusColor(balance.balanceStatus);

    return Card(
      child: InkWell(
        onTap: onTap ??
            (navigateOnTap
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TokensScreen()),
                    )
                : null),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.toll,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tokens',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        Text(
                          '${balance.totalBalance}',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              // Details section
              if (showDetails) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceDetail(
                        context,
                        label: 'Inclus',
                        value: balance.includedBalance,
                        icon: Icons.card_membership,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBalanceDetail(
                        context,
                        label: 'Achetes',
                        value: balance.purchasedBalance,
                        icon: Icons.shopping_bag,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ],

              // Warning for low balance
              if (balance.balanceStatus == 'low' ||
                  balance.balanceStatus == 'critical') ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: balance.balanceStatus == 'critical'
                        ? AppColors.errorContainer
                        : AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: balance.balanceStatus == 'critical'
                            ? AppColors.error
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          balance.balanceStatus == 'critical'
                              ? 'Solde tres faible'
                              : 'Solde faible',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: balance.balanceStatus == 'critical'
                                ? AppColors.error
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceDetail(
    BuildContext context, {
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tokens',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  'Chargement...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () => ref.invalidate(tokenBalanceDataProvider),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tokens',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    'Erreur - Appuyez pour reessayer',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'good':
        return AppColors.success;
      case 'low':
        return AppColors.warning;
      case 'critical':
        return AppColors.error;
      case 'empty':
        return AppColors.textTertiary;
      default:
        return AppColors.primary;
    }
  }
}

/// Minimal inline token balance display
class TokenBalanceInline extends ConsumerWidget {
  const TokenBalanceInline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(tokenBalanceDataProvider);

    return balanceAsync.when(
      data: (balance) {
        final statusColor = _getStatusColor(balance.balanceStatus);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.toll, size: 16, color: statusColor),
            const SizedBox(width: 4),
            Text(
              '${balance.totalBalance}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => Icon(
        Icons.error_outline,
        size: 16,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'good':
        return AppColors.success;
      case 'low':
        return AppColors.warning;
      case 'critical':
        return AppColors.error;
      case 'empty':
        return AppColors.textTertiary;
      default:
        return AppColors.primary;
    }
  }
}

/// Token balance chip for app bar or buttons
class TokenBalanceChip extends ConsumerWidget {
  final VoidCallback? onTap;

  const TokenBalanceChip({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(tokenBalanceDataProvider);

    return balanceAsync.when(
      data: (balance) {
        final statusColor = _getStatusColor(balance.balanceStatus);
        return ActionChip(
          avatar: Icon(Icons.toll, size: 18, color: statusColor),
          label: Text(
            '${balance.totalBalance}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          onPressed: onTap ??
              () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TokensScreen()),
                  ),
          backgroundColor: statusColor.withValues(alpha: 0.1),
          side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
        );
      },
      loading: () => ActionChip(
        avatar: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('...'),
        onPressed: null,
      ),
      error: (_, __) => ActionChip(
        avatar: Icon(
          Icons.error_outline,
          size: 18,
          color: Theme.of(context).colorScheme.error,
        ),
        label: const Text('--'),
        onPressed: () => ref.invalidate(tokenBalanceDataProvider),
        backgroundColor: AppColors.errorContainer,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'good':
        return AppColors.success;
      case 'low':
        return AppColors.warning;
      case 'critical':
        return AppColors.error;
      case 'empty':
        return AppColors.textTertiary;
      default:
        return AppColors.primary;
    }
  }
}
