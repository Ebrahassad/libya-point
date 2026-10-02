import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../data/directory.dart';
import '../data/hotels.dart';
import '../data/news_sources.dart';
import 'ad_settings.dart';
import 'content_parser.dart';

class Announcement {
  final String id;
  final String text;
  final String? url;
  const Announcement(this.id, this.text, this.url);
}

class UpdateInfo {
  final int versionCode;
  final String message;
  final String url;
  const UpdateInfo(this.versionCode, this.message, this.url);
}

/// مخزن المحتوى: يبدأ بالمحتوى المضمّن في التطبيق، ثم يطبّق فوقه آخر نسخة
/// محفوظة، ثم يجلب content.json من الإنترنت ويطبّقه. بهذا تصل الروابط
/// والتطبيقات والفنادق والأخبار والإعلانات للمستخدمين دون تحديث من المتجر.
class ContentStore extends ChangeNotifier {
  ContentStore._();
  static final ContentStore instance = ContentStore._();

  static const _cacheKey = 'content_cache_v2';
  static const _dismissedKey = 'dismissed_announcement';

  List<DirSection> sections = defaultSections;
  List<Hotel> hotels = defaultHotels;
  List<NewsSource> newsSources = defaultNewsSources;
  Announcement? announcement;
  UpdateInfo? update;
  String? aboutExtra;
  AdSettings ads = AdSettings.defaults();

  String appVersion = '';
  int buildNumber = 0;
  String? _dismissedId;
  bool _started = false;

  /// إعلان لم يُغلقه المستخدم بعد.
  Announcement? get visibleAnnouncement {
    final a = announcement;
    if (a == null || a.id == _dismissedId) return null;
    return a;
  }

  /// تحديث للتطبيق أحدث من النسخة المثبّتة.
  UpdateInfo? get pendingUpdate {
    final u = update;
    if (u == null || buildNumber == 0) return null;
    return u.versionCode > buildNumber ? u : null;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
      buildNumber = int.tryParse(info.buildNumber) ?? 0;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      _dismissedId = prefs.getString(_dismissedKey);
      final cached = prefs.getString(_cacheKey);
      if (cached != null) apply(cached);
    } catch (_) {}
    notifyListeners();
    unawaited(refresh());
    Timer.periodic(const Duration(minutes: 30), (_) => refresh());
  }

  Future<void> refresh() async {
    try {
      final r = await http
          .get(
            Uri.parse(AppConfig.contentUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return;
      final body = utf8.decode(r.bodyBytes, allowMalformed: true);
      if (apply(body)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, body);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// يطبّق نص JSON. يعيد false إن كان غير صالح (فيبقى المحتوى الحالي).
  @visibleForTesting
  bool apply(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return false;
    }
    if (decoded is! Map) return false;

    final remoteSections = parseSections(decoded['sections']);
    final remove = decoded['sections_remove'] is List
        ? (decoded['sections_remove'] as List).map((e) => e.toString())
        : const <String>[];
    sections = mergeSections(defaultSections, remoteSections, remove);

    final remoteHotels = parseHotels(decoded['hotels']);
    hotels = remoteHotels.isEmpty ? defaultHotels : remoteHotels;

    final remoteFeeds = parseNewsSources(decoded['newsFeeds']);
    newsSources = remoteFeeds.isEmpty ? defaultNewsSources : remoteFeeds;

    final a = decoded['announcement'];
    if (a is Map &&
        a['id'] != null &&
        a['text'] != null &&
        a['text'].toString().trim().isNotEmpty) {
      final url = a['url']?.toString().trim() ?? '';
      announcement = Announcement(
        a['id'].toString(),
        a['text'].toString().trim(),
        RegExp(r'^https?://\S+$').hasMatch(url) ? url : null,
      );
    } else {
      announcement = null;
    }

    final u = decoded['update'];
    if (u is Map && int.tryParse('${u['versionCode']}') != null) {
      final url = u['url']?.toString().trim() ?? '';
      update = UpdateInfo(
        int.parse('${u['versionCode']}'),
        (u['message']?.toString().trim().isNotEmpty ?? false)
            ? u['message'].toString().trim()
            : '',
        RegExp(r'^https?://\S+$').hasMatch(url) ? url : AppConfig.playUrl,
      );
    } else {
      update = null;
    }

    ads = AdSettings.fromJson(decoded['ads']);

    final extra = decoded['aboutExtra']?.toString().trim() ?? '';
    aboutExtra = extra.isEmpty ? null : extra;
    return true;
  }

  Future<void> dismissAnnouncement() async {
    final a = announcement;
    if (a == null) return;
    _dismissedId = a.id;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedKey, a.id);
    } catch (_) {}
  }
}
