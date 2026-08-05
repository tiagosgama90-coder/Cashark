/// Cashark economy — Points → Sharkcoins → Cash; Pearls = premium.
class EconomyConfig {
  static const double minCashEuro = 10.0;
  static const double priorityCashoutEuro = 20.0;

  static const int pointsPerConversion = 100;
  static const int sharkcoinsFromPoints = 8;

  static const int sharksPerConversion = 250;
  static const double cashPerConversion = 0.40;
  static const double boostedConversionCash = 0.65;

  static const double sharkWeight = 0.55;
  static const double coinWeight = 0.45;
  static const int sharksWinMin = 3;
  static const int sharksWinMax = 10;
  static const double cashWinMin = 0.01;
  static const double cashWinMax = 0.05;

  static const int dailyFreeSpins = 5;
  static const int adBonusSpins = 2;
  static const double dailyRouletteCashCap = 0.35;

  static const int maxLives = 3;
  static const int casharkPerKill = 1;
  static const int pointsPerKill = 12;
  static const double lifePriceCash = 0.49;
  static const int lifePriceSharks = 60;
  static const int lifePackSize = 3;

  static const double luckyCoinWeight = 0.68;
  static const int luckySpinsCount = 5;

  static const int killsPerWave = 8;
  static const double difficultySpeedPerWave = 0.12;
  static const double maxDifficultyMul = 2.8;

  /// Premium currency (Pérolas / Pearls).
  static const int pearlsPerSmallPack = 50;
  static const int pearlsPerMediumPack = 100;
  static const int pearlsPerLargePack = 300;
  static const double pearlsSmallPrice = 2.99;
  static const double pearlsMediumPrice = 6.49;
  static const double pearlsLargePrice = 14.99;

  /// Pearl sinks (intelligent spend loops).
  static const int pearlsForExtraSpin = 5;
  static const int pearlsForRaffleFlip = 3;
  static const int pearlsToSharkcoinsRate = 10; // 1 pearl → 10 SC
  static const int sharkcoinsPerPearlBuy = 10;

  static const String currencyName = 'Sharkcoins';
}

enum RouletteSymbol { shark, coin }

class ShopItem {
  final String id;
  final String titleKey;
  final String descKey;
  final String icon;
  final double priceEuro;
  final int? priceSharks;
  final int? pricePearls;
  final bool consumable;
  final String kind;

  const ShopItem({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.priceEuro,
    this.priceSharks,
    this.pricePearls,
    this.consumable = true,
    required this.kind,
  });
}

/// Classic boost packs (Stripe / Cash / Sharkcoins).
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
    priceSharks: 100,
    kind: 'lucky',
  ),
  ShopItem(
    id: 'double_convert',
    titleKey: 'shop_double',
    descKey: 'shop_double_desc',
    icon: '⚡',
    priceEuro: 1.29,
    priceSharks: 80,
    kind: 'double',
  ),
  ShopItem(
    id: 'shark_vault',
    titleKey: 'shop_vault',
    descKey: 'shop_vault_desc',
    icon: '🦈',
    priceEuro: 2.99,
    kind: 'sharks',
  ),
  ShopItem(
    id: 'points_pack',
    titleKey: 'shop_points',
    descKey: 'shop_points_desc',
    icon: '⭐',
    priceEuro: 1.99,
    kind: 'points',
  ),
  ShopItem(
    id: 'vip_pass',
    titleKey: 'shop_vip',
    descKey: 'shop_vip_desc',
    icon: '👑',
    priceEuro: 6.99,
    consumable: false,
    kind: 'vip',
  ),
  ShopItem(
    id: 'starter_bundle',
    titleKey: 'shop_starter',
    descKey: 'shop_starter_desc',
    icon: '🎁',
    priceEuro: 3.99,
    kind: 'bundle',
  ),
];

/// Ad-removal premium (like reference apps) — paid in EUR via Stripe.
class AdFreePlan {
  final String id;
  final String titleKey;
  final int days; // 0 = lifetime
  final double priceEuro;
  const AdFreePlan({
    required this.id,
    required this.titleKey,
    required this.days,
    required this.priceEuro,
  });
}

const adFreePlans = <AdFreePlan>[
  AdFreePlan(id: 'adfree_1d', titleKey: 'adfree_1d', days: 1, priceEuro: 2.09),
  AdFreePlan(id: 'adfree_7d', titleKey: 'adfree_7d', days: 7, priceEuro: 2.99),
  AdFreePlan(id: 'adfree_30d', titleKey: 'adfree_30d', days: 30, priceEuro: 7.49),
  AdFreePlan(id: 'adfree_life', titleKey: 'adfree_life', days: 0, priceEuro: 13.99),
];

class PearlPack {
  final String id;
  final int pearls;
  final double priceEuro;
  final int? discountPercent;
  const PearlPack({
    required this.id,
    required this.pearls,
    required this.priceEuro,
    this.discountPercent,
  });
}

const pearlPacks = <PearlPack>[
  PearlPack(id: 'pearls_50', pearls: 50, priceEuro: 2.99),
  PearlPack(id: 'pearls_100', pearls: 100, priceEuro: 6.49, discountPercent: 40),
  PearlPack(id: 'pearls_300', pearls: 300, priceEuro: 14.99, discountPercent: 35),
];
