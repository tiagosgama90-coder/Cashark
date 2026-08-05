import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Balanced ads: rewarded only, never interstitial spam that traps navigation.
class AdsService extends ChangeNotifier {
  static const rewardedUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Google test ID

  bool initialized = false;
  bool loading = false;
  RewardedAd? _rewarded;
  bool _loadFailed = false;

  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      initialized = true;
      await preload();
    } catch (_) {
      initialized = false;
    }
    notifyListeners();
  }

  Future<void> preload() async {
    if (loading) return;
    loading = true;
    _loadFailed = false;
    notifyListeners();
    await RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          loading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          _rewarded = null;
          loading = false;
          _loadFailed = true;
          notifyListeners();
          // Soft fallback — still allow offline demo rewards after short delay.
        },
      ),
    );
  }

  /// Shows a rewarded ad when available; falls back to simulated reward offline.
  Future<bool> showRewarded({required VoidCallback onReward}) async {
    final ad = _rewarded;
    if (ad != null) {
      final completer = Completer<bool>();
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewarded = null;
          preload();
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _rewarded = null;
          preload();
          // Fallback so UX never hard-locks.
          onReward();
          if (!completer.isCompleted) completer.complete(true);
        },
      );
      await ad.show(
        onUserEarnedReward: (_, __) {
          onReward();
        },
      );
      return completer.future;
    }

    // Offline / load-failed path for Samsung review without network ads.
    if (_loadFailed || !initialized) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      onReward();
      preload();
      return true;
    }
    await preload();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    onReward();
    return true;
  }
}
