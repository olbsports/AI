/// Token system models for credit-based AI service consumption

/// Token balance information
class TokenBalance {
  final String id;
  final String organizationId;

  /// Tokens from subscription (reset monthly)
  final int includedBalance;

  /// Tokens from purchases (never expire)
  final int purchasedBalance;

  /// Total available tokens
  int get totalBalance => includedBalance + purchasedBalance;

  /// Subscription period
  final DateTime? includedPeriodStart;
  final DateTime? includedPeriodEnd;
  final int includedMonthlyQuota;

  /// Historical stats
  final int totalConsumed;
  final int totalPurchased;

  final DateTime updatedAt;

  TokenBalance({
    required this.id,
    required this.organizationId,
    required this.includedBalance,
    required this.purchasedBalance,
    this.includedPeriodStart,
    this.includedPeriodEnd,
    this.includedMonthlyQuota = 0,
    this.totalConsumed = 0,
    this.totalPurchased = 0,
    required this.updatedAt,
  });

  factory TokenBalance.fromJson(Map<String, dynamic> json) {
    return TokenBalance(
      id: json['id'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      includedBalance: json['includedBalance'] as int? ?? 0,
      purchasedBalance: json['purchasedBalance'] as int? ?? 0,
      includedPeriodStart: json['includedPeriodStart'] != null
          ? DateTime.parse(json['includedPeriodStart'] as String)
          : null,
      includedPeriodEnd: json['includedPeriodEnd'] != null
          ? DateTime.parse(json['includedPeriodEnd'] as String)
          : null,
      includedMonthlyQuota: json['includedMonthlyQuota'] as int? ?? 0,
      totalConsumed: json['totalConsumed'] as int? ?? 0,
      totalPurchased: json['totalPurchased'] as int? ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'includedBalance': includedBalance,
      'purchasedBalance': purchasedBalance,
      'includedPeriodStart': includedPeriodStart?.toIso8601String(),
      'includedPeriodEnd': includedPeriodEnd?.toIso8601String(),
      'includedMonthlyQuota': includedMonthlyQuota,
      'totalConsumed': totalConsumed,
      'totalPurchased': totalPurchased,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Returns balance status color indicator
  /// Green: > 100 tokens, Orange: 20-100, Red: < 20, Grey: 0
  String get balanceStatus {
    if (totalBalance == 0) return 'empty';
    if (totalBalance < 20) return 'critical';
    if (totalBalance <= 100) return 'low';
    return 'good';
  }
}

/// Token transaction record
class TokenTransaction {
  final String id;
  final String organizationId;
  final String? userId;

  final TransactionType type;
  final TransactionDirection direction;

  final int amount;
  final BalanceType balanceType;
  final int balanceAfter;

  final TransactionSource? source;
  final PurchaseDetails? purchase;

  final TransactionStatus status;
  final String? failureReason;

  final String? description;
  final Map<String, dynamic>? metadata;

  final DateTime createdAt;

  TokenTransaction({
    required this.id,
    required this.organizationId,
    this.userId,
    required this.type,
    required this.direction,
    required this.amount,
    required this.balanceType,
    required this.balanceAfter,
    this.source,
    this.purchase,
    required this.status,
    this.failureReason,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  factory TokenTransaction.fromJson(Map<String, dynamic> json) {
    return TokenTransaction(
      id: json['id'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      userId: json['userId'] as String?,
      type: TransactionType.fromString(json['type'] as String? ?? 'consumption'),
      direction: json['direction'] == 'credit'
          ? TransactionDirection.credit
          : TransactionDirection.debit,
      amount: json['amount'] as int? ?? 0,
      balanceType: json['balanceType'] == 'included'
          ? BalanceType.included
          : BalanceType.purchased,
      balanceAfter: json['balanceAfter'] as int? ?? 0,
      source: json['source'] != null
          ? TransactionSource.fromJson(json['source'] as Map<String, dynamic>)
          : null,
      purchase: json['purchase'] != null
          ? PurchaseDetails.fromJson(json['purchase'] as Map<String, dynamic>)
          : null,
      status: TransactionStatus.fromString(json['status'] as String? ?? 'completed'),
      failureReason: json['failureReason'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'userId': userId,
      'type': type.name,
      'direction': direction.name,
      'amount': amount,
      'balanceType': balanceType.name,
      'balanceAfter': balanceAfter,
      'source': source?.toJson(),
      'purchase': purchase?.toJson(),
      'status': status.name,
      'failureReason': failureReason,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Transaction source information
class TransactionSource {
  final String type;
  final String id;
  final String? name;

  TransactionSource({
    required this.type,
    required this.id,
    this.name,
  });

  factory TransactionSource.fromJson(Map<String, dynamic> json) {
    return TransactionSource(
      type: json['type'] as String? ?? '',
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
    };
  }
}

/// Purchase details for token pack purchases
class PurchaseDetails {
  final String packId;
  final String packName;
  final int baseTokens;
  final int bonusTokens;
  final int amount; // Price in cents
  final String currency;
  final String? stripePaymentIntentId;

  PurchaseDetails({
    required this.packId,
    required this.packName,
    required this.baseTokens,
    required this.bonusTokens,
    required this.amount,
    required this.currency,
    this.stripePaymentIntentId,
  });

  int get totalTokens => baseTokens + bonusTokens;
  double get priceInEuros => amount / 100;

  factory PurchaseDetails.fromJson(Map<String, dynamic> json) {
    return PurchaseDetails(
      packId: json['packId'] as String? ?? '',
      packName: json['packName'] as String? ?? '',
      baseTokens: json['baseTokens'] as int? ?? 0,
      bonusTokens: json['bonusTokens'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
      stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packId': packId,
      'packName': packName,
      'baseTokens': baseTokens,
      'bonusTokens': bonusTokens,
      'amount': amount,
      'currency': currency,
      'stripePaymentIntentId': stripePaymentIntentId,
    };
  }
}

/// Token pack available for purchase
class TokenPack {
  final String id;
  final String name;
  final String description;

  final int baseTokens;
  final int bonusPercent;
  int get totalTokens => baseTokens + (baseTokens * bonusPercent ~/ 100);
  int get bonusTokens => totalTokens - baseTokens;

  final int price; // In cents
  final String currency;
  double get priceInEuros => price / 100;
  double get pricePerToken => price / totalTokens / 100;

  final String? stripePriceId;

  final bool isActive;
  final bool isPopular;
  final int sortOrder;

  final int? minPurchase;
  final int? maxPurchase;
  final int? limitPerMonth;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  TokenPack({
    required this.id,
    required this.name,
    required this.description,
    required this.baseTokens,
    required this.bonusPercent,
    required this.price,
    required this.currency,
    this.stripePriceId,
    this.isActive = true,
    this.isPopular = false,
    this.sortOrder = 0,
    this.minPurchase,
    this.maxPurchase,
    this.limitPerMonth,
    this.createdAt,
    this.updatedAt,
  });

  factory TokenPack.fromJson(Map<String, dynamic> json) {
    return TokenPack(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      baseTokens: json['baseTokens'] as int? ?? 0,
      bonusPercent: json['bonusPercent'] as int? ?? 0,
      price: json['price'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
      stripePriceId: json['stripePriceId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isPopular: json['isPopular'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      minPurchase: json['minPurchase'] as int?,
      maxPurchase: json['maxPurchase'] as int?,
      limitPerMonth: json['limitPerMonth'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'baseTokens': baseTokens,
      'bonusPercent': bonusPercent,
      'price': price,
      'currency': currency,
      'stripePriceId': stripePriceId,
      'isActive': isActive,
      'isPopular': isPopular,
      'sortOrder': sortOrder,
      'minPurchase': minPurchase,
      'maxPurchase': maxPurchase,
      'limitPerMonth': limitPerMonth,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Token usage statistics
class TokenUsageStats {
  final int totalConsumed;
  final int totalPurchased;
  final Map<String, int> byServiceType;
  final List<MonthlyUsage> monthlyUsage;
  final DateTime? lastUpdated;

  TokenUsageStats({
    required this.totalConsumed,
    required this.totalPurchased,
    required this.byServiceType,
    required this.monthlyUsage,
    this.lastUpdated,
  });

  factory TokenUsageStats.fromJson(Map<String, dynamic> json) {
    return TokenUsageStats(
      totalConsumed: json['totalConsumed'] as int? ?? 0,
      totalPurchased: json['totalPurchased'] as int? ?? 0,
      byServiceType: (json['byServiceType'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      monthlyUsage: (json['monthlyUsage'] as List?)
              ?.map((e) => MonthlyUsage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalConsumed': totalConsumed,
      'totalPurchased': totalPurchased,
      'byServiceType': byServiceType,
      'monthlyUsage': monthlyUsage.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
}

/// Monthly token usage data
class MonthlyUsage {
  final int year;
  final int month;
  final int consumed;
  final int purchased;
  final int included;

  MonthlyUsage({
    required this.year,
    required this.month,
    required this.consumed,
    required this.purchased,
    required this.included,
  });

  factory MonthlyUsage.fromJson(Map<String, dynamic> json) {
    return MonthlyUsage(
      year: json['year'] as int? ?? DateTime.now().year,
      month: json['month'] as int? ?? DateTime.now().month,
      consumed: json['consumed'] as int? ?? 0,
      purchased: json['purchased'] as int? ?? 0,
      included: json['included'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'consumed': consumed,
      'purchased': purchased,
      'included': included,
    };
  }
}

/// Service token costs
class ServiceTokenCost {
  final String serviceType;
  final String name;
  final String description;
  final int tokens;
  final String category;

  ServiceTokenCost({
    required this.serviceType,
    required this.name,
    required this.description,
    required this.tokens,
    required this.category,
  });

  factory ServiceTokenCost.fromJson(Map<String, dynamic> json) {
    return ServiceTokenCost(
      serviceType: json['serviceType'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tokens: json['tokens'] as int? ?? 0,
      category: json['category'] as String? ?? '',
    );
  }

  /// Default service costs based on spec
  static List<ServiceTokenCost> get defaultCosts => [
        // Video analyses
        ServiceTokenCost(
          serviceType: 'VIDEO_BASIC',
          name: 'Analyse simple',
          description: '30s max',
          tokens: 50,
          category: 'video',
        ),
        ServiceTokenCost(
          serviceType: 'VIDEO_STANDARD',
          name: 'Analyse complete',
          description: '1-2min',
          tokens: 100,
          category: 'video',
        ),
        ServiceTokenCost(
          serviceType: 'VIDEO_PARCOURS',
          name: 'Analyse parcours CSO',
          description: 'Parcours complet',
          tokens: 150,
          category: 'video',
        ),
        ServiceTokenCost(
          serviceType: 'VIDEO_ADVANCED',
          name: 'Analyse ultra-detaillee',
          description: 'Analyse approfondie',
          tokens: 250,
          category: 'video',
        ),
        ServiceTokenCost(
          serviceType: 'LOCOMOTION',
          name: 'Focus biomecanique',
          description: 'Analyse locomotion',
          tokens: 100,
          category: 'video',
        ),
        // Radio analyses
        ServiceTokenCost(
          serviceType: 'RADIO_SIMPLE',
          name: 'Radio simple',
          description: '1-3 cliches',
          tokens: 150,
          category: 'radio',
        ),
        ServiceTokenCost(
          serviceType: 'RADIO_COMPLETE',
          name: 'Radio complete',
          description: '4-10 cliches',
          tokens: 300,
          category: 'radio',
        ),
        ServiceTokenCost(
          serviceType: 'RADIO_EXPERT',
          name: 'Radio expert',
          description: '+ Validation expert',
          tokens: 500,
          category: 'radio',
        ),
        // Reports
        ServiceTokenCost(
          serviceType: 'HORSE_PROFILE',
          name: 'Fiche cheval PDF',
          description: 'Profil complet',
          tokens: 25,
          category: 'report',
        ),
        ServiceTokenCost(
          serviceType: 'ANALYSIS_REPORT',
          name: 'Rapport analyse',
          description: 'Rapport detaille',
          tokens: 50,
          category: 'report',
        ),
        ServiceTokenCost(
          serviceType: 'HEALTH_REPORT',
          name: 'Historique sante',
          description: 'Rapport sante',
          tokens: 30,
          category: 'report',
        ),
        ServiceTokenCost(
          serviceType: 'PROGRESSION_REPORT',
          name: 'Evolution temps',
          description: 'Rapport progression',
          tokens: 75,
          category: 'report',
        ),
        ServiceTokenCost(
          serviceType: 'SALE_REPORT',
          name: 'Dossier vente complet',
          description: 'Pour vente',
          tokens: 100,
          category: 'report',
        ),
        ServiceTokenCost(
          serviceType: 'BREEDING_REPORT',
          name: 'Pedigree + recommandations',
          description: 'Elevage',
          tokens: 75,
          category: 'report',
        ),
        // Other services
        ServiceTokenCost(
          serviceType: 'EQUICOTE_STANDARD',
          name: 'Valorisation basique',
          description: 'EquiCote standard',
          tokens: 100,
          category: 'valuation',
        ),
        ServiceTokenCost(
          serviceType: 'EQUICOTE_PREMIUM',
          name: 'Valorisation + Certificat',
          description: 'EquiCote premium',
          tokens: 200,
          category: 'valuation',
        ),
        ServiceTokenCost(
          serviceType: 'BREEDING_RECOMMEND',
          name: 'Recommandations etalons',
          description: 'Breeding AI',
          tokens: 200,
          category: 'breeding',
        ),
        ServiceTokenCost(
          serviceType: 'BREEDING_MATCH',
          name: 'Detail match',
          description: 'Match elevage',
          tokens: 50,
          category: 'breeding',
        ),
      ];
}

/// Transaction type enum
enum TransactionType {
  subscriptionCredit,
  purchase,
  consumption,
  refund,
  bonus,
  transfer,
  adjustment,
  expiration;

  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'subscription_credit':
      case 'subscriptioncredit':
        return TransactionType.subscriptionCredit;
      case 'purchase':
        return TransactionType.purchase;
      case 'consumption':
        return TransactionType.consumption;
      case 'refund':
        return TransactionType.refund;
      case 'bonus':
        return TransactionType.bonus;
      case 'transfer':
        return TransactionType.transfer;
      case 'adjustment':
        return TransactionType.adjustment;
      case 'expiration':
        return TransactionType.expiration;
      default:
        return TransactionType.consumption;
    }
  }

  String get displayName {
    switch (this) {
      case TransactionType.subscriptionCredit:
        return 'Credit abonnement';
      case TransactionType.purchase:
        return 'Achat';
      case TransactionType.consumption:
        return 'Utilisation';
      case TransactionType.refund:
        return 'Remboursement';
      case TransactionType.bonus:
        return 'Bonus';
      case TransactionType.transfer:
        return 'Transfert';
      case TransactionType.adjustment:
        return 'Ajustement';
      case TransactionType.expiration:
        return 'Expiration';
    }
  }
}

/// Transaction direction
enum TransactionDirection {
  credit,
  debit;
}

/// Balance type (included from subscription or purchased)
enum BalanceType {
  included,
  purchased;
}

/// Transaction status
enum TransactionStatus {
  pending,
  completed,
  failed,
  refunded;

  static TransactionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'refunded':
        return TransactionStatus.refunded;
      default:
        return TransactionStatus.completed;
    }
  }
}

/// Purchase intent result from Stripe
class TokenPurchaseIntent {
  final String clientSecret;
  final String paymentIntentId;
  final String packId;
  final int amount;
  final String currency;

  TokenPurchaseIntent({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.packId,
    required this.amount,
    required this.currency,
  });

  factory TokenPurchaseIntent.fromJson(Map<String, dynamic> json) {
    return TokenPurchaseIntent(
      clientSecret: json['clientSecret'] as String? ?? '',
      paymentIntentId: json['paymentIntentId'] as String? ?? '',
      packId: json['packId'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
    );
  }
}
