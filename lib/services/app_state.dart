import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/economy.dart';

class UserProfile {
  String email;
  String password;
  String displayName;
  double cash;
  int sharks;
  int points;
  int freeSpins;
  int lives;
  int spinsPlayed;
  int enemiesDefeated;
  bool vip;
  int luckySpinsLeft;
  bool turboConvertReady;
  String lastSpinDay;
  AppLang lang;

  UserProfile({
    required this.email,
    required this.password,
    required this.displayName,
    this.cash = 0.05,
    this.sharks = 20,
    this.points = 0,
    this.freeSpins = EconomyConfig.dailyFreeSpins,
    this.lives = EconomyConfig.maxLives,
    this.spinsPlayed = 0,
    this.enemiesDefeated = 0,
    this.vip = false,
    this.luckySpinsLeft = 0,
    this.turboConvertReady = false,
    this.lastSpinDay = '',
    this.lang = AppLang.pt,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'displayName': displayName,
        'cash': cash,
        'sharks': sharks,
        'points': points,
        'freeSpins': freeSpins,
        'lives': lives,
        'spinsPlayed': spinsPlayed,
        'enemiesDefeated': enemiesDefeated,
        'vip': vip,
        'luckySpinsLeft': luckySpinsLeft,
        'turboConvertReady': turboConvertReady,
        'lastSpinDay': lastSpinDay,
        'lang': lang.name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        email: j['email'] as String,
        password: j['password'] as String,
        displayName: j['displayName'] as String? ?? 'Player',
        cash: (j['cash'] as num?)?.toDouble() ?? 0,
        sharks: j['sharks'] as int? ?? 0,
        points: j['points'] as int? ?? 0,
        freeSpins: j['freeSpins'] as int? ?? 0,
        lives: j['lives'] as int? ?? 3,
        spinsPlayed: j['spinsPlayed'] as int? ?? 0,
        enemiesDefeated: j['enemiesDefeated'] as int? ?? 0,
        vip: j['vip'] as bool? ?? false,
        luckySpinsLeft: j['luckySpinsLeft'] as int? ?? 0,
        turboConvertReady: j['turboConvertReady'] as bool? ?? false,
        lastSpinDay: j['lastSpinDay'] as String? ?? '',
        lang: AppLang.values.firstWhere(
          (e) => e.name == (j['lang'] as String? ?? 'pt'),
          orElse: () => AppLang.pt,
        ),
      );
}

class AppState extends ChangeNotifier {
  static const _usersKey = 'cashark_users_v1';
  static const _sessionKey = 'cashark_session_v1';
  static const _langKey = 'cashark_lang_v1';
  static const _langPickedKey = 'cashark_lang_picked_v1';

  final _rng = Random();
  SharedPreferences? _prefs;

  UserProfile? user;
  AppLang lang = AppLang.pt;
  bool langPicked = false;
  bool ready = false;
  bool spinning = false;

  L10n get l10n => L10n(lang);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _ensureTestAccount();
    final langCode = _prefs!.getString(_langKey);
    if (langCode != null) {
      lang = AppLang.values.firstWhere(
        (e) => e.name == langCode,
        orElse: () => AppLang.pt,
      );
    }
    langPicked = _prefs!.getBool(_langPickedKey) ?? false;
    final session = _prefs!.getString(_sessionKey);
    if (session != null) {
      final users = _loadUsers();
      final u = users[session];
      if (u != null) {
        user = u;
        lang = u.lang;
        _refreshDailySpins();
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _ensureTestAccount() async {
    final users = _loadUsers();
    if (!users.containsKey('teste_samsung@email.com')) {
      users['teste_samsung@email.com'] = UserProfile(
        email: 'teste_samsung@email.com',
        password: 'SenhaTeste123',
        displayName: 'Samsung Reviewer',
        cash: 1.50,
        sharks: 120,
        points: 250,
        freeSpins: EconomyConfig.dailyFreeSpins + 3,
        lives: EconomyConfig.maxLives,
      );
      await _saveUsers(users);
    }
  }

  Map<String, UserProfile> _loadUsers() {
    final raw = _prefs?.getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, UserProfile.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> _saveUsers(Map<String, UserProfile> users) async {
    final encoded = jsonEncode(users.map((k, v) => MapEntry(k, v.toJson())));
    await _prefs!.setString(_usersKey, encoded);
  }

  Future<void> _persistUser() async {
    if (user == null) return;
    final users = _loadUsers();
    users[user!.email] = user!;
    await _saveUsers(users);
  }

  void _refreshDailySpins() {
    if (user == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (user!.lastSpinDay != today) {
      final bonus = user!.vip ? 1 : 0;
      user!.freeSpins = EconomyConfig.dailyFreeSpins + bonus;
      user!.lastSpinDay = today;
      _persistUser();
    }
  }

  Future<void> setLanguage(AppLang value) async {
    lang = value;
    langPicked = true;
    await _prefs!.setString(_langKey, value.name);
    await _prefs!.setBool(_langPickedKey, true);
    if (user != null) {
      user!.lang = value;
      await _persistUser();
    }
    notifyListeners();
  }

  Future<String?> register(String email, String password, String name) async {
    email = email.trim().toLowerCase();
    if (!_validEmail(email) || password.length < 6 || name.trim().isEmpty) {
      return l10n.t('invalid_login');
    }
    final users = _loadUsers();
    if (users.containsKey(email)) return l10n.t('invalid_login');
    final u = UserProfile(
      email: email,
      password: password,
      displayName: name.trim(),
      lang: lang,
    );
    users[email] = u;
    await _saveUsers(users);
    user = u;
    await _prefs!.setString(_sessionKey, email);
    notifyListeners();
    return null;
  }

  Future<String?> login(String email, String password) async {
    email = email.trim().toLowerCase();
    final users = _loadUsers();
    final u = users[email];
    if (u == null || u.password != password) return l10n.t('invalid_login');
    user = u;
    lang = u.lang;
    _refreshDailySpins();
    await _prefs!.setString(_sessionKey, email);
    await _persistUser();
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    user = null;
    await _prefs!.remove(_sessionKey);
    notifyListeners();
  }

  bool _validEmail(String e) => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(e);

  /// House-edge spin: weighted symbol + small drip rewards.
  /// Call [beginSpin]/[endSpin] around the wheel animation from the UI.
  Future<SpinResult?> spinRoulette() async {
    if (user == null) return null;
    _refreshDailySpins();
    if (user!.freeSpins <= 0) return null;

    final lucky = user!.luckySpinsLeft > 0;
    final coinW = lucky ? EconomyConfig.luckyCoinWeight : EconomyConfig.coinWeight;
    final roll = _rng.nextDouble();
    final symbol = roll < coinW ? RouletteSymbol.coin : RouletteSymbol.shark;

    late SpinResult result;
    if (symbol == RouletteSymbol.shark) {
      final n = EconomyConfig.sharksWinMin +
          _rng.nextInt(EconomyConfig.sharksWinMax - EconomyConfig.sharksWinMin + 1);
      user!.sharks += n;
      user!.points += n * 2;
      result = SpinResult(symbol: symbol, sharks: n, cash: 0);
    } else {
      final c = EconomyConfig.cashWinMin +
          _rng.nextDouble() * (EconomyConfig.cashWinMax - EconomyConfig.cashWinMin);
      final rounded = double.parse(c.toStringAsFixed(2));
      user!.cash += rounded;
      user!.points += (rounded * 100).round();
      result = SpinResult(symbol: symbol, sharks: 0, cash: rounded);
    }

    user!.freeSpins -= 1;
    if (lucky) user!.luckySpinsLeft -= 1;
    user!.spinsPlayed += 1;
    await _persistUser();
    notifyListeners();
    return result;
  }

  void beginSpin() {
    spinning = true;
    notifyListeners();
  }

  void endSpin() {
    spinning = false;
    notifyListeners();
  }

  Future<String?> convertSharks() async {
    if (user == null) return l10n.t('need_sharks');
    if (user!.sharks < EconomyConfig.sharksPerConversion) {
      return l10n.t('need_sharks');
    }
    final blocks = user!.sharks ~/ EconomyConfig.sharksPerConversion;
    final used = blocks * EconomyConfig.sharksPerConversion;
    final rate = user!.turboConvertReady
        ? EconomyConfig.boostedConversionCash
        : EconomyConfig.cashPerConversion;
    final gained = double.parse((blocks * rate).toStringAsFixed(2));
    user!.sharks -= used;
    user!.cash += gained;
    user!.turboConvertReady = false;
    user!.points += blocks * 10;
    await _persistUser();
    notifyListeners();
    return l10n.t('converted', vars: {'s': '$used', 'c': gained.toStringAsFixed(2)});
  }

  /// Locks cash while a real payout is submitted to the backend.
  Future<String?> lockCashForCashout(double amount) async {
    if (user == null) return l10n.t('cashout_need');
    final a = double.parse(amount.toStringAsFixed(2));
    if (a < EconomyConfig.minCashEuro) return l10n.t('cashout_need');
    if (user!.cash + 0.001 < a) return l10n.t('not_enough');
    user!.cash = double.parse((user!.cash - a).toStringAsFixed(2));
    user!.points += 25;
    await _persistUser();
    notifyListeners();
    return null;
  }

  Future<void> refundCashout(double amount) async {
    if (user == null) return;
    user!.cash = double.parse((user!.cash + amount).toStringAsFixed(2));
    await _persistUser();
    notifyListeners();
  }

  @Deprecated('Use CashoutScreen + lockCashForCashout')
  Future<String?> requestCashout() async {
    if (user == null) return l10n.t('cashout_need');
    if (user!.cash < EconomyConfig.minCashEuro) return l10n.t('cashout_need');
    user!.cash = double.parse((user!.cash - EconomyConfig.minCashEuro).toStringAsFixed(2));
    user!.points += 50;
    await _persistUser();
    notifyListeners();
    return l10n.t('cashout_ok');
  }

  Future<void> addSpinsFromAd() async {
    if (user == null) return;
    user!.freeSpins += EconomyConfig.adBonusSpins;
    await _persistUser();
    notifyListeners();
  }

  Future<void> addLifeFromAd() async {
    if (user == null) return;
    user!.lives = (user!.lives + 1).clamp(0, 99);
    await _persistUser();
    notifyListeners();
  }

  Future<String?> buyLifeWithCash() async {
    if (user == null) return l10n.t('not_enough');
    if (user!.cash < EconomyConfig.lifePriceCash) return l10n.t('not_enough');
    user!.cash = double.parse((user!.cash - EconomyConfig.lifePriceCash).toStringAsFixed(2));
    user!.lives += 1;
    await _persistUser();
    notifyListeners();
    return null;
  }

  Future<String?> buyLifeWithSharks() async {
    if (user == null) return l10n.t('not_enough');
    if (user!.sharks < EconomyConfig.lifePriceSharks) return l10n.t('not_enough');
    user!.sharks -= EconomyConfig.lifePriceSharks;
    user!.lives += 1;
    await _persistUser();
    notifyListeners();
    return null;
  }

  void loseLife() {
    if (user == null) return;
    if (user!.lives > 0) user!.lives -= 1;
    _persistUser();
    notifyListeners();
  }

  void registerKill() {
    if (user == null) return;
    user!.sharks += EconomyConfig.casharkPerKill;
    user!.enemiesDefeated += 1;
    user!.points += 5;
    _persistUser();
    notifyListeners();
  }

  Future<String?> purchaseShopItem(ShopItem item, {bool useSharks = false}) async {
    if (user == null) return l10n.t('not_enough');
    if (item.kind == 'vip' && user!.vip) return l10n.t('owned');

    if (useSharks) {
      final cost = item.priceSharks;
      if (cost == null || user!.sharks < cost) return l10n.t('not_enough');
      user!.sharks -= cost;
    } else {
      // Simulated IAP — real billing wires to Play Billing / Galaxy Store later.
      // For demo/review, deducting from cash if available else grant as paid unlock.
      if (user!.cash >= item.priceEuro) {
        user!.cash = double.parse((user!.cash - item.priceEuro).toStringAsFixed(2));
      }
      // Always grant — simulates successful store purchase for review flow.
    }

    switch (item.kind) {
      case 'lives':
        user!.lives += EconomyConfig.lifePackSize;
        break;
      case 'spins':
        user!.freeSpins += 10;
        break;
      case 'lucky':
        user!.luckySpinsLeft += EconomyConfig.luckySpinsCount;
        break;
      case 'double':
        user!.turboConvertReady = true;
        break;
      case 'sharks':
        user!.sharks += 150;
        break;
      case 'vip':
        user!.vip = true;
        user!.freeSpins += 1;
        break;
      case 'bundle':
        user!.lives += 5;
        user!.freeSpins += 8;
        user!.sharks += 60;
        break;
    }
    user!.points += 25;
    await _persistUser();
    notifyListeners();
    return null;
  }
}

class SpinResult {
  final RouletteSymbol symbol;
  final int sharks;
  final double cash;
  SpinResult({required this.symbol, required this.sharks, required this.cash});
}
