// دوال تحليل نقية (بدون شبكة) كي يمكن اختبارها.

class CblRate {
  final String date;
  final String name;
  final String unit;
  final double average;
  final double? sell;
  final double? buy;
  const CblRate(
    this.date,
    this.name,
    this.unit,
    this.average,
    this.sell,
    this.buy,
  );

  Map<String, dynamic> toJson() => {
        'date': date,
        'name': name,
        'unit': unit,
        'avg': average,
        'sell': sell,
        'buy': buy,
      };

  factory CblRate.fromJson(Map<String, dynamic> j) => CblRate(
        j['date'] as String,
        j['name'] as String,
        j['unit'] as String,
        (j['avg'] as num).toDouble(),
        (j['sell'] as num?)?.toDouble(),
        (j['buy'] as num?)?.toDouble(),
      );
}

class ParallelRate {
  final String name;
  final double price;
  const ParallelRate(this.name, this.price);

  Map<String, dynamic> toJson() => {'name': name, 'price': price};
  factory ParallelRate.fromJson(Map<String, dynamic> j) =>
      ParallelRate(j['name'] as String, (j['price'] as num).toDouble());
}

class NewsItem {
  final String title;
  final String link;
  final String source;
  final DateTime? date;
  const NewsItem(this.title, this.link, this.source, this.date);

  Map<String, dynamic> toJson() => {
        'title': title,
        'link': link,
        'source': source,
        'date': date?.toIso8601String(),
      };

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
        j['title'] as String,
        j['link'] as String,
        j['source'] as String,
        j['date'] == null ? null : DateTime.tryParse(j['date'] as String),
      );
}

String decodeEntities(String s) {
  var out = s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ');
  out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m.group(1)!);
    return code == null ? m.group(0)! : String.fromCharCode(code);
  });
  out = out.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m.group(1)!, radix: 16);
    return code == null ? m.group(0)! : String.fromCharCode(code);
  });
  return out;
}

String stripTags(String s) {
  final noTags = s.replaceAll(RegExp(r'<[^>]*>'), ' ');
  return decodeEntities(noTags).replaceAll(RegExp(r'\s+'), ' ').trim();
}

double? firstNumber(String s) {
  final m = RegExp(r'\d+(?:\.\d+)?').firstMatch(s);
  return m == null ? null : double.tryParse(m.group(0)!);
}

List<List<String>> _tableRows(String html) {
  final rows = <List<String>>[];
  final trRe = RegExp(
    r'<tr[^>]*>(.*?)</tr>',
    dotAll: true,
    caseSensitive: false,
  );
  final tdRe = RegExp(
    r'<t[dh][^>]*>(.*?)</t[dh]>',
    dotAll: true,
    caseSensitive: false,
  );
  for (final tr in trRe.allMatches(html)) {
    final cells = tdRe
        .allMatches(tr.group(1)!)
        .map((m) => stripTags(m.group(1)!))
        .toList();
    if (cells.isNotEmpty) rows.add(cells);
  }
  return rows;
}

/// يزيل بادئة مثل "العملة: " من خلية الجدول إن وُجدت.
String _dropLabel(String c) =>
    c.replaceFirst(RegExp(r'^[^:：\d]{1,20}[:：]\s*'), '').trim();

/// أسعار صرف مصرف ليبيا المركزي (cbl.gov.ly/currency-exchange-rates).
/// الأعمدة: التاريخ، العملة، الوحدة، المتوسط، بيع، شراء.
List<CblRate> parseCblRates(String html) {
  final out = <CblRate>[];
  for (final cells in _tableRows(html)) {
    if (cells.length < 6) continue;
    final f = cells.map(_dropLabel).toList();
    final avg = firstNumber(f[3]);
    if (avg == null) continue;
    out.add(
      CblRate(f[0], f[1], f[2], avg, firstNumber(f[4]), firstNumber(f[5])),
    );
  }
  return out;
}

/// أسعار السوق الموازي (عين ليبيا). يعيد الاسم والسعر.
List<ParallelRate> parseParallelRates(String html) {
  final out = <ParallelRate>[];
  for (final cells in _tableRows(html)) {
    final ne = cells.where((c) => c.isNotEmpty).toList();
    if (ne.length < 2) continue;
    final price = firstNumber(ne.last);
    final name = ne.first;
    if (price == null || firstNumber(name) != null) continue;
    out.add(ParallelRate(name, price));
  }
  return out;
}

String? parseParallelUpdated(String html) {
  final text = stripTags(html);
  final m = RegExp(r'آخر تحديث:\s*(.{5,40}?\d{1,2}:\d{2})').firstMatch(text);
  return m?.group(1)?.trim();
}

DateTime? _parseRssDate(String s) {
  final iso = DateTime.tryParse(s.trim());
  if (iso != null) return iso;
  // RFC 822: Tue, 29 Sep 2026 10:20:00 +0000
  final m = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2})')
      .firstMatch(s);
  if (m == null) return null;
  const months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };
  final mo = months[m.group(2)!.toLowerCase()];
  if (mo == null) return null;
  return DateTime.utc(
    int.parse(m.group(3)!),
    mo,
    int.parse(m.group(1)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
  );
}

String _cdata(String s) {
  final m = RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true).firstMatch(s);
  return (m != null ? m.group(1)! : s).trim();
}

String? _tag(String block, String tag) {
  final m = RegExp(
    '<$tag[^>]*>(.*?)</$tag>',
    dotAll: true,
    caseSensitive: false,
  ).firstMatch(block);
  return m == null ? null : _cdata(m.group(1)!);
}

/// يحلل RSS 2.0 أو Atom بشكل مبسط. إن وُجد وسم <source> (أخبار جوجل) يُستعمل
/// اسمه كمصدر للخبر ويُحذف اللاحق " - اسم الموقع" من العنوان.
List<NewsItem> parseFeed(String xml, String source, {int limit = 12}) {
  final out = <NewsItem>[];
  final itemRe = RegExp(
    r'<(item|entry)[ >].*?</\1>',
    dotAll: true,
    caseSensitive: false,
  );
  for (final m in itemRe.allMatches(xml)) {
    final block = m.group(0)!;
    final rawTitle = _tag(block, 'title');
    var link = _tag(block, 'link');
    if (link == null || link.isEmpty) {
      link = RegExp(r'<link[^>]*href="([^"]+)"').firstMatch(block)?.group(1);
    }
    if (rawTitle == null || link == null || link.isEmpty) continue;
    var title = stripTags(rawTitle);
    var src = source;
    final srcTag = _tag(block, 'source');
    if (srcTag != null && srcTag.isNotEmpty) {
      src = stripTags(srcTag);
      final suffix = ' - $src';
      if (title.endsWith(suffix)) {
        title = title.substring(0, title.length - suffix.length).trim();
      }
    }
    if (title.isEmpty) continue;
    final dateRaw = _tag(block, 'pubDate') ??
        _tag(block, 'updated') ??
        _tag(block, 'published');
    out.add(
      NewsItem(
        title,
        decodeEntities(link.trim()),
        src,
        dateRaw == null ? null : _parseRssDate(dateRaw),
      ),
    );
    if (out.length >= limit) break;
  }
  return out;
}

/// مفتاح لإزالة تكرار الخبر الواحد القادم من أكثر من مصدر.
String newsKey(String title) =>
    title.replaceAll(RegExp(r'[^\u0600-\u06FFA-Za-z0-9]'), '').toLowerCase();

// رموز الطقس WMO إلى مفتاح ترجمة.
String weatherKey(int code) {
  if (code == 0) return 'w_clear';
  if (code == 1) return 'w_mostly_clear';
  if (code == 2) return 'w_partly';
  if (code == 3) return 'w_cloudy';
  if (code == 45 || code == 48) return 'w_fog';
  if (code >= 51 && code <= 57) return 'w_drizzle';
  if (code >= 61 && code <= 67) return 'w_rain';
  if (code >= 71 && code <= 77) return 'w_snow';
  if (code >= 80 && code <= 82) return 'w_showers';
  if (code == 85 || code == 86) return 'w_snow_showers';
  if (code >= 95) return 'w_storm';
  return 'w_unknown';
}

/// أيقونة مناسبة لرمز الطقس.
int weatherIconGroup(int code) {
  if (code <= 1) return 0; // صافٍ
  if (code <= 3) return 1; // غائم
  if (code == 45 || code == 48) return 2; // ضباب
  if (code >= 95) return 5; // رعد
  if (code >= 71 && code <= 77 || code == 85 || code == 86) return 4; // ثلج
  return 3; // مطر
}
