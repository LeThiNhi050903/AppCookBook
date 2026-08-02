import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageService {
  ProfileImageService._internal();
  static final ProfileImageService instance = ProfileImageService._internal();
  final ValueNotifier<String?> avatarPath = ValueNotifier<String?>(null);
  static const _kPrefsKey = 'profile_avatar_path';

  String? _keyForCurrentUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null ? '$_kPrefsKey:$uid' : null;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForCurrentUser();
    final path = key == null ? null : prefs.getString(key);
    avatarPath.value = path;
  }

  Future<void> setImagePath(String? path) async {
    avatarPath.value = path;
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForCurrentUser();
    if (key == null) {
      return;
    }
    if (path == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, path);
    }
  }
}
