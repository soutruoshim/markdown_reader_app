import 'package:shared_preferences/shared_preferences.dart';

/// Thin seam around the metadata index, allowing file-based tests without
/// requiring the platform key/value plugin.
abstract interface class RecentIndexStore {
  Future<String?> read();
  Future<void> write(String json);
}

class SharedPreferencesRecentIndexStore implements RecentIndexStore {
  const SharedPreferencesRecentIndexStore([
    this._preferencesFactory = SharedPreferences.getInstance,
  ]);

  static const String key = 'markdown_recent_documents_v1';
  final Future<SharedPreferences> Function() _preferencesFactory;

  @override
  Future<String?> read() async {
    final prefs = await _preferencesFactory();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String json) async {
    final prefs = await _preferencesFactory();
    await prefs.setString(key, json);
  }
}
