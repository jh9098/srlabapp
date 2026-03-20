import '../../../core/utils/json_parsers.dart';
import '../../shared/models/common_models.dart';

class HomeFeaturedStockModel {
  const HomeFeaturedStockModel({
    required this.stockCode,
    required this.stockName,
    required this.currentPrice,
    required this.changePct,
    required this.status,
    required this.summary,
  });

  final String stockCode;
  final String stockName;
  final double currentPrice;
  final double changePct;
  final StatusBadgeModel status;
  final String summary;

  factory HomeFeaturedStockModel.fromJson(Map<String, dynamic> json) {
    return HomeFeaturedStockModel(
      stockCode: json['stock_code'] as String,
      stockName: json['stock_name'] as String,
      currentPrice: parseJsonDouble(json['current_price']),
      changePct: parseJsonDouble(json['change_pct']),
      status: StatusBadgeModel.fromJson(json['status'] as Map<String, dynamic>),
      summary: json['summary'] as String,
    );
  }
}

class HomeWatchlistSignalSummaryModel {
  const HomeWatchlistSignalSummaryModel({
    required this.supportNearCount,
    required this.resistanceNearCount,
    required this.warningCount,
  });

  final int supportNearCount;
  final int resistanceNearCount;
  final int warningCount;

  factory HomeWatchlistSignalSummaryModel.fromJson(Map<String, dynamic> json) {
    return HomeWatchlistSignalSummaryModel(
      supportNearCount: json['support_near_count'] as int,
      resistanceNearCount: json['resistance_near_count'] as int,
      warningCount: json['warning_count'] as int,
    );
  }
}

class ThemeItemModel {
  const ThemeItemModel({
    required this.themeId,
    required this.name,
    required this.score,
    required this.summary,
    required this.leaderStock,
    required this.followerStocks,
  });

  final int themeId;
  final String name;
  final double? score;
  final String? summary;
  final ThemeStockSummaryModel? leaderStock;
  final List<ThemeStockSummaryModel> followerStocks;

  factory ThemeItemModel.fromJson(Map<String, dynamic> json) {
    return ThemeItemModel(
      themeId: json['theme_id'] as int,
      name: json['name'] as String,
      score: parseNullableJsonDouble(json['score']),
      summary: json['summary'] as String?,
      leaderStock: json['leader_stock'] == null
          ? null
          : ThemeStockSummaryModel.fromJson(json['leader_stock'] as Map<String, dynamic>),
      followerStocks: (json['follower_stocks'] as List<dynamic>)
          .map((item) => ThemeStockSummaryModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecentContentModel {
  const RecentContentModel({
    required this.contentId,
    required this.category,
    required this.title,
    required this.summary,
    required this.externalUrl,
  });

  final int contentId;
  final String category;
  final String title;
  final String? summary;
  final String? externalUrl;

  factory RecentContentModel.fromJson(Map<String, dynamic> json) {
    return RecentContentModel(
      contentId: json['content_id'] as int,
      category: json['category'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      externalUrl: json['external_url'] as String?,
    );
  }
}

class HomeResponseModel {
  const HomeResponseModel({
    required this.marketHeadline,
    required this.featuredStocks,
    required this.watchlistSignalSummary,
    required this.themes,
    required this.recentContents,
  });

  final String marketHeadline;
  final List<HomeFeaturedStockModel> featuredStocks;
  final HomeWatchlistSignalSummaryModel watchlistSignalSummary;
  final List<ThemeItemModel> themes;
  final List<RecentContentModel> recentContents;

  factory HomeResponseModel.fromJson(Map<String, dynamic> json) {
    return HomeResponseModel(
      marketHeadline: (json['market_summary'] as Map<String, dynamic>)['headline'] as String,
      featuredStocks: (json['featured_stocks'] as List<dynamic>)
          .map((item) => HomeFeaturedStockModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      watchlistSignalSummary: HomeWatchlistSignalSummaryModel.fromJson(
        json['watchlist_signal_summary'] as Map<String, dynamic>,
      ),
      themes: (json['themes'] as List<dynamic>)
          .map((item) => ThemeItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentContents: (json['recent_contents'] as List<dynamic>)
          .map((item) => RecentContentModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}