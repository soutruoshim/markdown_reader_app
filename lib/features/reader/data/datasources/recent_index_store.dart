import 'package:shared_preferences/shared_preferences.dart';

/// Thin seam around the metadata index, allowing file-based tests without
/// requiring the platform key/value plugin.
abstract interface class RecentIndexStore {
  Future<String?> read();
  Future<void> write(String json);
}

class SharedPreferencesRecentIndexStore implements RecentIndexStore {
  const SharedPreferencesRecentIndexStore(this._preferences);
  static const String key = 'markdown_recent_documents_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(key);

  @override
  Future<void> write(String json) => _preferences.setString(key, json);
}
