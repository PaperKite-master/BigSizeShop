import '../core/network/api_client.dart';
import '../models/category_model.dart';

class CategoryService {
  const CategoryService(this._client);

  final ApiClient _client;

  Future<List<CategoryModel>> list() async {
    final response = await _client.get<Map<String, dynamic>>('/categories');
    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryModel> create(String name) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/categories',
      data: {'name': name},
    );

    return CategoryModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<CategoryModel> update(String id, String name) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/categories/$id',
      data: {'name': name},
    );

    return CategoryModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete<Map<String, dynamic>>('/categories/$id');
  }
}
