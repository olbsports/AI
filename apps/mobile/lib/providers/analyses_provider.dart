import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import '../models/models.dart';
import '../services/api_service.dart';

final analysesProvider = FutureProvider.autoDispose<List<Analysis>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getAnalyses();
});

final analysisProvider = FutureProvider.autoDispose.family<Analysis, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.getAnalysis(id);
});

class AnalysesNotifier extends StateNotifier<AsyncValue<List<Analysis>>> {
  final ApiService _api;

  AnalysesNotifier(this._api) : super(const AsyncValue.loading()) {
    loadAnalyses();
  }

  Future<void> loadAnalyses({String? horseId, String? type, String? status}) async {
    state = const AsyncValue.loading();
    try {
      final analyses = await _api.getAnalyses(
        horseId: horseId,
        type: type,
        status: status,
      );
      state = AsyncValue.data(analyses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Analysis?> createAnalysis({
    required String horseId,
    required String type,
    required File videoFile,
    String? notes,
  }) async {
    try {
      final analysis = await _api.createAnalysis(
        horseId: horseId,
        type: type,
        videoFile: videoFile,
        notes: notes,
      );
      state = state.whenData((analyses) => [analysis, ...analyses]);
      return analysis;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteAnalysis(String id) async {
    try {
      await _api.deleteAnalysis(id);
      state = state.whenData(
        (analyses) => analyses.where((a) => a.id != id).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void refresh() {
    loadAnalyses();
  }
}

final analysesNotifierProvider =
    StateNotifierProvider<AnalysesNotifier, AsyncValue<List<Analysis>>>((ref) {
  return AnalysesNotifier(ref.watch(apiServiceProvider));
});

// Provider for analyses by horse
final horseAnalysesProvider = FutureProvider.autoDispose.family<List<Analysis>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getAnalyses(horseId: horseId);
});
