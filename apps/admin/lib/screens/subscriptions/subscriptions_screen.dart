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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Abonnements',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau plan'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Revenue stats
              revenueAsync.when(
                data: (stats) => Row(
                  children: [
                    _buildRevenueCard('MRR', stats.mrr, stats.mrrGrowth),
                    const SizedBox(width: 16),
                    _buildRevenueCard('ARR', stats.arr, null),
                    const SizedBox(width: 16),
                    _buildStatCard('LTV', '${stats.ltv.toStringAsFixed(0)}€'),
                    const SizedBox(width: 16),
                    _buildStatCard('Churn', '${stats.churnRate.toStringAsFixed(1)}%'),
                    const SizedBox(width: 16),
                    _buildStatCard('Conversions essai', '${stats.trialConversions}'),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Tabs
              const TabBar(
                tabs: [
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
                    // Subscriptions list
                    _buildSubscriptionsList(subscriptionsAsync, ref),
                    // Plans
                    _buildPlansList(plansAsync, ref),
                    // Revenue chart
                    _buildRevenueChart(revenueAsync),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard(String label, double value, double? growth) {
    return Expanded(
      child: Card(
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
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  if (growth != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: growth >= 0
                            ? AdminColors.success.withOpacity(0.1)
                            : AdminColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: growth >= 0 ? AdminColors.success : AdminColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AdminColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionsList(
    AsyncValue<SubscriptionListResponse> subscriptionsAsync,
    WidgetRef ref,
  ) {
    return subscriptionsAsync.when(
      data: (response) => Card(
        child: ListView.separated(
          itemCount: response.subscriptions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final sub = response.subscriptions[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(sub.status.colorValue).withOpacity(0.1),
                child: Icon(Icons.person, color: Color(sub.status.colorValue)),
              ),
              title: Text(sub.userName),
              subtitle: Text('${sub.planName} • ${sub.amount}€/${sub.interval.displayName}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(sub.status.colorValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sub.status.displayName,
                  style: TextStyle(
                    color: Color(sub.status.colorValue),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () {},
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildPlansList(
    AsyncValue<List<SubscriptionPlan>> plansAsync,
    WidgetRef ref,
  ) {
    return plansAsync.when(
      data: (plans) => GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      Switch(value: plan.isActive, onChanged: (_) {}),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${plan.monthlyPrice.toStringAsFixed(0)}€/mois',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.primary,
                    ),
                  ),
                  Text(
                    '${plan.yearlyPrice.toStringAsFixed(0)}€/an',
                    style: TextStyle(color: AdminColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${plan.subscriberCount} abonnés',
                    style: TextStyle(color: AdminColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: plan.features
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: AdminColors.success,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        f,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AdminColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Modifier'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildRevenueChart(AsyncValue<RevenueStats> revenueAsync) {
    return revenueAsync.when(
      data: (stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Évolution du revenu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Text(
                    'Graphique des revenus',
                    style: TextStyle(color: AdminColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}
