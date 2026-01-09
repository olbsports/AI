import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tokens.dart';
import '../providers/tokens_provider.dart';
import '../theme/app_theme.dart';
import '../screens/tokens/purchase_tokens_screen.dart';

/// Pre-analysis modal that shows token cost and balance before starting an analysis
class PreAnalysisModal extends ConsumerWidget {
  /// The type of service being requested
  final String serviceType;

  /// Human-readable name for the service
  final String serviceName;

  /// Optional description of what will be analyzed
  final String? analysisDescription;

  /// Callback when user confirms to proceed with the analysis
  final VoidCallback onConfirm;

  /// Optional callback when user cancels
  final VoidCallback? onCancel;

  const PreAnalysisModal({
    super.key,
    required this.serviceType,
    required this.serviceName,
    this.analysisDescription,
    required this.onConfirm,
    this.onCancel,
  });

  /// Show the pre-analysis modal as a bottom sheet
  static Future<bool?> show({
    required BuildContext context,
    required String serviceType,
    required String serviceName,
    String? analysisDescription,
  }) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PreAnalysisModalContent(
        serviceType: serviceType,
        serviceName: serviceName,
        analysisDescription: analysisDescription,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(tokenBalanceDataProvider);
    final tokensNotifier = ref.read(tokensNotifierProvider.notifier);

    // Get the cost for this service type
    final cost = ServiceTokenCost.defaultCosts
        .where((c) => c.serviceType == serviceType)
        .firstOrNull;

    final requiredTokens = cost?.tokens ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Row(
                children: [
                  Icon(
                    Icons.toll,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confirmation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Service info card
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (analysisDescription != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          analysisDescription!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cout de l\'analyse',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.toll,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$requiredTokens tokens',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Balance info
              balanceAsync.when(
                data: (balance) {
                  final hasSufficientBalance =
                      balance.totalBalance >= requiredTokens;
                  final missingTokens = requiredTokens - balance.totalBalance;

                  return Column(
                    children: [
                      // Current balance
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Votre solde',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '${balance.totalBalance} tokens',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(
                                              balance.balanceStatus),
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.card_membership,
                                          size: 14,
                                          color: AppColors.secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${balance.includedBalance} inclus',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag,
                                        size: 14,
                                        color: AppColors.tertiary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${balance.purchasedBalance} achetes',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Insufficient balance warning
                      if (!hasSufficientBalance) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Solde insuffisant',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Il vous manque $missingTokens tokens pour effectuer cette analyse.',
                                style: TextStyle(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Action buttons
                      if (hasSufficientBalance) ...[
                        // Confirm button
                        FilledButton.icon(
                          onPressed: () {
                            onConfirm();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Lancer l\'analyse'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Cancel button
                        OutlinedButton(
                          onPressed: () {
                            onCancel?.call();
                            Navigator.pop(context);
                          },
                          child: const Text('Annuler'),
                        ),
                      ] else ...[
                        // Buy tokens button
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PurchaseTokensScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Acheter des tokens'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            onCancel?.call();
                            Navigator.pop(context);
                          },
                          child: const Text('Annuler'),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Erreur lors de la verification du solde',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(tokenBalanceDataProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reessayer'),
                    ),
                  ],
                ),
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

/// Internal modal content widget for static show method
class _PreAnalysisModalContent extends ConsumerWidget {
  final String serviceType;
  final String serviceName;
  final String? analysisDescription;

  const _PreAnalysisModalContent({
    required this.serviceType,
    required this.serviceName,
    this.analysisDescription,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(tokenBalanceDataProvider);

    // Get the cost for this service type
    final cost = ServiceTokenCost.defaultCosts
        .where((c) => c.serviceType == serviceType)
        .firstOrNull;

    final requiredTokens = cost?.tokens ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Row(
                children: [
                  Icon(
                    Icons.toll,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confirmation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Service info card
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (analysisDescription != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          analysisDescription!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cout de l\'analyse',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.toll,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$requiredTokens tokens',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Balance and actions
              balanceAsync.when(
                data: (balance) {
                  final hasSufficientBalance =
                      balance.totalBalance >= requiredTokens;
                  final missingTokens = requiredTokens - balance.totalBalance;

                  return Column(
                    children: [
                      // Current balance card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Votre solde',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '${balance.totalBalance} tokens',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(
                                              balance.balanceStatus),
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.card_membership,
                                          size: 14,
                                          color: AppColors.secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${balance.includedBalance} inclus',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag,
                                        size: 14,
                                        color: AppColors.tertiary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${balance.purchasedBalance} achetes',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Insufficient balance warning
                      if (!hasSufficientBalance) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Solde insuffisant',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Il vous manque $missingTokens tokens pour effectuer cette analyse.',
                                style: TextStyle(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Action buttons
                      if (hasSufficientBalance) ...[
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Lancer l\'analyse'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context, false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PurchaseTokensScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Acheter des tokens'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Erreur lors de la verification du solde',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(tokenBalanceDataProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reessayer'),
                    ),
                  ],
                ),
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

/// Quick token check result returned by checkTokensAndShowModal
class TokenCheckResult {
  final bool hasBalance;
  final bool shouldProceed;
  final int currentBalance;
  final int requiredTokens;

  TokenCheckResult({
    required this.hasBalance,
    required this.shouldProceed,
    required this.currentBalance,
    required this.requiredTokens,
  });
}

/// Helper function to check tokens and show modal if needed
Future<TokenCheckResult?> checkTokensAndShowModal({
  required BuildContext context,
  required WidgetRef ref,
  required String serviceType,
  required String serviceName,
  String? analysisDescription,
}) async {
  final balanceAsync = ref.read(tokenBalanceDataProvider);

  final balance = balanceAsync.valueOrNull;
  if (balance == null) {
    // Force refresh and wait
    await ref.refresh(tokenBalanceDataProvider.future);
  }

  final result = await PreAnalysisModal.show(
    context: context,
    serviceType: serviceType,
    serviceName: serviceName,
    analysisDescription: analysisDescription,
  );

  final currentBalance = ref.read(tokenBalanceDataProvider).valueOrNull;
  final cost = ServiceTokenCost.defaultCosts
      .where((c) => c.serviceType == serviceType)
      .firstOrNull;

  return TokenCheckResult(
    hasBalance: (currentBalance?.totalBalance ?? 0) >= (cost?.tokens ?? 0),
    shouldProceed: result == true,
    currentBalance: currentBalance?.totalBalance ?? 0,
    requiredTokens: cost?.tokens ?? 0,
  );
}
