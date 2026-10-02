import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/directory.dart';

import '../../services/app_state.dart';
import '../../widgets/dir_item_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('favorites_title'.tr()), centerTitle: true),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final favs = allSearchableItems()
              .where((i) => AppState.instance.isFavorite(i.key))
              .toList();
          if (favs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'favorites_empty'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final i in favs)
                DirItemTile(
                  item: i,
                  accent: Theme.of(context).colorScheme.primary,
                ),
            ],
          );
        },
      ),
    );
  }
}
