import 'package:flutter_test/flutter_test.dart';
import 'package:i_tabung/core/utils/currency_utils.dart';

void main() {
  test('roundToCents rounds correctly', () {
    expect(CurrencyUtils.roundToCents(10.126), 10.13);
    expect(CurrencyUtils.roundToCents(10.124), 10.12);
  });
}
