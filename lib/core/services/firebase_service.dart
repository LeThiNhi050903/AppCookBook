import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/auth_utils.dart';
import '../../data/models/recipe.dart';

enum RecipeCreationMode { admin, user }

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _users = FirebaseFirestore.instance.collection('users');
  FirebaseFirestore get firestore => _db;
  FirebaseAuth get auth => _auth;
  CollectionReference<Map<String, dynamic>> get _recipes => _db.collection('recipes');
  CollectionReference<Map<String, dynamic>> get _reviewRequests => _db.collection('recipe_review_requests');
  CollectionReference<Map<String, dynamic>> get _usersCollection => _db.collection('users');
  CollectionReference<Map<String, dynamic>> _savedRecipesRef(String uid) {
    return _usersCollection.doc(uid).collection('savedRecipes');
  }

  CollectionReference<Map<String, dynamic>> _draftRecipesRef(String uid) {
    return _db.collection('users').doc(uid).collection('draft_recipes');
  }

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) {
    return _usersCollection.doc(uid).collection('notifications');
  }

  Future<void> sendUserNotification(
    String userId,
    String title,
    String message,
  ) async {
    try {
      await _notificationsRef(userId).add({
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Lỗi sendUserNotification: $e');
    }
  }

  String? lastError;
  static bool _adminModeCache = false;

  static const String _adminUserId = 'admin';

  bool get isAdminModeActive => _adminModeCache;

  String? get currentUserId {
    return _auth.currentUser?.uid ?? (_adminModeCache ? _adminUserId : null);
  }

  bool get isAdminUser {
    final email = _auth.currentUser?.email;
    return _adminModeCache || (email != null && isAdminEmail(email));
  }

  static RecipeCreationMode resolveCreationMode(
    String? email, {
    bool adminModeOverride = false,
  }) {
    final isAdmin = adminModeOverride || (email != null && isAdminEmail(email));
    return isAdmin ? RecipeCreationMode.admin : RecipeCreationMode.user;
  }

  Future<void> setAdminMode(bool enabled) async {
    _adminModeCache = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_mode', enabled);
    } catch (e) {
      debugPrint('setAdminMode error: $e');
    }
  }

  Future<bool> loadAdminMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _adminModeCache = prefs.getBool('admin_mode') ?? false;
      return _adminModeCache;
    } catch (e) {
      debugPrint('loadAdminMode error: $e');
      return _adminModeCache;
    }
  }

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

  Stream<QuerySnapshot<Map<String, dynamic>>> getPublishedRecipesByCategory(String category) {
    return _recipes
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserRecipes(String uid) {
    return _recipes
        .where('userId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingRecipes() {
    return _recipes
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReviewRequestsForAdmin() {
    return _reviewRequests
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserReviewStatus(String uid) {
    return _reviewRequests
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  Future<bool> reviewRecipe(
    String recipeId,
    String status, {
    String? reviewReason,
  }) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return false;
      final data = <String, dynamic>{
        'status': status,
        'reviewedBy': current.uid,
        'reviewedAt': Timestamp.now(),
        'reviewReason': reviewReason ?? '',
        'updatedAt': Timestamp.now(),
      };
      if (status == 'published') {
        data['week'] = getCurrentWeek();
      }
      await _recipes.doc(recipeId).update(data);
      return true;
    } catch (e) {
      debugPrint('Lỗi reviewRecipe: $e');
      lastError = e.toString();
      return false;
    }
  }

  Future<String?> createUserDraft({
    String? draftId,
    required String title,
    required String category,
    required String servings,
    required List<String> ingredients,
    required List<RecipeStep> steps,
    required List<File> mainMediaFiles,
    required List<String> mainMediaTypes,
    required List<List<File>> stepMediaFiles,
    required List<List<String>> stepMediaTypes,
  }) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return null;
      DocumentReference<Map<String, dynamic>> draftRef;
      if (draftId == null) {
        draftRef = _draftRecipesRef(current.uid).doc();
      } else {
        final existing = await _draftRecipesRef(current.uid).doc(draftId).get();
        if (!existing.exists || existing.data()?['userId'] != current.uid) {
          draftRef = _draftRecipesRef(current.uid).doc();
        } else {
          draftRef = _draftRecipesRef(current.uid).doc(draftId);
        }
      }

      final id = draftRef.id;
      String? mainMediaUrl;
      String? mainMediaType;
      if (mainMediaFiles.isNotEmpty) {
        final uploaded = await _uploadMediaFiles(
          files: mainMediaFiles,
          types: mainMediaTypes,
          recipeId: id,
          userId: current.uid,
          folder: 'draft_main',
        );
        if (uploaded.isNotEmpty) {
          mainMediaUrl = uploaded.first['url'];
          mainMediaType = uploaded.first['type'];
        }
      }
      final stepMediaData = <Map<String, dynamic>>[];
      for (int i = 0; i < stepMediaFiles.length; i++) {
        if (stepMediaFiles[i].isEmpty) continue;
        final uploaded = await _uploadMediaFiles(
          files: stepMediaFiles[i],
          types: stepMediaTypes[i],
          recipeId: id,
          userId: current.uid,
          folder: 'draft_step_$i',
        );
        stepMediaData.add({
          'stepIndex': i,
          'media': uploaded,
        });
      }
      await draftRef.set(
        {
          'id': id,
          'userId': current.uid,
          'title': title,
          'name': title,
          'category': category,
          'servings': servings,
          'ingredients': ingredients,
          'steps': steps.map((e) => e.toJson()).toList(),
          'imageUrl': mainMediaUrl ?? '',
          'image': mainMediaUrl ?? '',
          'mainMediaType': mainMediaType ?? '',
          'stepMedia': stepMediaData,
          'status': 'draft',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
      return id;
    } catch (e) {
      debugPrint("Lỗi createUserDraft: $e");
      lastError = e.toString();
      return null;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserDrafts() {
    final current = _auth.currentUser;
    if (current == null) {
      return const Stream.empty();
    }
    return _draftRecipesRef(current.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserDraft(String draftId) async {
    final current = _auth.currentUser;
    if (current == null) return null;
    final doc = await _draftRecipesRef(current.uid).doc(draftId).get();
    if (!doc.exists) return null;
    return doc;
  }

  Future<void> deleteUserDraft(String draftId) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return;
      final docRef = _draftRecipesRef(current.uid).doc(draftId);
      final doc = await docRef.get();
      if (!doc.exists) return;
      await docRef.delete();
    } catch (e) {
      debugPrint('Lỗi deleteUserDraft: $e');
    }
  }

Stream<List<Recipe>> streamPublishedRecipes() {
  return _recipes
      .where('status', isEqualTo: 'published')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        debugPrint(
            "========== Published Recipes ==========");
        debugPrint(
            "Docs: ${snapshot.docs.length}");
        for (final doc in snapshot.docs) {
          debugPrint(doc.data().toString());
        }
        return snapshot.docs
            .map((doc) => Recipe.fromFirestore(doc))
            .toList();
      });
}

  Stream<List<Recipe>> streamRecipesByCategory(String category) {
    return _recipes
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
          final recipes = snapshot.docs
              .map((e) => Recipe.fromFirestore(e))
              .where((recipe) => recipe.category.trim().toLowerCase() == category.trim().toLowerCase(),)
              .toList();
          recipes.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );
          return recipes;
        });
  }

  Stream<List<Recipe>> streamMyRecipes() {
    final current = _auth.currentUser;
    if (current == null) {
      return const Stream.empty();
    }
    return _recipes
        .where('userId', isEqualTo: current.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Recipe.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<Recipe>> streamDraftRecipes() {
    final current = _auth.currentUser;
    if (current == null) {
      return const Stream.empty();
    }
    return _db
        .collection('draft_recipes')
        .where('userId', isEqualTo: current.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Recipe.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _recipes.doc(recipeId).delete();
    } catch (e) {
      debugPrint("Lỗi deleteRecipe: $e");
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _recipes.doc(recipe.id).update({
        ...recipe.toFirestore(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint("Lỗi updateRecipe: $e");
    }
  }

  Future<List<Recipe>> getPublishedRecipes() async {
    try {
      final snapshot = await _recipes
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Recipe.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("Lỗi getPublishedRecipes: $e");
      return [];
    }
  }

  Future<List<Recipe>> searchPublishedRecipes(String keyword) async {
    try {
      final query = keyword.trim().toLowerCase();
      if (query.isEmpty) return [];

      final snapshot = await _recipes
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Recipe.fromFirestore(doc))
          .where((recipe) => recipe.name.toLowerCase().contains(query))
          .toList();
    } catch (e) {
      debugPrint('Lỗi searchPublishedRecipes: $e');
      return [];
    }
  }
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final snapshot = await _recipes
          .where('status', isEqualTo: 'published')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Recipe.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("Lỗi getRecipesByCategory: $e");
      return [];
    }
  }

  Future<Recipe?> getRecipeById(String recipeId) async {
    try {
      final doc = await _recipes.doc(recipeId).get();
      if (!doc.exists) return null;
      return Recipe.fromFirestore(doc);
    } catch (e) {
      debugPrint("Lỗi getRecipeById: $e");
      return null;
    }
  }

  Future<bool> toggleSaveRecipe(String recipeId) async {
    try {
      final current = _auth.currentUser;
      if (current == null) {
        return false;
      }
      final doc = _savedRecipesRef(current.uid).doc(recipeId);
      final snapshot = await doc.get();
      if (snapshot.exists) {
        await doc.delete();
        return false;
      }
      await doc.set({
        "recipeId": recipeId,
        "savedAt": FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint("toggleSaveRecipe: $e");
      lastError = e.toString();
      return false;
    }
  }

  Future<bool> isRecipeSaved(String recipeId) async {
    try {
      final current = _auth.currentUser;
      if (current == null) {
        return false;
      }
      final doc = await _savedRecipesRef(current.uid)
          .doc(recipeId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint("isRecipeSaved: $e");
      return false;
    }
  }

  Stream<bool> streamIsRecipeSaved(String recipeId) {
    final current = _auth.currentUser;
    if (current == null) {
      return const Stream.empty();
    }
    return _savedRecipesRef(current.uid)
        .doc(recipeId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<Recipe>> streamSavedRecipes() {
    final current = _auth.currentUser;
    if (current == null) {
      return const Stream.empty();
    }
    return _savedRecipesRef(current.uid)
        .orderBy(
          "savedAt",
          descending: true,
        )
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Recipe> recipes = [];
          for (final saved in snapshot.docs) {
            final recipeId = saved.data()["recipeId"] as String;
            final recipeDoc = await _recipes.doc(recipeId).get();
            if (recipeDoc.exists) {
              recipes.add(
                Recipe.fromFirestore(recipeDoc),
              );
            }
          }
          return recipes;
        });
  }

  Future<void> removeSavedRecipe(
    String recipeId,
  ) async {
    final current = _auth.currentUser;
    if (current == null) {
      return;
    }
    await _savedRecipesRef(current.uid)
        .doc(recipeId)
        .delete();
  }

  Future<void> saveRecipe(
    String recipeId,
  ) async {
    final current = _auth.currentUser;
    if (current == null) {
      return;
    }
    await _savedRecipesRef(current.uid)
        .doc(recipeId)
        .set({
      "recipeId": recipeId,
      "savedAt":
          FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> searchUsersByUsername(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      final q = query.trim().toLowerCase();
      final snapshot = await _db
          .collection('users')
          .where('usernameLower', isGreaterThanOrEqualTo: q)
          .where('usernameLower', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(50)
          .get();
      var results = snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            return {...data, 'uid': doc.id};
          })
          .toList();
      if (results.isNotEmpty) return results;
      final fallback = await _db.collection('users').limit(50).get();
      return fallback.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
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
    required List<RecipeStep> steps,
    required List<File> mainMediaFiles,
    required List<String> mainMediaTypes,
    required List<List<File>> stepMediaFiles,
    required List<List<String>> stepMediaTypes,
    String status = 'published',
    bool isAdmin = false,
    List<Map<String, dynamic>> existingMainMedia = const [],
    List<List<Map<String, dynamic>>> existingStepMedia = const [],
  }) async {
    try {
      final current = _auth.currentUser;
      if (current == null && !_adminModeCache) return null;
      final uid = current?.uid ?? _adminUserId;
      final creationMode = resolveCreationMode(
        current?.email,
        adminModeOverride: isAdmin || _adminModeCache,
      );
      final recipeRef = _recipes.doc();
      final recipeId = recipeRef.id;
      String? mainMediaUrl;
      String? mainMediaType;
      if (mainMediaFiles.isNotEmpty) {
        final uploaded = await _uploadMediaFiles(
          files: mainMediaFiles,
          types: mainMediaTypes,
          recipeId: recipeId,
          userId: uid,
          folder: 'main',
        );
        if (uploaded.isNotEmpty) {
          mainMediaUrl = uploaded.first['url'] as String?;
          mainMediaType = uploaded.first['type'] as String?;
        }
      }
      if (mainMediaUrl == null && existingMainMedia.isNotEmpty) {
        mainMediaUrl = existingMainMedia.first['url'] as String?;
        mainMediaType = existingMainMedia.first['type'] as String?;
      }
      final stepMediaData = <Map<String, dynamic>>[];
      for (int i = 0; i < stepMediaFiles.length; i++) {
        final existingMedia = i < existingStepMedia.length ? existingStepMedia[i] : const [];
        final uploaded = <Map<String, dynamic>>[];
        if (stepMediaFiles[i].isNotEmpty) {
          final result = await _uploadMediaFiles(
            files: stepMediaFiles[i],
            types: stepMediaTypes[i],
            recipeId: recipeId,
            userId: uid,
            folder: 'step_$i',
          );
          uploaded.addAll(result);
        }
        final mergedMedia = [...existingMedia, ...uploaded];
        if (mergedMedia.isNotEmpty) {
          stepMediaData.add({
            "stepIndex": i,
            "media": mergedMedia,
          });
        }
      }
      final recipeSteps = <Map<String, dynamic>>[];
      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];
        recipeSteps.add({
          "stepNumber": step.stepNumber,
          "title": step.title.isNotEmpty ? step.title : "Bước ${i + 1}",
          "description": step.description,
          "images": stepMediaData
              .where((e) => e["stepIndex"] == i)
              .expand((e) => (e["media"] as List))
              .map((e) => e["url"])
              .toList(),
        });
      }
      final userDoc = current != null ? await _users.doc(uid).get() : null;
      final userData = userDoc?.data() ?? {};
      final String authorName =
          (userData["username"] as String?)?.trim().isNotEmpty == true
              ? userData["username"]
              : (current?.displayName ?? "Admin");
      final String authorAvatar =
          (userData["avatarUrl"] as String?)?.trim().isNotEmpty == true
              ? userData["avatarUrl"]
              : (current?.photoURL ?? "");
      final String authorLocation =
          (userData["location"] as String?)?.trim().isNotEmpty == true
              ? userData["location"]
              : "Việt Nam";
      final bool isAdminFlow = creationMode == RecipeCreationMode.admin;
      final String saveStatus = isAdminFlow ? 'published' : (status == 'published' ? 'pending' : status);
      await recipeRef.set({
        "id": recipeId,
        "name": title,
        "title": title,
        "category": category,
        "thumbnail": mainMediaUrl ?? "",
        "image": mainMediaUrl ?? "",
        "imageUrl": mainMediaUrl ?? "",
        "ingredientTitle": "Nguyên liệu",
        "ingredients": ingredients,
        "steps": recipeSteps,
        "servings": servings,
        "authorId": uid,
        "authorName": authorName,
        "authorLocation": authorLocation,
        "authorAvatar": authorAvatar,
        "userId": uid,
        "userName": authorName,
        "userAvatar": authorAvatar,
        "isAdmin": isAdminFlow,
        "createdByRole": isAdminFlow ? 'admin' : 'user',
        "status": saveStatus,
        "mainMediaType": mainMediaType ?? "",
        "stepMedia": stepMediaData,
        "createdAt": Timestamp.now(),
        "updatedAt": Timestamp.now(),
        "submittedAt": Timestamp.now(),
        "week": saveStatus == "published" ? getCurrentWeek() : 0,
      });
      return recipeId;
    } catch (e) {
      debugPrint("Lỗi createRecipe: $e");
      lastError = e.toString();
      return null;
    }
  }

  Future<String?> createReviewRequest({
    String? requestId,
    required String title,
    required String category,
    required String servings,
    required List<String> ingredients,
    required List<RecipeStep> steps,
    required List<File> mainMediaFiles,
    required List<String> mainMediaTypes,
    required List<List<File>> stepMediaFiles,
    required List<List<String>> stepMediaTypes,
    List<Map<String, dynamic>> existingMainMedia = const [],
    List<List<Map<String, dynamic>>> existingStepMedia = const [],
  }) async {
    try {
      final current = _auth.currentUser;
      if (current == null && !_adminModeCache) return null;
      final uid = current?.uid ?? _adminUserId;
      final requestRef = requestId == null
          ? _reviewRequests.doc()
          : _reviewRequests.doc(requestId);
      final id = requestRef.id;
      String? mainMediaUrl;
      String? mainMediaType;
      if (mainMediaFiles.isNotEmpty) {
        final uploaded = await _uploadMediaFiles(
          files: mainMediaFiles,
          types: mainMediaTypes,
          recipeId: id,
          userId: uid,
          folder: 'review_main',
        );
        if (uploaded.isNotEmpty) {
          mainMediaUrl = uploaded.first['url'];
          mainMediaType = uploaded.first['type'];
        }
      }
      if (mainMediaUrl == null && existingMainMedia.isNotEmpty) {
        mainMediaUrl = existingMainMedia.first['url'] as String?;
        mainMediaType = existingMainMedia.first['type'] as String?;
      }
      final stepMediaData = <Map<String, dynamic>>[];
      for (int i = 0; i < stepMediaFiles.length; i++) {
        final existingMedia = i < existingStepMedia.length ? existingStepMedia[i] : const [];
        final uploaded = <Map<String, dynamic>>[];
        if (stepMediaFiles[i].isNotEmpty) {
          final result = await _uploadMediaFiles(
            files: stepMediaFiles[i],
            types: stepMediaTypes[i],
            recipeId: id,
            userId: uid,
            folder: 'review_step_$i',
          );
          uploaded.addAll(result);
        }
        final mergedMedia = [...existingMedia, ...uploaded];
        if (mergedMedia.isNotEmpty) {
          stepMediaData.add({
            'stepIndex': i,
            'media': mergedMedia,
          });
        }
      }
      final userDoc = current != null ? await _users.doc(uid).get() : null;
      final userData = userDoc?.data() ?? {};
      final String authorName =
          (userData["username"] as String?)?.trim().isNotEmpty == true
              ? userData["username"]
              : (current?.displayName ?? "Admin");
      final String authorAvatar =
          (userData["avatarUrl"] as String?)?.trim().isNotEmpty == true
              ? userData["avatarUrl"]
              : (current?.photoURL ?? "");
      final String authorLocation =
          (userData["location"] as String?)?.trim().isNotEmpty == true
              ? userData["location"]
              : "Việt Nam";
      final recipeSteps = <Map<String, dynamic>>[];
      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];
        recipeSteps.add({
          "stepNumber": step.stepNumber,
          "title": step.title.isNotEmpty ? step.title : "Bước ${i + 1}",
          "description": step.description,
          "images": stepMediaData
              .where((e) => e["stepIndex"] == i)
              .expand((e) => (e["media"] as List))
              .map((e) => e["url"])
              .toList(),
        });
      }
      await requestRef.set({
        "id": id,
        "title": title,
        "name": title,
        "category": category,
        "thumbnail": mainMediaUrl ?? "",
        "image": mainMediaUrl ?? "",
        "imageUrl": mainMediaUrl ?? "",
        "ingredientTitle": "Nguyên liệu",
        "ingredients": ingredients,
        "steps": recipeSteps,
        "servings": servings,
        "authorId": uid,
        "authorName": authorName,
        "authorLocation": authorLocation,
        "authorAvatar": authorAvatar,
        "userId": uid,
        "userName": authorName,
        "userAvatar": authorAvatar,
        "isAdmin": false,
        "status": 'pending',
        "reviewReason": '',
        "createdByRole": 'user',
        "mainMediaType": mainMediaType ?? "",
        "stepMedia": stepMediaData,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "submittedAt": FieldValue.serverTimestamp(),
      });
      return id;
    } catch (e) {
      debugPrint("Lỗi createReviewRequest: $e");
      lastError = e.toString();
      return null;
    }
  }

  Future<bool> approveReviewRequest(String requestId) async {
    try {
      final requestDoc = await _reviewRequests.doc(requestId).get();
      if (!requestDoc.exists) return false;
      final data = requestDoc.data()!;
      final newRecipeRef = _recipes.doc();
      final newRecipeId = newRecipeRef.id;
      final publishedData = {
        ...data,
        'id': newRecipeId,
        'status': 'published',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _auth.currentUser?.uid ?? '',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewReason': '',
        'week': getCurrentWeek(),
      };
      await newRecipeRef.set(publishedData);
      await _reviewRequests.doc(requestId).update({
        'status': 'approved',
        'reviewedBy': _auth.currentUser?.uid ?? '',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewReason': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final String userId = data['userId'] ?? '';
      if (userId.isNotEmpty) {
        await sendUserNotification(
          userId,
          'Công thức đã được duyệt',
          'Công thức "${data['title']}" của bạn đã được admin phê duyệt.',
        );
      }
      return true;
    } catch (e) {
      debugPrint('Lỗi approveReviewRequest: $e');
      lastError = e.toString();
      return false;
    }
  }

  Future<bool> rejectReviewRequest(
    String requestId,
    String reason,
  ) async {
    try {
      final requestDoc = await _reviewRequests.doc(requestId).get();
      if (!requestDoc.exists) return false;
      final data = requestDoc.data()!;
      final userId = data['userId'] as String? ?? '';
      await _reviewRequests.doc(requestId).update({
        'status': 'rejected',
        'reviewReason': reason,
        'reviewedBy': _auth.currentUser?.uid ?? '',
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (userId.isNotEmpty) {
        await sendUserNotification(
          userId,
          'Công thức bị từ chối',
          'Công thức "${data['title']}" đã bị từ chối: $reason',
        );
        final draftId = _draftRecipesRef(userId).doc().id;
        await _draftRecipesRef(userId).doc(draftId).set({
          'id': draftId,
          'userId': userId,
          'title': data['title'] ?? '',
          'name': data['title'] ?? '',
          'category': data['category'] ?? '',
          'servings': data['servings'] ?? '',
          'ingredients': List<String>.from(data['ingredients'] ?? []),
          'steps': data['steps'] ?? [],
          'imageUrl': data['imageUrl'] ?? '',
          'image': data['imageUrl'] ?? '',
          'mainMediaType': data['mainMediaType'] ?? '',
          'stepMedia': data['stepMedia'] ?? [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'draft',
          'reviewReason': reason,
          'sourceRequestId': requestId,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Lỗi rejectReviewRequest: $e');
      lastError = e.toString();
      return false;
    }
  }

  Future<bool> updateRecipeStatus(
    String recipeId,
    String status, {
    String? reviewReason,
  }) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return false;
      final data = <String, dynamic>{
        'status': status,
        'reviewedBy': current.uid,
        'reviewedAt': Timestamp.now(),
        'reviewReason': reviewReason ?? '',
        'updatedAt': Timestamp.now(),
      };
      if (status == 'published') {
        data['week'] = getCurrentWeek();
      }
      await _recipes.doc(recipeId).update(data);
      return true;
    } catch (e) {
      debugPrint('Lỗi updateRecipeStatus: $e');
      lastError = e.toString();
      return false;
    }
  }

  Future<String?> saveDraft({
    String? draftId,
    required String title,
    required String category,
    required String servings,
    required List<String> ingredients,
    required List<RecipeStep> steps,
    required List<File> mainMediaFiles,
    required List<String> mainMediaTypes,
    required List<List<File>> stepMediaFiles,
    required List<List<String>> stepMediaTypes,
    List<Map<String, dynamic>> existingMainMedia = const [],
    List<List<Map<String, dynamic>>> existingStepMedia = const [],
  }) async {
    try {
      final current = _auth.currentUser;
      if (current == null && !_adminModeCache) return null;
      final uid = current?.uid ?? _adminUserId;
      DocumentReference<Map<String, dynamic>> draftRef;
      if (draftId == null) {
        draftRef = _draftRecipesRef(uid).doc();
      } else {
        final existing = await _draftRecipesRef(uid).doc(draftId).get();
        if (!existing.exists || existing.data()?['userId'] != uid) {
          draftRef = _draftRecipesRef(uid).doc();
        } else {
          draftRef = _draftRecipesRef(uid).doc(draftId);
        }
      }
      final id = draftRef.id;
      String? mainMediaUrl;
      String? mainMediaType;
      if (mainMediaFiles.isNotEmpty) {
        final uploaded = await _uploadMediaFiles(
          files: mainMediaFiles,
          types: mainMediaTypes,
          recipeId: id,
          userId: uid,
          folder: 'draft_main',
        );
        if (uploaded.isNotEmpty) {
          mainMediaUrl = uploaded.first['url'];
          mainMediaType = uploaded.first['type'];
        }
      }
      if (mainMediaUrl == null && existingMainMedia.isNotEmpty) {
        mainMediaUrl = existingMainMedia.first['url'] as String?;
        mainMediaType = existingMainMedia.first['type'] as String?;
      }
      final stepMediaData = <Map<String, dynamic>>[];
      for (int i = 0; i < stepMediaFiles.length; i++) {
        final existingMedia = i < existingStepMedia.length ? existingStepMedia[i] : const [];
        final uploaded = <Map<String, dynamic>>[];
        if (stepMediaFiles[i].isNotEmpty) {
          final result = await _uploadMediaFiles(
            files: stepMediaFiles[i],
            types: stepMediaTypes[i],
            recipeId: id,
            userId: uid,
            folder: 'draft_step_$i',
          );
          uploaded.addAll(result);
        }
        final mergedMedia = [...existingMedia, ...uploaded];
        if (mergedMedia.isNotEmpty) {
          stepMediaData.add({
            'stepIndex': i,
            'media': mergedMedia,
          });
        }
      }
      await draftRef.set(
        {
          'id': id,
          'userId': uid,
          'title': title,
          'name': title,
          'category': category,
          'servings': servings,
          'ingredients': ingredients,
          'steps': steps
            .map((e) => e.toJson())
            .toList(),
          'imageUrl': mainMediaUrl ?? '',
          'image': mainMediaUrl ?? '',
          'mainMediaType': mainMediaType ?? '',
          'stepMedia': stepMediaData,
          'status': 'draft',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
      );
      return id;
    } catch (e) {
      debugPrint("Lỗi saveDraft: $e");
      lastError = e.toString();
      return null;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDraftRecipes() {
    final current = _auth.currentUser;
    if (current == null && !_adminModeCache) return const Stream.empty();
    final uid = current?.uid ?? _adminUserId;
    return _draftRecipesRef(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getDraft(String draftId) async {
    final current = _auth.currentUser;
    if (current == null && !_adminModeCache) return null;
    final uid = current?.uid ?? _adminUserId;
    final doc = await _draftRecipesRef(uid).doc(draftId).get();
    if (!doc.exists) return null;
    return doc;
  }

  Future<void> deleteDraft(String draftId) async {
    try {
      final current = _auth.currentUser;
      if (current == null && !_adminModeCache) return;
      final uid = current?.uid ?? _adminUserId;
      final docRef = _draftRecipesRef(uid).doc(draftId);
      final doc = await docRef.get();
      if (!doc.exists) return;
      await docRef.delete();
    } catch (e) {
      debugPrint('Lỗi deleteDraft: $e');
    }
  }

  // Plans: stored under users/{uid}/plans to ensure per-user isolation
  CollectionReference<Map<String, dynamic>> _plansRef(String uid) {
    return _db.collection('users').doc(uid).collection('plans');
  }

  Stream<List<Map<String, dynamic>>> streamUserPlans(String uid) {
    return _plansRef(uid)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = Map<String, dynamic>.from(d.data());
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Future<String?> savePlan({
    String? planId,
    required String recipeId,
    required DateTime date,
    required String meal,
    required int quantity,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) return null;
      final ref = planId == null
          ? _plansRef(uid).doc()
          : _plansRef(uid).doc(planId);
      final id = ref.id;
      await ref.set({
        'recipeId': recipeId,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'meal': meal,
        'quantity': quantity,
        'userId': uid,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      return id;
    } catch (e) {
      debugPrint('Lỗi savePlan: $e');
      lastError = e.toString();
      return null;
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      final uid = currentUserId;
      if (uid == null) return;
      await _plansRef(uid).doc(planId).delete();
    } catch (e) {
      debugPrint('Lỗi deletePlan: $e');
    }
  }

  Future<Map<String, dynamic>?> getPlan(String planId) async {
    try {
      final uid = currentUserId;
      if (uid == null) return null;
      final doc = await _plansRef(uid).doc(planId).get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('Lỗi getPlan: $e');
      return null;
    }
  }

  String _contentTypeFromExtension(String ext, String type) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      default:
        return type == 'video' ? 'video/mp4' : 'image/jpeg';
    }
  }

  Future<Map<String, dynamic>?> _uploadMediaFile({
    required File file,
    required String type,
    required String recipeId,
    required String userId,
    required String folder,
    int attempt = 1,
  }) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];
    if (cloudName == null || uploadPreset == null) {
      throw Exception('Cloudinary config missing in .env');
    }
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');
    //final resourceType = type == 'video' ? 'video' : 'image';
    //final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',);
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'recipes/$userId/$recipeId/$folder'
      ..fields['resource_type'] = type == 'video' ? 'video' : 'image'
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(_contentTypeFromExtension(file.path.split('.').last.toLowerCase(), type)),
      ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      //debugPrint(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'url': data['secure_url'] as String, 'type': type};
      }
      debugPrint('Cloudinary upload failed [${response.statusCode}]: ${response.body}');
      if (attempt < 3) {
        await Future.delayed(Duration(seconds: 2 * attempt));
        return _uploadMediaFile(
          file: file,
          type: type,
          recipeId: recipeId,
          userId: userId,
          folder: folder,
          attempt: attempt + 1,
        );
      }
      throw Exception('Cloudinary upload failed: ${response.body}');
    } catch (e) {
      debugPrint('Upload attempt #$attempt failed for $file: $e');
      if (attempt < 3) {
        await Future.delayed(Duration(seconds: 2 * attempt));
        return _uploadMediaFile(
          file: file,
          type: type,
          recipeId: recipeId,
          userId: userId,
          folder: folder,
          attempt: attempt + 1,
        );
      }
      rethrow;
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
      final result = await _uploadMediaFile(
        file: file,
        type: types[i],
        recipeId: recipeId,
        userId: userId,
        folder: folder,
      );
      if (result != null) {
        uploaded.add(result);
      }
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
  Future<void> updateFeaturedRecipes(List<String> recipeIds) async {
    await FirebaseFirestore.instance
        .collection("featured_recipes")
        .doc("home")
        .set({
      "recipeIds": recipeIds,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }
  Stream<List<String>> streamFeaturedRecipeIds() {
    return FirebaseFirestore.instance
        .collection("featured_recipes")
        .doc("home")
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final data = doc.data()!;
      return List<String>.from(data["recipeIds"] ?? []);
    });
  }
  Stream<List<Recipe>> streamFeaturedRecipes() {
    return FirebaseFirestore.instance
        .collection("featured_recipes")
        .doc("home")
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return [];
      final ids = List<String>.from(doc.data()?["recipeIds"] ?? []);
      if (ids.isEmpty) return [];
      final snapshot = await FirebaseFirestore.instance
          .collection("recipes")
          .where(FieldPath.documentId, whereIn: ids)
          .get();
      final recipes = snapshot.docs
          .map((e) => Recipe.fromFirestore(e))
          .toList();
      recipes.sort(
        (a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)),
      );
      return recipes;
    });
  }
  Future<List<String>> getFeaturedRecipeIds() async {
    final doc = await firestore
        .collection("featured_recipes")
        .doc("home")
        .get();
    if (!doc.exists) return [];
    return List<String>.from(doc.data()?["recipeIds"] ?? []);
  }
  Future<void> saveRecentSearch(String keyword) async {
    keyword = keyword.trim();
    if (keyword.isEmpty) return;
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final snapshot = await doc.get();
    List<String> searches = [];
    if (snapshot.exists && snapshot.data()!.containsKey("recentSearch")) {
      searches = List<String>.from(
        snapshot["recentSearch"],
      );
    }
    searches.remove(keyword);
    searches.insert(0, keyword);
    if (searches.length > 10) {
      searches = searches.sublist(0, 10);
    }
    await doc.set({"recentSearch": searches,}, SetOptions(merge: true));
  }
  Stream<List<String>> streamRecentSearch() {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return <String>[];
      }
      final data = snapshot.data();
      if (data == null) { return <String>[]; }
      if (!data.containsKey("recentSearch")) {
        return <String>[];
      }
      return List<String>.from(data["recentSearch"],);
    });
  }
  Future<void> saveRecentViewed(String recipeId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final snapshot = await doc.get();
    List<String> viewed = [];
    if (snapshot.exists &&
        snapshot.data()!.containsKey("recentViewed")) {
      viewed = List<String>.from(
        snapshot["recentViewed"],
      );
    }
    viewed.remove(recipeId);
    viewed.insert(0, recipeId);
    if (viewed.length > 10) {
      viewed = viewed.sublist(0, 10);
    }
    await doc.set({"recentViewed": viewed,}, SetOptions(merge: true,));
  }
  Stream<List<Recipe>> streamRecentViewedRecipes() {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) {
        return <Recipe>[];
      }
      final data = snapshot.data();
      if (data == null || !data.containsKey("recentViewed")) {
        return <Recipe>[];
      }
      final ids = List<String>.from(data["recentViewed"]);
      if (ids.isEmpty) {
        return <Recipe>[];
      }
      final recipeSnapshot = await FirebaseFirestore.instance
          .collection("recipes")
          .where(FieldPath.documentId, whereIn: ids)
          .get();
      final recipes = recipeSnapshot.docs
          .map((e) => Recipe.fromFirestore(e))
          .toList();
      recipes.sort(
        (a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)),
      );
      return recipes;
    });
  }
}
