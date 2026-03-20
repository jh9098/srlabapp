import '../../../core/network/api_client.dart';
import '../../home/data/home_models.dart';

class ThemeRepository {
  ThemeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ThemeItemModel>> fetchThemes() async {
    final response = await _apiClient.get('/themes');
    final data = response['data'] as Map<String, dynamic>;
    return (data['items'] as List<dynamic>? ?? const [])
        .map((item) => ThemeItemModel.fromJson((item as Map<String, dynamic>?) ?? const {}))
        .toList();
  }

  Future<ThemeDetailModel> fetchThemeDetail(int themeId) async {
    final response = await _apiClient.get('/themes/$themeId');
    return ThemeDetailModel.fromJson((response['data'] as Map<String, dynamic>?) ?? const {});
  }

  Future<List<RecentContentModel>> fetchContents({String? category, int limit = 20}) async {
    final response = await _apiClient.get(
      '/contents',
      queryParameters: {
        'limit': '$limit',
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['items'] as List<dynamic>? ?? const [])
        .map((item) => RecentContentModel.fromJson((item as Map<String, dynamic>?) ?? const {}))
        .toList();
  }
}
