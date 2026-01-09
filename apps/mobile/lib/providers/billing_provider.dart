import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

// Current subscription provider - with extra error handling
final subscriptionProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    return await api.getCurrentSubscription();
  } catch (e) {
    // Return default subscription on any error
    return <String, dynamic>{
      'status': 'active',
      'planId': 'free',
      'planName': 'Starter',
      'plan': {'id': 'free', 'name': 'Starter', 'price': 0},
    };
  }
});

// Available plans provider
final plansProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    return await api.getPlans();
  } catch (e) {
    return <Map<String, dynamic>>[];
  }
});

// Token balance provider
final tokenBalanceProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    return await api.getTokenBalance();
  } catch (e) {
    return <String, dynamic>{
      'horsesUsed': 0,
      'horsesLimit': 5,
      'analysesUsed': 0,
      'analysesLimit': 10,
    };
  }
});

// Invoices provider
final invoicesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    return await api.getInvoices();
  } catch (e) {
    return <Map<String, dynamic>>[];
  }
});

// Billing notifier for actions
class BillingNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> upgradePlan(String planId) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiServiceProvider);
      await api.upgradePlan(planId);
      ref.invalidate(subscriptionProvider);
      ref.invalidate(tokenBalanceProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiServiceProvider);
      await api.cancelSubscription();
      ref.invalidate(subscriptionProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reactivateSubscription() async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiServiceProvider);
      await api.reactivateSubscription();
      ref.invalidate(subscriptionProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final billingNotifierProvider = NotifierProvider<BillingNotifier, AsyncValue<void>>(() {
  return BillingNotifier();
});
