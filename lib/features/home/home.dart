import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/local_service.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/bottomnav.dart';
import '../../core/widgets/ai_plant_button.dart';
import '../notification/notification_screen.dart';
import 'tabhome.dart';

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
    super.dispose();
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
                  child: selectedCategory == null
                      ? _buildHomeContent()
                      : _buildCategoryContent(),
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
        decoration: InputDecoration(
          hintText: "Nhập tên món ăn...",
          prefixIcon: const Icon(Icons.search),
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

  Widget _buildSectionTitle(String title, {bool showUpdate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (showUpdate)
            const Text("Cập nhật 04:30", style: TextStyle(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildTrending() => const SizedBox(
      height: 120,
      child: Center(
          child: Text("Không có dữ liệu",
              style: TextStyle(color: Colors.grey))));

  Widget _buildRecentSearch() => const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text("Chưa có tìm kiếm",
          style: TextStyle(color: Colors.grey)));

  Widget _buildRecentViewed() => const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text("Bạn chưa xem món nào",
          style: TextStyle(color: Colors.grey)));

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Thịnh hành", showUpdate: true),
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

  Widget _buildCategoryContent() {
    List recipes = [];

    return SingleChildScrollView(
      child: Column(
        children: [

          _buildSectionTitle(selectedCategory!),

          recipes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(
                    child: Text(
                      "Chưa có món nào",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recipes.length,
                  itemBuilder: (_, index) {
                    return ListTile(
                      title: Text(recipes[index].name),
                    );
                  },
                ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}