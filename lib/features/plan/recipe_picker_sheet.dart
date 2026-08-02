import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/recipe.dart';

class RecipePickerSheet extends StatefulWidget {
  const RecipePickerSheet({
    super.key,
    required this.onSelected,
  });
  final ValueChanged<Recipe> onSelected;

  @override
  State<RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<RecipePickerSheet> {
  final FirebaseService firebaseService = FirebaseService();
  final ScrollController _categoryController = ScrollController();
  final List<String> categories = [
    "Món chiên",
    "Món xào",
    "Món hấp",
    "Món kho",
    "Món chay",
    "Món canh",
    "Món nước",
    "Món chè",
    "Món kem",
    "Salad",
    "Thức uống",
    "Gỏi/nộm",
    "Bánh ngọt",
    "Cháo/súp",
  ];
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            const SizedBox(height: 18),
            _buildCategory(),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<Recipe>>(
                stream: firebaseService.streamRecipesByCategory(
                  categories[selectedIndex],
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }
                  final recipes = snapshot.data!;
                  if (recipes.isEmpty) {
                    return const Center(
                      child: Text(
                        "Chưa có công thức",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: recipes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: .83,
                    ),
                    itemBuilder: (_, index) {
                      final recipe = recipes[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          widget.onSelected(recipe);
                          Navigator.pop(context);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  recipe.thumbnail,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recipe.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:Colors.black87,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        controller: _categoryController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final selected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(
              right: 8,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                _scrollToCenter(index);
              },
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ),
                curve: Curves.ease,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? Colors.orange : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected ? Colors.orange : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    categories[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _scrollToCenter(int index) {
    if (!_categoryController.hasClients) return;
    double estimatedWidth(String text) {
      final textLength = text.length;
      if (textLength <= 6) return 90;
      if (textLength <= 10) return 110;
      if (textLength <= 14) return 130;
      return 150;
    }
    double offset = 0;
    for (int i = 0; i < index; i++) {
      offset += estimatedWidth(categories[i]) + 8;
    }
    final target = offset - (MediaQuery.of(context).size.width / 2) + estimatedWidth(categories[index]) / 2;
    _categoryController.animateTo(
      target.clamp(
        0.0,
        _categoryController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }
}