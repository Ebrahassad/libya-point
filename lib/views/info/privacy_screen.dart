import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config.dart';
import '../../widgets/open_link.dart';

/// سياسة الخصوصية (نسخة كاملة تعمل بدون إنترنت).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    'data',
    'local',
    'third',
    'links',
    'form',
    'ads',
    'kids',
    'contact',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('privacy_title'.tr()), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'privacy_updated'.tr(),
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 10),
          Text('privacy_intro'.tr(), style: const TextStyle(height: 1.6)),
          for (final s in _sections) ...[
            const SizedBox(height: 16),
            Text(
              'p_${s}_t'.tr(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('p_${s}_b'.tr(), style: const TextStyle(height: 1.6)),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text('privacy_web'.tr()),
            onPressed: () => openUri(context, Uri.parse(AppConfig.privacyUrl)),
          ),
        ],
      ),
    );
  }
}
