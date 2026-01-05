import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import '../models/models.dart';
import '../services/api_service.dart';

final horsesProvider = FutureProvider.autoDispose<List<Horse>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getHorses();
});

final horseProvider = FutureProvider.autoDispose.family<Horse, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.getHorse(id);
});

class HorsesNotifier extends StateNotifier<AsyncValue<List<Horse>>> {
  final ApiService _api;

  HorsesNotifier(this._api) : super(const AsyncValue.loading()) {
    loadHorses();
  }

  Future<void> loadHorses({String? search, String? status}) async {
    state = const AsyncValue.loading();
    try {
      final horses = await _api.getHorses(search: search, status: status);
      state = AsyncValue.data(horses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Horse?> createHorse(Map<String, dynamic> data) async {
    try {
      final horse = await _api.createHorse(data);
      state = state.whenData((horses) => [horse, ...horses]);
      return horse;
    } catch (e) {
      return null;
    }
  }

  Future<Horse?> updateHorse(String id, Map<String, dynamic> data) async {
    try {
      final horse = await _api.updateHorse(id, data);
      state = state.whenData(
        (horses) => horses.map((h) => h.id == id ? horse : h).toList(),
      );
      return horse;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteHorse(String id) async {
    try {
      await _api.deleteHorse(id);
      state = state.whenData(
        (horses) => horses.where((h) => h.id != id).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadPhoto(String horseId, File file) async {
    try {
      return await _api.uploadHorsePhoto(horseId, file);
    } catch (e) {
      return null;
    }
  }
}

final horsesNotifierProvider =
    StateNotifierProvider<HorsesNotifier, AsyncValue<List<Horse>>>((ref) {
  return HorsesNotifier(ref.watch(apiServiceProvider));
});
