// ignore_for_file: dead_code, unnecessary_null_comparison, unnecessary_cast
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../data/models/recipe.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore get firestore => _db;
  FirebaseAuth get auth => _auth;
  String? lastError;

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot query = await _db
            .collection('users')
            .where('uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          return query.docs.first.data() as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint("Lỗi FirebaseService (getUserProfile): $e");
    }
    return null;
  }
  int getCurrentWeek() {
    final now = DateTime.now();
    return int.parse("${now.year}${now.weekday}");
  }

  Future<List<Recipe>> getTrendingRecipes() async {
    try {
      int week = getCurrentWeek();
      final snapshot = await _db
          .collection('recipes')
          .where('week', isEqualTo: week)
          .get();

      return snapshot.docs
          .map((doc) => Recipe.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Lỗi lấy món thịnh hành: $e");
      return [];
    }
  }

  Future<List<Recipe>> getAllRecipes() async {
    try {
      final snapshot = await _db.collection('recipes').get();
      return snapshot.docs
          .map((doc) => Recipe.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Lỗi lấy tất cả món ăn: $e");
      return [];
    }
  }

  // Search users by username (case-insensitive, prefix match)
  Future<List<Map<String, dynamic>>> searchUsersByUsername(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      final q = query.trim().toLowerCase();
      // Try range query on usernameLower (if present)
      final snapshot = await _db
          .collection('users')
          .where('usernameLower', isGreaterThanOrEqualTo: q)
          .where('usernameLower', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(50)
          .get();

      var results = snapshot.docs
          .map((doc) {
            final raw = doc.data();
            final data = raw != null ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
            return {...data, 'uid': doc.id};
          })
          .toList();

      if (results.isNotEmpty) return results;

      // Fallback: fetch a small set and filter client-side (handles cases where usernameLower not set)
      final fallback = await _db.collection('users').limit(50).get();
      return fallback.docs
          .map((doc) {
            final raw = doc.data();
            final data = raw != null ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
            return {...data, 'uid': doc.id};
          })
          .where((u) {
            final name = (u['username'] ?? '').toString().toLowerCase();
            return name.contains(q) || name.startsWith(q);
          })
          .toList();
    } catch (e) {
      debugPrint('Lỗi searchUsersByUsername: $e');
      lastError = e.toString();
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final raw = doc.data();
        final data = raw != null ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        return {...data, 'uid': doc.id};
      }
    } catch (e) {
      debugPrint('Lỗi getUserByUid: $e');
      lastError = e.toString();
    }
    return null;
  }

  Future<bool> sendFriendRequest(String toUid) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return false;
      final fromUid = current.uid;
      final batch = _db.batch();
      final toRef = _db.collection('users').doc(toUid);
      final meRef = _db.collection('users').doc(fromUid);
      batch.update(toRef, {'friendRequests': FieldValue.arrayUnion([fromUid])});
      batch.update(meRef, {'outgoingRequests': FieldValue.arrayUnion([toUid])});
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Lỗi sendFriendRequest: $e');
      lastError = e.toString();
      return false;
    }
  }

  Future<bool> cancelFriendRequest(String toUid) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return false;
      final fromUid = current.uid;
      final batch = _db.batch();
      final toRef = _db.collection('users').doc(toUid);
      final meRef = _db.collection('users').doc(fromUid);
      batch.update(toRef, {'friendRequests': FieldValue.arrayRemove([fromUid])});
      batch.update(meRef, {'outgoingRequests': FieldValue.arrayRemove([toUid])});
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Lỗi cancelFriendRequest: $e');
      lastError = e.toString();
      return false;
    }
  }

  Future<bool> acceptFriendRequest(String fromUid) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return false;
      final myUid = current.uid;
      final batch = _db.batch();
      final myRef = _db.collection('users').doc(myUid);
      final otherRef = _db.collection('users').doc(fromUid);

      batch.update(myRef, {
        'friendRequests': FieldValue.arrayRemove([fromUid]),
        'friends': FieldValue.arrayUnion([fromUid])
      });
      batch.update(otherRef, {
        'friends': FieldValue.arrayUnion([myUid]),
        'outgoingRequests': FieldValue.arrayRemove([myUid])
      });
      // Also ensure any outgoingRequests entries cleaned up both sides
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Lỗi acceptFriendRequest: $e');
      lastError = e.toString();
      return false;
    }
  }

  Future<bool> followUser(String targetUid) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return false;
      final myUid = current.uid;
      final batch = _db.batch();
      final myRef = _db.collection('users').doc(myUid);
      final targetRef = _db.collection('users').doc(targetUid);

      batch.update(myRef, {
        'followingCount': FieldValue.increment(1),
        'following': FieldValue.arrayUnion([targetUid])
      });
      batch.update(targetRef, {
        'followersCount': FieldValue.increment(1),
        'followers': FieldValue.arrayUnion([myUid])
      });
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Lỗi followUser: $e');
      lastError = e.toString();
      return false;
    }
  }

  Future<bool> unfollowUser(String targetUid) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return false;
      final myUid = current.uid;
      final batch = _db.batch();
      final myRef = _db.collection('users').doc(myUid);
      final targetRef = _db.collection('users').doc(targetUid);

      batch.update(myRef, {
        'followingCount': FieldValue.increment(-1),
        'following': FieldValue.arrayRemove([targetUid])
      });
      batch.update(targetRef, {
        'followersCount': FieldValue.increment(-1),
        'followers': FieldValue.arrayRemove([myUid])
      });
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Lỗi unfollowUser: $e');
      lastError = e.toString();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFriendRequests() async {
    try {
      final current = _auth.currentUser;
      if (current == null) return [];
      final uid = current.uid;
      final doc = await _db.collection('users').doc(uid).get();
      final raw = doc.data();
      final data = raw != null ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final reqs = (data['friendRequests'] as List?) ?? [];
      final results = <Map<String, dynamic>>[];
      for (var r in reqs) {
        final u = await getUserByUid(r);
        if (u != null) results.add(u);
      }
      return results;
    } catch (e) {
      debugPrint('Lỗi getFriendRequests: $e');
      lastError = e.toString();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFriendsList() async {
    try {
      final current = _auth.currentUser;
      if (current == null) return [];
      final uid = current.uid;
      final doc = await _db.collection('users').doc(uid).get();
      final raw = doc.data();
      final data = raw != null ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final friends = (data['friends'] as List?) ?? [];
      final results = <Map<String, dynamic>>[];
      for (var f in friends) {
        final u = await getUserByUid(f);
        if (u != null) results.add(u);
      }
      return results;
    } catch (e) {
      debugPrint('Lỗi getFriendsList: $e');
      lastError = e.toString();
      return [];
    }
  }

  Future<bool> removeFriend(String otherUid) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return false;
      final myUid = current.uid;
      final batch = _db.batch();
      final myRef = _db.collection('users').doc(myUid);
      final otherRef = _db.collection('users').doc(otherUid);
      batch.update(myRef, {
        'friends': FieldValue.arrayRemove([otherUid])
      });
      batch.update(otherRef, {
        'friends': FieldValue.arrayRemove([myUid])
      });
      batch.update(myRef, {
        'following': FieldValue.arrayRemove([otherUid]),
        'followers': FieldValue.arrayRemove([otherUid]),
      });
      batch.update(otherRef, {
        'following': FieldValue.arrayRemove([myUid]),
        'followers': FieldValue.arrayRemove([myUid]),
      });
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Lỗi removeFriend: $e');
      lastError = e.toString();
      return false;
    }
  }

  Future<String?> createRecipe({
    required String title,
    required String category,
    required String servings,
    required List<String> ingredients,
    required List<String> steps,
    required List<File> mainMediaFiles,
    required List<String> mainMediaTypes,
    required List<List<File>> stepMediaFiles,
    required List<List<String>> stepMediaTypes,
  }) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return null;

      final recipeRef = _db.collection('recipes').doc();
      final recipeId = recipeRef.id;
      String? mainMediaUrl;
      String? mainMediaType;

      if (mainMediaFiles.isNotEmpty) {
        final uploaded = await _uploadMediaFiles(
          files: mainMediaFiles,
          types: mainMediaTypes,
          recipeId: recipeId,
          userId: current.uid,
          folder: 'main',
        );
        if (uploaded.isNotEmpty) {
          mainMediaUrl = uploaded.first['url'] as String?;
          mainMediaType = uploaded.first['type'] as String?;
        }
      }

      final stepMediaData = <Map<String, dynamic>>[];
      for (var i = 0; i < stepMediaFiles.length; i++) {
        final mediaFiles = stepMediaFiles[i];
        final mediaTypes = stepMediaTypes[i];
        if (mediaFiles.isEmpty) continue;
        final uploaded = await _uploadMediaFiles(
          files: mediaFiles,
          types: mediaTypes,
          recipeId: recipeId,
          userId: current.uid,
          folder: 'step_$i',
        );
        stepMediaData.add({
          'stepIndex': i,
          'media': uploaded,
        });
      }

      await recipeRef.set({
        'id': recipeId,
        'title': title,
        'name': title,
        'userId': current.uid,
        'imageUrl': mainMediaUrl ?? '',
        'image': mainMediaUrl ?? '',
        'category': category,
        'servings': servings,
        'ingredients': ingredients,
        'steps': steps,
        'stepMedia': stepMediaData,
        'mainMediaType': mainMediaType ?? '',
        'createdAt': Timestamp.now(),
        'week': getCurrentWeek(),
      });
      return recipeId;
    } catch (e) {
      debugPrint('Lỗi createRecipe: $e');
      lastError = e.toString();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _uploadMediaFiles({
    required List<File> files,
    required List<String> types,
    required String recipeId,
    required String userId,
    required String folder,
  }) async {
    final uploaded = <Map<String, dynamic>>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final ext = file.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
      final ref = FirebaseStorage.instance.ref().child('recipes/$userId/$recipeId/$folder/$fileName');
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      uploaded.add({'url': url, 'type': types[i]});
    }
    return uploaded;
  }
  Future<int> migrateUsers({int batchSize = 500}) async {
    try {
      final snapshot = await _db.collection('users').get();
      int updated = 0;
      WriteBatch batch = _db.batch();
      int counter = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final updates = <String, dynamic>{};
        if (!data.containsKey('usernameLower')) {
          updates['usernameLower'] = (data['username'] ?? '').toString().toLowerCase();
        }
        if (!data.containsKey('followers')) updates['followers'] = [];
        if (!data.containsKey('following')) updates['following'] = [];
        if (!data.containsKey('outgoingRequests')) updates['outgoingRequests'] = [];
        if (!data.containsKey('friends')) updates['friends'] = [];
        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
          updated++;
        }
        counter++;
        if (counter >= batchSize) {
          await batch.commit();
          batch = _db.batch();
          counter = 0;
        }
      }
      if (counter > 0) await batch.commit();
      return updated;
    } catch (e) {
      debugPrint('Lỗi migrateUsers: $e');
      lastError = e.toString();
      return 0;
    }
  }
}