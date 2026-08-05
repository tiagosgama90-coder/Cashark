import 'package:flutter_test/flutter_test.dart';
import 'package:cashark/models/economy.dart';

void main() {
  test('economy house edge constants are coherent', () {
    expect(EconomyConfig.minCashEuro, 1.0);
    expect(EconomyConfig.sharksPerConversion, 100);
    expect(EconomyConfig.cashPerConversion, lessThan(1.0));
    expect(EconomyConfig.sharkWeight + EconomyConfig.coinWeight, closeTo(1.0, 0.001));
    expect(EconomyConfig.maxLives, 3);
  });

  test('shop catalog has monetization items', () {
    expect(shopCatalog.length, greaterThanOrEqualTo(5));
    expect(shopCatalog.any((e) => e.kind == 'lives'), isTrue);
    expect(shopCatalog.any((e) => e.kind == 'vip'), isTrue);
  });
}
