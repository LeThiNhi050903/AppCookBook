import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../core/utils/auth_utils.dart';
import '../../data/models/recipe.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore get firestore => _db;
  FirebaseAuth get auth => _auth;
  CollectionReference<Map<String, dynamic>> get _recipes => _db.collection('recipes');
  CollectionReference<Map<String, dynamic>> get _drafts => _db.collection('draft_recipes');
  String? lastError;

  bool get isAdminUser {
    final email = _auth.currentUser?.email;
    return email != null && isAdminEmail(email);
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

  Stream<List<Recipe>> streamPublishedRecipes() {
    return _recipes
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Recipe.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<Recipe>> streamRecipesByCategory(String category) {
    return _recipes
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
          final recipes = snapshot.docs
              .map((e) => Recipe.fromFirestore(e))
              .where(
                (recipe) =>
                    recipe.category.trim().toLowerCase() ==
                    category.trim().toLowerCase(),
              )
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
  required List<RecipeStep> steps,
  required List<File> mainMediaFiles,
  required List<String> mainMediaTypes,
  required List<List<File>> stepMediaFiles,
  required List<List<String>> stepMediaTypes,
  String status = 'published',
}) async {
  try {
    final current = _auth.currentUser;
    if (current == null) return null;
    final recipeRef = _recipes.doc();
    final recipeId = recipeRef.id;

    String? mainMediaUrl;
    String? mainMediaType;

    // Upload ảnh/video đại diện
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

    // Upload media từng bước
    final stepMediaData = <Map<String, dynamic>>[];

    for (int i = 0; i < stepMediaFiles.length; i++) {
      if (stepMediaFiles[i].isEmpty) continue;

      final uploaded = await _uploadMediaFiles(
        files: stepMediaFiles[i],
        types: stepMediaTypes[i],
        recipeId: recipeId,
        userId: current.uid,
        folder: 'step_$i',
      );

      stepMediaData.add({
        "stepIndex": i,
        "media": uploaded,
      });
    }

    // Chuyển các bước thành đúng cấu trúc RecipeStep
    final recipeSteps = <Map<String, dynamic>>[];

    for (int i = 0; i < steps.length; i++) {
      recipeSteps.add({
        "stepNumber": i + 1,
        "title": "Bước ${i + 1}",
        "description": steps[i],
        "images": stepMediaData
            .where((e) => e["stepIndex"] == i)
            .expand((e) => (e["media"] as List))
            .map((e) => e["url"])
            .toList(),
      });
    }

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
      "authorId": current.uid,
      "authorName": current.displayName ?? "Người dùng",
      "authorLocation": "Việt Nam",
      "userId": current.uid,
      "userName": current.displayName ?? current.email ?? "",
      "isAdmin": false,
      "status": status,
      "mainMediaType": mainMediaType ?? "",
      "stepMedia": stepMediaData,
      "createdAt": Timestamp.now(),
      "updatedAt": Timestamp.now(),
      "submittedAt": Timestamp.now(),
      "week": status == "published" ? getCurrentWeek() : 0,
    });

    return recipeId;
  } catch (e) {
    debugPrint("Lỗi createRecipe: $e");
    lastError = e.toString();
    return null;
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
  }) async {
    try {
      final current = _auth.currentUser;
      if (current == null) return null;
      final draftRef = draftId == null
          ? _db.collection('draft_recipes').doc()
          : _db.collection('draft_recipes').doc(draftId);

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
          'steps': steps
            .map((e) => e.toJson())
            .toList(),
          'imageUrl': mainMediaUrl ?? '',
          'image': mainMediaUrl ?? '',
          'mainMediaType': mainMediaType ?? '',
          'stepMedia': stepMediaData,
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
    return _db
        .collection('draft_recipes')
        //.where('userId', isEqualTo: current!.uid)
        //.orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDraft(
      String draftId) async {
    return await _db
        .collection('draft_recipes')
        .doc(draftId)
        .get();
  }

  Future<void> deleteDraft(String draftId) async {
    await _db
        .collection('draft_recipes')
        .doc(draftId)
        .delete();
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