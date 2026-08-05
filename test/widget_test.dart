import 'package:flutter_test/flutter_test.dart';
import 'package:cashark/models/economy.dart';

void main() {
  test('economy protects creator float with €10 gate', () {
    expect(EconomyConfig.minCashEuro, 10.0);
    expect(EconomyConfig.sharksPerConversion, 250);
    expect(EconomyConfig.cashPerConversion, lessThan(1.0));
    // Need many Sharkcoins to reach €10
    final blocksForTen = (10.0 / EconomyConfig.cashPerConversion).ceil();
    final scForTen = blocksForTen * EconomyConfig.sharksPerConversion;
    expect(scForTen, greaterThanOrEqualTo(5000));
  });

  test('points to sharkcoins mid-layer exists', () {
    expect(EconomyConfig.pointsPerConversion, 100);
    expect(EconomyConfig.sharkcoinsFromPoints, lessThan(20));
  });

  test('shop catalog monetizes lives spins and points', () {
    expect(shopCatalog.any((e) => e.kind == 'lives'), isTrue);
    expect(shopCatalog.any((e) => e.kind == 'points'), isTrue);
    expect(shopCatalog.any((e) => e.kind == 'vip'), isTrue);
  });
}
