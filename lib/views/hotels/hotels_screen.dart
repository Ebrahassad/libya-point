import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../data/cities.dart';
import '../../data/directory.dart';
import '../../data/hotels.dart';
import '../../services/app_state.dart';
import '../../widgets/city_picker.dart';
import '../../widgets/dir_item_tile.dart';
import '../../widgets/open_link.dart';
import '../../widgets/ad_banner.dart';

/// الفنادق على مستوى المناطق والمدن: فنادق معروفة بأرقامها وصفحاتها وخرائطها،
/// وأزرار بحث جاهزة (خرائط جوجل وBooking) لكل مدينة.
class HotelsScreen extends StatelessWidget {
  const HotelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('hotels_title'.tr()), centerTitle: true),
      bottomNavigationBar: const AdBanner(),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'hotels_note'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.location_city),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.hasCity ? s.city : 'choose_city'.tr()),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                onPressed: () => showCityPicker(context),
              ),
              const SizedBox(height: 14),
              if (s.hasCity)
                _CityBlock(
                  city: s.city,
                  initiallyExpanded: true,
                  showHeader: true,
                )
              else
                for (final region in _regions())
                  Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      leading: const Icon(Icons.map),
                      title: Text(
                        region,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'hotels_count'.tr(args: ['${_regionCount(region)}']),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      children: [
                        for (final c in libyaCities.where(
                          (c) => c.region == region,
                        ))
                          _CityBlock(city: c.name),
                      ],
                    ),
                  ),
              const SizedBox(height: 10),
              Text(
                'hotels_sources'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final src in hotelSources)
                DirItemTile(
                  item: src,
                  accent: Theme.of(context).colorScheme.primary,
                ),
              Text(
                'disclaimer'.tr(),
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

  static List<String> _regions() {
    final r = <String>[];
    for (final c in libyaCities) {
      if (!r.contains(c.region)) r.add(c.region);
    }
    return r;
  }

  static int _regionCount(String region) {
    final names =
        libyaCities.where((c) => c.region == region).map((c) => c.name).toSet();
    return libyaHotels.where((h) => names.contains(h.city)).length;
  }
}

class _CityBlock extends StatelessWidget {
  final String city;
  final bool initiallyExpanded;
  final bool showHeader;
  const _CityBlock({
    required this.city,
    this.initiallyExpanded = false,
    this.showHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final hotels = hotelsInCity(city);
    final body = <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ActionChip(
            avatar: const Icon(Icons.map, size: 18, color: Colors.green),
            label: Text('hotels_search_maps'.tr(args: [city])),
            onPressed: () => openUri(context, mapsSearchUri('فندق', city)),
          ),
          ActionChip(
            avatar: const Icon(
              Icons.travel_explore,
              size: 18,
              color: Colors.blue,
            ),
            label: const Text('Booking.com'),
            onPressed: () => openUri(context, bookingSearchUri(city)),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (hotels.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'hotels_none'.tr(),
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
        )
      else
        for (final h in hotels) _HotelCard(hotel: h),
    ];

    if (showHeader) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            city,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...body,
        ],
      );
    }
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      leading: const Icon(Icons.location_city, size: 20),
      title: Text(city),
      subtitle: Text('hotels_count'.tr(args: ['${hotels.length}'])),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: body,
    );
  }
}

class _HotelCard extends StatelessWidget {
  final Hotel hotel;
  const _HotelCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hotel.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hotel.stars > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${hotel.stars}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                    ],
                  ),
              ],
            ),
            if (hotel.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  hotel.note,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (hotel.phoneLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  hotel.phoneLabel!,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.map, size: 18),
                  label: Text('hotel_map'.tr()),
                  onPressed: () => openUri(context, hotel.mapsUri),
                ),
                if (hotel.phoneUri != null)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.call, size: 18),
                    label: Text('call'.tr()),
                    onPressed: () => openUri(context, hotel.phoneUri!),
                  ),
                if (hotel.webUri != null)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text('hotel_page'.tr()),
                    onPressed: () => openUri(context, hotel.webUri!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
