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
}
