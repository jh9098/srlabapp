DateTime? parseNullableJsonDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return DateTime.tryParse(normalized);
  }

  return null;
}

DateTime? parseNullableJsonDate(dynamic value) {
  final parsed = parseNullableJsonDateTime(value);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

double parseJsonDouble(dynamic value, {double defaultValue = 0}) {
  if (value == null) {
    return defaultValue;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty) {
      return defaultValue;
    }
    final parsed = double.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }
  }

  return defaultValue;
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

int parseJsonInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) {
    return defaultValue;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  if (value is String) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty) {
      return defaultValue;
    }
    final intValue = int.tryParse(normalized);
    if (intValue != null) {
      return intValue;
    }
    final doubleValue = double.tryParse(normalized);
    if (doubleValue != null) {
      return doubleValue.round();
    }
  }

  return defaultValue;
}

int? parseNullableJsonInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is String && value.trim().isEmpty) {
    return null;
  }

  return parseJsonInt(value);
}
