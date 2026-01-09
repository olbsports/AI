import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tokens.dart';
import '../services/api_service.dart';

/// Token balance provider
final tokenBalanceDataProvider = FutureProvider.autoDispose<TokenBalance>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final result = await api.get('/tokens/balance');
    debugPrint('TOKENS: getBalance returned type: ${result.runtimeType}');

    if (result is Map<String, dynamic>) {
      return TokenBalance.fromJson(result);
    }

    // Return default balance on invalid response
    return TokenBalance(
      id: '',
      organizationId: '',
      includedBalance: 50,
      purchasedBalance: 0,
      includedMonthlyQuota: 50,
      updatedAt: DateTime.now(),
    );
  } catch (e, st) {
    debugPrint('TOKENS: tokenBalanceDataProvider error: $e');
    debugPrint('TOKENS: stack trace: $st');
    // Return default balance on error
    return TokenBalance(
      id: '',
      organizationId: '',
      includedBalance: 50,
      purchasedBalance: 0,
      includedMonthlyQuota: 50,
      updatedAt: DateTime.now(),
    );
  }
});

/// Token packs provider
final tokenPacksProvider = FutureProvider.autoDispose<List<TokenPack>>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final result = await api.get('/tokens/packs');
    debugPrint('TOKENS: getPacks returned type: ${result.runtimeType}');

    if (result is List) {
      return result.map((e) => TokenPack.fromJson(e as Map<String, dynamic>)).toList();
    }

    // Return default packs if API fails
    return _defaultTokenPacks;
  } catch (e, st) {
    debugPrint('TOKENS: tokenPacksProvider error: $e');
    debugPrint('TOKENS: stack trace: $st');
    // Return default packs on error
    return _defaultTokenPacks;
  }
});

/// Token transactions provider with pagination
final tokenTransactionsProvider = FutureProvider.autoDispose
    .family<List<TokenTransaction>, TokenTransactionFilter>((ref, filter) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final queryParams = <String, String>{
      'page': filter.page.toString(),
      'pageSize': filter.pageSize.toString(),
    };

    if (filter.type != null) {
      queryParams['type'] = filter.type!.name;
    }
    if (filter.direction != null) {
      queryParams['direction'] = filter.direction!.name;
    }
    if (filter.startDate != null) {
      queryParams['startDate'] = filter.startDate!.toIso8601String();
    }
    if (filter.endDate != null) {
      queryParams['endDate'] = filter.endDate!.toIso8601String();
    }

    final result = await api.get('/tokens/transactions', queryParams: queryParams);
    debugPrint('TOKENS: getTransactions returned type: ${result.runtimeType}');

    if (result is Map<String, dynamic> && result['items'] is List) {
      return (result['items'] as List)
          .map((e) => TokenTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (result is List) {
      return result.map((e) => TokenTransaction.fromJson(e as Map<String, dynamic>)).toList();
    }

    return <TokenTransaction>[];
  } catch (e, st) {
    debugPrint('TOKENS: tokenTransactionsProvider error: $e');
    debugPrint('TOKENS: stack trace: $st');
    return <TokenTransaction>[];
  }
});

/// Token usage statistics provider
final tokenUsageStatsProvider = FutureProvider.autoDispose<TokenUsageStats>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final result = await api.get('/tokens/usage');
    debugPrint('TOKENS: getUsage returned type: ${result.runtimeType}');

    if (result is Map<String, dynamic>) {
      return TokenUsageStats.fromJson(result);
    }

    // Return empty stats on invalid response
    return TokenUsageStats(
      totalConsumed: 0,
      totalPurchased: 0,
      byServiceType: {},
      monthlyUsage: [],
    );
  } catch (e, st) {
    debugPrint('TOKENS: tokenUsageStatsProvider error: $e');
    debugPrint('TOKENS: stack trace: $st');
    return TokenUsageStats(
      totalConsumed: 0,
      totalPurchased: 0,
      byServiceType: {},
      monthlyUsage: [],
    );
  }
});

/// Service token costs provider
final serviceTokenCostsProvider = FutureProvider.autoDispose<List<ServiceTokenCost>>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final result = await api.get('/tokens/costs');
    debugPrint('TOKENS: getCosts returned type: ${result.runtimeType}');

    if (result is List) {
      return result.map((e) => ServiceTokenCost.fromJson(e as Map<String, dynamic>)).toList();
    }

    // Return default costs if API fails
    return ServiceTokenCost.defaultCosts;
  } catch (e, st) {
    debugPrint('TOKENS: serviceTokenCostsProvider error: $e');
    debugPrint('TOKENS: stack trace: $st');
    return ServiceTokenCost.defaultCosts;
  }
});

/// Token notifier for actions (purchase, check balance, etc.)
class TokensNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Check if balance is sufficient for a service
  Future<bool> checkBalance(String serviceType, int requiredTokens) async {
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.post('/tokens/check', {
        'serviceType': serviceType,
        'amount': requiredTokens,
      });

      if (result is Map<String, dynamic>) {
        return result['sufficient'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('TOKENS: checkBalance error: $e');
      return false;
    }
  }

  /// Get cost estimate for a service
  Future<int> estimateCost(String serviceType) async {
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.get('/tokens/estimate/$serviceType');

      if (result is Map<String, dynamic>) {
        return result['tokens'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('TOKENS: estimateCost error: $e');
      // Return default cost from static list
      final defaultCost = ServiceTokenCost.defaultCosts
          .where((c) => c.serviceType == serviceType)
          .firstOrNull;
      return defaultCost?.tokens ?? 0;
    }
  }

  /// Initiate token purchase with Stripe
  Future<TokenPurchaseIntent?> initiatePurchase(String packId) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.post('/tokens/purchase', {
        'packId': packId,
      });

      if (result is Map<String, dynamic>) {
        state = const AsyncValue.data(null);
        return TokenPurchaseIntent.fromJson(result);
      }
      state = AsyncValue.error('Invalid response', StackTrace.current);
      return null;
    } catch (e, st) {
      debugPrint('TOKENS: initiatePurchase error: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Confirm payment after Stripe success
  Future<bool> confirmPurchase(String paymentIntentId) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/tokens/purchase/confirm', {
        'paymentIntentId': paymentIntentId,
      });

      // Refresh balance and transactions
      ref.invalidate(tokenBalanceDataProvider);
      ref.invalidate(tokenTransactionsProvider);
      ref.invalidate(tokenUsageStatsProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('TOKENS: confirmPurchase error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Refresh all token data
  void refreshAll() {
    ref.invalidate(tokenBalanceDataProvider);
    ref.invalidate(tokenPacksProvider);
    ref.invalidate(tokenTransactionsProvider);
    ref.invalidate(tokenUsageStatsProvider);
  }
}

final tokensNotifierProvider = NotifierProvider<TokensNotifier, AsyncValue<void>>(() {
  return TokensNotifier();
});

/// Transaction filter for history queries
class TokenTransactionFilter {
  final int page;
  final int pageSize;
  final TransactionType? type;
  final TransactionDirection? direction;
  final DateTime? startDate;
  final DateTime? endDate;

  const TokenTransactionFilter({
    this.page = 1,
    this.pageSize = 20,
    this.type,
    this.direction,
    this.startDate,
    this.endDate,
  });

  TokenTransactionFilter copyWith({
    int? page,
    int? pageSize,
    TransactionType? type,
    TransactionDirection? direction,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TokenTransactionFilter(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TokenTransactionFilter &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.type == type &&
        other.direction == direction &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return Object.hash(page, pageSize, type, direction, startDate, endDate);
  }
}

/// Current transaction filter state
final tokenTransactionFilterProvider = StateProvider<TokenTransactionFilter>((ref) {
  return const TokenTransactionFilter();
});

/// Default token packs based on spec
final List<TokenPack> _defaultTokenPacks = [
  TokenPack(
    id: 'starter',
    name: 'Starter',
    description: 'Pour commencer',
    baseTokens: 100,
    bonusPercent: 0,
    price: 999, // 9.99 EUR
    currency: 'EUR',
    isActive: true,
    isPopular: false,
    sortOrder: 1,
  ),
  TokenPack(
    id: 'standard',
    name: 'Standard',
    description: 'Le plus populaire',
    baseTokens: 300,
    bonusPercent: 10,
    price: 2499, // 24.99 EUR
    currency: 'EUR',
    isActive: true,
    isPopular: true,
    sortOrder: 2,
  ),
  TokenPack(
    id: 'pro',
    name: 'Pro',
    description: 'Meilleur rapport qualite/prix',
    baseTokens: 600,
    bonusPercent: 20,
    price: 4499, // 44.99 EUR
    currency: 'EUR',
    isActive: true,
    isPopular: false,
    sortOrder: 3,
  ),
  TokenPack(
    id: 'business',
    name: 'Business',
    description: 'Pour les professionnels',
    baseTokens: 1500,
    bonusPercent: 30,
    price: 9999, // 99.99 EUR
    currency: 'EUR',
    isActive: true,
    isPopular: false,
    sortOrder: 4,
  ),
  TokenPack(
    id: 'enterprise',
    name: 'Enterprise',
    description: 'Pour les grandes structures',
    baseTokens: 5000,
    bonusPercent: 40,
    price: 29999, // 299.99 EUR
    currency: 'EUR',
    isActive: true,
    isPopular: false,
    sortOrder: 5,
  ),
];
