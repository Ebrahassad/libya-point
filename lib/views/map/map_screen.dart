import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/cities.dart';
import '../../data/directory.dart';
import '../../services/app_state.dart';
import '../../widgets/city_picker.dart';
import '../../widgets/open_link.dart';

/// خريطة ليبيا بكل المدن. الضغط على مدينة يفتح خدمات قريبة عبر خرائط جوجل.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _controller = MapController();

  @override
  void initState() {
    super.initState();
    // بعد أول رسم: نركّز على المدينة المختارة إن وُجدت.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusSelected());
  }

  void _focusSelected() {
    final c = cityByName(AppState.instance.city);
    if (c != null) _controller.move(LatLng(c.lat, c.lng), 10);
  }

  void _showCity(LibyaCity c) {
    AppState.instance.setCity(c.name);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(c.region, style: TextStyle(color: Theme.of(ctx).hintColor)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in nearbyKinds)
                    ActionChip(
                      avatar: Icon(k.icon, size: 18, color: k.color),
                      label: Text('near_${k.id}'.tr()),
                      onPressed: () {
                        Navigator.pop(ctx);
                        openUri(context, mapsSearchUri(k.query, c.name));
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: Text('open_in_maps'.tr()),
                onPressed: () => openUri(
                  context,
                  Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${c.lat},${c.lng}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('map_title'.tr()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_city),
            tooltip: 'choose_city'.tr(),
            onPressed: () async {
              await showCityPicker(context);
              _focusSelected();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: const MapOptions(
              initialCenter: LatLng(28.5, 17.5),
              initialZoom: 5.2,
              minZoom: 4,
              maxZoom: 17,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hassadi.libya_point',
              ),
              MarkerLayer(
                markers: [
                  for (final c in libyaCities)
                    Marker(
                      point: LatLng(c.lat, c.lng),
                      width: 90,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showCity(c),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 30,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text('map_hint'.tr(), textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
