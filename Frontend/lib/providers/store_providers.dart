import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store_model.dart';
import '../services/store_service.dart';
import 'app_providers.dart';

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService(ref.watch(apiClientProvider));
});

final storesProvider = FutureProvider<List<StoreModel>>((ref) async {
  return ref.watch(storeServiceProvider).getStores();
});
