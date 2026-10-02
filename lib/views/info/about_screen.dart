import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config.dart';
import '../../services/content_store.dart';
import '../../widgets/open_link.dart';

/// نبذة تعريفية عن التطبيق والمطور.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _features = [
    'about_f1',
    'about_f2',
    'about_f3',
    'about_f4',
    'about_f5',
    'about_f6',
    'about_f7',
  ];

  @override
  Widget build(BuildContext context) {
    final store = ContentStore.instance;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('about_title'.tr()), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/libya_icon.jpg',
                width: 110,
                height: 110,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'app_title'.tr(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          if (store.appVersion.isNotEmpty)
            Center(
              child: Text(
                '${'version'.tr()} ${store.appVersion}',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'about_desc'.tr(),
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
          if (store.aboutExtra != null) ...[
            const SizedBox(height: 8),
            Text(
              store.aboutExtra!,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'about_features'.tr(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          for (final f in _features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f.tr(), style: const TextStyle(height: 1.4)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/hassadi_icon.png',
                          width: 56,
                          height: 56,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: scheme.primaryContainer,
                            child: Icon(Icons.code, color: scheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'developer_title'.tr(),
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            const Text(
                              'HASSADI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'developer_desc'.tr(),
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: Text('developer_open'.tr()),
                      onPressed: () =>
                          openUri(context, Uri.parse(AppConfig.developerUrl)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'disclaimer'.tr(),
            style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}
