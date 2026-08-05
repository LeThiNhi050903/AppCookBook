import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/local_service.dart';
import '../../core/services/profile_image_service.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/bottomnav.dart';
import '../../core/widgets/ai_plant_button.dart';
import '../notification/notification_screen.dart';
import 'tabhome.dart';
import '../../data/models/recipe.dart';
import '../../core/widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';
import 'trending_recipe_picker_sheet.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({super.key, this.isAdmin = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService firebaseService = FirebaseService();
  final LocalService localService = LocalService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Future<List<Recipe>>? _searchFuture;
  String _searchQuery = '';
  String username = "User";
  bool isLoading = true;
  int selectedIndex = -1;
  String? selectedCategory;
  final List<Map<String, String>> categories = [
    {'name': 'Món chiên', 'image': 'images/Mon_chien.jpg'},
    {'name': 'Món xào', 'image': 'images/Mon_xao.jpg'},
    {'name': 'Món hấp', 'image': 'images/Mon_hap.jpg'},
    {'name': 'Món kho', 'image': 'images/Mon_kho.jpg'},
    {'name': 'Món chay', 'image': 'images/Mon_chay.jpg'},
    {'name': 'Món canh', 'image': 'images/Mon_canh.jpg'},
    {'name': 'Món nước', 'image': 'images/Mon_nuoc.jpg'},
    {'name': 'Món chè', 'image': 'images/Mon_che.png'},
    {'name': 'Món kem', 'image': 'images/Mon_kem.png'},
    {'name': 'Salad', 'image': 'images/Sa_lat.png'},
    {'name': 'Thức uống', 'image': 'images/Thuc_uong.jpg'},
    {'name': 'Gỏi/nộm', 'image': 'images/Goi_nom.jpg'},
    {'name': 'Bánh ngọt', 'image': 'images/Banh_ngot.png'},
    {'name': 'Cháo/súp', 'image': 'images/Chao_sup.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) {
      username = "Admin";
      isLoading = false;
    }
    loadData();
  }

  Future<void> loadData() async {
    final currentUser = firebaseService.auth.currentUser;
    await ProfileImageService.instance.init();
    if (widget.isAdmin || currentUser?.email == 'adminCookBook@gmail.com') {
      username = 'Admin';
      if (mounted) setState(() => isLoading = false);
      return;
    }
    final userData = await firebaseService.getUserProfile();
    if (userData != null && userData['username'] != null) {
      username = userData['username'].toString();
      await localService.saveUsername(username);
    } else if (currentUser != null) {
      username = currentUser.displayName?.trim().isNotEmpty == true
          ? currentUser.displayName!
          : (currentUser.email?.split('@').first ?? 'User');
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _searchFuture = null;
      } else {
        _searchFuture = firebaseService.searchPublishedRecipes(query);
      }
    });
  }
  Future<void> _openRecipeDetail(Recipe recipe) async {
    await firebaseService.saveRecentViewed(recipe.id);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          recipe: recipe,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: TabHome(isAdmin: widget.isAdmin),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildFixedTopSection(),
                Expanded(
                  child: _searchQuery.isNotEmpty
                    ? _buildSearchResults()
                    : (selectedCategory == null
                        ? _buildHomeContent()
                        : _buildCategoryContent(selectedCategory!)),
                ),
              ],
            ),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AiPlantButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedTopSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          const SizedBox(height: 15),
          _buildCategories(),
          const Divider(
            thickness: 1,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        UserAvatar(
          username: username,
          isLoading: isLoading,
          useCurrentUserAvatar: true,
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.isAdmin ? "Quản trị viên" : "Xin chào!",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (!widget.isAdmin)
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
          ),
        if (widget.isAdmin)
          IconButton(
            icon: const Icon(
              Icons.admin_panel_settings_outlined,
              size: 28,
            ),
            onPressed: () {

            },
          ),
      ],
    ),
  );
}

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onSubmitted: (value) async {
          final keyword = value.trim();
          if (keyword.isNotEmpty) {
            await firebaseService.saveRecentSearch(keyword);
          }
        },
        decoration: InputDecoration(
          hintText: "Nhập tên món ăn...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Recipe>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tìm kiếm: ${snapshot.error}'));
        }
        final recipes = snapshot.data ?? [];
        if (recipes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Text(
                'Không tìm thấy công thức phù hợp.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 130,
          ),
          itemCount: recipes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            return RecipeCard(
              recipe: recipes[index],
              onTap: () async {
                await firebaseService.saveRecentSearch(
                  _searchController.text.trim(),
                );
                await _openRecipeDetail(
                  recipes[index],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                if (selectedIndex == index) {
                  selectedIndex = -1;
                  selectedCategory = null;
                  return;
                }
                final selectedItem = categories.removeAt(index);
                categories.insert(0, selectedItem);
                selectedIndex = 0;
                selectedCategory = categories[0]['name'];
              });
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 30, 
                        backgroundImage: AssetImage(categories[index]['image']!),
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categories[index]['name']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    bool showUpdate = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showUpdate)
            TextButton.icon(
              onPressed: _showTrendingPicker,
              icon: const Icon(
                Icons.edit,
                size: 18,
              ),
              label: const Text("Cập nhật"),
            ),
        ],
      ),
    );
  }

  Widget _buildTrending() {
    return StreamBuilder<List<Recipe>>(
      stream: firebaseService.streamFeaturedRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }
        final recipes = snapshot.data ?? [];
        if (recipes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Chưa có món thịnh hành",
            ),
          );
        }
        return SizedBox(
          height: 200,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recipes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (_, index) {
              return RecipeCard(
                recipe: recipes[index],
                onTap: () async {
                  await _openRecipeDetail(
                    recipes[index],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentSearch() {
    return StreamBuilder<List<String>>(
      stream: firebaseService.streamRecentSearch(),
      builder: (context, snapshot) {
        final searches = snapshot.data ?? [];
        if (searches.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Chưa có tìm kiếm",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: searches.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final keyword = searches[index];
              return ActionChip(
                label: Text(keyword),
                onPressed: () {
                  _searchController.text = keyword;
                  _onSearchChanged(keyword);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentViewed() {
    return StreamBuilder<List<Recipe>>(
      stream: firebaseService.streamRecentViewedRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(snapshot.error.toString()),
          );
        }
        final recipes = snapshot.data ?? [];
        if (recipes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Bạn chưa xem món nào",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: RecipeCard(
                    recipe: recipes[index],
                    onTap: () async {
                      await _openRecipeDetail(recipes[index]);
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Thịnh hành", showUpdate: widget.isAdmin,),
          _buildTrending(),
          _buildSectionTitle("Tìm kiếm gần đây"),
          _buildRecentSearch(),
          _buildSectionTitle("Các món đã xem gần đây"),
          _buildRecentViewed(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(String category) {
    return StreamBuilder<List<Recipe>>(
      stream: firebaseService.streamRecipesByCategory(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }
        final recipes = snapshot.data ?? [];
        if (recipes.isEmpty) {
          return const Center(
            child: Text("Chưa có công thức"),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 130,
          ),
          itemCount: recipes.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            return RecipeCard(
              recipe: recipes[index],
              onTap: () async {
                await _openRecipeDetail(
                  recipes[index],
                );
              },
            );
          },
        );
      },
    );
  }
    Future<void> _showTrendingPicker() async {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
        builder: (_) {
          return const TrendingRecipePickerSheet();
        },
      );
    }
}