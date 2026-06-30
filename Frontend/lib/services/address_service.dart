import '../core/network/api_client.dart';
import '../models/address_model.dart';

class AddressService {
  const AddressService(this._client);

  final ApiClient _client;

  Future<List<AddressModel>> list() async {
    final response = await _client.get<Map<String, dynamic>>('/addresses');
    final list = response.data!['data'] as List<dynamic>;
    return list.map((item) => AddressModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<AddressModel> create(AddressModel address) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/addresses',
      data: address.toJson(),
    );
    return AddressModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<AddressModel> update(String id, AddressModel address) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/addresses/$id',
      data: address.toJson(),
    );
    return AddressModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await _client.delete<Map<String, dynamic>>('/addresses/$id');
  }
}
