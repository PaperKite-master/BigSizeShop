import '../core/network/api_client.dart';
import '../models/store_model.dart';

class StoreService {
  const StoreService(this._client);

  final ApiClient _client;

  Future<List<StoreModel>> getStores() async {
    final response = await _client.get<Map<String, dynamic>>('/stores');
    final list = response.data!['data'] as List<dynamic>;
    return list.map((item) => StoreModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
