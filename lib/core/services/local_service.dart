import 'package:shared_preferences/shared_preferences.dart';

class LocalService {
  static const String _keyUsername = 'username';
  static const String _keyRecentSearch = 'recentSearch';
  static const String _keyRecentViewed = 'recentViewed';

  Future<void> saveUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, name);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  Future<List<String>> getRecentSearch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRecentSearch) ?? [];
  }

  Future<void> saveSearch(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_keyRecentSearch) ?? [];
    if (list.contains(keyword)) {
      list.remove(keyword);
    }
    list.insert(0, keyword);
    if (list.length > 10) list = list.sublist(0, 10);
    await prefs.setStringList(_keyRecentSearch, list);
  }

  Future<List<String>> getRecentViewed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRecentViewed) ?? [];
  }

  Future<void> saveViewed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_keyRecentViewed) ?? [];
    if (!list.contains(id)) {
      list.insert(0, id);
    }
    if (list.length > 20) list = list.sublist(0, 20);
    await prefs.setStringList(_keyRecentViewed, list);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}