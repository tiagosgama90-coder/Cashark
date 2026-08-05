/// Economy constants tuned so the house stays profitable while play stays fun.
class EconomyConfig {
  /// Minimum cash balance required to request a payout (€1.00).
  static const double minCashEuro = 1.0;

  /// Sharks needed to convert into cash (base rate).
  static const int sharksPerConversion = 100;

  /// Cash granted per conversion block — house edge vs perceived value.
  /// 100 sharks → €0.35 (need ~286 sharks for €1).
  static const double cashPerConversion = 0.35;

  /// Roulette: shark sector weight (house prefers sharks that convert slowly).
  static const double sharkWeight = 0.42;
  static const double coinWeight = 0.58;

  static const int sharksWinMin = 4;
  static const int sharksWinMax = 12;

  /// Coin wins are small — drip cash toward €1 slowly.
  static const double cashWinMin = 0.02;
  static const double cashWinMax = 0.08;

  /// Free spins regenerate slowly; extra spins push ads / shop.
  static const int dailyFreeSpins = 5;
  static const int adBonusSpins = 2;

  /// Space shooter.
  static const int maxLives = 3;
  static const int casharkPerKill = 1;
  static const double lifePriceCash = 0.25;
  static const int lifePriceSharks = 40;
  static const int lifePackSize = 3;
  static const double lifePackPriceIap = 1.99;

  /// Lucky boost (shop) temporarily raises coin chance.
  static const double luckyCoinWeight = 0.72;
  static const int luckySpinsCount = 5;

  /// Double shark conversion for one conversion (shop / rewarded ad).
  static const double boostedConversionCash = 0.55;
}

enum RouletteSymbol { shark, coin }

class ShopItem {
  final String id;
  final String titleKey;
  final String descKey;
  final String icon;
  final double priceEuro;
  final int? priceSharks;
  final bool consumable;
  final String kind;

  const ShopItem({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.priceEuro,
    this.priceSharks,
    this.consumable = true,
    required this.kind,
  });
}

const shopCatalog = <ShopItem>[
  ShopItem(
    id: 'lives_pack',
    titleKey: 'shop_lives',
    descKey: 'shop_lives_desc',
    icon: '❤️',
    priceEuro: 1.99,
    kind: 'lives',
  ),
  ShopItem(
    id: 'spin_pack',
    titleKey: 'shop_spins',
    descKey: 'shop_spins_desc',
    icon: '🎰',
    priceEuro: 0.99,
    kind: 'spins',
  ),
  ShopItem(
    id: 'lucky_boost',
    titleKey: 'shop_lucky',
    descKey: 'shop_lucky_desc',
    icon: '🍀',
    priceEuro: 1.49,
    priceSharks: 80,
    kind: 'lucky',
  ),
  ShopItem(
    id: 'double_convert',
    titleKey: 'shop_double',
    descKey: 'shop_double_desc',
    icon: '⚡',
    priceEuro: 0.79,
    priceSharks: 50,
    kind: 'double',
  ),
  ShopItem(
    id: 'shark_vault',
    titleKey: 'shop_vault',
    descKey: 'shop_vault_desc',
    icon: '🦈',
    priceEuro: 2.49,
    kind: 'sharks',
  ),
  ShopItem(
    id: 'vip_pass',
    titleKey: 'shop_vip',
    descKey: 'shop_vip_desc',
    icon: '👑',
    priceEuro: 4.99,
    consumable: false,
    kind: 'vip',
  ),
  ShopItem(
    id: 'starter_bundle',
    titleKey: 'shop_starter',
    descKey: 'shop_starter_desc',
    icon: '🎁',
    priceEuro: 2.99,
    kind: 'bundle',
  ),
];
