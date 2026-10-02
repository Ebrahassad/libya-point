import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cities.dart';

/// حالة التطبيق العامة: المدينة المختارة، المظهر، المفضلة (كلها محفوظة).
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const _kCity = 'saved_city';
  static const _kDark = 'dark_mode';
  static const _kFavs = 'favorite_keys';

  String city = allCitiesLabel;
  bool dark = false;
  Set<String> favorites = {};

  bool get hasCity => city != allCitiesLabel;

  /// المدينة المستخدمة للطقس والخريطة عندما لا يُختار شيء.
  String get cityOrDefault => hasCity ? city : 'طرابلس';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_kCity);
    if (saved != null &&
        (saved == allCitiesLabel || cityByName(saved) != null)) {
      city = saved;
    }
    dark = p.getBool(_kDark) ?? false;
    favorites = (p.getStringList(_kFavs) ?? const []).toSet();
    notifyListeners();
  }

  Future<void> setCity(String value) async {
    city = value;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCity, value);
  }

  Future<void> setDark(bool value) async {
    dark = value;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDark, value);
  }

  bool isFavorite(String key) => favorites.contains(key);

  Future<void> toggleFavorite(String key) async {
    if (!favorites.remove(key)) favorites.add(key);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kFavs, favorites.toList());
  }
}
