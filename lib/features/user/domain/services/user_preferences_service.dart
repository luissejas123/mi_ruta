import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para almacenar y recuperar las preferencias generales del usuario.
class UserPreferencesService {
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyLocation = 'location_enabled';
  static const String _keyAutoSync = 'auto_sync_enabled';

  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // ==============================
  // NOTIFICACIONES
  // ==============================

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyNotifications) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyNotifications, value);
  }

  // ==============================
  // UBICACIÓN
  // ==============================

  Future<bool> getLocationEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyLocation) ?? true;
  }

  Future<void> setLocationEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyLocation, value);
  }

  // ==============================
  // SINCRONIZACIÓN AUTOMÁTICA
  // ==============================

  Future<bool> getAutoSyncEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyAutoSync) ?? true;
  }

  Future<void> setAutoSyncEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyAutoSync, value);
  }

  // ==============================
  // TODAS LAS PREFERENCIAS
  // ==============================

  Future<Map<String, bool>> getPreferences() async {
    return {
      'notifications': await getNotificationsEnabled(),
      'location': await getLocationEnabled(),
      'autoSync': await getAutoSyncEnabled(),
    };
  }

  Future<void> clearPreferences() async {
    final prefs = await _prefs;

    await prefs.remove(_keyNotifications);
    await prefs.remove(_keyLocation);
    await prefs.remove(_keyAutoSync);
  }
}
