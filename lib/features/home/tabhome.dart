import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/avatar.dart'; 
import 'package:dantn_app_cookbook/features/create_recipe/create_recipe.dart';
import '../../features/plan/plan_screen.dart';
import '../../features/storage/storage_screen.dart';

class TabHome extends StatefulWidget {
  const TabHome({super.key});

  @override
  State<TabHome> createState() => _TabHomeState();
}

class _TabHomeState extends State<TabHome> {
  String username = ""; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          username = user.displayName ?? "";
          isLoading = username.isEmpty; 
        });
      }
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!mounted) return;
        if (doc.exists) {
          final firestoreName = doc.data()?['username'] ?? "";
          setState(() {
            username = firestoreName;
            isLoading = false; 
          });
        }
      } catch (e) {
        debugPrint("Lỗi cập nhật dữ liệu Firestore: $e");
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.pop(context); 
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      debugPrint("Lỗi đăng xuất: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double drawerWidth = MediaQuery.of(context).size.width * 0.75;
    
    return Drawer(
      width: drawerWidth,
      child: Column(
        children: [
          _buildFixedHeader(),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(context, Icons.home, "Trang chủ", () {
                    Navigator.pop(context);
                  }),
                  _drawerItem(context, Icons.storage, "Kho của bạn", () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StorageScreen()));
                  }),
                  _drawerItem(context, Icons.event_note, "Kế hoạch", () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const PlanScreen())
                    );
                  }),
                  _drawerItem(context, Icons.create, "Tạo công thức", () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRecipeScreen()));
                  }),
                  _drawerItem(context, Icons.people_outline, "Bạn bếp", () {}),
                  _drawerItem(context, Icons.person_outline, "Hồ sơ", () {}),
                  _drawerItem(context, Icons.help_outline, "Hỗ trợ", () {}),
                  _drawerItem(context, Icons.settings, "Cài đặt", () {}),
                  _drawerItem(context, Icons.logout, "Đăng xuất", () => _logout(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeader() {
    return Container(
      width: double.infinity,
      color: Colors.orange,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      child: Row(
        children: [
          UserAvatar(
            username: username,
            isLoading: isLoading,
            radius: 25,
            backgroundColor: Colors.white,
            textColor: Colors.orange,
            onTap: () => debugPrint("Click vào Avatar"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username.isEmpty ? "Người dùng" : username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  "0 Người theo dõi",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        if (!context.mounted) return;
        onTap();
      },
    );
  }
}