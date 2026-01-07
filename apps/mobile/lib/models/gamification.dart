/// Complete Gamification System for Horse Tempo

// ============================================
// XP & LEVELS
// ============================================

/// User level based on XP
class UserLevel {
  final int level;
  final String title;
  final int currentXp;
  final int xpForNextLevel;
  final int totalXp;
  final List<String> unlockedFeatures;

  UserLevel({
    required this.level,
    required this.title,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.totalXp,
    this.unlockedFeatures = const [],
  });

  double get progressToNextLevel =>
      xpForNextLevel > 0 ? currentXp / xpForNextLevel : 1.0;

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      level: (json['level'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? 'Débutant',
      currentXp: (json['currentXp'] as num?)?.toInt() ?? 0,
      xpForNextLevel: (json['xpForNextLevel'] as num?)?.toInt() ?? 100,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      unlockedFeatures: (json['unlockedFeatures'] as List?)?.map((e) => e as String? ?? '').toList() ?? [],
    );
  }

  /// Level titles in French
  static String getTitleForLevel(int level) {
    if (level < 5) return 'Débutant';
    if (level < 10) return 'Apprenti';
    if (level < 20) return 'Cavalier';
    if (level < 35) return 'Confirmé';
    if (level < 50) return 'Expert';
    if (level < 75) return 'Maître';
    if (level < 100) return 'Champion';
    return 'Légende';
  }

  /// XP required for each level (exponential curve)
  static int xpRequiredForLevel(int level) {
    return (100 * level * (1 + level * 0.1)).toInt();
  }
}

/// XP transaction/event
class XpTransaction {
  final String id;
  final String userId;
  final int amount;
  final XpSource source;
  final String? sourceId;
  final String description;
  final DateTime createdAt;

  XpTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.source,
    this.sourceId,
    required this.description,
    required this.createdAt,
  });

  factory XpTransaction.fromJson(Map<String, dynamic> json) {
    return XpTransaction(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      source: XpSource.fromString(json['source'] as String? ?? 'achievement'),
      sourceId: json['sourceId'] as String?,
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Sources of XP
enum XpSource {
  analysis,        // +50 XP per analysis
  dailyLogin,      // +10 XP
  streak,          // +5 XP per day of streak
  challengeComplete, // +100-500 XP
  badgeEarned,     // +25-200 XP
  horseAdded,      // +20 XP
  reportGenerated, // +30 XP
  socialShare,     // +15 XP
  referral,        // +100 XP
  competition,     // +50-500 XP
  levelUp,         // Bonus XP
  achievement;     // Variable

  static XpSource fromString(String value) {
    return XpSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => XpSource.achievement,
    );
  }

  int get defaultXp {
    switch (this) {
      case XpSource.analysis: return 50;
      case XpSource.dailyLogin: return 10;
      case XpSource.streak: return 5;
      case XpSource.challengeComplete: return 100;
      case XpSource.badgeEarned: return 50;
      case XpSource.horseAdded: return 20;
      case XpSource.reportGenerated: return 30;
      case XpSource.socialShare: return 15;
      case XpSource.referral: return 100;
      case XpSource.competition: return 50;
      case XpSource.levelUp: return 0;
      case XpSource.achievement: return 25;
    }
  }
}

// ============================================
// BADGES & ACHIEVEMENTS
// ============================================

/// Badge definition
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final BadgeRequirement requirement;
  final int xpReward;
  final bool isSecret;
  final DateTime? earnedAt;
  final double? progress; // 0-1 for progress towards badge

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    this.rarity = BadgeRarity.common,
    required this.requirement,
    this.xpReward = 50,
    this.isSecret = false,
    this.earnedAt,
    this.progress,
  });

  bool get isEarned => earnedAt != null;

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
      category: BadgeCategory.fromString(json['category'] as String? ?? 'general'),
      rarity: BadgeRarity.fromString(json['rarity'] as String? ?? 'common'),
      requirement: json['requirement'] != null
          ? BadgeRequirement.fromJson(json['requirement'] as Map<String, dynamic>)
          : BadgeRequirement(type: BadgeRequirementType.specificAction, targetValue: 1),
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 50,
      isSecret: json['isSecret'] as bool? ?? false,
      earnedAt: json['earnedAt'] != null
          ? DateTime.tryParse(json['earnedAt'] as String)
          : null,
      progress: (json['progress'] as num?)?.toDouble(),
    );
  }
}

/// Badge categories
enum BadgeCategory {
  analysis,    // Analyses milestones
  training,    // Training achievements
  social,      // Community engagement
  competition, // Competition results
  streak,      // Consistency badges
  collection,  // Horse collection
  breeding,    // Breeding achievements
  health,      // Health tracking
  general;     // General achievements

  String get displayName {
    switch (this) {
      case BadgeCategory.analysis: return 'Analyses';
      case BadgeCategory.training: return 'Entraînement';
      case BadgeCategory.social: return 'Communauté';
      case BadgeCategory.competition: return 'Compétition';
      case BadgeCategory.streak: return 'Régularité';
      case BadgeCategory.collection: return 'Collection';
      case BadgeCategory.breeding: return 'Élevage';
      case BadgeCategory.health: return 'Santé';
      case BadgeCategory.general: return 'Général';
    }
  }

  static BadgeCategory fromString(String value) {
    return BadgeCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BadgeCategory.general,
    );
  }
}

/// Badge rarity
enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  String get displayName {
    switch (this) {
      case BadgeRarity.common: return 'Commun';
      case BadgeRarity.uncommon: return 'Peu commun';
      case BadgeRarity.rare: return 'Rare';
      case BadgeRarity.epic: return 'Épique';
      case BadgeRarity.legendary: return 'Légendaire';
    }
  }

  int get color {
    switch (this) {
      case BadgeRarity.common: return 0xFF9E9E9E;
      case BadgeRarity.uncommon: return 0xFF4CAF50;
      case BadgeRarity.rare: return 0xFF2196F3;
      case BadgeRarity.epic: return 0xFF9C27B0;
      case BadgeRarity.legendary: return 0xFFFF9800;
    }
  }

  static BadgeRarity fromString(String value) {
    return BadgeRarity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BadgeRarity.common,
    );
  }
}

/// Requirement to earn a badge
class BadgeRequirement {
  final BadgeRequirementType type;
  final int targetValue;
  final String? targetId; // For specific horse/discipline
  final Map<String, dynamic>? conditions;

  BadgeRequirement({
    required this.type,
    required this.targetValue,
    this.targetId,
    this.conditions,
  });

  factory BadgeRequirement.fromJson(Map<String, dynamic> json) {
    return BadgeRequirement(
      type: BadgeRequirementType.fromString(json['type'] as String? ?? 'specificAction'),
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 1,
      targetId: json['targetId'] as String?,
      conditions: json['conditions'] as Map<String, dynamic>?,
    );
  }
}

enum BadgeRequirementType {
  analysisCount,      // Complete X analyses
  streakDays,         // X consecutive days
  horseCount,         // Own X horses
  competitionWins,    // Win X competitions
  totalXp,            // Reach X total XP
  level,              // Reach level X
  shareCount,         // Share X times
  referralCount,      // Refer X users
  challengeCount,     // Complete X challenges
  healthRecordCount,  // Log X health records
  breedingCount,      // X successful breedings
  specificAction;     // Custom action

  static BadgeRequirementType fromString(String value) {
    return BadgeRequirementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BadgeRequirementType.specificAction,
    );
  }
}

// ============================================
// CHALLENGES
// ============================================

/// Weekly/Daily challenge
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final int targetValue;
  final int currentValue;
  final int xpReward;
  final int? tokenReward;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final bool isExpired;
  final String? iconUrl;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.difficulty = ChallengeDifficulty.medium,
    required this.targetValue,
    this.currentValue = 0,
    required this.xpReward,
    this.tokenReward,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    this.isExpired = false,
    this.iconUrl,
  });

  double get progress => targetValue > 0 ? currentValue / targetValue : 0;
  bool get isActive => !isCompleted && !isExpired && DateTime.now().isBefore(endDate);
  Duration get timeRemaining => endDate.difference(DateTime.now());

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: ChallengeType.fromString(json['type'] as String? ?? 'daily'),
      difficulty: ChallengeDifficulty.fromString(json['difficulty'] as String? ?? 'medium'),
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 1,
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      tokenReward: (json['tokenReward'] as num?)?.toInt(),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now() : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) ?? DateTime.now().add(Duration(days: 1)) : DateTime.now().add(Duration(days: 1)),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isExpired: json['isExpired'] as bool? ?? false,
      iconUrl: json['iconUrl'] as String?,
    );
  }
}

enum ChallengeType {
  daily,
  weekly,
  monthly,
  special,
  seasonal;

  String get displayName {
    switch (this) {
      case ChallengeType.daily: return 'Quotidien';
      case ChallengeType.weekly: return 'Hebdomadaire';
      case ChallengeType.monthly: return 'Mensuel';
      case ChallengeType.special: return 'Spécial';
      case ChallengeType.seasonal: return 'Saisonnier';
    }
  }

  static ChallengeType fromString(String value) {
    return ChallengeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChallengeType.daily,
    );
  }
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  extreme;

  String get displayName {
    switch (this) {
      case ChallengeDifficulty.easy: return 'Facile';
      case ChallengeDifficulty.medium: return 'Moyen';
      case ChallengeDifficulty.hard: return 'Difficile';
      case ChallengeDifficulty.extreme: return 'Extrême';
    }
  }

  int get xpMultiplier {
    switch (this) {
      case ChallengeDifficulty.easy: return 1;
      case ChallengeDifficulty.medium: return 2;
      case ChallengeDifficulty.hard: return 3;
      case ChallengeDifficulty.extreme: return 5;
    }
  }

  static ChallengeDifficulty fromString(String value) {
    return ChallengeDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChallengeDifficulty.medium,
    );
  }
}

// ============================================
// STREAKS
// ============================================

/// User streak tracking
class UserStreak {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final List<DateTime> activityDates; // Last 30 days
  final bool isActiveToday;

  UserStreak({
    required this.id,
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.activityDates = const [],
    this.isActiveToday = false,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.tryParse(json['lastActivityDate'] as String)
          : null,
      activityDates: (json['activityDates'] as List?)
          ?.map((d) => DateTime.tryParse(d as String))
          .where((d) => d != null)
          .cast<DateTime>()
          .toList() ?? [],
      isActiveToday: json['isActiveToday'] as bool? ?? false,
    );
  }
}

// ============================================
// REWARDS & UNLOCKABLES
// ============================================

/// Reward that can be earned
class Reward {
  final String id;
  final String name;
  final String description;
  final RewardType type;
  final int value;
  final String? iconUrl;
  final DateTime? claimedAt;
  final DateTime? expiresAt;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.iconUrl,
    this.claimedAt,
    this.expiresAt,
  });

  bool get isClaimed => claimedAt != null;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: RewardType.fromString(json['type'] as String? ?? 'xp'),
      value: (json['value'] as num?)?.toInt() ?? 0,
      iconUrl: json['iconUrl'] as String?,
      claimedAt: json['claimedAt'] != null
          ? DateTime.tryParse(json['claimedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }
}

enum RewardType {
  tokens,           // Analysis tokens
  xp,               // Bonus XP
  premiumDays,      // Free premium days
  discount,         // Discount percentage
  featureUnlock,    // Unlock a feature
  customization,    // Profile customization
  badge;            // Special badge

  String get displayName {
    switch (this) {
      case RewardType.tokens: return 'Tokens';
      case RewardType.xp: return 'XP Bonus';
      case RewardType.premiumDays: return 'Jours Premium';
      case RewardType.discount: return 'Réduction';
      case RewardType.featureUnlock: return 'Fonctionnalité';
      case RewardType.customization: return 'Personnalisation';
      case RewardType.badge: return 'Badge';
    }
  }

  static RewardType fromString(String value) {
    return RewardType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RewardType.xp,
    );
  }
}

// ============================================
// REFERRAL/SPONSORSHIP
// ============================================

/// Referral/sponsorship program
class Referral {
  final String id;
  final String referrerId;
  final String referrerName;
  final String refereeId;
  final String refereeName;
  final String referralCode;
  final ReferralStatus status;
  final int referrerReward;
  final int refereeReward;
  final DateTime createdAt;
  final DateTime? completedAt;

  Referral({
    required this.id,
    required this.referrerId,
    required this.referrerName,
    required this.refereeId,
    required this.refereeName,
    required this.referralCode,
    this.status = ReferralStatus.pending,
    this.referrerReward = 100,
    this.refereeReward = 50,
    required this.createdAt,
    this.completedAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as String? ?? '',
      referrerId: json['referrerId'] as String? ?? '',
      referrerName: json['referrerName'] as String? ?? '',
      refereeId: json['refereeId'] as String? ?? '',
      refereeName: json['refereeName'] as String? ?? '',
      referralCode: json['referralCode'] as String? ?? '',
      status: ReferralStatus.fromString(json['status'] as String? ?? 'pending'),
      referrerReward: (json['referrerReward'] as num?)?.toInt() ?? 100,
      refereeReward: (json['refereeReward'] as num?)?.toInt() ?? 50,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}

enum ReferralStatus {
  pending,    // Invited but not registered
  registered, // Registered but not active
  active,     // Active user, rewards given
  expired;    // Link expired

  static ReferralStatus fromString(String value) {
    return ReferralStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReferralStatus.pending,
    );
  }
}

/// User's referral stats
class ReferralStats {
  final String userId;
  final String referralCode;
  final String referralLink;
  final int totalReferrals;
  final int pendingReferrals;
  final int activeReferrals;
  final int totalTokensEarned;
  final List<Referral> recentReferrals;

  ReferralStats({
    required this.userId,
    required this.referralCode,
    required this.referralLink,
    this.totalReferrals = 0,
    this.pendingReferrals = 0,
    this.activeReferrals = 0,
    this.totalTokensEarned = 0,
    this.recentReferrals = const [],
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      userId: json['userId'] as String? ?? '',
      referralCode: json['referralCode'] as String? ?? '',
      referralLink: json['referralLink'] as String? ?? '',
      totalReferrals: (json['totalReferrals'] as num?)?.toInt() ?? 0,
      pendingReferrals: (json['pendingReferrals'] as num?)?.toInt() ?? 0,
      activeReferrals: (json['activeReferrals'] as num?)?.toInt() ?? 0,
      totalTokensEarned: (json['totalTokensEarned'] as num?)?.toInt() ?? 0,
      recentReferrals: (json['recentReferrals'] as List?)
          ?.map((r) => Referral.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

// ============================================
// PREDEFINED BADGES
// ============================================

/// All available badges in the system
class PredefinedBadges {
  static final List<Badge> all = [
    // Analysis badges
    Badge(
      id: 'first_analysis',
      name: 'Première Analyse',
      description: 'Réalisez votre première analyse vidéo',
      iconUrl: '🎬',
      category: BadgeCategory.analysis,
      rarity: BadgeRarity.common,
      requirement: BadgeRequirement(type: BadgeRequirementType.analysisCount, targetValue: 1),
      xpReward: 25,
    ),
    Badge(
      id: 'analyst_10',
      name: 'Analyste Débutant',
      description: 'Réalisez 10 analyses',
      iconUrl: '📊',
      category: BadgeCategory.analysis,
      rarity: BadgeRarity.common,
      requirement: BadgeRequirement(type: BadgeRequirementType.analysisCount, targetValue: 10),
      xpReward: 50,
    ),
    Badge(
      id: 'analyst_50',
      name: 'Analyste Confirmé',
      description: 'Réalisez 50 analyses',
      iconUrl: '📈',
      category: BadgeCategory.analysis,
      rarity: BadgeRarity.uncommon,
      requirement: BadgeRequirement(type: BadgeRequirementType.analysisCount, targetValue: 50),
      xpReward: 100,
    ),
    Badge(
      id: 'analyst_100',
      name: 'Expert en Analyse',
      description: 'Réalisez 100 analyses',
      iconUrl: '🏆',
      category: BadgeCategory.analysis,
      rarity: BadgeRarity.rare,
      requirement: BadgeRequirement(type: BadgeRequirementType.analysisCount, targetValue: 100),
      xpReward: 200,
    ),
    Badge(
      id: 'analyst_500',
      name: 'Maître Analyste',
      description: 'Réalisez 500 analyses',
      iconUrl: '👑',
      category: BadgeCategory.analysis,
      rarity: BadgeRarity.legendary,
      requirement: BadgeRequirement(type: BadgeRequirementType.analysisCount, targetValue: 500),
      xpReward: 500,
    ),

    // Streak badges
    Badge(
      id: 'streak_7',
      name: 'Semaine Parfaite',
      description: '7 jours consécutifs d\'activité',
      iconUrl: '🔥',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.common,
      requirement: BadgeRequirement(type: BadgeRequirementType.streakDays, targetValue: 7),
      xpReward: 50,
    ),
    Badge(
      id: 'streak_30',
      name: 'Mois d\'Or',
      description: '30 jours consécutifs d\'activité',
      iconUrl: '⚡',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.rare,
      requirement: BadgeRequirement(type: BadgeRequirementType.streakDays, targetValue: 30),
      xpReward: 200,
    ),
    Badge(
      id: 'streak_100',
      name: 'Légende de la Régularité',
      description: '100 jours consécutifs d\'activité',
      iconUrl: '💎',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.legendary,
      requirement: BadgeRequirement(type: BadgeRequirementType.streakDays, targetValue: 100),
      xpReward: 500,
    ),

    // Horse collection badges
    Badge(
      id: 'first_horse',
      name: 'Premier Compagnon',
      description: 'Ajoutez votre premier cheval',
      iconUrl: '🐴',
      category: BadgeCategory.collection,
      rarity: BadgeRarity.common,
      requirement: BadgeRequirement(type: BadgeRequirementType.horseCount, targetValue: 1),
      xpReward: 20,
    ),
    Badge(
      id: 'stable_5',
      name: 'Petite Écurie',
      description: 'Gérez 5 chevaux',
      iconUrl: '🏠',
      category: BadgeCategory.collection,
      rarity: BadgeRarity.uncommon,
      requirement: BadgeRequirement(type: BadgeRequirementType.horseCount, targetValue: 5),
      xpReward: 75,
    ),
    Badge(
      id: 'stable_10',
      name: 'Grande Écurie',
      description: 'Gérez 10 chevaux',
      iconUrl: '🏰',
      category: BadgeCategory.collection,
      rarity: BadgeRarity.rare,
      requirement: BadgeRequirement(type: BadgeRequirementType.horseCount, targetValue: 10),
      xpReward: 150,
    ),

    // Social badges
    Badge(
      id: 'social_first_share',
      name: 'Premier Partage',
      description: 'Partagez une analyse sur les réseaux',
      iconUrl: '📤',
      category: BadgeCategory.social,
      rarity: BadgeRarity.common,
      requirement: BadgeRequirement(type: BadgeRequirementType.shareCount, targetValue: 1),
      xpReward: 25,
    ),
    Badge(
      id: 'social_influencer',
      name: 'Influenceur Équestre',
      description: 'Partagez 50 contenus',
      iconUrl: '⭐',
      category: BadgeCategory.social,
      rarity: BadgeRarity.rare,
      requirement: BadgeRequirement(type: BadgeRequirementType.shareCount, targetValue: 50),
      xpReward: 200,
    ),
    Badge(
      id: 'referral_1',
      name: 'Ambassadeur',
      description: 'Parrainez votre premier ami',
      iconUrl: '🤝',
      category: BadgeCategory.social,
      rarity: BadgeRarity.uncommon,
      requirement: BadgeRequirement(type: BadgeRequirementType.referralCount, targetValue: 1),
      xpReward: 100,
    ),
    Badge(
      id: 'referral_10',
      name: 'Super Ambassadeur',
      description: 'Parrainez 10 amis',
      iconUrl: '🌟',
      category: BadgeCategory.social,
      rarity: BadgeRarity.epic,
      requirement: BadgeRequirement(type: BadgeRequirementType.referralCount, targetValue: 10),
      xpReward: 300,
    ),

    // Level badges
    Badge(
      id: 'level_10',
      name: 'Cavalier Niveau 10',
      description: 'Atteignez le niveau 10',
      iconUrl: '🎖️',
      category: BadgeCategory.general,
      rarity: BadgeRarity.uncommon,
      requirement: BadgeRequirement(type: BadgeRequirementType.level, targetValue: 10),
      xpReward: 100,
    ),
    Badge(
      id: 'level_25',
      name: 'Cavalier Niveau 25',
      description: 'Atteignez le niveau 25',
      iconUrl: '🏅',
      category: BadgeCategory.general,
      rarity: BadgeRarity.rare,
      requirement: BadgeRequirement(type: BadgeRequirementType.level, targetValue: 25),
      xpReward: 250,
    ),
    Badge(
      id: 'level_50',
      name: 'Cavalier Niveau 50',
      description: 'Atteignez le niveau 50',
      iconUrl: '🥇',
      category: BadgeCategory.general,
      rarity: BadgeRarity.epic,
      requirement: BadgeRequirement(type: BadgeRequirementType.level, targetValue: 50),
      xpReward: 500,
    ),

    // Health badges
    Badge(
      id: 'health_first',
      name: 'Carnet Santé',
      description: 'Créez votre premier suivi santé',
      iconUrl: '💉',
      category: BadgeCategory.health,
      rarity: BadgeRarity.common,
      requirement: BadgeRequirement(type: BadgeRequirementType.healthRecordCount, targetValue: 1),
      xpReward: 25,
    ),
    Badge(
      id: 'health_tracker',
      name: 'Vétérinaire en Herbe',
      description: '50 entrées dans le carnet santé',
      iconUrl: '🩺',
      category: BadgeCategory.health,
      rarity: BadgeRarity.rare,
      requirement: BadgeRequirement(type: BadgeRequirementType.healthRecordCount, targetValue: 50),
      xpReward: 150,
    ),

    // Breeding badges
    Badge(
      id: 'breeder_first',
      name: 'Premier Poulain',
      description: 'Enregistrez votre première naissance',
      iconUrl: '🐎',
      category: BadgeCategory.breeding,
      rarity: BadgeRarity.uncommon,
      requirement: BadgeRequirement(type: BadgeRequirementType.breedingCount, targetValue: 1),
      xpReward: 100,
    ),
    Badge(
      id: 'breeder_pro',
      name: 'Éleveur Pro',
      description: '10 naissances enregistrées',
      iconUrl: '🎠',
      category: BadgeCategory.breeding,
      rarity: BadgeRarity.epic,
      requirement: BadgeRequirement(type: BadgeRequirementType.breedingCount, targetValue: 10),
      xpReward: 300,
    ),
  ];
}

// ============================================
// PREDEFINED CHALLENGES
// ============================================

/// Challenge templates
class ChallengeTemplates {
  static List<Map<String, dynamic>> dailyChallenges = [
    {
      'title': 'Analyse du Jour',
      'description': 'Réalisez 1 analyse vidéo aujourd\'hui',
      'targetValue': 1,
      'xpReward': 30,
      'difficulty': 'easy',
    },
    {
      'title': 'Connexion Quotidienne',
      'description': 'Connectez-vous et consultez votre tableau de bord',
      'targetValue': 1,
      'xpReward': 10,
      'difficulty': 'easy',
    },
    {
      'title': 'Mise à Jour Santé',
      'description': 'Ajoutez une entrée au carnet santé',
      'targetValue': 1,
      'xpReward': 20,
      'difficulty': 'easy',
    },
  ];

  static List<Map<String, dynamic>> weeklyChallenges = [
    {
      'title': 'Semaine d\'Analyse',
      'description': 'Réalisez 5 analyses cette semaine',
      'targetValue': 5,
      'xpReward': 150,
      'difficulty': 'medium',
    },
    {
      'title': 'Série Hebdo',
      'description': 'Connectez-vous 7 jours consécutifs',
      'targetValue': 7,
      'xpReward': 100,
      'difficulty': 'medium',
    },
    {
      'title': 'Social Butterfly',
      'description': 'Partagez 3 analyses sur les réseaux',
      'targetValue': 3,
      'xpReward': 75,
      'difficulty': 'easy',
    },
    {
      'title': 'Explorateur',
      'description': 'Analysez 3 chevaux différents',
      'targetValue': 3,
      'xpReward': 100,
      'difficulty': 'medium',
    },
  ];

  static List<Map<String, dynamic>> monthlyChallenges = [
    {
      'title': 'Champion du Mois',
      'description': 'Réalisez 20 analyses ce mois',
      'targetValue': 20,
      'xpReward': 500,
      'difficulty': 'hard',
    },
    {
      'title': 'Régularité Mensuelle',
      'description': '25 jours d\'activité ce mois',
      'targetValue': 25,
      'xpReward': 400,
      'difficulty': 'hard',
    },
    {
      'title': 'Parrain du Mois',
      'description': 'Parrainez 3 nouveaux utilisateurs',
      'targetValue': 3,
      'xpReward': 300,
      'difficulty': 'hard',
    },
  ];
}
