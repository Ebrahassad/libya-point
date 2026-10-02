import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/cities.dart';
import '../../data/news_sources.dart';
import '../../services/app_state.dart';
import '../../services/live_data.dart';
import '../../services/parsers.dart';
import '../../widgets/open_link.dart';
import '../../widgets/rates_view.dart';
import '../../widgets/ad_banner.dart';

/// شاشة الأخبار: أخبار من مصادر ليبية + الطقس + الأسعار.
class NewsScreen extends StatelessWidget {
  final int initialTab;
  const NewsScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text('news_title'.tr()),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: 'tab_news'.tr()),
              Tab(text: 'tab_weather'.tr()),
              Tab(text: 'tab_rates'.tr()),
            ],
          ),
        ),
        bottomNavigationBar: const AdBanner(),
        body: const TabBarView(
          children: [_NewsTab(), _WeatherTab(), _PricesTab()],
        ),
      ),
    );
  }
}

class _PricesTab extends StatelessWidget {
  const _PricesTab();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: LiveData.instance.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [RatesView()],
      ),
    );
  }
}

class _NewsTab extends StatelessWidget {
  const _NewsTab();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveData.instance,
      builder: (context, _) {
        final d = LiveData.instance;
        return RefreshIndicator(
          onRefresh: d.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'latest_news'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                d.lastUpdated == null
                    ? 'loading'.tr()
                    : 'updated_at'.tr(args: [fmtTime(d.lastUpdated)]),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 12),
              if (d.news.isEmpty && d.newsState == LoadState.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (d.news.isEmpty) ...[
                Text('news_failed'.tr()),
                const SizedBox(height: 8),
              ] else
                for (final n in d.news)
                  Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        n.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${n.source}${n.date != null ? ' • ${fmtTime(n.date)}' : ''}',
                      ),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => openUri(context, Uri.parse(n.link)),
                    ),
                  ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in newsSourcesWithSite)
                    ActionChip(
                      avatar: const Icon(Icons.open_in_new, size: 16),
                      label: Text(s.name),
                      onPressed: () => openUri(context, Uri.parse(s.site!)),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

IconData _weatherIcon(int code) {
  switch (weatherIconGroup(code)) {
    case 0:
      return Icons.wb_sunny;
    case 1:
      return Icons.cloud;
    case 2:
      return Icons.foggy;
    case 4:
      return Icons.ac_unit;
    case 5:
      return Icons.thunderstorm;
    default:
      return Icons.grain;
  }
}

class _WeatherTab extends StatelessWidget {
  const _WeatherTab();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LiveData.instance, AppState.instance]),
      builder: (context, _) {
        final d = LiveData.instance;
        final selected = AppState.instance.cityOrDefault;
        final names = libyaCities
            .map((c) => c.name)
            .where(d.weather.containsKey)
            .toList();
        names.sort((a, b) {
          if (a == selected) return -1;
          if (b == selected) return 1;
          return 0;
        });
        return RefreshIndicator(
          onRefresh: d.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (names.isEmpty && d.weatherState == LoadState.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (names.isEmpty)
                Text('weather_failed'.tr())
              else ...[
                Text(
                  'weather_now'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                for (final name in names)
                  Card(
                    elevation: name == selected ? 3 : 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: name == selected
                          ? BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5,
                            )
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: Icon(
                        _weatherIcon(d.weather[name]!.code),
                        size: 32,
                        color: Colors.orange,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${weatherKey(d.weather[name]!.code).tr()} • ${'wind'.tr()} ${d.weather[name]!.wind.round()} ${'kmh'.tr()}'
                        '${d.weather[name]!.humidity != null ? ' • ${'humidity'.tr()} ${d.weather[name]!.humidity!.round()}%' : ''}',
                      ),
                      trailing: Text(
                        '${d.weather[name]!.temp.round()}°',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
