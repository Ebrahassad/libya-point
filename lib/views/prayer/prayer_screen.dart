import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/cities.dart';
import '../../services/app_state.dart';
import '../../services/prayer.dart';
import '../../widgets/city_picker.dart';

/// أوقات الصلاة للمدينة المختارة (طرابلس إن لم تُختر مدينة).
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Future<Map<String, String>?>? _future;
  String _loadedCity = '';

  void _load() {
    final name = AppState.instance.cityOrDefault;
    final c = cityByName(name) ?? libyaCities.first;
    _loadedCity = c.name;
    _future = fetchPrayerTimes(c.lat, c.lng);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _nextPrayer(Map<String, String> t) {
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    for (final k in prayerOrder) {
      if (k == 'Sunrise') continue;
      final parts = t[k]!.split(':');
      final m = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (m > nowMin) return k;
    }
    return 'Fajr';
  }

  IconData _icon(String k) {
    switch (k) {
      case 'Fajr':
        return Icons.nights_stay;
      case 'Sunrise':
        return Icons.wb_twilight;
      case 'Dhuhr':
        return Icons.wb_sunny;
      case 'Asr':
        return Icons.wb_cloudy;
      case 'Maghrib':
        return Icons.wb_twilight;
      default:
        return Icons.bedtime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('prayer_title'.tr()), centerTitle: true),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          if (AppState.instance.cityOrDefault != _loadedCity) _load();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.location_city),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadedCity),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                onPressed: () => showCityPicker(context),
              ),
              const SizedBox(height: 14),
              FutureBuilder<Map<String, String>?>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final t = snap.data;
                  if (t == null) {
                    return Column(
                      children: [
                        Text('prayer_failed'.tr()),
                        TextButton(
                          onPressed: () => setState(_load),
                          child: Text('retry'.tr()),
                        ),
                      ],
                    );
                  }
                  final next = _nextPrayer(t);
                  return Column(
                    children: [
                      for (final k in prayerOrder)
                        Card(
                          elevation: k == next ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: k == next
                                ? BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    width: 1.5,
                                  )
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            leading: Icon(_icon(k)),
                            title: Text(
                              'prayer_$k'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              t[k]!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                'prayer_note'.tr(),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
