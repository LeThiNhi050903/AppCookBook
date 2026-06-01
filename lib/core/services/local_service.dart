import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalService {
  static const String _keyUsername = 'username';
  static const String _keyRecentSearch = 'recentSearch';
  static const String _keyRecentViewed = 'recentViewed';
  static const String _keyAiNotes = 'aiNotes';
  static const String _keyAiChatHistory = 'aiChatHistory';

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

  Future<List<Map<String, String>>> getAiNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyAiNotes) ?? [];
    return raw.map((e) {
      try {
        final decoded = jsonDecode(e);
        if (decoded is Map<String, dynamic>) {
          return decoded.map((key, value) => MapEntry(key, value.toString()));
        }
      } catch (_) {
        // Nếu dữ liệu không phải JSON, giữ nguyên nội dung plain text.
      }
      return <String, String>{'title': 'Ghi chú AI', 'content': e};
    }).toList();
  }

  Future<void> saveAiNote(String content, {String? userQuestion}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_keyAiNotes) ?? [];
    final title = userQuestion ?? _extractAiNoteTitle(content);
    final noteData = jsonEncode({'title': title, 'content': content});
    list.removeWhere((item) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          return decoded['content'] == content;
        }
      } catch (_) {
        return item == content;
      }
      return false;
    });
    list.insert(0, noteData);
    if (list.length > 50) list = list.sublist(0, 50);
    await prefs.setStringList(_keyAiNotes, list);
  }

  Future<void> deleteAiNoteAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_keyAiNotes) ?? [];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await prefs.setStringList(_keyAiNotes, list);
    }
  }

  Future<List<List<Map<String, String>>>> getAiChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyAiChatHistory) ?? [];
    return raw.map((item) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is List) {
          return decoded.map<Map<String, String>>((entry) {
            if (entry is Map) {
              return entry.map((key, value) => MapEntry(key.toString(), value.toString()));
            }
            return <String, String>{};
          }).toList();
        }
      } catch (_) {
        // ignore invalid stored entry
      }
      return <Map<String, String>>[];
    }).where((chat) => chat.isNotEmpty).toList();
  }

  Future<void> saveAiChatHistory(List<List<Map<String, String>>> chatHistory) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = chatHistory.map((chat) => jsonEncode(chat)).toList();
    await prefs.setStringList(_keyAiChatHistory, raw);
  }

  String _extractAiNoteTitle(String content) {
    final lines = content.trim().split(RegExp(r'\r?\n'));
    String first = lines.firstWhere(
      (line) => line.trim().isNotEmpty,
      orElse: () => content.trim(),
    );
    if (first.length > 40) {
      first = first.substring(0, 40).trim();
    }
    final sentenceEnd = RegExp(r'[.!?]');
    final match = sentenceEnd.firstMatch(first);
    if (match != null && match.start < 30) {
      first = first.substring(0, match.start + 1);
    }
    return first.isEmpty ? 'Ghi chú AI' : first;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
