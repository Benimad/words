import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ad unit identifiers.
///
/// These are Google's **official test IDs** — they serve real test creatives
/// without risking a policy strike during development.
///
/// >  ⚠️ Before publishing, replace every value in [AdUnits] with your own unit
/// >  IDs from the AdMob console, and set your real app ID in
/// >  `android/app/src/main/AndroidManifest.xml`
/// >  (`com.google.android.gms.ads.APPLICATION_ID`).
abstract final class AdUnits {
  static const _androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _androidRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const _iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const _iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _iosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static String get banner =>
      Platform.isAndroid ? _androidBanner : _iosBanner;
  static String get interstitial =>
      Platform.isAndroid ? _androidInterstitial : _iosInterstitial;
  static String get rewarded =>
      Platform.isAndroid ? _androidRewarded : _iosRewarded;
}

/// Wraps the ads SDK behind a small, failure-tolerant API.
///
/// Two principles drive this design:
///
/// 1. **Ads may never break the game.** Every SDK call is wrapped; if the SDK
///    is missing, offline, or unsupported on the current platform, the service
///    quietly reports "no ad" and play continues. This is also what lets the
///    game run in unit tests and on desktop.
/// 2. **Ads may never feel punishing.** Interstitials are frequency-capped
///    (see [_minInterstitialGap] and [_levelsBetweenInterstitials]), never
///    shown to premium players, and never shown *before* the reward screen —
///    only after the player has seen their prize.
class AdService {
  AdService();

  bool _initialised = false;
  bool _available = false;

  /// Set from the player's premium status; suppresses all advertising.
  bool _adsRemoved = false;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  DateTime _lastInterstitial = DateTime.fromMillisecondsSinceEpoch(0);
  int _levelsSinceInterstitial = 0;

  /// Never show two interstitials closer together than this.
  static const _minInterstitialGap = Duration(minutes: 3);

  /// ...and never more often than every N completed levels.
  static const _levelsBetweenInterstitials = 4;

  bool get isAvailable => _available && !_adsRemoved;
  bool get adsRemoved => _adsRemoved;

  void setAdsRemoved(bool value) {
    _adsRemoved = value;
    if (value) {
      _interstitial?.dispose();
      _interstitial = null;
      _rewarded?.dispose();
      _rewarded = null;
    } else {
      _preloadAll();
    }
  }

  /// Initialises the SDK. Safe to call on any platform.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    // The ads SDK only exists on Android and iOS.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      debugPrint('AdService: unsupported platform — ads disabled.');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _available = true;
      _preloadAll();
    } catch (error) {
      debugPrint('AdService: initialisation failed ($error) — ads disabled.');
      _available = false;
    }
  }

  void _preloadAll() {
    if (!isAvailable) return;
    _loadInterstitial();
    _loadRewarded();
  }

  // --- Banner -----------------------------------------------------------

  /// Creates (but does not load) a banner. The caller owns disposal — see
  /// `BannerAdSlot` in the UI layer.
  BannerAd? createBanner({required void Function() onLoaded}) {
    if (!isAvailable) return null;
    try {
      return BannerAd(
        adUnitId: AdUnits.banner,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => onLoaded(),
          onAdFailedToLoad: (ad, error) {
            debugPrint('AdService: banner failed ($error).');
            ad.dispose();
          },
        ),
      );
    } catch (error) {
      debugPrint('AdService: could not create banner ($error).');
      return null;
    }
  }

  // --- Interstitial -----------------------------------------------------

  void _loadInterstitial() {
    if (!isAvailable || _interstitial != null) return;
    try {
      InterstitialAd.load(
        adUnitId: AdUnits.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _interstitial = ad,
          onAdFailedToLoad: (error) {
            debugPrint('AdService: interstitial failed to load ($error).');
            _interstitial = null;
          },
        ),
      );
    } catch (error) {
      debugPrint('AdService: interstitial load threw ($error).');
    }
  }

  /// True when the frequency caps allow an interstitial right now.
  bool get canShowInterstitial =>
      isAvailable &&
      _interstitial != null &&
      _levelsSinceInterstitial >= _levelsBetweenInterstitials &&
      DateTime.now().difference(_lastInterstitial) >= _minInterstitialGap;

  /// Call once per completed level so the cap can count.
  void registerLevelCompleted() => _levelsSinceInterstitial++;

  /// Shows an interstitial if the caps allow. Returns whether one was shown.
  /// Always completes — a failure just means "no ad was shown".
  Future<bool> maybeShowInterstitial() async {
    if (!canShowInterstitial) return false;

    final ad = _interstitial;
    if (ad == null) return false;
    _interstitial = null;

    try {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('AdService: interstitial show failed ($error).');
          ad.dispose();
          _loadInterstitial();
        },
      );
      await ad.show();
      _lastInterstitial = DateTime.now();
      _levelsSinceInterstitial = 0;
      return true;
    } catch (error) {
      debugPrint('AdService: interstitial threw on show ($error).');
      _loadInterstitial();
      return false;
    }
  }

  // --- Rewarded ---------------------------------------------------------

  void _loadRewarded() {
    if (!isAvailable || _rewarded != null) return;
    try {
      RewardedAd.load(
        adUnitId: AdUnits.rewarded,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) => _rewarded = ad,
          onAdFailedToLoad: (error) {
            debugPrint('AdService: rewarded failed to load ($error).');
            _rewarded = null;
          },
        ),
      );
    } catch (error) {
      debugPrint('AdService: rewarded load threw ($error).');
    }
  }

  /// True when a rewarded ad is ready to play. Note this ignores [_adsRemoved]
  /// deliberately *not* being checked separately: premium players keep the
  /// option to watch rewarded ads if they want free coins, but they are never
  /// forced to. (Set `isAvailable` to gate this if you prefer to hide them.)
  bool get isRewardedReady => _available && _rewarded != null;

  /// Shows a rewarded ad. Resolves `true` only if the reward was actually
  /// earned (the user watched enough of it).
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (!_available || ad == null) return false;
    _rewarded = null;

    var earned = false;
    try {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewarded();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('AdService: rewarded show failed ($error).');
          ad.dispose();
          _loadRewarded();
        },
      );
      await ad.show(
        onUserEarnedReward: (_, _) => earned = true,
      );
    } catch (error) {
      debugPrint('AdService: rewarded threw on show ($error).');
      _loadRewarded();
      return false;
    }
    return earned;
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
  }
}
