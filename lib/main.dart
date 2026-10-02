import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'services/ad_service.dart';
import 'services/app_state.dart';
import 'services/content_store.dart';
import 'services/live_data.dart';
import 'views/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await AppState.instance.load();
  // بدء جلب البيانات المباشرة في الخلفية دون انتظار.
  LiveData.instance.start();
  // المحتوى البعيد (روابط، تطبيقات، فنادق، إعلانات) يصل دون تحديث من المتجر.
  ContentStore.instance.start();
  // الإعلانات: لا تعمل إلا بعد وضع Game ID (انظر README).
  AdService.instance.start();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const LibyaPointApp(),
    ),
  );
}

class LibyaPointApp extends StatelessWidget {
  const LibyaPointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (_) => 'app_title'.tr(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1976D2),
          brightness: Brightness.light,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF1976D2),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        themeMode: AppState.instance.dark ? ThemeMode.dark : ThemeMode.light,
        home: const HomeScreen(),
      ),
    );
  }
}
