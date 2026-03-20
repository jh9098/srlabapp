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
      stockCode: json['stock_code'] as String? ?? '',
      stockName: json['stock_name'] as String? ?? '',
      currentPrice: parseJsonDouble(json['current_price']),
      changePct: parseJsonDouble(json['change_pct']),
      status: StatusBadgeModel.fromJson((json['status'] as Map<String, dynamic>?) ?? const {}),
      summary: parseJsonString(json['summary'], fallback: '운영자 코멘트가 아직 없습니다.'),
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
      supportNearCount: parseJsonInt(json['support_near_count']),
      resistanceNearCount: parseJsonInt(json['resistance_near_count']),
      warningCount: parseJsonInt(json['warning_count']),
    );
  }
}

class ThemeStockSummaryModel {
  const ThemeStockSummaryModel({required this.stockCode, required this.stockName});

  final String stockCode;
  final String stockName;

  factory ThemeStockSummaryModel.fromJson(Map<String, dynamic> json) {
    return ThemeStockSummaryModel(
      stockCode: parseJsonString(json['stock_code']),
      stockName: parseJsonString(json['stock_name']),
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
    required this.stockCount,
  });

  final int themeId;
  final String name;
  final double? score;
  final String? summary;
  final ThemeStockSummaryModel? leaderStock;
  final List<ThemeStockSummaryModel> followerStocks;
  final int stockCount;

  factory ThemeItemModel.fromJson(Map<String, dynamic> json) {
    return ThemeItemModel(
      themeId: parseJsonInt(json['theme_id']),
      name: parseJsonString(json['name'], fallback: '이름 없는 테마'),
      score: parseNullableJsonDouble(json['score']),
      summary: parseNullableJsonString(json['summary']),
      leaderStock: json['leader_stock'] == null
          ? null
          : ThemeStockSummaryModel.fromJson((json['leader_stock'] as Map<String, dynamic>?) ?? const {}),
      followerStocks: (json['follower_stocks'] as List<dynamic>? ?? const [])
          .map((item) => ThemeStockSummaryModel.fromJson((item as Map<String, dynamic>?) ?? const {}))
          .toList(),
      stockCount: parseJsonInt(json['stock_count']),
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
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  final int contentId;
  final String category;
  final String title;
  final String? summary;
  final String? externalUrl;
  final String? thumbnailUrl;
  final DateTime? publishedAt;

  bool get hasExternalLink => (externalUrl ?? '').trim().isNotEmpty;

  factory RecentContentModel.fromJson(Map<String, dynamic> json) {
    return RecentContentModel(
      contentId: parseJsonInt(json['content_id']),
      category: parseJsonString(json['category'], fallback: 'CONTENT'),
      title: parseJsonString(json['title'], fallback: '제목 없는 콘텐츠'),
      summary: parseNullableJsonString(json['summary']),
      externalUrl: parseNullableJsonString(json['external_url']),
      thumbnailUrl: parseNullableJsonString(json['thumbnail_url']),
      publishedAt: parseNullableJsonDateTime(json['published_at']),
    );
  }
}

class ThemeDetailModel {
  const ThemeDetailModel({
    required this.theme,
    required this.stocks,
    required this.recentContents,
  });

  final ThemeItemModel theme;
  final List<ThemeStockSummaryModel> stocks;
  final List<RecentContentModel> recentContents;

  factory ThemeDetailModel.fromJson(Map<String, dynamic> json) {
    return ThemeDetailModel(
      theme: ThemeItemModel.fromJson((json['theme'] as Map<String, dynamic>?) ?? const {}),
      stocks: (json['stocks'] as List<dynamic>? ?? const [])
          .map((item) => ThemeStockSummaryModel.fromJson((item as Map<String, dynamic>?) ?? const {}))
          .toList(),
      recentContents: (json['recent_contents'] as List<dynamic>? ?? const [])
          .map((item) => RecentContentModel.fromJson((item as Map<String, dynamic>?) ?? const {}))
          .toList(),
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
      marketHeadline: parseJsonString((json['market_summary'] as Map<String, dynamic>?)?['headline']),
      featuredStocks: (json['featured_stocks'] as List<dynamic>? ?? const [])
          .map((item) => HomeFeaturedStockModel.fromJson((item as Map<String, dynamic>?) ?? const {}))
          .toList(),
      watchlistSignalSummary: HomeWatchlistSignalSummaryModel.fromJson(
        (json['watchlist_signal_summary'] as Map<String, dynamic>?) ?? const {},
      ),
      themes: (json['themes'] as List<dynamic>? ?? const [])
          .map((item) => ThemeItemModel.fromJson((item as Map<String, dynamic>?) ?? const {}))
          .toList(),
      recentContents: (json['recent_contents'] as List<dynamic>? ?? const [])
          .map((item) => RecentContentModel.fromJson((item as Map<String, dynamic>?) ?? const {}))
          .toList(),
    );
  }
}
