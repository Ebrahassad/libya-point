import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/cities.dart';
import '../../widgets/open_link.dart';

/// نبذة عن ليبيا: حقائق أساسية والمناطق والمدن.
class AboutLibyaScreen extends StatelessWidget {
  const AboutLibyaScreen({super.key});

  static const _facts = [
    ('capital', Icons.location_city),
    ('area', Icons.square_foot),
    ('population', Icons.groups),
    ('language', Icons.translate),
    ('currency', Icons.attach_money),
    ('independence', Icons.flag),
    ('neighbors', Icons.public),
    ('coast', Icons.waves),
    ('climate', Icons.thermostat),
    ('economy', Icons.oil_barrel),
    ('unesco', Icons.account_balance),
    ('dial', Icons.phone),
    ('time', Icons.schedule),
  ];

  @override
  Widget build(BuildContext context) {
    final regions = <String>[];
    for (final c in libyaCities) {
      if (!regions.contains(c.region)) regions.add(c.region);
    }
    return Scaffold(
      appBar: AppBar(title: Text('libya_title'.tr()), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'libya_intro'.tr(),
            style: const TextStyle(fontSize: 15, height: 1.7),
          ),
          const SizedBox(height: 14),
          for (final f in _facts)
            Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  f.$2,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'lf_${f.$1}'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'lv_${f.$1}'.tr(),
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            'libya_regions'.tr(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          for (final r in regions)
            Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      libyaCities
                          .where((c) => c.region == r)
                          .map((c) => c.name)
                          .join('، '),
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text('libya_more'.tr()),
            onPressed: () => openUri(
              context,
              Uri.parse(
                'https://ar.wikipedia.org/wiki/%D9%84%D9%8A%D8%A8%D9%8A%D8%A7',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
