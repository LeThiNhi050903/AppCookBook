import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/models/recipe.dart';

class RecipeImportService {
  RecipeImportService._();

  static final RecipeImportService instance = RecipeImportService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Chỉ gọi khi khởi động ứng dụng
  Future<void> initializeRecipes() async {
    try {
      debugPrint("========== KIỂM TRA DỮ LIỆU ==========");

      final snapshot = await _firestore
          .collection('recipes')
          .limit(1)
          .get();

      // Nếu đã có dữ liệu thì bỏ qua
      if (snapshot.docs.isNotEmpty) {
        debugPrint("Đã có dữ liệu mặc định.");
        return;
      }

      debugPrint("Firestore đang trống.");
      debugPrint("Bắt đầu import recipes.json...");

      await _importRecipes();

      debugPrint("Import hoàn tất.");
    } catch (e) {
      debugPrint("Lỗi initializeRecipes: $e");
    }
  }

  Future<void> _importRecipes() async {
    final jsonString =
        await rootBundle.loadString("assets/data/recipes.json");
    final List<dynamic> jsonData = json.decode(jsonString);
    final batch = _firestore.batch();

    for (final item in jsonData) {
      final recipe = Recipe.fromJson(item);

      final doc = _firestore.collection("recipes").doc(recipe.id);

      final data = recipe.toFirestore();

      // Các trường chỉ có trong Firestore
      data["servings"] = "";
      data["status"] = "published";
      data["mainMediaType"] = "image";
      data["stepMedia"] = [];
      data["updatedAt"] = Timestamp.now();
      data["submittedAt"] = Timestamp.now();
      data["week"] = 0;

      batch.set(doc, data);

      debugPrint("Import: ${recipe.id}");
    }

    await batch.commit();

    debugPrint(
      "Đã import ${jsonData.length} công thức mặc định.",
    );
  }
}