import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address_model.dart';
import '../services/address_service.dart';
import 'app_providers.dart';

final addressServiceProvider = Provider<AddressService>((ref) {
  return AddressService(ref.watch(apiClientProvider));
});

final addressesProvider =
    StateNotifierProvider<AddressNotifier, AsyncValue<List<AddressModel>>>((ref) {
  return AddressNotifier(ref);
});

class AddressNotifier extends StateNotifier<AsyncValue<List<AddressModel>>> {
  AddressNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen(authControllerProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          fetchAddresses();
        } else {
          state = const AsyncValue.data([]);
        }
      });
    });

    final user = _ref.read(authControllerProvider).value;
    if (user != null) {
      fetchAddresses();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  final Ref _ref;

  AddressService get _addressService => _ref.read(addressServiceProvider);

  Future<void> fetchAddresses() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _addressService.list();
    });
  }

  Future<void> addAddress({
    required String receiverName,
    required String receiverPhone,
    String? province,
    String? district,
    String? ward,
    required String streetAddress,
    bool isDefault = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newAddress = AddressModel(
        id: '',
        userId: '',
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        province: province,
        district: district,
        ward: ward,
        streetAddress: streetAddress,
        isDefault: isDefault,
      );
      await _addressService.create(newAddress);
      return await _addressService.list();
    });
  }

  Future<void> deleteAddress(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _addressService.remove(id);
      return await _addressService.list();
    });
  }
}
