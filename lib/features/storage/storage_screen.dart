import 'package:flutter/material.dart';
import 'my_recipe.dart';
import 'save_recipe.dart';
import 'ai_note.dart';
import '../../core/widgets/ai_plant_button.dart';
import '../../core/widgets/bottomnav.dart';
import '../home/home.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            
            // 1. SỬA LỖI TREO: Dùng isScrollable: false để 3 tab tự chia đều màn hình
            // Bọc trong SizedBox để cố định chiều cao thanh Tab, tránh đẩy layout gây tràn
            SizedBox(
              height: 45,
              child: TabBar(
                controller: _tabController,
                isScrollable: false, // Tắt cuộn để 3 tab tự dàn hàng ngang cân đối
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.orange,
                indicatorWeight: 3,
                // indicatorSize: TabBarIndicatorSize.tab giúp thanh cam dài bằng ô tab, trông sẽ cân hơn
                indicatorSize: TabBarIndicatorSize.tab, 
                labelPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 13, // Giảm nhẹ size chữ để "Món của bạn" không bị tràn
                ),
                tabs: const [
                  Tab(text: "Món của bạn"),
                  Tab(text: "Món đã lưu"),
                  Tab(text: "Ghi chú AI"),
                ],
              ),
            ),

            // 2. Nội dung Tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  MyRecipeTab(),
                  SaveRecipeTab(),
                  AiNoteTab(),
                ],
              ),
            ),

            // 3. CHỐNG TRÀN: Nút AI cố định
            // Nếu vẫn tràn, Nhi hãy kiểm tra chiều cao bên trong file AiPlantButton
            const AiPlantButton(),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4), // Thu gọn padding để tiết kiệm diện tích
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const HomeScreen())
            ),
          ),
          Expanded(
            child: Container(
              height: 38, // Giảm nhẹ chiều cao search bar
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Tìm kiếm...",
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}