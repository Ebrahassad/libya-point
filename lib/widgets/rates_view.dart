import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/live_data.dart';
import 'open_link.dart';

String fmtTime(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${l.day}/${l.month} ${two(l.hour)}:${two(l.minute)}';
}

String _n(double? v, [int digits = 2]) =>
    v == null ? '—' : v.toStringAsFixed(digits);

/// العملات (المركزي + الموازي) والذهب والنفط ومحول العملات.
/// يُستخدم داخل شاشة الأسعار وداخل تبويب الأسعار في شاشة الأخبار.
class RatesView extends StatefulWidget {
  const RatesView({super.key});

  @override
  State<RatesView> createState() => _RatesViewState();
}

class _RatesViewState extends State<RatesView> {
  // (اسم العملة عند المركزي، اسمها في السوق الموازي، الاسم المعروض)
  static const _convertible = [
    ('الدولار الأمريكي', 'الدولار', 'الدولار (USD)'),
    ('اليورو', 'اليورو', 'اليورو (EUR)'),
    ('الاسترليني', 'الإسترليني', 'الجنيه الإسترليني (GBP)'),
    ('الدينار التونسي', 'الدينار التونسي', 'الدينار التونسي (TND)'),
    ('الليرة التركية', 'الليرة التركية', 'الليرة التركية (TRY)'),
  ];

  final TextEditingController _amount = TextEditingController(text: '100');
  int _selected = 0;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String left, String right, {String? sub, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  left,
                  style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
              ],
            ),
          ),
          Text(right, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          text,
          style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
        ),
      );

  Widget _failed(String key, VoidCallback retry) => Row(
        children: [
          Expanded(child: Text(key.tr())),
          TextButton(onPressed: retry, child: Text('retry'.tr())),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveData.instance,
      builder: (context, _) {
        final d = LiveData.instance;
        final cur = 'currency_lyd'.tr();

        final official = _sectionCard(
          context,
          title: 'official_cbl'.tr(),
          icon: Icons.account_balance,
          color: Colors.teal,
          children: [
            if (d.cbl.isEmpty && d.currency == LoadState.failed)
              _failed('rates_failed', d.refresh)
            else if (d.cbl.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              for (final r in d.cbl)
                _row(
                  r.name,
                  '${'sell'.tr()} ${_n(r.sell, 4)} | ${'buy'.tr()} ${_n(r.buy, 4)}',
                  sub: '${r.unit} - ${'average'.tr()} ${_n(r.average, 4)} $cur',
                ),
              _note('${'cbl_source'.tr()} - ${d.cbl.first.date}'),
            ],
          ],
        );

        final parallel = _sectionCard(
          context,
          title: 'parallel_market'.tr(),
          icon: Icons.storefront,
          color: Colors.deepOrange,
          children: [
            if (d.parallel.isEmpty && d.currency == LoadState.failed)
              _failed('rates_failed', d.refresh)
            else if (d.parallel.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              for (final r in d.parallel)
                _row(r.name, '${_n(r.price, 3)} $cur', bold: true),
              _note(
                '${'parallel_note'.tr()}${d.parallelUpdated != null ? ' (${d.parallelUpdated})' : ''}',
              ),
            ],
          ],
        );

        final gold = _sectionCard(
          context,
          title: 'gold_title'.tr(),
          icon: Icons.monetization_on,
          color: Colors.amber.shade800,
          children: [
            if (d.goldUsdPerOunce == null && d.gold == LoadState.failed)
              _failed('rates_failed', d.refresh)
            else if (d.goldUsdPerOunce == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _row('gold_ounce'.tr(), '${_n(d.goldUsdPerOunce)} USD'),
              for (final k in const [24, 21, 18])
                _row(
                  'gold_gram'.tr(args: ['$k']),
                  '${_n(d.goldPerGramLyd(k), 1)} $cur',
                  bold: true,
                ),
              _note('gold_note'.tr()),
            ],
          ],
        );

        final oil = _sectionCard(
          context,
          title: 'oil_title'.tr(),
          icon: Icons.oil_barrel,
          color: Colors.brown,
          children: [
            if (d.brentUsd != null)
              _row('oil_barrel'.tr(), _n(d.brentUsd), bold: true),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text('oil_open_source'.tr()),
              onPressed: () => openUri(context, Uri.parse('https://noc.ly/')),
            ),
          ],
        );

        final converter = _buildConverter(context, d, cur);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      d.lastUpdated == null
                          ? 'loading'.tr()
                          : 'updated_at'.tr(args: [fmtTime(d.lastUpdated)]),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'refresh'.tr(),
                    icon: const Icon(Icons.refresh),
                    onPressed: d.refresh,
                  ),
                ],
              ),
            ),
            converter,
            official,
            parallel,
            gold,
            oil,
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
    );
  }

  Widget _buildConverter(BuildContext context, LiveData d, String cur) {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
    final c = _convertible[_selected];
    final off = d.cblRate(c.$1)?.average;
    final par = d.parallelRate(c.$2);
    return _sectionCard(
      context,
      title: 'converter'.tr(),
      icon: Icons.calculate,
      color: Colors.indigo,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'amount'.tr(),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<int>(
              value: _selected,
              items: [
                for (var i = 0; i < _convertible.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                      _convertible[i].$3,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _selected = v ?? 0),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _row(
          'official_cbl'.tr(),
          off == null ? '—' : '${_n(amount * off)} $cur',
          bold: true,
        ),
        _row(
          'parallel_market'.tr(),
          par == null ? '—' : '${_n(amount * par)} $cur',
          bold: true,
        ),
      ],
    );
  }
}
