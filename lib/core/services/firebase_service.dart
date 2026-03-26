import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/models/recipe.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseFirestore get firestore => _db;
  FirebaseAuth get auth => _auth;

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
}