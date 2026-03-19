import '../../../core/network/api_client.dart';
import '../../home/data/home_models.dart';

class ThemeRepository {
  ThemeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ThemeItemModel>> fetchThemes() async {
    final response = await _apiClient.get('/themes');
    final data = response['data'] as Map<String, dynamic>;
    return (data['items'] as List<dynamic>)
        .map((item) => ThemeItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
