import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_theme.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final revenueAsync = ref.watch(revenueStatsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AdminColors.darkBackground,
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(subscriptionsProvider);
            ref.invalidate(subscriptionPlansProvider);
            ref.invalidate(revenueStatsProvider);
          },
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Abonnements',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreatePlanDialog(context, ref),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nouveau plan'),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Abonnements',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showCreatePlanDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Nouveau plan'),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Revenue stats
                revenueAsync.when(
                  data: (stats) => _buildRevenueStats(stats, isMobile),
                  loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Tabs
                TabBar(
                  labelColor: AdminColors.primary,
                  unselectedLabelColor: AdminColors.textSecondary,
                  indicatorColor: AdminColors.primary,
                  tabs: const [
                    Tab(text: 'Abonnements'),
                    Tab(text: 'Plans'),
                    Tab(text: 'Revenus'),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSubscriptionsList(subscriptionsAsync, ref, context, isMobile),
                      _buildPlansList(plansAsync, ref, context, isMobile),
                      _buildRevenueChart(revenueAsync),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueStats(RevenueStats stats, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMiniStatCard('MRR', '${stats.mrr.toStringAsFixed(0)}€', stats.mrrGrowth)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniStatCard('ARR', '${stats.arr.toStringAsFixed(0)}€', null)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMiniStatCard('LTV', '${stats.ltv.toStringAsFixed(0)}€', null)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniStatCard('Churn', '${stats.churnRate.toStringAsFixed(1)}%', null)),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildRevenueCard('MRR', stats.mrr, stats.mrrGrowth),
        const SizedBox(width: 16),
        _buildRevenueCard('ARR', stats.arr, null),
        const SizedBox(width: 16),
        _buildStatCard('LTV', '${stats.ltv.toStringAsFixed(0)}€'),
        const SizedBox(width: 16),
        _buildStatCard('Churn', '${stats.churnRate.toStringAsFixed(1)}%'),
        const SizedBox(width: 16),
        _buildStatCard('Conversions', '${stats.trialConversions}'),
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, double? growth) {
    return Card(
      color: AdminColors.darkCard,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                if (growth != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                    style: TextStyle(color: growth >= 0 ? AdminColors.success : AdminColors.error, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(String label, double value, double? growth) {
    return Expanded(
      child: Card(
        color: AdminColors.darkCard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AdminColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    NumberFormat.currency(locale: 'fr', symbol: '€').format(value),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                  ),
                  if (growth != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: growth >= 0 ? AdminColors.success.withOpacity(0.1) : AdminColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                        style: TextStyle(color: growth >= 0 ? AdminColors.success : AdminColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Card(
        color: AdminColors.darkCard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AdminColors.textSecondary)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionsList(AsyncValue<SubscriptionListResponse> subscriptionsAsync, WidgetRef ref, BuildContext context, bool isMobile) {
    return subscriptionsAsync.when(
      data: (response) {
        if (response.subscriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.credit_card_off, size: 64, color: AdminColors.textMuted),
                const SizedBox(height: 16),
                Text('Aucun abonnement', style: TextStyle(color: AdminColors.textSecondary)),
              ],
            ),
          );
        }

        return Card(
          color: AdminColors.darkCard,
          child: ListView.separated(
            itemCount: response.subscriptions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AdminColors.darkBorder),
            itemBuilder: (ctx, index) {
              final sub = response.subscriptions[index];
              return _buildSubscriptionItem(sub, ref, context, isMobile);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorView('Erreur: $e', () => ref.invalidate(subscriptionsProvider)),
    );
  }

  Widget _buildSubscriptionItem(Subscription sub, WidgetRef ref, BuildContext context, bool isMobile) {
    return InkWell(
      onTap: () => _showSubscriptionDetails(context, ref, sub),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: isMobile ? 20 : 24,
              backgroundColor: Color(sub.status.colorValue).withOpacity(0.1),
              child: Icon(Icons.person, color: Color(sub.status.colorValue), size: isMobile ? 20 : 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.userName, style: TextStyle(fontWeight: FontWeight.w600, color: AdminColors.textPrimary, fontSize: isMobile ? 14 : 16)),
                  Text(
                    '${sub.planName} • ${sub.amount}€/${sub.interval.displayName}',
                    style: TextStyle(color: AdminColors.textSecondary, fontSize: isMobile ? 12 : 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(sub.status.colorValue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                sub.status.displayName,
                style: TextStyle(color: Color(sub.status.colorValue), fontWeight: FontWeight.w500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(AsyncValue<List<SubscriptionPlan>> plansAsync, WidgetRef ref, BuildContext context, bool isMobile) {
    return plansAsync.when(
      data: (plans) {
        if (plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: AdminColors.textMuted),
                const SizedBox(height: 16),
                Text('Aucun plan configuré', style: TextStyle(color: AdminColors.textSecondary)),
              ],
            ),
          );
        }

        if (isMobile) {
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (ctx, index) => _buildMobilePlanCard(plans[index], ref, context),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: plans.length,
          itemBuilder: (ctx, index) => _buildDesktopPlanCard(plans[index], ref, context),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorView('Erreur: $e', () => ref.invalidate(subscriptionPlansProvider)),
    );
  }

  Widget _buildMobilePlanCard(SubscriptionPlan plan, WidgetRef ref, BuildContext context) {
    return Card(
      color: AdminColors.darkCard,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('${plan.monthlyPrice.toStringAsFixed(0)}€/mois', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AdminColors.primary)),
                  ],
                ),
                Switch(
                  value: plan.isActive,
                  activeColor: AdminColors.primary,
                  onChanged: (value) => _togglePlanActive(context, ref, plan, value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${plan.subscriberCount} abonnés', style: TextStyle(color: AdminColors.textSecondary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: plan.features.take(3).map((f) => Chip(
                label: Text(f, style: const TextStyle(fontSize: 10, color: AdminColors.textPrimary)),
                backgroundColor: AdminColors.darkSurface,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showEditPlanDialog(context, ref, plan),
                child: const Text('Modifier'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPlanCard(SubscriptionPlan plan, WidgetRef ref, BuildContext context) {
    return Card(
      color: AdminColors.darkCard,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
                Switch(
                  value: plan.isActive,
                  activeColor: AdminColors.primary,
                  onChanged: (value) => _togglePlanActive(context, ref, plan, value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${plan.monthlyPrice.toStringAsFixed(0)}€/mois', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AdminColors.primary)),
            Text('${plan.yearlyPrice.toStringAsFixed(0)}€/an', style: TextStyle(color: AdminColors.textSecondary)),
            const SizedBox(height: 16),
            Text('${plan.subscriberCount} abonnés', style: TextStyle(color: AdminColors.textSecondary)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 16, color: AdminColors.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: TextStyle(fontSize: 12, color: AdminColors.textSecondary))),
                    ],
                  ),
                )).toList(),
              ),
            ),
            OutlinedButton(
              onPressed: () => _showEditPlanDialog(context, ref, plan),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(AsyncValue<RevenueStats> revenueAsync) {
    return revenueAsync.when(
      data: (stats) => Card(
        color: AdminColors.darkCard,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Évolution du revenu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up, size: 64, color: AdminColors.textMuted),
                      const SizedBox(height: 16),
                      Text('Graphique des revenus', style: TextStyle(color: AdminColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('Données en cours de collecte...', style: TextStyle(color: AdminColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e', style: TextStyle(color: AdminColors.error))),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AdminColors.error),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AdminColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _showCreatePlanDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final monthlyPriceController = TextEditingController();
    final yearlyPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AdminColors.darkCard,
        title: const Text('Nouveau plan', style: TextStyle(color: AdminColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(nameController, 'Nom du plan'),
              const SizedBox(height: 16),
              _buildDialogTextField(monthlyPriceController, 'Prix mensuel (€)', isNumber: true),
              const SizedBox(height: 16),
              _buildDialogTextField(yearlyPriceController, 'Prix annuel (€)', isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(adminActionsProvider.notifier).createPlan(
                name: nameController.text,
                monthlyPrice: double.tryParse(monthlyPriceController.text) ?? 0,
                yearlyPrice: double.tryParse(yearlyPriceController.text) ?? 0,
              );
              ref.invalidate(subscriptionPlansProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan créé avec succès')));
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDetails(BuildContext context, WidgetRef ref, Subscription sub) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AdminColors.darkCard,
        title: Text('Abonnement de ${sub.userName}', style: const TextStyle(color: AdminColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Plan', sub.planName),
            _buildDetailRow('Montant', '${sub.amount}€/${sub.interval.displayName}'),
            _buildDetailRow('Statut', sub.status.displayName),
            _buildDetailRow('Créé le', DateFormat('dd/MM/yyyy').format(sub.createdAt)),
            if (sub.cancelledAt != null)
              _buildDetailRow('Annulé le', DateFormat('dd/MM/yyyy').format(sub.cancelledAt!)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fermer')),
          if (sub.status.name == 'active')
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ref.read(adminActionsProvider.notifier).cancelSubscription(sub.id);
                ref.invalidate(subscriptionsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abonnement annulé')));
                }
              },
              child: const Text('Annuler abonnement'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AdminColors.textSecondary)),
          Text(value, style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _togglePlanActive(BuildContext context, WidgetRef ref, SubscriptionPlan plan, bool active) async {
    await ref.read(adminActionsProvider.notifier).updatePlan(planId: plan.id, isActive: active);
    ref.invalidate(subscriptionPlansProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plan ${active ? 'activé' : 'désactivé'}')));
    }
  }

  void _showEditPlanDialog(BuildContext context, WidgetRef ref, SubscriptionPlan plan) {
    final nameController = TextEditingController(text: plan.name);
    final monthlyPriceController = TextEditingController(text: plan.monthlyPrice.toStringAsFixed(0));
    final yearlyPriceController = TextEditingController(text: plan.yearlyPrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AdminColors.darkCard,
        title: Text('Modifier ${plan.name}', style: const TextStyle(color: AdminColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(nameController, 'Nom du plan'),
              const SizedBox(height: 16),
              _buildDialogTextField(monthlyPriceController, 'Prix mensuel (€)', isNumber: true),
              const SizedBox(height: 16),
              _buildDialogTextField(yearlyPriceController, 'Prix annuel (€)', isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(adminActionsProvider.notifier).updatePlan(
                planId: plan.id,
                name: nameController.text,
                monthlyPrice: double.tryParse(monthlyPriceController.text),
                yearlyPrice: double.tryParse(yearlyPriceController.text),
              );
              ref.invalidate(subscriptionPlansProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan modifié avec succès')));
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AdminColors.textPrimary),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AdminColors.textSecondary),
        filled: true,
        fillColor: AdminColors.darkSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
