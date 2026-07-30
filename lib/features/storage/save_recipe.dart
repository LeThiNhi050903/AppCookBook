import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/recipe_card.dart';
import '../../data/models/recipe.dart';
import '../recipe/recipe_detail_screen.dart';

class SaveRecipeTab extends StatelessWidget {
  const SaveRecipeTab({super.key});
  static final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Recipe>>(
      stream: _firebaseService.streamSavedRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Có lỗi xảy ra\n${snapshot.error}",
              textAlign: TextAlign.center,
            ),
          );
        }
        final recipes = snapshot.data ?? [];
        if (recipes.isEmpty) {
          return const _EmptySavedRecipe();
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: recipes.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final recipe = recipes[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(
                      recipe: recipe,
                    ),
                  ),
                );
              },
              child: RecipeCard(
                recipe: recipe,
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptySavedRecipe extends StatelessWidget {
  const _EmptySavedRecipe();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 90,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              "Chưa có công thức đã lưu",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Nhấn biểu tượng lưu ở trang chi tiết công thức để lưu món ăn yêu thích.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}