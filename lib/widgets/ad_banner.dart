import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../services/ad_service.dart';

/// بانر Unity صغير (320x50) في أسفل الشاشة. لا يأخذ أي مساحة إذا كانت الإعلانات
/// غير مفعّلة أو أُخفيت أو فشل تحميلها.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdService.instance,
      builder: (context, _) {
        final ad = AdService.instance;
        if (!ad.bannersActive) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Center(
              child: UnityBannerAd(
                placementId: ad.settings.bannerPlacement,
                size: BannerSize.standard,
                onFailed: (placementId, error, message) => ad.bannerFailed(),
              ),
            ),
          ),
        );
      },
    );
  }
}
