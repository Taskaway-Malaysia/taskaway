// This file provides cross-platform storage functionality
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional import for web-specific functionality
import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_web.dart' as web_storage;

class WebStorageService {
  // Session storage operations (web only)
  static String? getSessionItem(String key) {
    if (kIsWeb) {
      return web_storage.getSessionItem(key);
    }
    return null;
  }

  static void setSessionItem(String key, String value) {
    if (kIsWeb) {
      web_storage.setSessionItem(key, value);
    }
  }

  static void removeSessionItem(String key) {
    if (kIsWeb) {
      web_storage.removeSessionItem(key);
    }
  }

  // Persistent storage operations (cross-platform)
  static Future<String?> getPersistentItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> setPersistentItem(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> removePersistentItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}