import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/live_data.dart';
import '../services/parsers.dart';

class TickerItem {
  final IconData icon;
  final String text;
  final Color color;
  const TickerItem(this.icon, this.text, this.color);
}

String _n2(double? v) => v == null ? '—' : v.toStringAsFixed(2);

/// يبني عناصر الشريط من البيانات الحالية. لا يعرض إلا ما وصل فعلاً.
List<TickerItem> buildTickerItems(LiveData d, AppState s) {
  final items = <TickerItem>[];

  final usdO = d.usdOfficial;
  final usdP = d.usdParallel;
  if (usdO != null || usdP != null) {
    items.add(
      TickerItem(
        Icons.attach_money,
        'ticker_usd'.tr(args: [_n2(usdO), _n2(usdP)]),
        Colors.green,
      ),
    );
  }
  final eurO = d.cblRate('اليورو')?.average;
  final eurP = d.parallelRate('اليورو');
  if (eurO != null || eurP != null) {
    items.add(
      TickerItem(
        Icons.euro,
        'ticker_eur'.tr(args: [_n2(eurO), _n2(eurP)]),
        Colors.blue,
      ),
    );
  }
  final g21 = d.goldPerGramLyd(21);
  if (g21 != null) {
    items.add(
      TickerItem(
        Icons.monetization_on,
        'ticker_gold'.tr(args: [g21.round().toString()]),
        Colors.amber.shade800,
      ),
    );
  }
  if (d.brentUsd != null) {
    items.add(
      TickerItem(
        Icons.oil_barrel,
        'ticker_oil'.tr(args: [_n2(d.brentUsd)]),
        Colors.brown,
      ),
    );
  }
  final w = d.weather[s.cityOrDefault];
  if (w != null) {
    items.add(
      TickerItem(
        Icons.wb_sunny,
        'ticker_weather'.tr(
          args: [w.city, w.temp.round().toString(), weatherKey(w.code).tr()],
        ),
        Colors.orange,
      ),
    );
  }
  for (final n in d.tickerNews(14)) {
    items.add(
      TickerItem(Icons.campaign, '${n.source}: ${n.title}', Colors.red),
    );
  }
  if (items.isEmpty) {
    items.add(TickerItem(Icons.sync, 'ticker_loading'.tr(), Colors.grey));
  }
  return items;
}

/// شريط أخبار متحرك يتحدث تلقائياً. الضغط عليه يفتح شاشة الأخبار.
class NewsTicker extends StatefulWidget {
  final VoidCallback onTap;
  const NewsTicker({super.key, required this.onTap});

  @override
  State<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<NewsTicker> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => _tick());
  }

  void _tick() {
    if (_paused || !_controller.hasClients) return;
    final pos = _controller.position;
    if (pos.maxScrollExtent <= 0) return;
    final half = (pos.maxScrollExtent + pos.viewportDimension) / 2;
    var next = _controller.offset + 1.4;
    if (next >= half) next -= half;
    _controller.jumpTo(next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _copy(List<TickerItem> items, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final i in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(i.icon, size: 16, color: i.color),
                const SizedBox(width: 6),
                Text(
                  i.text,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([LiveData.instance, AppState.instance]),
      builder: (context, _) {
        final items = buildTickerItems(LiveData.instance, AppState.instance);
        return Listener(
          onPointerDown: (_) => _paused = true,
          onPointerUp: (_) => _paused = false,
          onPointerCancel: (_) => _paused = false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.campaign, color: scheme.error),
                  ),
                  Expanded(
                    child: ClipRect(
                      child: SingleChildScrollView(
                        controller: _controller,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _copy(items, scheme.onSurface),
                            _copy(items, scheme.onSurface),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.chevron_left, color: scheme.error),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
