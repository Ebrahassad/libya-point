import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/directory.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/dir_item_tile.dart';

String _norm(String s) => s
    .replaceAll(RegExp('[\u064B-\u065F]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .toLowerCase()
    .trim();

/// شاشة القسم: عنوان/وصف/بحث/بطاقات متعددة الروابط.
class SectionScreen extends StatefulWidget {
  final DirSection section;
  const SectionScreen({super.key, required this.section});

  @override
  State<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  String _q = '';

  bool get _adFreeSection => const {
        'state',
        'citizen',
        'banks',
        'complaints',
        'emergency',
      }.contains(widget.section.id);

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final q = _norm(_q);
    return Scaffold(
      appBar: AppBar(title: Text(sectionTitle(section)), centerTitle: true),
      bottomNavigationBar: _adFreeSection ? null : const AdBanner(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (sectionSubtitle(section).isNotEmpty)
            Text(
              sectionSubtitle(section),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).hintColor,
                height: 1.35,
              ),
            ),
          if (sectionSubtitle(section).isNotEmpty) const SizedBox(height: 8),
          Row(
            children: [
              Icon(section.icon, color: section.color),
              const SizedBox(width: 8),
              Text(
                'items_count'.tr(args: ['${section.count}']),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          if (section.count > 6) ...[
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'section_search'.tr(),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          for (final g in section.groups) ...[
            Builder(
              builder: (context) {
                final items = g.items
                    .where(
                      (i) =>
                          q.isEmpty ||
                          _norm(i.title).contains(q) ||
                          _norm(i.desc).contains(q) ||
                          (i.source != null && _norm(i.source!).contains(q)),
                    )
                    .toList();
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (g.title.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          g.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: section.color,
                          ),
                        ),
                      ),
                    for (final item in items)
                      DirItemTile(item: item, accent: section.color),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'directory_source_note'.tr(),
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
