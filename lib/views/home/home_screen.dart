import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config.dart';
import '../../data/directory.dart';
import '../../services/ad_service.dart';
import '../../services/app_state.dart';
import '../../services/content_store.dart';
import '../../services/play_update.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/city_picker.dart';
import '../../widgets/dir_item_tile.dart';
import '../../widgets/open_link.dart';
import '../../widgets/ticker.dart';
import '../emergency/emergency_screen.dart';
import '../favorites/favorites_screen.dart';
import '../hotels/hotels_screen.dart';
import '../info/about_libya_screen.dart';
import '../info/about_screen.dart';
import '../info/privacy_screen.dart';
import '../map/map_screen.dart';
import '../merchant/merchant_screen.dart';
import '../news/news_screen.dart';
import '../prayer/prayer_screen.dart';
import '../rates/rates_screen.dart';
import '../section/section_screen.dart';

class _Tile {
  final String title;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  final String? count;

  /// هل يُحسب إغلاق هذه الشاشة ضمن شروط الإعلان البيني (لا إعلانات بعد الطوارئ والصلاة).
  final bool ads;
  const _Tile(
    this.title,
    this.icon,
    this.color,
    this.builder, {
    this.count,
    this.ads = true,
  });
}

String _norm(String s) => s
    .replaceAll(RegExp('[\u064B-\u065F]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .toLowerCase()
    .trim();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int _tab = 0;
  int _shownUpdateFor = 0;

  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_maybeShowUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowUpdate());
    _checkPlayUpdate();
  }

  /// تحديث جوجل بلاي الداخلي: ينزّل التحديث بالخلفية ثم يعرض زر إعادة التشغيل.
  Future<void> _checkPlayUpdate() async {
    await Future<void>.delayed(const Duration(seconds: 6));
    final ready = await downloadPlayUpdateIfAny();
    if (!ready || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        content: Text('update_downloaded'.tr()),
        action: SnackBarAction(
          label: 'restart'.tr(),
          onPressed: installPlayUpdate,
        ),
      ),
    );
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_maybeShowUpdate);
    _search.dispose();
    super.dispose();
  }

  /// يعرض نافذة «تحديث متوفر» مرة واحدة لكل إصدار جديد.
  void _maybeShowUpdate() {
    final u = ContentStore.instance.pendingUpdate;
    if (u == null || !mounted || _shownUpdateFor == u.versionCode) return;
    _shownUpdateFor = u.versionCode;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('update_title'.tr()),
        content: Text(u.message.isEmpty ? 'update_body'.tr() : u.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('later'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openUri(context, Uri.parse(u.url));
            },
            child: Text('update_now'.tr()),
          ),
        ],
      ),
    );
  }

  List<_Tile> _tiles() {
    return [
      _Tile(
        'tile_rates'.tr(),
        Icons.currency_exchange,
        const Color(0xFFF9A825),
        (_) => const RatesScreen(),
      ),
      _Tile(
        'tile_news'.tr(),
        Icons.newspaper,
        const Color(0xFFD84315),
        (_) => const NewsScreen(),
      ),
      _Tile(
        'tile_hotels'.tr(),
        Icons.hotel,
        const Color(0xFF6A1B9A),
        (_) => const HotelsScreen(),
      ),
      _Tile(
        'tile_prayer'.tr(),
        Icons.mosque,
        const Color(0xFF00695C),
        (_) => const PrayerScreen(),
        ads: false,
      ),
      _Tile(
        'tile_map'.tr(),
        Icons.map,
        const Color(0xFF2E7D32),
        (_) => const MapScreen(),
      ),
      _Tile(
        'tile_emergency'.tr(),
        Icons.emergency,
        const Color(0xFFC62828),
        (_) => const EmergencyScreen(),
        ads: false,
      ),
      for (final s in directorySections)
        _Tile(
          sectionTitle(s),
          s.icon,
          s.color,
          (_) => SectionScreen(section: s),
          count: 'items_count'.tr(args: ['${s.count}']),
        ),
    ];
  }

  /// فتح شاشة. عند الرجوع منها يُسأل مدير الإعلانات هل حان وقت إعلان بيني نادر.
  Future<void> _open(WidgetBuilder builder, {bool ads = true}) async {
    await Navigator.push(context, MaterialPageRoute(builder: builder));
    if (ads) AdService.instance.screenClosed();
  }

  /// فتح شاشة من القائمة العلوية أو الشريط: لا تُحسب للإعلانات.
  void _push(Widget w) => _open((_) => w, ads: false);

  Future<void> _adFreeFlow() async {
    final messenger = ScaffoldMessenger.of(context);
    final hours = AdService.instance.settings.adFreeHours;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ad_free_title'.tr()),
        content: Text('ad_free_body'.tr(args: ['$hours'])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ad_free_watch'.tr()),
          ),
        ],
      ),
    );
    if (go != true) return;
    final ok = await AdService.instance.watchForAdFree();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'ad_free_done'.tr(args: ['$hours']) : 'ad_free_unavailable'.tr(),
        ),
      ),
    );
  }

  List<DirItem> _results() {
    final q = _norm(_query);
    if (q.isEmpty) return const [];
    return allSearchableItems()
        .where(
          (i) =>
              _norm(i.title).contains(q) ||
              _norm(i.desc).contains(q) ||
              (i.source != null && _norm(i.source!).contains(q)) ||
              i.visibleActions.any((a) => _norm(a.label).contains(q)),
        )
        .toList();
  }

  Future<void> _onMenu(String value) async {
    switch (value) {
      case 'theme':
        AppState.instance.setDark(!AppState.instance.dark);
        break;
      case 'about':
        _push(const AboutScreen());
        break;
      case 'privacy':
        _push(const PrivacyScreen());
        break;
      case 'developer':
        openUri(context, Uri.parse(AppConfig.developerUrl));
        break;
      case 'libya':
        _push(const AboutLibyaScreen());
        break;
      case 'adfree':
        _adFreeFlow();
        break;
      case 'rate':
        openUri(context, Uri.parse(AppConfig.playUrl));
        break;
      case 'share':
        final messenger = ScaffoldMessenger.of(context);
        await Clipboard.setData(
          ClipboardData(
            text:
                '${'app_title'.tr()}: ${'share_text'.tr()}\n${AppConfig.playUrl}',
          ),
        );
        messenger.showSnackBar(SnackBar(content: Text('share_copied'.tr())));
        break;
      case 'exit':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('exit_title'.tr()),
            content: Text('exit_confirm'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('exit'.tr()),
              ),
            ],
          ),
        );
        if (ok == true) SystemNavigator.pop();
        break;
    }
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ContentStore.instance,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final searching = _query.trim().isNotEmpty;
    // قراءة اللغة هنا تجعل الشاشة تُعاد رسمها فور تغييرها.
    final localeCode = context.locale.languageCode;
    final tiles = _tiles();
    final announcement = ContentStore.instance.visibleAnnouncement;

    return Scaffold(
      key: ValueKey(localeCode),
      appBar: AppBar(
        title: Text(
          'app_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active, color: scheme.error),
            tooltip: 'news_tooltip'.tr(),
            onPressed: () => _push(const NewsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'lang_tooltip'.tr(),
            onPressed: () {
              context.setLocale(
                context.locale.languageCode == 'ar'
                    ? const Locale('en')
                    : const Locale('ar'),
              );
            },
          ),
          ListenableBuilder(
            listenable: Listenable.merge([
              AppState.instance,
              AdService.instance,
            ]),
            builder: (context, _) => PopupMenuButton<String>(
              tooltip: 'menu_tooltip'.tr(),
              onSelected: _onMenu,
              itemBuilder: (_) => [
                _menuItem(
                  'theme',
                  AppState.instance.dark ? Icons.light_mode : Icons.dark_mode,
                  'theme_tooltip'.tr(),
                ),
                const PopupMenuDivider(),
                _menuItem('about', Icons.info_outline, 'menu_about_app'.tr()),
                _menuItem(
                  'libya',
                  Icons.flag_outlined,
                  'menu_about_libya'.tr(),
                ),
                _menuItem(
                  'privacy',
                  Icons.privacy_tip_outlined,
                  'menu_privacy'.tr(),
                ),
                _menuItem('developer', Icons.code, 'menu_developer'.tr()),
                const PopupMenuDivider(),
                if (AdService.instance.canOfferAdFree)
                  _menuItem('adfree', Icons.block, 'menu_ad_free'.tr()),
                _menuItem('rate', Icons.star_outline, 'menu_rate'.tr()),
                _menuItem('share', Icons.share, 'menu_share'.tr()),
                const PopupMenuDivider(),
                _menuItem('exit', Icons.exit_to_app, 'menu_exit'.tr()),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (announcement != null) ...[
                    _announcementCard(context, announcement),
                    const SizedBox(height: 10),
                  ],
                  NewsTicker(onTap: () => _push(const NewsScreen())),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'search_hint'.tr(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searching
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListenableBuilder(
                    listenable: AppState.instance,
                    builder: (context, _) {
                      final s = AppState.instance;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 10),
                          Text(
                            s.hasCity
                                ? 'nearby_in'.tr(args: [s.city])
                                : 'nearby_pick_city'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (final k in nearbyKinds)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 8,
                                    ),
                                    child: ActionChip(
                                      avatar: Icon(
                                        k.icon,
                                        size: 18,
                                        color: k.color,
                                      ),
                                      label: Text('near_${k.id}'.tr()),
                                      onPressed: () {
                                        if (!s.hasCity) {
                                          showCityPicker(context);
                                          return;
                                        }
                                        openUri(
                                          context,
                                          mapsSearchUri(k.query, s.city),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (!searching) ...[
                    Text(
                      'quick_access'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _quickChip(
                            'tile_emergency'.tr(),
                            Icons.emergency,
                            const Color(0xFFC62828),
                            'emergency',
                          ),
                          _quickChip(
                            'sec_banks'.tr(),
                            Icons.account_balance_wallet,
                            const Color(0xFF00796B),
                            'banks',
                          ),
                          _quickChip(
                            'sec_citizen'.tr(),
                            Icons.how_to_reg,
                            const Color(0xFF00838F),
                            'citizen',
                          ),
                          _quickChip(
                            'sec_state'.tr(),
                            Icons.account_balance,
                            const Color(0xFF1565C0),
                            'state',
                          ),
                          _quickChip(
                            'tile_news'.tr(),
                            Icons.newspaper,
                            const Color(0xFFD84315),
                            'news',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'all_sections'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ]),
              ),
            ),
            if (searching)
              _searchResults(scheme)
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: tiles.length,
                  itemBuilder: (context, index) => _tileCard(tiles[index]),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBanner(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) {
              setState(() => _tab = 0);
              if (i == 1) _open((_) => const FavoritesScreen());
              if (i == 2) _push(const MerchantScreen());
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home),
                label: 'nav_home'.tr(),
              ),
              NavigationDestination(
                icon: const Icon(Icons.bookmark),
                label: 'nav_favorites'.tr(),
              ),
              NavigationDestination(
                icon: const Icon(Icons.storefront),
                label: 'nav_add_store'.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _announcementCard(BuildContext context, Announcement a) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: a.url == null ? null : () => openUri(context, Uri.parse(a.url!)),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
          child: Row(
            children: [
              Icon(Icons.campaign_outlined, color: scheme.onPrimaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  a.text,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    height: 1.4,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: scheme.onPrimaryContainer,
                ),
                onPressed: ContentStore.instance.dismissAnnouncement,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchResults(ColorScheme scheme) {
    final results = _results();
    if (results.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text('no_results'.tr())),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList.builder(
        itemCount: results.length,
        itemBuilder: (context, i) =>
            DirItemTile(item: results[i], accent: scheme.primary),
      ),
    );
  }

  Widget _quickChip(String label, IconData icon, Color color, String id) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: color),
        label: Text(label),
        onPressed: () {
          if (id == 'emergency') {
            _push(const EmergencyScreen());
            return;
          }
          final s = sectionById(id);
          if (s != null) {
            final adFree = const {
              'banks',
              'citizen',
              'state',
              'complaints',
            }.contains(id);
            _open((_) => SectionScreen(section: s), ads: !adFree);
          }
        },
      ),
    );
  }

  Widget _tileCard(_Tile t) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(t.builder, ads: t.ads),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: t.color.withValues(alpha: 0.15),
                child: Icon(t.icon, size: 26, color: t.color),
              ),
              const SizedBox(height: 8),
              Text(
                t.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (t.count != null) ...[
                const SizedBox(height: 2),
                Text(
                  t.count!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
