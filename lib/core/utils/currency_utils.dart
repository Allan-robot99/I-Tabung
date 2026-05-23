class CurrencyUtils {
  CurrencyUtils._();

  static double roundToCents(num value) {
    return (value * 100).roundToDouble() / 100;
  }

  static String asRm(num value) {
    final rounded = roundToCents(value);
    return 'RM${rounded.toStringAsFixed(2)}';
  }
}
