import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static const String _keyCachedData = 'cached_mock_data';
  static const String _keyOfflineQueue = 'offline_pending_queue';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyBiometricEnabled = 'biometric_enabled';

  Future<void> saveCachedData(String jsonString) async {
    await _prefs.setString(_keyCachedData, jsonString);
  }

  String? getCachedData() {
    return _prefs.getString(_keyCachedData);
  }

  Future<void> savePendingQueue(List<String> queueJsonList) async {
    await _prefs.setStringList(_keyOfflineQueue, queueJsonList);
  }

  List<String> getPendingQueue() {
    return _prefs.getStringList(_keyOfflineQueue) ?? [];
  }

  Future<void> clearPendingQueue() async {
    await _prefs.remove(_keyOfflineQueue);
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'dark';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(_keyBiometricEnabled, enabled);
  }

  bool isBiometricEnabled() {
    return _prefs.getBool(_keyBiometricEnabled) ?? false;
  }
}
