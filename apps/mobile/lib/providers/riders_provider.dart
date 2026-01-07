import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/api_service.dart';

final ridersProvider = FutureProvider.autoDispose<List<Rider>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getRiders();
});

final riderProvider = FutureProvider.autoDispose.family<Rider, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.getRider(id);
});

class RidersNotifier extends StateNotifier<AsyncValue<List<Rider>>> {
  final ApiService _api;

  RidersNotifier(this._api) : super(const AsyncValue.loading()) {
    loadRiders();
  }

  Future<void> loadRiders({String? search}) async {
    state = const AsyncValue.loading();
    try {
      final riders = await _api.getRiders(search: search);
      state = AsyncValue.data(riders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Rider?> createRider(Map<String, dynamic> data) async {
    try {
      final rider = await _api.createRider(data);
      state = state.whenData((riders) => [rider, ...riders]);
      return rider;
    } catch (e) {
      return null;
    }
  }

  Future<Rider?> updateRider(String id, Map<String, dynamic> data) async {
    try {
      final rider = await _api.updateRider(id, data);
      state = state.whenData(
        (riders) => riders.map((r) => r.id == id ? rider : r).toList(),
      );
      return rider;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteRider(String id) async {
    try {
      await _api.deleteRider(id);
      state = state.whenData(
        (riders) => riders.where((r) => r.id != id).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadPhoto(String riderId, File file) async {
    try {
      return await _api.uploadRiderPhoto(riderId, file);
    } catch (e) {
      return null;
    }
  }
}

final ridersNotifierProvider =
    StateNotifierProvider<RidersNotifier, AsyncValue<List<Rider>>>((ref) {
  return RidersNotifier(ref.watch(apiServiceProvider));
});
