export 'user.dart';
export 'horse.dart';
export 'rider.dart';
export 'analysis.dart';
export 'report.dart';
export 'leaderboard.dart' hide HorseDiscipline;
export 'breeding.dart';
// Hide Badge classes from social.dart to avoid conflict with gamification.dart
export 'social.dart' hide Badge, BadgeCategory, BadgeRarity;
export 'marketplace.dart';
export 'gamification.dart';
export 'health.dart';
export 'planning.dart';
export 'clubs.dart';
export 'gestation.dart';
export 'services.dart';
export 'user_level.dart';
export 'performance.dart';
export 'tokens.dart';
// Hide conflicting classes from nutrition.dart (already defined in health.dart and planning.dart)
export 'nutrition.dart' hide NutritionPlan, ActivityLevel, NutritionRecommendation, RecommendationType, RecommendationPriority;
// Hide conflicting classes from horse_ai_data.dart (already defined in gestation.dart and planning.dart)
export 'horse_ai_data.dart' hide GestationCheckup, TrainingPlan;
