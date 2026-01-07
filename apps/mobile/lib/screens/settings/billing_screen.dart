import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/billing_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final plansAsync = ref.watch(plansProvider);
    final tokenBalanceAsync = ref.watch(tokenBalanceProvider);
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnement'),
      ),
      body: subscriptionAsync.when(
        data: (subscription) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current plan
              _buildCurrentPlanCard(context, subscription),
              const SizedBox(height: 24),

              // Usage
              tokenBalanceAsync.when(
                data: (balance) => _buildUsageSection(context, balance),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Plans
              Text(
                'Changer d\'offre',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              plansAsync.when(
                data: (plans) => Column(
                  children: plans
                      .map((plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildPlanCard(
                              context,
                              ref,
                              plan: plan,
                              currentPlanId: subscription['planId'] ?? subscription['plan'],
                            ),
                          ))
                      .toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildDefaultPlans(context, ref, subscription['planId'] ?? subscription['plan']),
              ),
              const SizedBox(height: 24),

              // Billing history
              invoicesAsync.when(
                data: (invoices) => _buildBillingHistory(context, invoices),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildEmptyBillingHistory(context),
              ),

              // Cancel subscription button
              if (subscription['status'] == 'active' &&
                  (subscription['planId'] ?? subscription['plan']) != 'free') ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => _confirmCancelSubscription(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Annuler l\'abonnement'),
                ),
              ],

              // Reactivate button for cancelled subscriptions
              if (subscription['status'] == 'cancelled') ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _reactivateSubscription(context, ref),
                  child: const Text('Réactiver l\'abonnement'),
                ),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(subscriptionProvider),
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context, Map<String, dynamic> subscription) {
    final planName = subscription['planName'] ?? subscription['plan']?['name'] ?? 'Starter';
    final price = subscription['plan']?['price'] ?? 0;
    final status = subscription['status'] ?? 'active';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Plan actuel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (status == 'cancelled')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Annulé',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              planName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              price == 0 ? 'Gratuit' : '${price}€/mois',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subscription['currentPeriodEnd'] != null) ...[
              const SizedBox(height: 8),
              Text(
                status == 'cancelled'
                    ? 'Expire le ${_formatDate(subscription['currentPeriodEnd'])}'
                    : 'Renouvellement le ${_formatDate(subscription['currentPeriodEnd'])}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSection(BuildContext context, Map<String, dynamic> balance) {
    final horsesUsed = balance['horsesUsed'] ?? 0;
    final horsesLimit = balance['horsesLimit'] ?? 5;
    final analysesUsed = balance['analysesUsed'] ?? 0;
    final analysesLimit = balance['analysesLimit'] ?? 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Utilisation ce mois',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildUsageItem(
          context,
          label: 'Chevaux',
          used: horsesUsed,
          total: horsesLimit,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildUsageItem(
          context,
          label: 'Analyses',
          used: analysesUsed,
          total: analysesLimit,
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildUsageItem(
    BuildContext context, {
    required String label,
    required int used,
    required int total,
    required Color color,
  }) {
    final progress = total > 0 ? used / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  total == -1 ? '$used / illimité' : '$used / $total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total == -1 ? 0 : progress.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    WidgetRef ref, {
    required Map<String, dynamic> plan,
    required String? currentPlanId,
  }) {
    final id = plan['id'] ?? '';
    final name = plan['name'] ?? '';
    final price = plan['price'] ?? 0;
    final features = (plan['features'] as List?)?.cast<String>() ?? [];
    final isCurrentPlan = id == currentPlanId;
    final isRecommended = plan['recommended'] == true || name.toLowerCase() == 'pro';

    return Card(
      shape: isRecommended
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isRecommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Recommandé',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price == 0 ? 'Gratuit' : '${price}€/mois',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isCurrentPlan
                  ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Plan actuel'),
                    )
                  : FilledButton(
                      onPressed: () => _upgradePlan(context, ref, id, name),
                      child: const Text('Choisir ce plan'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultPlans(BuildContext context, WidgetRef ref, String? currentPlanId) {
    final defaultPlans = [
      {
        'id': 'free',
        'name': 'Starter',
        'price': 0,
        'features': ['5 chevaux', '10 analyses/mois', 'Support email'],
      },
      {
        'id': 'pro',
        'name': 'Pro',
        'price': 29,
        'features': ['25 chevaux', '100 analyses/mois', 'Rapports avancés', 'Support prioritaire'],
        'recommended': true,
      },
      {
        'id': 'enterprise',
        'name': 'Enterprise',
        'price': -1,
        'features': ['Chevaux illimités', 'Analyses illimitées', 'API access', 'Support dédié'],
      },
    ];

    return Column(
      children: defaultPlans
          .map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPlanCard(context, ref, plan: plan, currentPlanId: currentPlanId),
              ))
          .toList(),
    );
  }

  Widget _buildBillingHistory(BuildContext context, List<Map<String, dynamic>> invoices) {
    if (invoices.isEmpty) {
      return _buildEmptyBillingHistory(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historique des paiements',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...invoices.map((invoice) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  invoice['status'] == 'paid' ? Icons.check_circle : Icons.pending,
                  color: invoice['status'] == 'paid' ? AppColors.success : Colors.orange,
                ),
                title: Text('Facture ${invoice['number'] ?? invoice['id']}'),
                subtitle: Text(_formatDate(invoice['date'] ?? invoice['createdAt'])),
                trailing: Text(
                  '${invoice['amount'] ?? 0}€',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildEmptyBillingHistory(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historique des paiements',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun paiement',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final DateTime dateTime = date is String ? DateTime.parse(date) : date;
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }

  void _upgradePlan(BuildContext context, WidgetRef ref, String planId, String planName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer de plan'),
        content: Text('Voulez-vous passer au plan $planName ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await ref.read(billingNotifierProvider.notifier).upgradePlan(planId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Plan mis à jour avec succès' : 'Erreur lors du changement de plan',
                    ),
                    backgroundColor: success ? AppColors.success : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelSubscription(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'abonnement'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler votre abonnement ? '
          'Vous conserverez l\'accès jusqu\'à la fin de la période en cours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await ref.read(billingNotifierProvider.notifier).cancelSubscription();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Abonnement annulé' : 'Erreur lors de l\'annulation',
                    ),
                    backgroundColor: success ? null : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  void _reactivateSubscription(BuildContext context, WidgetRef ref) async {
    final success =
        await ref.read(billingNotifierProvider.notifier).reactivateSubscription();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Abonnement réactivé' : 'Erreur lors de la réactivation',
          ),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
  }
}
