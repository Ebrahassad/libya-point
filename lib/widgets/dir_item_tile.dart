import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/directory.dart';
import '../services/app_state.dart';
import 'open_link.dart';

/// بطاقة الجهة: عدة روابط في مكان واحد + مصدر ووقت التحقق + مفضلة.
class DirItemTile extends StatelessWidget {
  final DirItem item;
  final Color accent;
  const DirItemTile({super.key, required this.item, required this.accent});

  String _label(DirAction action) {
    if (action.label.isNotEmpty && !action.label.startsWith('open_')) {
      return action.label;
    }
    switch (action.kind) {
      case LinkKind.web:
        return 'open_site'.tr();
      case LinkKind.phone:
        return 'call'.tr();
      case LinkKind.app:
        return action.package != null
            ? 'download_play'.tr()
            : 'search_play'.tr();
      case LinkKind.email:
        return 'email'.tr();
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: item.uri.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('link_copied'.tr())));
  }

  Future<void> _copyCard(BuildContext context) async {
    final lines = <String>[item.title, item.desc];
    if (item.source != null) lines.add('${'source'.tr()}: ${item.source}');
    if (item.verifiedAt != null) {
      lines.add('${'verified'.tr()}: ${item.verifiedAt}');
    }
    for (final a in item.visibleActions) {
      lines.add('${a.label}: ${a.uri}');
    }
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('card_copied'.tr())));
  }

  Future<void> _reportLink(BuildContext context) async {
    final report = [
      '${'broken_link_item'.tr()}: ${item.title}',
      '${'broken_link_id'.tr()}: ${item.id ?? '-'}',
      '${'broken_link_url'.tr()}: ${item.uri}',
      if (item.source != null) '${'source'.tr()}: ${item.source}',
      '${'verified'.tr()}: ${item.verifiedAt ?? '-'}',
    ].join('\n');

    if (AppConfig.contactEmail.trim().isEmpty) {
      await Clipboard.setData(ClipboardData(text: report));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('report_copied'.tr())));
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.contactEmail,
      queryParameters: {
        'subject': '${'report_link'.tr()}: ${item.title}',
        'body': report,
      },
    );
    await openUri(context, uri);
  }

  void _more(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text('copy_link'.tr()),
              onTap: () {
                Navigator.pop(sheetContext);
                _copyLink(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_books_outlined),
              title: Text('copy_card'.tr()),
              onTap: () {
                Navigator.pop(sheetContext);
                _copyCard(context);
              },
            ),
            if (item.sourceUrl != null)
              ListTile(
                leading: const Icon(Icons.source_outlined),
                title: Text('open_source'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  openUri(context, Uri.parse(item.sourceUrl!));
                },
              ),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_outlined),
              title: Text('report_link'.tr()),
              onTap: () {
                Navigator.pop(sheetContext);
                _reportLink(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final fav = AppState.instance.isFavorite(item.key);
        return Card(
          elevation: item.official ? 1.5 : 1,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (item.official)
                      Container(
                        margin: const EdgeInsetsDirectional.only(
                          start: 6,
                          top: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 15,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'official'.tr(),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'nav_favorites'.tr(),
                      icon: Icon(
                        fav ? Icons.star : Icons.star_border,
                        color: fav ? Colors.amber : null,
                      ),
                      onPressed: () =>
                          AppState.instance.toggleFavorite(item.key),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'more'.tr(),
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _more(context),
                    ),
                  ],
                ),
                if (item.tag != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.tag!.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(
                    item.desc,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (item.source != null || item.verifiedAt != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (item.source != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.source_outlined,
                              size: 14,
                              color: Theme.of(context).hintColor,
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width * .58,
                              child: Text(
                                '${'source'.tr()}: ${item.source}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (item.verifiedAt != null)
                        Text(
                          '${'verified'.tr()}: ${item.verifiedAt}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final action in item.visibleActions)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(
                            color: accent.withValues(alpha: .35),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 9,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: Icon(action.iconData, size: 17),
                        label: Text(
                          _label(action),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => openUri(context, action.uri),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
