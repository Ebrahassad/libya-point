import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import 'ad_settings.dart';
import 'content_store.dart';

/// إدارة إعلانات Unity بأسلوب غير مزعج:
/// - بانر صغير في أسفل شاشات القوائم فقط (لا في الطوارئ ولا الصلاة ولا النماذج).
/// - إعلان بيني نادر: بعد إغلاق عدة شاشات، وبفاصل زمني طويل، وبحد يومي،
///   ولا يظهر عند فتح التطبيق ولا عند الخروج.
/// - إعلان مكافأة اختياري يخفي كل الإعلانات عدة ساعات.
/// بدون Game ID صالح لا يحدث أي شيء.
class AdService extends ChangeNotifier {
  AdService._();
  static final AdService instance = AdService._();

  static const _kAdFree = 'ad_free_until';
  static const _kDay = 'ad_day';
  static const _kCount = 'ad_count';

  AdSettings settings = AdSettings.defaults();

  bool _initialized = false;
  bool _initStarted = false;
  bool _interReady = false;
  bool _interLoading = false;
  bool _showing = false;
  bool _started = false;
  int _screens = 0;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  final DateTime _startedAt = DateTime.now();
  DateTime? _adFreeUntil;
  DateTime? _bannerBlockedUntil;
  Timer? _retry;

  bool get adFree =>
      _adFreeUntil != null && _adFreeUntil!.isAfter(DateTime.now());
  DateTime? get adFreeUntil => adFree ? _adFreeUntil : null;

  bool get ready => settings.active && _initialized;

  bool get bannersActive =>
      ready &&
      settings.banner &&
      !adFree &&
      (_bannerBlockedUntil == null ||
          DateTime.now().isAfter(_bannerBlockedUntil!));

  bool get canOfferAdFree => ready && settings.rewarded && !adFree && !_showing;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_kAdFree);
      if (ms != null) _adFreeUntil = DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {}
    ContentStore.instance.addListener(_onContent);
    _onContent();
  }

  void _onContent() {
    settings = ContentStore.instance.ads;
    _maybeInit();
    notifyListeners();
  }

  void _maybeInit() {
    if (!settings.active || _initialized || _initStarted) return;
    _initStarted = true;
    try {
      UnityAds.init(
        gameId: settings.gameId,
        testMode: settings.testMode,
        onComplete: () {
          _initialized = true;
          _loadInterstitial();
          notifyListeners();
        },
        onFailed: (error, message) {
          _initStarted = false;
          _scheduleRetry();
        },
      );
    } catch (_) {
      _initStarted = false;
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _retry?.cancel();
    _retry = Timer(const Duration(minutes: 2), () {
      _maybeInit();
      _loadInterstitial();
    });
  }

  void _loadInterstitial() {
    if (!ready || !settings.interstitial || _interReady || _interLoading) {
      return;
    }
    _interLoading = true;
    try {
      UnityAds.load(
        placementId: settings.interstitialPlacement,
        onComplete: (id) {
          _interLoading = false;
          _interReady = true;
        },
        onFailed: (id, error, message) {
          _interLoading = false;
          _interReady = false;
          _scheduleRetry();
        },
      );
    } catch (_) {
      _interLoading = false;
    }
  }

  /// يُستدعى كلما أغلق المستخدم شاشة محتوى. يقرر هل يُعرض إعلان بيني الآن.
  Future<void> screenClosed() async {
    if (!ready || !settings.interstitial || adFree || _showing) return;
    _screens++;
    if (_screens < settings.interstitialEvery) return;
    final now = DateTime.now();
    if (now.difference(_startedAt).inSeconds < settings.firstAdAfterSeconds) {
      return;
    }
    if (now.difference(_lastShown).inSeconds < settings.minSecondsBetween) {
      return;
    }
    if (!_interReady) {
      _loadInterstitial();
      return;
    }
    if (!await _underDailyCap()) return;

    _showing = true;
    _interReady = false;
    try {
      UnityAds.showVideoAd(
        placementId: settings.interstitialPlacement,
        onStart: (id) {},
        onClick: (id) {},
        onSkipped: (id) => _afterInterstitial(shown: true),
        onComplete: (id) => _afterInterstitial(shown: true),
        onFailed: (id, error, message) => _afterInterstitial(shown: false),
      );
    } catch (_) {
      _afterInterstitial(shown: false);
    }
  }

  void _afterInterstitial({required bool shown}) {
    _showing = false;
    if (shown) {
      _screens = 0;
      _lastShown = DateTime.now();
      _countShown();
    }
    _loadInterstitial();
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _underDailyCap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_kDay) != _today()) return settings.dailyCap > 0;
      return (prefs.getInt(_kCount) ?? 0) < settings.dailyCap;
    } catch (_) {
      return true;
    }
  }

  Future<void> _countShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _today();
      final count = prefs.getString(_kDay) == today
          ? (prefs.getInt(_kCount) ?? 0)
          : 0;
      await prefs.setString(_kDay, today);
      await prefs.setInt(_kCount, count + 1);
    } catch (_) {}
  }

  /// البانر فشل تحميله: نخفيه دقيقتين حتى لا تبقى مساحة فارغة.
  void bannerFailed() {
    _bannerBlockedUntil = DateTime.now().add(const Duration(minutes: 2));
    scheduleMicrotask(notifyListeners);
  }

  /// مشاهدة إعلان مكافأة لإخفاء كل الإعلانات عدة ساعات. يعيد true عند النجاح.
  Future<bool> watchForAdFree() async {
    if (!canOfferAdFree) return false;
    _showing = true;
    try {
      final loaded = Completer<bool>();
      UnityAds.load(
        placementId: settings.rewardedPlacement,
        onComplete: (id) {
          if (!loaded.isCompleted) loaded.complete(true);
        },
        onFailed: (id, error, message) {
          if (!loaded.isCompleted) loaded.complete(false);
        },
      );
      final ok = await loaded.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
      if (!ok) return false;

      final done = Completer<bool>();
      UnityAds.showVideoAd(
        placementId: settings.rewardedPlacement,
        onStart: (id) {},
        onClick: (id) {},
        onSkipped: (id) {
          if (!done.isCompleted) done.complete(false);
        },
        onComplete: (id) {
          if (!done.isCompleted) done.complete(true);
        },
        onFailed: (id, error, message) {
          if (!done.isCompleted) done.complete(false);
        },
      );
      final rewarded = await done.future;
      if (rewarded) {
        _adFreeUntil = DateTime.now().add(
          Duration(hours: settings.adFreeHours),
        );
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_kAdFree, _adFreeUntil!.millisecondsSinceEpoch);
        } catch (_) {}
      }
      return rewarded;
    } catch (_) {
      return false;
    } finally {
      _showing = false;
      notifyListeners();
      _loadInterstitial();
    }
  }
}
