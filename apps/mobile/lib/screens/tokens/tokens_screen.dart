import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/tokens.dart';
import '../../providers/tokens_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';
import 'purchase_tokens_screen.dart';
import 'token_history_screen.dart';
import 'token_usage_screen.dart';

class TokensScreen extends ConsumerWidget {
  const TokensScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(tokenBalanceDataProvider);
    final usageAsync = ref.watch(tokenUsageStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tokens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TokenUsageScreen()),
            ),
            tooltip: 'Statistiques',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TokenHistoryScreen()),
            ),
            tooltip: 'Historique',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tokenBalanceDataProvider);
          ref.invalidate(tokenUsageStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance card
              balanceAsync.when(
                data: (balance) => _buildBalanceCard(context, balance),
                loading: () => _buildBalanceCardLoading(context),
                error: (e, _) => _buildBalanceCardError(context, ref, e),
              ),
              const SizedBox(height: 24),

              // Buy tokens button
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PurchaseTokensScreen()),
                ),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Acheter des tokens'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Usage statistics
              usageAsync.when(
                data: (stats) => _buildUsageSection(context, stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Token costs info
              _buildTokenCostsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, TokenBalance balance) {
    final statusColor = _getStatusColor(balance.balanceStatus);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Total balance
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.toll,
                  size: 32,
                  color: statusColor,
                ),
                const SizedBox(width: 12),
                Text(
                  '${balance.totalBalance}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  'tokens',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Balance breakdown
            Row(
              children: [
                Expanded(
                  child: _buildBalanceItem(
                    context,
                    label: 'Inclus (abonnement)',
                    value: balance.includedBalance,
                    icon: Icons.card_membership,
                    color: AppColors.secondary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildBalanceItem(
                    context,
                    label: 'Achetes',
                    value: balance.purchasedBalance,
                    icon: Icons.shopping_bag,
                    color: AppColors.tertiary,
                  ),
                ),
              ],
            ),

            // Period info
            if (balance.includedPeriodEnd != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Renouvellement le ${DateFormat('dd/MM/yyyy').format(balance.includedPeriodEnd!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],

            // Low balance warning
            if (balance.balanceStatus == 'low' || balance.balanceStatus == 'critical') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
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
                      color: balance.balanceStatus == 'critical'
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        balance.balanceStatus == 'critical'
                            ? 'Solde tres faible ! Pensez a recharger.'
                            : 'Solde faible. Pensez a recharger.',
                        style: TextStyle(
                          color: balance.balanceStatus == 'critical'
                              ? AppColors.error
                              : AppColors.warning,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildBalanceItem(
    BuildContext context, {
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBalanceCardLoading(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildBalanceCardError(BuildContext context, WidgetRef ref, Object error) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.invalidate(tokenBalanceDataProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSection(BuildContext context, TokenUsageStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques d\'utilisation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Total consomme',
                value: '${stats.totalConsumed}',
                icon: Icons.trending_down,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Total achete',
                value: '${stats.totalPurchased}',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Usage by service type
        if (stats.byServiceType.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Par type de service',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...stats.byServiceType.entries.map((entry) {
                    final total = stats.totalConsumed > 0 ? stats.totalConsumed : 1;
                    final percentage = (entry.value / total * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getServiceDisplayName(entry.key),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '${entry.value} tokens ($percentage%)',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCostsSection(BuildContext context) {
    final costs = ServiceTokenCost.defaultCosts;
    final categories = <String, List<ServiceTokenCost>>{};

    for (final cost in costs) {
      categories.putIfAbsent(cost.category, () => []).add(cost);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cout des services',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...categories.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(_getCategoryIcon(entry.key)),
              title: Text(
                _getCategoryDisplayName(entry.key),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: entry.value.map((cost) {
                return ListTile(
                  dense: true,
                  title: Text(cost.name),
                  subtitle: Text(cost.description),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${cost.tokens}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
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

  String _getServiceDisplayName(String serviceType) {
    switch (serviceType) {
      case 'VIDEO_BASIC':
        return 'Analyse video simple';
      case 'VIDEO_STANDARD':
        return 'Analyse video complete';
      case 'VIDEO_PARCOURS':
        return 'Analyse parcours';
      case 'VIDEO_ADVANCED':
        return 'Analyse avancee';
      case 'LOCOMOTION':
        return 'Analyse locomotion';
      case 'RADIO_SIMPLE':
        return 'Radio simple';
      case 'RADIO_COMPLETE':
        return 'Radio complete';
      case 'RADIO_EXPERT':
        return 'Radio expert';
      case 'HORSE_PROFILE':
        return 'Fiche cheval';
      case 'ANALYSIS_REPORT':
        return 'Rapport analyse';
      case 'HEALTH_REPORT':
        return 'Rapport sante';
      case 'PROGRESSION_REPORT':
        return 'Rapport progression';
      case 'SALE_REPORT':
        return 'Dossier vente';
      case 'BREEDING_REPORT':
        return 'Rapport elevage';
      case 'EQUICOTE_STANDARD':
        return 'EquiCote standard';
      case 'EQUICOTE_PREMIUM':
        return 'EquiCote premium';
      case 'BREEDING_RECOMMEND':
        return 'Recommandations elevage';
      case 'BREEDING_MATCH':
        return 'Match elevage';
      default:
        return serviceType;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'video':
        return 'Analyses Video';
      case 'radio':
        return 'Analyses Radiologiques';
      case 'report':
        return 'Rapports';
      case 'valuation':
        return 'Valorisation';
      case 'breeding':
        return 'Elevage';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'video':
        return Icons.videocam;
      case 'radio':
        return Icons.medical_services;
      case 'report':
        return Icons.description;
      case 'valuation':
        return Icons.euro;
      case 'breeding':
        return Icons.favorite;
      default:
        return Icons.token;
    }
  }
}
