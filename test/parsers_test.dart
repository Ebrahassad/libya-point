import 'package:flutter_test/flutter_test.dart';
import 'package:libya_point/services/ad_settings.dart';
import 'package:libya_point/services/content_parser.dart';
import 'package:libya_point/services/parsers.dart';
import 'package:libya_point/services/prayer.dart';

void main() {
  test('parseCblRates reads rows with or without labels', () {
    const html = '''
<table>
<tr><th>التاريخ</th><th>العملة</th><th>الوحدة</th><th>المتوسط</th><th>بيع</th><th>شراء</th></tr>
<tr><td>التاريخ: 2026-09-29</td><td>العملة: الدولار الأمريكي</td><td>الوحدة: دولار واحد</td>
<td>المتوسط: 6.3967 د.ل</td><td>بيع: 6.4127 د.ل</td><td>شراء: 6.3808 د.ل</td></tr>
<tr><td>2026-09-29</td><td>اليورو</td><td>يورو واحد</td><td>7.2693 د.ل</td><td>7.2874 د.ل</td><td>7.2511 د.ل</td></tr>
</table>''';
    final rates = parseCblRates(html);
    expect(rates.length, 2);
    expect(rates[0].name, 'الدولار الأمريكي');
    expect(rates[0].average, closeTo(6.3967, 0.00001));
    expect(rates[0].sell, closeTo(6.4127, 0.00001));
    expect(rates[0].buy, closeTo(6.3808, 0.00001));
    expect(rates[1].name, 'اليورو');
    expect(rates[1].date, '2026-09-29');
  });

  test('parseParallelRates skips empty image cells', () {
    const html = '''
<table>
<tr><th></th><th>العملة</th><th>السعر</th><th></th></tr>
<tr><td><img src="a.png"></td><td>الدولار</td><td>9.53</td><td></td></tr>
<tr><td><img src="b.png"></td><td>اليورو</td><td>10.80</td><td></td></tr>
</table>''';
    final rates = parseParallelRates(html);
    expect(rates.length, 2);
    expect(rates[0].name, 'الدولار');
    expect(rates[0].price, 9.53);
    expect(rates[1].price, 10.8);
  });

  test('parseFeed reads RSS items with CDATA and entities', () {
    const xml = '''
<rss><channel><title>x</title>
<item><title><![CDATA[خبر عاجل &amp; مهم]]></title><link>https://example.ly/a</link>
<pubDate>Tue, 29 Sep 2026 10:20:00 +0000</pubDate></item>
<item><title>Second</title><link>https://example.ly/b</link></item>
</channel></rss>''';
    final items = parseFeed(xml, 'مصدر');
    expect(items.length, 2);
    expect(items[0].title, contains('خبر عاجل'));
    expect(items[0].link, 'https://example.ly/a');
    expect(items[0].source, 'مصدر');
    expect(items[0].date, isNotNull);
    expect(items[1].date, isNull);
  });

  test('weatherKey maps WMO codes', () {
    expect(weatherKey(0), 'w_clear');
    expect(weatherKey(3), 'w_cloudy');
    expect(weatherKey(63), 'w_rain');
    expect(weatherKey(95), 'w_storm');
  });

  test('parseFeed uses the <source> tag and strips the title suffix', () {
    const xml = '''
<rss><channel>
<item><title>الدبيبة يلتقي وفداً - بوابة الوسط</title><link>https://news.google.com/a</link>
<pubDate>Wed, 30 Sep 2026 10:00:00 GMT</pubDate><source url="https://alwasat.ly">بوابة الوسط</source></item>
</channel></rss>''';
    final items = parseFeed(xml, 'أخبار ليبيا');
    expect(items.length, 1);
    expect(items[0].source, 'بوابة الوسط');
    expect(items[0].title, 'الدبيبة يلتقي وفداً');
  });

  test('newsKey makes equal headlines equal', () {
    expect(newsKey('خبر: عاجل!'), newsKey('خبر عاجل'));
  });

  test('parsePrayerTimes reads Aladhan timings', () {
    const body =
        '{"data":{"timings":{"Fajr":"05:12 (EET)","Sunrise":"06:30","Dhuhr":"12:05","Asr":"15:20","Maghrib":"17:41","Isha":"19:00"}}}';
    final t = parsePrayerTimes(body)!;
    expect(t['Fajr'], '05:12');
    expect(t['Isha'], '19:00');
    expect(parsePrayerTimes('{}'), isNull);
  });

  test('parseDirItem accepts valid items and rejects unsafe ones', () {
    expect(
      parseDirItem({'type': 'web', 'title': 'a', 'url': 'https://x.ly/'}),
      isNotNull,
    );
    expect(
      parseDirItem({'type': 'web', 'title': 'a', 'url': 'javascript:alert(1)'}),
      isNull,
    );
    expect(
      parseDirItem({'type': 'app', 'title': 'a', 'package': 'com.a.b'}),
      isNotNull,
    );
    expect(
      parseDirItem({'type': 'app', 'title': 'a', 'package': 'bad package'}),
      isNull,
    );
    expect(
      parseDirItem({'type': 'phone', 'title': 'a', 'phone': '+218910000000'}),
      isNotNull,
    );
    expect(
      parseDirItem({'type': 'phone', 'title': 'a', 'phone': 'abc'}),
      isNull,
    );
    expect(parseDirItem({'title': '', 'url': 'https://x.ly/'}), isNull);
  });

  test('parseSections and mergeSections replace by id and append new ones', () {
    final remote = parseSections([
      {
        'id': 'cars',
        'title': 'السيارات',
        'groups': [
          {
            'title': 'g',
            'items': [
              {'type': 'web', 'title': 'x', 'url': 'https://x.ly/'},
            ],
          },
        ],
      },
      {'id': 'broken', 'groups': []},
    ]);
    expect(remote.length, 1);
    final merged = mergeSections(remote, remote, const ['zzz']);
    expect(merged.length, 1);
    expect(merged.first.title, 'السيارات');
    expect(mergeSections(remote, const [], const ['cars']), isEmpty);
  });

  test('AdSettings: no game id means ads are off, and limits are clamped', () {
    final d = AdSettings.fromJson(null);
    expect(d.active, isFalse);
    final a = AdSettings.fromJson({
      'gameId': 1234567,
      'interstitialEvery': 1,
      'minSecondsBetween': 5,
      'dailyCap': 99,
      'bannerPlacement': 'bad placement!',
    });
    expect(a.active, isTrue);
    expect(a.gameId, '1234567');
    expect(a.interstitialEvery, 3);
    expect(a.minSecondsBetween, 90);
    expect(a.dailyCap, 12);
    expect(a.bannerPlacement, 'BP_Banner_Android');
    expect(AdSettings.fromJson({'gameId': 'abc'}).active, isFalse);
    expect(
      AdSettings.fromJson({'gameId': '1234567', 'enabled': false}).active,
      isFalse,
    );
  });
}
