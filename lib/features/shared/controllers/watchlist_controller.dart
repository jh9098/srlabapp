import 'package:flutter/foundation.dart';

import '../../watchlist/data/watchlist_models.dart';
import '../../watchlist/data/watchlist_repository.dart';

class WatchlistController extends ChangeNotifier {
  WatchlistController(this._repository);

  final WatchlistRepository _repository;

  List<WatchlistItemModel> _items = const [];
  WatchlistSummaryModel? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  List<WatchlistItemModel> get items => _items;
  WatchlistSummaryModel? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _repository.fetchWatchlist();
      _items = response.items;
      _summary = response.summary;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool containsStock(String stockCode) {
    return _items.any((item) => item.stockCode == stockCode);
  }

  WatchlistItemModel? findByStockCode(String stockCode) {
    try {
      return _items.firstWhere((item) => item.stockCode == stockCode);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(String stockCode) async {
    await _repository.addWatchlist(stockCode);
    await load();
  }

  Future<void> remove(int watchlistId) async {
    await _repository.deleteWatchlist(watchlistId);
    await load();
  }

  Future<void> toggleAlert({required int watchlistId, required bool alertEnabled}) async {
    await _repository.updateAlert(watchlistId, alertEnabled);
    _items = _items.map((item) {
      if (item.watchlistId != watchlistId) {
        return item;
      }
      return item.copyWith(alertEnabled: alertEnabled);
    }).toList();
    notifyListeners();
  }
}
