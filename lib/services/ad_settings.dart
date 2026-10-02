import '../config.dart';

final RegExp _gameIdRe = RegExp(r'^[0-9]{4,12}$');
final RegExp _placementRe = RegExp(r'^[A-Za-z0-9_\-]{3,60}$');

/// إعدادات الإعلانات. القيم الافتراضية آمنة (بدون Game ID لا تظهر إعلانات)،
/// ويمكن تعديلها من content.json (كتلة "ads") دون تحديث التطبيق.
/// الحدود الدنيا والعليا تمنع أي إعداد خاطئ من جعل الإعلانات مزعجة.
class AdSettings {
  final bool enabled;
  final bool banner;
  final bool interstitial;
  final bool rewarded;
  final bool testMode;
  final String gameId;
  final String bannerPlacement;
  final String interstitialPlacement;
  final String rewardedPlacement;

  /// كم شاشة محتوى يغلقها المستخدم قبل أن يصبح الإعلان البيني مؤهلاً.
  final int interstitialEvery;

  /// أقل فاصل بين إعلانين بينيين بالثواني.
  final int minSecondsBetween;

  /// لا إعلان بيني في أول هذه المدة بعد فتح التطبيق.
  final int firstAdAfterSeconds;

  /// أقصى عدد إعلانات بينية في اليوم.
  final int dailyCap;

  /// مدة إخفاء الإعلانات (بالساعات) بعد مشاهدة إعلان مكافأة.
  final int adFreeHours;

  const AdSettings({
    required this.enabled,
    required this.banner,
    required this.interstitial,
    required this.rewarded,
    required this.testMode,
    required this.gameId,
    required this.bannerPlacement,
    required this.interstitialPlacement,
    required this.rewardedPlacement,
    required this.interstitialEvery,
    required this.minSecondsBetween,
    required this.firstAdAfterSeconds,
    required this.dailyCap,
    required this.adFreeHours,
  });

  factory AdSettings.defaults() => const AdSettings(
        enabled: true,
        banner: true,
        interstitial: true,
        rewarded: true,
        testMode: AppConfig.unityTestMode,
        gameId: AppConfig.unityGameId,
        bannerPlacement: 'BP_Banner_Android',
        interstitialPlacement: 'BP_Interstitial_Android',
        rewardedPlacement: 'BP_Rewarded_Android',
        interstitialEvery: 5,
        minSecondsBetween: 240,
        firstAdAfterSeconds: 120,
        dailyCap: 6,
        adFreeHours: 24,
      );

  /// هل الإعلانات مفعّلة فعلاً (يوجد Game ID صالح).
  bool get active => enabled && _gameIdRe.hasMatch(gameId);

  static bool _b(Object? v, bool d) => v is bool ? v : d;
  static String _id(Object? v, String d, RegExp re) =>
      (v is String && re.hasMatch(v.trim())) ? v.trim() : d;
  static int _i(Object? v, int d, int min, int max) =>
      v is num ? v.toInt().clamp(min, max).toInt() : d;

  factory AdSettings.fromJson(Object? raw) {
    final d = AdSettings.defaults();
    if (raw is! Map) return d;
    return AdSettings(
      enabled: _b(raw['enabled'], d.enabled),
      banner: _b(raw['banner'], d.banner),
      interstitial: _b(raw['interstitial'], d.interstitial),
      rewarded: _b(raw['rewarded'], d.rewarded),
      testMode: _b(raw['testMode'], d.testMode),
      gameId: _id(
        raw['gameId'] is num ? '${raw['gameId']}' : raw['gameId'],
        d.gameId,
        _gameIdRe,
      ),
      bannerPlacement: _id(
        raw['bannerPlacement'],
        d.bannerPlacement,
        _placementRe,
      ),
      interstitialPlacement: _id(
        raw['interstitialPlacement'],
        d.interstitialPlacement,
        _placementRe,
      ),
      rewardedPlacement: _id(
        raw['rewardedPlacement'],
        d.rewardedPlacement,
        _placementRe,
      ),
      interstitialEvery: _i(
        raw['interstitialEvery'],
        d.interstitialEvery,
        3,
        30,
      ),
      minSecondsBetween: _i(
        raw['minSecondsBetween'],
        d.minSecondsBetween,
        90,
        3600,
      ),
      firstAdAfterSeconds: _i(
        raw['firstAdAfterSeconds'],
        d.firstAdAfterSeconds,
        60,
        1800,
      ),
      dailyCap: _i(raw['dailyCap'], d.dailyCap, 0, 12),
      adFreeHours: _i(raw['adFreeHours'], d.adFreeHours, 1, 72),
    );
  }
}
