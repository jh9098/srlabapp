import '../../../core/network/api_client.dart';
import 'home_models.dart';

class HomeRepository {
  HomeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<HomeResponseModel> fetchHome() async {
    final response = await _apiClient.get('/home');
    return HomeResponseModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
