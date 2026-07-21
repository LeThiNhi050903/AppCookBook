import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../core/widgets/avatar.dart'; 
import 'package:dantn_app_cookbook/features/create_recipe/create_recipe.dart';
import '../../features/plan/plan_screen.dart';
import '../../features/storage/storage_screen.dart';
import '../../features/setting/setting_screen.dart';
import '../support/support.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/admin_profile_screen.dart';
import '../../features/friends/friends_screen.dart';
import 'admin_home_screen.dart';

class TabHome extends StatefulWidget {
  final bool isAdmin;

  const TabHome({super.key, this.isAdmin = false});

  @override
  State<TabHome> createState() => _TabHomeState();
}

class _TabHomeState extends State<TabHome> {
  String username = ""; 
  bool isLoading = true;
  int followersCount = 0;
  StreamSubscription<DocumentSnapshot>? _userSub;
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (widget.isAdmin) {
      setState(() {
        username = 'Admin';
        followersCount = 0;
        isLoading = false;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSub?.cancel();
      _userSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (!mounted) return;
        final data = doc.data();
        setState(() {
          username = (data?['username'] ?? user.displayName ?? '').toString();
          followersCount = (data?['followersCount']) ?? 0;
          isLoading = false;
        });
      }, onError: (e) {
        debugPrint("Lỗi cập nhật dữ liệu Firestore: $e");
        if (mounted) setState(() => isLoading = false);
      });
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawerItems = widget.isAdmin
        ? [
            _drawerItem(context, Icons.home, "Trang chủ", () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminHomeScreen()));
            }),
            _drawerItem(context, Icons.event_note, "Kế hoạch", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PlanScreen()));
            }),
            _drawerItem(context, Icons.create, "Tạo công thức", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRecipeScreen()));
            }),
            _drawerItem(context, Icons.fact_check, "Xét duyệt công thức", () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Màn hình xét duyệt sẽ được tích hợp ở bước tiếp theo')),
              );
            }),
            _drawerItem(context, Icons.person_outline, "Hồ sơ", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfileScreen()));
            }),
            _drawerItem(context, Icons.settings, "Cài đặt", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),
          ]
        : [
            _drawerItem(context, Icons.home, "Trang chủ", () {
              Navigator.pop(context);
            }),
            _drawerItem(context, Icons.storage, "Kho của bạn", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StorageScreen()));
            }),
            _drawerItem(context, Icons.event_note, "Kế hoạch", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PlanScreen()));
            }),
            _drawerItem(context, Icons.create, "Tạo công thức", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRecipeScreen()));
            }),
            _drawerItem(context, Icons.people_outline, "Bạn bếp", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsScreen()));
            }),
            _drawerItem(context, Icons.person_outline, "Hồ sơ", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            }),
            _drawerItem(context, Icons.help_outline, "Hỗ trợ", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
            }),
            _drawerItem(context, Icons.settings, "Cài đặt", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),
          ];

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
                children: drawerItems,
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
                Text(
                  "$followersCount Người theo dõi",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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