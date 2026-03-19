import '../../../core/network/api_client.dart';
import 'watchlist_models.dart';

class WatchlistRepository {
  WatchlistRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<WatchlistResponseModel> fetchWatchlist() async {
    final response = await _apiClient.get('/watchlist', requiresUser: true);
    return WatchlistResponseModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<int> addWatchlist(String stockCode, {bool alertEnabled = true}) async {
    final response = await _apiClient.post(
      '/watchlist',
      requiresUser: true,
      body: {
        'stock_code': stockCode,
        'alert_enabled': alertEnabled,
      },
    );
    return (response['data'] as Map<String, dynamic>)['watchlist_id'] as int;
  }

  Future<void> deleteWatchlist(int watchlistId) async {
    await _apiClient.delete('/watchlist/$watchlistId', requiresUser: true);
  }

  Future<void> updateAlert(int watchlistId, bool alertEnabled) async {
    await _apiClient.patch(
      '/watchlist/$watchlistId/alert',
      requiresUser: true,
      body: {'alert_enabled': alertEnabled},
    );
  }
}
