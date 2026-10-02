/// إعدادات التطبيق. القيم التي تبدأ بـ fromEnvironment تُمرَّر وقت البناء:
///   flutter build apk --release --dart-define=OIL_API_KEY=xxxx
class AppConfig {
  /// مفتاح اختياري من oilpriceapi.com. إن وُجد يظهر سعر برنت داخل التطبيق،
  /// وإن لم يوجد تظهر بطاقة النفط بزر لفتح مصدر السعر فقط.
  static const String oilApiKey = String.fromEnvironment('OIL_API_KEY');

  /// بريد استقبال طلبات إضافة المتاجر (شاشة أضف متجرك).
  static const String contactEmail = String.fromEnvironment('CONTACT_EMAIL');

  /// كم دقيقة بين كل تحديث تلقائي للبيانات المباشرة.
  static const int refreshMinutes = 5;

  /// ملف المحتوى البعيد. أي تعديل عليه في GitHub يصل المستخدمين خلال دقائق
  /// دون تحديث من المتجر (روابط، تطبيقات، فنادق، أخبار، إعلانات).
  /// يجب أن يكون المستودع عاماً (public) ليقرأه التطبيق.
  static const String contentUrl = String.fromEnvironment(
    'CONTENT_URL',
    defaultValue: 'https://raw.githubusercontent.com/Ebrahassad/libya_point/main/content/content.json',
  );

  /// إعلانات Unity Ads. القيم الحقيقية تُضاف لاحقاً بإحدى طريقتين (انظر README):
  /// 1) في content/content.json داخل كتلة "ads" (تصل دون تحديث من المتجر)، أو
  /// 2) وقت البناء: --dart-define=UNITY_GAME_ID=1234567
  /// بدون Game ID لا تظهر أي إعلانات ولا يُحمَّل شيء.
  static const String unityGameId = String.fromEnvironment('UNITY_GAME_ID');

  /// وضع الاختبار (إعلانات تجريبية بلا أرباح). غيّره إلى false عند النشر.
  static const bool unityTestMode = bool.fromEnvironment(
    'UNITY_TEST_MODE',
    defaultValue: true,
  );

  /// معرّف التطبيق في جوجل بلاي (يطابق applicationId في build.gradle.kts).
  static const String playPackage = 'com.hassadi.libya_point';
  static const String playUrl =
      'https://play.google.com/store/apps/details?id=$playPackage';

  /// صفحة المطور.
  static const String developerUrl =
      'https://ebrahassad.github.io/Hassadi-Apps/#apps';

  /// سياسة الخصوصية على الويب (يجب تفعيل GitHub Pages للمستودع لتعمل).
  /// داخل التطبيق توجد نسخة كاملة تعمل بدون إنترنت.
  static const String privacyUrl =
      'https://ebrahassad.github.io/libya_point/privacy-policy.html';
}
