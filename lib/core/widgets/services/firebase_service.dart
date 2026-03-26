import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/recipe.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int getCurrentWeek() {
    final now = DateTime.now();
    return int.parse("${now.year}${now.weekday}");
  }

  Future<List<Recipe>> getTrendingRecipes() async {
    int week = getCurrentWeek();

    final snapshot = await _db
        .collection('recipes')
        .where('week', isEqualTo: week)
        .get();

    return snapshot.docs
        .map((doc) => Recipe.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<List<Recipe>> getAllRecipes() async {
    final snapshot = await _db.collection('recipes').get();

    return snapshot.docs
        .map((doc) => Recipe.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}