import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  // ── String ────────────────────────────────────────────────────────────────

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  String? getString(String key) => _prefs.getString(key);

  // ── Bool ──────────────────────────────────────────────────────────────────

  Future<bool> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  // ── Int ───────────────────────────────────────────────────────────────────

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  // ── Double ────────────────────────────────────────────────────────────────

  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);

  // ── List<String> ──────────────────────────────────────────────────────────

  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  List<String>? getStringList(String key) => _prefs.getStringList(key);

  // ── Object (Map<String, dynamic>) ─────────────────────────────────────────

  Future<bool> setObject(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  Map<String, dynamic>? getObject(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clear() => _prefs.clear();

  bool containsKey(String key) => _prefs.containsKey(key);

  Set<String> getKeys() => _prefs.getKeys();
}
