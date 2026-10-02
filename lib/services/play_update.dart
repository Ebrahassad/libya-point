import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// تحديث داخل التطبيق عبر جوجل بلاي (يعمل فقط للنسخة المثبّتة من المتجر).
/// يُنزَّل التحديث في الخلفية أثناء استخدام التطبيق، ثم يُعرض زر «إعادة التشغيل».
/// أي خطأ (نسخة غير مثبّتة من المتجر، لا تحديث، إلخ) يُتجاهل بصمت.
Future<bool> downloadPlayUpdateIfAny() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable ||
        !info.flexibleUpdateAllowed) {
      return false;
    }
    final result = await InAppUpdate.startFlexibleUpdate();
    return result == AppUpdateResult.success;
  } catch (_) {
    return false;
  }
}

Future<void> installPlayUpdate() async {
  try {
    await InAppUpdate.completeFlexibleUpdate();
  } catch (_) {}
}
