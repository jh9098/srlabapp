import 'package:flutter_test/flutter_test.dart';

import 'package:srlabapp/core/config/app_config.dart';
import 'package:srlabapp/features/app/app.dart';
import 'package:srlabapp/features/home/data/home_models.dart';
import 'package:srlabapp/features/stock/data/stock_models.dart';

void main() {
  testWidgets('앱 하단 탭이 표시된다', (tester) async {
    await tester.pumpWidget(
      SrLabApp(
        config: AppConfig(
          apiBaseUrl: 'http://127.0.0.1:8000/api/v1',
          userIdentifier: 'demo-user',
          appEnv: 'test',
          enableVerboseLog: false,
          firebaseProjectId: '',
          firebaseAppId: '',
          firebaseApiKey: '',
          firebaseMessagingSenderId: '',
          firebaseIosBundleId: '',
          firebaseAndroidAppId: '',
          firebaseWebAppId: '',
          firebaseWebVapidKey: '',
          googleClientId: '',
          googleServerClientId: '',
        ),
      ),
    );

    expect(find.text('홈'), findsWidgets);
    expect(find.text('관심종목'), findsOneWidget);
    expect(find.text('테마'), findsOneWidget);
    expect(find.text('쇼츠'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);
  });

  test('홈 모델 파싱이 동작한다', () {
    final model = HomeResponseModel.fromJson({
      'market_summary': {'headline': '반등 시도'},
      'featured_stocks': [],
      'watchlist_signal_summary': {
        'support_near_count': 1,
        'resistance_near_count': 2,
        'warning_count': 0,
      },
      'themes': [],
      'recent_contents': [],
    });

    expect(model.marketHeadline, '반등 시도');
    expect(model.watchlistSignalSummary.resistanceNearCount, 2);
  });

  test('종목 상세 모델이 문자열 숫자와 신호 데이터를 안전하게 파싱한다', () {
    final model = StockDetailModel.fromJson({
      'stock': {'stock_code': '005930', 'stock_name': '삼성전자', 'market_type': 'KOSPI'},
      'price': {
        'current_price': '70000.00',
        'change_value': '1000',
        'change_pct': '1.4',
        'day_high': '71,000',
        'day_low': '69000',
        'volume': '1000',
        'updated_at': '2026-03-19T10:00:00',
      },
      'status': {'code': 'TESTING_SUPPORT', 'label': '지지선 반응 확인 중', 'severity': 'watch'},
      'levels': [
        {'level_id': '1', 'level_type': 'SUPPORT', 'level_order': '1', 'level_price': '68000.00', 'distance_pct': '2.0'},
        {'level_id': 2, 'level_type': 'RESISTANCE', 'level_order': 1, 'level_price': '72000', 'distance_pct': null},
      ],
      'support_state': {
        'status': 'TESTING_SUPPORT',
        'reaction_type': null,
        'first_touched_at': '2026-03-19T09:30:00',
        'rebound_pct': '1.2',
      },
      'scenario': {'base': '기본', 'bull': '상방', 'bear': '하방'},
      'reason_lines': ['하나', '둘', '셋'],
      'chart': {
        'daily_bars': [
          {
            'trade_date': '2026-03-19',
            'open_price': '68000',
            'high_price': '71000.00',
            'low_price': '67500',
            'close_price': '70000.00',
            'volume': '1000',
          }
        ],
      },
      'latest_signal_summary': {
        'title': '지지선 접근',
        'summary': '지지선 부근 반응 확인이 필요합니다.',
        'signal_type': 'SUPPORT_TESTING',
        'event_time': '2026-03-19T10:05:00',
      },
      'recent_signal_events': [
        {
          'event_id': '10',
          'signal_type': 'SUPPORT_TESTING',
          'label': '지지 확인',
          'message': '첫 반응 체크',
          'event_time': '2026-03-19T10:05:00',
        }
      ],
      'related_themes': [],
      'related_contents': [],
      'watchlist': {'is_in_watchlist': true, 'alert_enabled': true, 'watchlist_id': '1'},
    });

    expect(model.stock.stockName, '삼성전자');
    expect(model.levels.first.levelType, 'SUPPORT');
    expect(model.reasonLines.length, 3);
    expect(model.price.currentPrice, 70000);
    expect(model.price.volume, 1000);
    expect(model.chart.first.closePrice, 70000);
    expect(model.recentSignalEvents.first.eventId, 10);
    expect(model.latestSignalSummary?.title, '지지선 접근');
  });
}
