class Formatters {
  static String price(num value) {
    final integer = value.round();
    final text = integer.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    final prefix = integer < 0 ? '-' : '';
    return '$prefix${buffer.toString()}원';
  }

  static String compactPrice(num value) {
    final rounded = value.round();
    if (rounded.abs() >= 100000000) {
      return '${(rounded / 100000000).toStringAsFixed(1)}억';
    }
    if (rounded.abs() >= 10000) {
      return '${(rounded / 10000).toStringAsFixed(1)}만';
    }
    return price(rounded);
  }

  static String percent(num value, {bool signed = true}) {
    final fixed = value.toStringAsFixed(2);
    if (!signed) {
      return '$fixed%';
    }
    if (value > 0) {
      return '+$fixed%';
    }
    return '$fixed%';
  }

  static String date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String dateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${date(value)} $hour:$minute';
  }
}
