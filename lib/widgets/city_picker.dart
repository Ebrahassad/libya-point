import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../data/cities.dart';
import '../services/app_state.dart';

/// نافذة اختيار المدينة: قائمة بكل المدن الليبية مع بحث داخلها.
Future<void> showCityPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _CityPickerSheet(),
  );
}

String _norm(String s) => s
    .replaceAll(RegExp('[\u064B-\u065F]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .toLowerCase()
    .trim();

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet();

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _norm(_q);
    final matches = libyaCities
        .where((c) => q.isEmpty || _norm(c.name).contains(q))
        .toList();
    final regions = <String>[];
    for (final c in matches) {
      if (!regions.contains(c.region)) regions.add(c.region);
    }
    final height = MediaQuery.of(context).size.height * 0.75;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'city_search_hint'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: matches.isEmpty && q.isNotEmpty
                  ? Center(child: Text('no_results'.tr()))
                  : ListView(
                      children: [
                        if (q.isEmpty)
                          ListTile(
                            leading: const Icon(Icons.public),
                            title: Text('all_cities'.tr()),
                            trailing: AppState.instance.hasCity
                                ? null
                                : const Icon(Icons.check),
                            onTap: () {
                              AppState.instance.setCity(allCitiesLabel);
                              Navigator.pop(context);
                            },
                          ),
                        for (final r in regions) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              r,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          for (final c in matches.where((c) => c.region == r))
                            ListTile(
                              leading: const Icon(Icons.location_city),
                              title: Text(c.name),
                              trailing: AppState.instance.city == c.name
                                  ? const Icon(Icons.check)
                                  : null,
                              onTap: () {
                                AppState.instance.setCity(c.name);
                                Navigator.pop(context);
                              },
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
