import '../../../core/network/api_client.dart';
import 'stock_models.dart';

class StockRepository {
  StockRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<StockSearchItemModel>> searchStocks(String query) async {
    final response = await _apiClient.get('/stocks/search', queryParameters: {'q': query});
    final data = response['data'] as Map<String, dynamic>;
    return (data['items'] as List<dynamic>)
        .map((item) => StockSearchItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StockDetailModel> fetchStockDetail(String stockCode) async {
    final response = await _apiClient.get('/stocks/$stockCode');
    return StockDetailModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
