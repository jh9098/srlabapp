import 'package:cloud_firestore/cloud_firestore.dart';

import 'json_parsers.dart';

DateTime? parseFirestoreDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return parseNullableJsonDateTime(value);
}

String normalizeTicker(dynamic value) {
  return parseJsonString(value).replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();
}

List<double> parseFirestoreDoubleList(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value.map((item) => parseJsonDouble(item)).where((item) => item > 0).toList();
}

List<Map<String, dynamic>> parseFirestoreMapList(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map((item) => item.map((key, val) => MapEntry(key.toString(), val)))
      .toList();
}

Map<String, dynamic> parseFirestoreMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

class FirestorePriceSummary {
  const FirestorePriceSummary({
    required this.currentPrice,
    required this.changeValue,
    required this.changePct,
    required this.updatedAt,
  });

  final double currentPrice;
  final double changeValue;
  final double changePct;
  final DateTime? updatedAt;
}

FirestorePriceSummary parseFirestorePriceSummary(Map<String, dynamic> data) {
  final prices = parseFirestoreMapList(data['prices']);
  if (prices.isEmpty) {
    return FirestorePriceSummary(
      currentPrice: parseJsonDouble(data['currentPrice']),
      changeValue: parseJsonDouble(data['changeValue']),
      changePct: parseJsonDouble(data['changePct']),
      updatedAt: parseFirestoreDateTime(data['updatedAt']),
    );
  }

  final latest = prices.last;
  final previous = prices.length > 1 ? prices[prices.length - 2] : null;
  final currentClose = parseJsonDouble(latest['close']);
  final previousClose = parseJsonDouble(previous?['close']);
  final changeValue = currentClose - previousClose;
  final changePct = previousClose == 0 ? 0.0 : (changeValue / previousClose) * 100;

  return FirestorePriceSummary(
    currentPrice: currentClose,
    changeValue: changeValue,
    changePct: changePct,
    updatedAt: parseFirestoreDateTime(data['updatedAt']) ??
        parseFirestoreDateTime(data['intradayRefreshedAt']) ??
        parseFirestoreDateTime(latest['date']),
  );
}
