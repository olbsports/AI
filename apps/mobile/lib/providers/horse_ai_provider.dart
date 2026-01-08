import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/horse_ai_data.dart';
import '../services/api_service.dart';

/// Provider pour récupérer les données IA d'un cheval spécifique
final horseAIDataProvider = FutureProvider.autoDispose
    .family<HorseAIData, String>((ref, horseId) async {
  final notifier = ref.watch(horseAINotifierProvider.notifier);
  return notifier.getHorseAIData(horseId);
});

/// Provider pour toutes les données IA des chevaux (cache)
final allHorseAIDataProvider =
    StateNotifierProvider<HorseAINotifier, Map<String, HorseAIData>>((ref) {
  return HorseAINotifier(ref.watch(apiServiceProvider));
});

/// Alias pour faciliter l'utilisation
final horseAINotifierProvider = allHorseAIDataProvider;

/// Provider pour obtenir le score IA global d'un cheval
final horseGlobalAIScoreProvider =
    Provider.autoDispose.family<double?, String>((ref, horseId) {
  final allData = ref.watch(allHorseAIDataProvider);
  return allData[horseId]?.globalAIScore;
});

/// Provider pour obtenir les alertes IA actives d'un cheval
final horseAIAlertsProvider =
    Provider.autoDispose.family<List<AIAlert>, String>((ref, horseId) {
  final allData = ref.watch(allHorseAIDataProvider);
  return allData[horseId]?.alerts.where((a) => !a.isResolved).toList() ?? [];
});

/// Provider pour obtenir les recommandations IA d'un cheval
final horseAIRecommendationsProvider =
    Provider.autoDispose.family<List<AIRecommendation>, String>((ref, horseId) {
  final allData = ref.watch(allHorseAIDataProvider);
  return allData[horseId]
          ?.recommendations
          .where((r) => !r.isDismissed)
          .toList() ??
      [];
});

/// Provider pour les données de santé IA
final horseHealthAIProvider =
    Provider.autoDispose.family<HealthAIData?, String>((ref, horseId) {
  final allData = ref.watch(allHorseAIDataProvider);
  return allData[horseId]?.healthData;
});

/// Provider pour les données d'analyse IA
final horseAnalysisAIProvider =
    Provider.autoDispose.family<AnalysisAIData?, String>((ref, horseId) {
  final allData = ref.watch(allHorseAIDataProvider);
  return allData[horseId]?.analysisData;
});

/// Provider pour les données de gestation IA
final horseGestationAIProvider =
    Provider.autoDispose.family<GestationAIData?, String>((ref, horseId) {
  final allData = ref.watch(allHorseAIDataProvider);
  return allData[horseId]?.gestationData;
});

/// Provider pour les données d'entraînement IA
final horseTrainingAIProvider =
    Provider.autoDispose.family<TrainingAIData?, String>((ref, horseId) {
  final allData = ref.watch(allHorseAIDataProvider);
  return allData[horseId]?.trainingData;
});

/// Provider pour les données de nutrition IA
final horseNutritionAIProvider =
    Provider.autoDispose.family<NutritionAIData?, String>((ref, horseId) {
  final allData = ref.watch(allHorseAIDataProvider);
  return allData[horseId]?.nutritionData;
});

/// Provider pour les données de conformation IA
final horseConformationAIProvider =
    Provider.autoDispose.family<ConformationAIData?, String>((ref, horseId) {
  final allData = ref.watch(allHorseAIDataProvider);
  return allData[horseId]?.conformationData;
});

/// Notifier pour gérer les données IA des chevaux
class HorseAINotifier extends StateNotifier<Map<String, HorseAIData>> {
  final ApiService _api;
  static const String _storageKey = 'horse_ai_data';

  HorseAINotifier(this._api) : super({}) {
    _loadFromStorage();
  }

  /// Charge les données depuis le stockage local
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        final loadedData = <String, HorseAIData>{};
        jsonMap.forEach((key, value) {
          loadedData[key] = HorseAIData.fromJson(value);
        });
        state = loadedData;
      }
    } catch (e) {
      // Ignore errors on load
    }
  }

  /// Sauvegarde les données dans le stockage local
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonMap = <String, dynamic>{};
      state.forEach((key, value) {
        jsonMap[key] = value.toJson();
      });
      await prefs.setString(_storageKey, json.encode(jsonMap));
    } catch (e) {
      // Ignore errors on save
    }
  }

  /// Récupère les données IA d'un cheval (avec fetch depuis l'API si nécessaire)
  Future<HorseAIData> getHorseAIData(String horseId) async {
    // Si les données sont en cache et récentes, les retourner
    if (state.containsKey(horseId)) {
      final cached = state[horseId]!;
      final age = DateTime.now().difference(cached.lastUpdated);
      if (age.inHours < 1) {
        return cached;
      }
    }

    // Sinon, essayer de récupérer depuis l'API
    try {
      final response = await _api.get('/horses/$horseId/ai-data');
      final aiData = HorseAIData.fromJson(response);
      state = {...state, horseId: aiData};
      await _saveToStorage();
      return aiData;
    } catch (e) {
      // Si erreur API, retourner les données en cache ou créer des données vides
      if (state.containsKey(horseId)) {
        return state[horseId]!;
      }
      final emptyData = HorseAIData.empty(horseId);
      state = {...state, horseId: emptyData};
      await _saveToStorage();
      return emptyData;
    }
  }

  /// Met à jour les données IA complètes d'un cheval
  Future<void> updateHorseAIData(HorseAIData data) async {
    state = {...state, data.horseId: data};
    await _saveToStorage();

    // Synchroniser avec l'API
    try {
      await _api.put('/horses/${data.horseId}/ai-data', data.toJson());
    } catch (e) {
      // Continue even if API sync fails
    }
  }

  /// Met à jour les données de santé IA
  Future<void> updateHealthData(String horseId, HealthAIData healthData) async {
    final current = state[horseId] ?? HorseAIData.empty(horseId);
    final updated = current.copyWith(healthData: healthData);
    await updateHorseAIData(updated);
  }

  /// Met à jour les données d'analyse IA
  Future<void> updateAnalysisData(
      String horseId, AnalysisAIData analysisData) async {
    final current = state[horseId] ?? HorseAIData.empty(horseId);
    final updated = current.copyWith(analysisData: analysisData);
    await updateHorseAIData(updated);
  }

  /// Met à jour les données de gestation IA
  Future<void> updateGestationData(
      String horseId, GestationAIData gestationData) async {
    final current = state[horseId] ?? HorseAIData.empty(horseId);
    final updated = current.copyWith(gestationData: gestationData);
    await updateHorseAIData(updated);
  }

  /// Met à jour les données d'entraînement IA
  Future<void> updateTrainingData(
      String horseId, TrainingAIData trainingData) async {
    final current = state[horseId] ?? HorseAIData.empty(horseId);
    final updated = current.copyWith(trainingData: trainingData);
    await updateHorseAIData(updated);
  }

  /// Met à jour les données de nutrition IA
  Future<void> updateNutritionData(
      String horseId, NutritionAIData nutritionData) async {
    final current = state[horseId] ?? HorseAIData.empty(horseId);
    final updated = current.copyWith(nutritionData: nutritionData);
    await updateHorseAIData(updated);
  }

  /// Met à jour les données de conformation IA
  Future<void> updateConformationData(
      String horseId, ConformationAIData conformationData) async {
    final current = state[horseId] ?? HorseAIData.empty(horseId);
    final updated = current.copyWith(conformationData: conformationData);
    await updateHorseAIData(updated);
  }

  /// Met à jour le score IA global
  Future<void> updateGlobalAIScore(String horseId, double score) async {
    final current = state[horseId] ?? HorseAIData.empty(horseId);
    final updated = current.copyWith(globalAIScore: score);
    await updateHorseAIData(updated);
  }

  /// Ajoute une recommandation IA
  Future<void> addRecommendation(
      String horseId, AIRecommendation recommendation) async {
    final current = state[horseId] ?? HorseAIData.empty(horseId);
    final updated = current.copyWith(
      recommendations: [...current.recommendations, recommendation],
    );
    await updateHorseAIData(updated);
  }

  /// Supprime une recommandation (marque comme dismissed)
  Future<void> dismissRecommendation(
      String horseId, String recommendationId) async {
    final current = state[horseId];
    if (current == null) return;

    final updatedRecommendations = current.recommendations.map((r) {
      if (r.id == recommendationId) {
        return AIRecommendation(
          id: r.id,
          category: r.category,
          title: r.title,
          description: r.description,
          priority: r.priority,
          createdAt: r.createdAt,
          isDismissed: true,
        );
      }
      return r;
    }).toList();

    final updated = current.copyWith(recommendations: updatedRecommendations);
    await updateHorseAIData(updated);
  }

  /// Ajoute une alerte IA
  Future<void> addAlert(String horseId, AIAlert alert) async {
    final current = state[horseId] ?? HorseAIData.empty(horseId);
    final updated = current.copyWith(
      alerts: [...current.alerts, alert],
    );
    await updateHorseAIData(updated);
  }

  /// Marque une alerte comme lue
  Future<void> markAlertAsRead(String horseId, String alertId) async {
    final current = state[horseId];
    if (current == null) return;

    final updatedAlerts = current.alerts.map((a) {
      if (a.id == alertId) {
        return AIAlert(
          id: a.id,
          type: a.type,
          message: a.message,
          actionRequired: a.actionRequired,
          createdAt: a.createdAt,
          isRead: true,
          isResolved: a.isResolved,
        );
      }
      return a;
    }).toList();

    final updated = current.copyWith(alerts: updatedAlerts);
    await updateHorseAIData(updated);
  }

  /// Résout une alerte
  Future<void> resolveAlert(String horseId, String alertId) async {
    final current = state[horseId];
    if (current == null) return;

    final updatedAlerts = current.alerts.map((a) {
      if (a.id == alertId) {
        return AIAlert(
          id: a.id,
          type: a.type,
          message: a.message,
          actionRequired: a.actionRequired,
          createdAt: a.createdAt,
          isRead: true,
          isResolved: true,
        );
      }
      return a;
    }).toList();

    final updated = current.copyWith(alerts: updatedAlerts);
    await updateHorseAIData(updated);
  }

  /// Synchronise toutes les données IA avec l'API
  Future<void> syncAllWithAPI() async {
    for (final entry in state.entries) {
      try {
        await _api.put('/horses/${entry.key}/ai-data', entry.value.toJson());
      } catch (e) {
        // Continue with other horses even if one fails
      }
    }
  }

  /// Efface les données IA d'un cheval
  Future<void> clearHorseAIData(String horseId) async {
    final newState = Map<String, HorseAIData>.from(state);
    newState.remove(horseId);
    state = newState;
    await _saveToStorage();
  }

  /// Calcule le score IA global basé sur toutes les données
  double calculateGlobalScore(String horseId) {
    final data = state[horseId];
    if (data == null) return 0.0;

    double totalScore = 0;
    int count = 0;

    if (data.healthData?.overallHealthScore != null) {
      totalScore += data.healthData!.overallHealthScore!;
      count++;
    }

    if (data.analysisData != null) {
      double analysisAvg = 0;
      int analysisCount = 0;

      if (data.analysisData!.locomotionScore != null) {
        analysisAvg += data.analysisData!.locomotionScore!;
        analysisCount++;
      }
      if (data.analysisData!.symmetryScore != null) {
        analysisAvg += data.analysisData!.symmetryScore!;
        analysisCount++;
      }
      if (data.analysisData!.rhythmScore != null) {
        analysisAvg += data.analysisData!.rhythmScore!;
        analysisCount++;
      }

      if (analysisCount > 0) {
        totalScore += analysisAvg / analysisCount;
        count++;
      }
    }

    if (data.trainingData?.performanceScore != null) {
      totalScore += data.trainingData!.performanceScore!;
      count++;
    }

    if (data.nutritionData?.bodyConditionScore != null) {
      // Convert 1-9 scale to 0-100
      totalScore += (data.nutritionData!.bodyConditionScore! / 9) * 100;
      count++;
    }

    if (data.conformationData?.overallScore != null) {
      totalScore += data.conformationData!.overallScore!;
      count++;
    }

    return count > 0 ? totalScore / count : 0.0;
  }
}
