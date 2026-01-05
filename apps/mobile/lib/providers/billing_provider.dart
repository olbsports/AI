import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

// Current subscription provider
final subscriptionProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getCurrentSubscription();
});

// Available plans provider
final plansProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getPlans();
});

// Token balance provider
final tokenBalanceProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getTokenBalance();
});

// Invoices provider
final invoicesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getInvoices();
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
