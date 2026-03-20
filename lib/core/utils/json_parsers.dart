double parseJsonDouble(dynamic value, {double defaultValue = 0}) {
  if (value == null) {
    return defaultValue;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    final normalized = value.replaceAll(',', '').trim();
    final parsed = double.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }
  }

  throw FormatException('double 파싱 실패: $value');
}

double? parseNullableJsonDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is String && value.trim().isEmpty) {
    return null;
  }

  return parseJsonDouble(value);
}