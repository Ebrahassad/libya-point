import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/directory.dart';
import '../../services/app_state.dart';
import '../../widgets/city_picker.dart';
import '../../widgets/open_link.dart';

/// مركز الطوارئ: أرقام حرجة + مصادر رسمية + خدمات قريبة.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const _nearbyIds = ['hospital', 'pharmacy', 'police', 'fuel'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('emergency_title'.tr()), centerTitle: true),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'emergency_note'.tr(),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'emergency_source_note'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'emergency_numbers'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final n in emergencyNumbers)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsetsDirectional.fromSTEB(
                      14,
                      4,
                      8,
                      4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: n.official
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                      child: Icon(
                        Icons.call,
                        color: n.official
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          n.phone ?? '',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${n.desc}\n${n.source ?? ''}${n.verifiedAt != null ? ' • ${'verified'.tr()}: ${n.verifiedAt}' : ''}',
                        style: const TextStyle(fontSize: 11, height: 1.35),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'more'.tr(),
                      onSelected: (value) {
                        if (value == 'copy') {
                          Clipboard.setData(ClipboardData(text: n.phone ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('number_copied'.tr())),
                          );
                        }
                        if (value == 'source' && n.sourceUrl != null) {
                          openUri(context, Uri.parse(n.sourceUrl!));
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'copy',
                          child: Text('copy_number'.tr()),
                        ),
                        if (n.sourceUrl != null)
                          PopupMenuItem(
                            value: 'source',
                            child: Text('open_source'.tr()),
                          ),
                      ],
                    ),
                    onTap: () => openUri(context, n.uri),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'security_and_services'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final id in const [
                'state-moi',
                'state-mod',
                'state-passports',
              ])
                _stateLink(context, id),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.hasCity
                          ? 'emergency_nearby'.tr(args: [s.city])
                          : 'nearby_pick_city'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.location_city),
                    label: Text('choose_city'.tr()),
                    onPressed: () => showCityPicker(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in nearbyKinds.where(
                    (k) => _nearbyIds.contains(k.id),
                  ))
                    ActionChip(
                      avatar: Icon(k.icon, size: 18, color: k.color),
                      label: Text('near_${k.id}'.tr()),
                      onPressed: () {
                        if (!s.hasCity) {
                          showCityPicker(context);
                          return;
                        }
                        openUri(context, mapsSearchUri(k.query, s.city));
                      },
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stateLink(BuildContext context, String id) {
    DirItem? item;
    for (final candidate in allDirectoryItems()) {
      if (candidate.id == id) {
        item = candidate;
        break;
      }
    }
    if (item == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.verified_user_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(item.desc),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => openUri(context, item!.uri),
      ),
    );
  }
}
