import 'dart:convert';

import 'package:http/http.dart' as http;

/// أوقات الصلاة من خدمة Aladhan المجانية (بدون مفتاح). التوقيت تقريبي وعلى
/// طريقة الهيئة المصرية للمساحة؛ يُنصح بمطابقته مع الهيئة العامة للأوقاف.
const List<String> prayerOrder = [
  'Fajr',
  'Sunrise',
  'Dhuhr',
  'Asr',
  'Maghrib',
  'Isha',
];

Map<String, String>? parsePrayerTimes(String body) {
  try {
    final j = jsonDecode(body) as Map<String, dynamic>;
    final timings =
        (j['data'] as Map<String, dynamic>)['timings'] as Map<String, dynamic>;
    final out = <String, String>{};
    for (final k in prayerOrder) {
      final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch('${timings[k]}');
      if (m == null) return null;
      out[k] = '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}';
    }
    return out;
  } catch (_) {
    return null;
  }
}

Future<Map<String, String>?> fetchPrayerTimes(double lat, double lng) async {
  try {
    final r = await http
        .get(
          Uri.parse(
            'https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lng&method=5',
          ),
        )
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return null;
    return parsePrayerTimes(utf8.decode(r.bodyBytes, allowMalformed: true));
  } catch (_) {
    return null;
  }
}
