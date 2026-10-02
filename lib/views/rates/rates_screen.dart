import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../services/live_data.dart';
import '../../widgets/rates_view.dart';
import '../../widgets/ad_banner.dart';

class RatesScreen extends StatelessWidget {
  const RatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('rates_title'.tr()), centerTitle: true),
      bottomNavigationBar: const AdBanner(),
      body: RefreshIndicator(
        onRefresh: LiveData.instance.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: const [RatesView()],
        ),
      ),
    );
  }
}
