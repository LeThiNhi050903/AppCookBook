import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageService {
  ProfileImageService._internal();

  static final ProfileImageService instance = ProfileImageService._internal();

  final ValueNotifier<String?> avatarPath = ValueNotifier<String?>(null);

  static const _kPrefsKey = 'profile_avatar_path';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kPrefsKey);
    avatarPath.value = path;
  }

  Future<void> setImagePath(String? path) async {
    avatarPath.value = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kPrefsKey);
    } else {
      await prefs.setString(_kPrefsKey, path);
    }
  }
}
