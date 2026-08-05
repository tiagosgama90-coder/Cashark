/// Cashark economy — addictive loops, progressive grind, house edge for the creator.
///
/// Flow:  Points  →  Sharkcoins  →  Cash (€ →  real payout (≥ €10)
///
/// Design goals:
/// - Players feel constant progress (points drip every kill / spin)
/// - Cashout is real but slow enough that ads + shop fund the pool
/// - Difficulty rises so continues / lives / ads stay valuable
class EconomyConfig {
  /// Minimum real cashout. €10 balances player appeal vs creator risk/fraud.
  /// (€5 burns float too fast; €20 scares new users.)
  static const double minCashEuro = 10.0;

  /// Priority cashout tier (optional UX) — same balance, faster review messaging.
  static const double priorityCashoutEuro = 20.0;

  // ── Points → Sharkcoins ─────────────────────────────────────────────
  /// Spend this many points to mint Sharkcoins.
  static const int pointsPerConversion = 100;

  /// Sharkcoins granted per points block (house keeps ~half the "felt" value).
  static const int sharkcoinsFromPoints = 8;

  // ── Sharkcoins → Cash ───────────────────────────────────────────────
  /// Sharkcoins needed per cash conversion block.
  static const int sharksPerConversion = 250;

  /// Cash per block. 250 SC → €0.40 ⇒ need **6 250 SC** (~78 125 points) for €10.
  static const double cashPerConversion = 0.40;

  /// Shop turbo: one boosted conversion.
  static const double boostedConversionCash = 0.65;

  // ── Roulette (dynamic wheel) ────────────────────────────────────────
  /// Prefer Sharkcoin wins (slow convert) over direct Cash drips.
  static const double sharkWeight = 0.55;
  static const double coinWeight = 0.45;

  static const int sharksWinMin = 3;
  static const int sharksWinMax = 10;

  /// Tiny cash drips — never a shortcut past the €10 gate.
  static const double cashWinMin = 0.01;
  static const double cashWinMax = 0.05;

  static const int dailyFreeSpins = 5;
  static const int adBonusSpins = 2;

  /// Soft daily cap on roulette Cash to protect the float.
  static const double dailyRouletteCashCap = 0.35;

  // ── Ocean Stardust game ─────────────────────────────────────────────
  static const int maxLives = 3;

  /// Base Sharkcoins per kill (scaled by wave difficulty in-game).
  static const int casharkPerKill = 1;

  /// Points per kill (primary addictive meter).
  static const int pointsPerKill = 12;

  static const double lifePriceCash = 0.49;
  static const int lifePriceSharks = 60;
  static const int lifePackSize = 3;
  static const double lifePackPriceIap = 1.99;

  /// Wave difficulty: every N kills, speed/HP ramp.
  static const int killsPerWave = 8;
  static const double difficultySpeedPerWave = 0.12;
  static const double maxDifficultyMul = 2.8;

  // ── Shop boosts ─────────────────────────────────────────────────────
  static const double luckyCoinWeight = 0.68;
  static const int luckySpinsCount = 5;

  /// Alias used across code — Sharkcoins balance field name stays `sharks`.
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
