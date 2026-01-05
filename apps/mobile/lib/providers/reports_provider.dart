import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/api_service.dart';

final reportsProvider = FutureProvider.autoDispose<List<Report>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getReports();
});

final reportProvider = FutureProvider.autoDispose.family<Report, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.getReport(id);
});

class ReportsNotifier extends StateNotifier<AsyncValue<List<Report>>> {
  final ApiService _api;

  ReportsNotifier(this._api) : super(const AsyncValue.loading()) {
    loadReports();
  }

  Future<void> loadReports({String? horseId, String? type, String? status}) async {
    state = const AsyncValue.loading();
    try {
      final reports = await _api.getReports(
        horseId: horseId,
        type: type,
        status: status,
      );
      state = AsyncValue.data(reports);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Report?> createReport({
    required String horseId,
    required String type,
    String? title,
    List<String>? analysisIds,
  }) async {
    try {
      final report = await _api.createReport(
        horseId: horseId,
        type: type,
        title: title,
        analysisIds: analysisIds,
      );
      state = state.whenData((reports) => [report, ...reports]);
      return report;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteReport(String id) async {
    try {
      await _api.deleteReport(id);
      state = state.whenData(
        (reports) => reports.where((r) => r.id != id).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void refresh() {
    loadReports();
  }
}

final reportsNotifierProvider =
    StateNotifierProvider<ReportsNotifier, AsyncValue<List<Report>>>((ref) {
  return ReportsNotifier(ref.watch(apiServiceProvider));
});

// Provider for reports by horse
final horseReportsProvider = FutureProvider.autoDispose.family<List<Report>, String>((ref, horseId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getReports(horseId: horseId);
});
