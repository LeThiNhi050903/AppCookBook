import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/recipe.dart';

class TrendingRecipePickerSheet extends StatefulWidget {
  const TrendingRecipePickerSheet({
    super.key,
  });

  @override
  State<TrendingRecipePickerSheet> createState() =>
      _TrendingRecipePickerSheetState();
}

class _TrendingRecipePickerSheetState extends State<TrendingRecipePickerSheet> {
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
  int selectedCategoryIndex = 0;
  List<String> selectedIds = [];
  List<Recipe> selectedRecipes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedRecipes();
  }

  Future<void> _loadSelectedRecipes() async {
    final ids = await firebaseService.getFeaturedRecipeIds();
    setState(() {
      selectedIds = ids;
      loading = false;
    });
  }
  bool isSelected(Recipe recipe) {
    return selectedIds.contains(recipe.id);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 500,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .82,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Chọn 4 món thịnh hành",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 14),
            _buildCategory(),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<Recipe>>(
                stream: firebaseService.streamRecipesByCategory(
                  categories[selectedCategoryIndex],
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: .83,
                    ),
                    itemBuilder: (_, index) {
                      final recipe = recipes[index];
                      final selected = isSelected(recipe);
                      return _buildRecipeCard(
                        recipe,
                        selected,
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedIds.isEmpty ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Lưu (${selectedIds.length}/4)",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildRecipeCard(
    Recipe recipe,
    bool selected,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _toggleRecipe(recipe),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      recipe.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleRecipe(recipe),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? Colors.orange : Colors.white,
                        border: Border.all(
                          color: selected ? Colors.orange : Colors.grey,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 18,
                        color: selected
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recipe.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  void _toggleRecipe(Recipe recipe) {
    final alreadySelected = selectedIds.contains(recipe.id);
    if (alreadySelected) {
      setState(() {
        selectedIds.remove(recipe.id);
      });
      return;
    }
    if (selectedIds.length == 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Chỉ được chọn tối đa 4 món"),
        ),
      );
      return;
    }
    setState(() {
      selectedIds.add(recipe.id);
    });
  }
  Future<void> _save() async {
    try {
      await firebaseService.updateFeaturedRecipes(
        selectedIds,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Đã cập nhật món thịnh hành.",
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }
  void _scrollToCenter(int index) {
    if (!_categoryController.hasClients) return;
    double estimatedWidth(String text) {
      final length = text.length;
      if (length <= 6) return 90;
      if (length <= 10) return 110;
      if (length <= 14) return 130;
      return 150;
    }
    double offset = 0;
    for (int i = 0; i < index; i++) {
      offset += estimatedWidth(categories[i]) + 8;
    }
    final target = offset - (MediaQuery.of(context).size.width / 2) + estimatedWidth(categories[index]) / 2;
    _categoryController.animateTo(
      target.clamp( 0, _categoryController.position.maxScrollExtent,),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }
  Widget _buildCategory() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        controller: _categoryController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12,),
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final selected = selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8,),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                setState(() {
                  selectedCategoryIndex = index;
                });
                _scrollToCenter(index);
              },
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? Colors.orange : Colors.white,
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: selected ? Colors.orange : Colors.grey.shade400,
                  ),
                ),
                child: Center(
                  child: Text(
                    categories[index],
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
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
  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }
}