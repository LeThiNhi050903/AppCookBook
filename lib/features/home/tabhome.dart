import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/avatar.dart';

class TabHome extends StatefulWidget {
  const TabHome({super.key}); 

  @override
  State<TabHome> createState() => _TabHomeState();
}

class _TabHomeState extends State<TabHome> {
  String username = "User";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            username = doc.data()?['username'] ?? "User";
            isLoading = false;
          });
        } else {
          setState(() {
            username = "User";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          username = "User";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        username = "User";
        isLoading = false;
      });
    }
  }

  void _logout(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, '/login');
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
              child: Column(
                children: [
                  _drawerItem(Icons.home, "Trang chủ",
                      () => Navigator.pop(context)),
                  _drawerItem(Icons.storage, "Kho của bạn", () {}),
                  _drawerItem(Icons.event_note, "Kế hoạch", () {}),
                  _drawerItem(Icons.create, "Tạo công thức", () {}),
                  _drawerItem(Icons.people, "Bạn bếp", () {}),
                  _drawerItem(Icons.settings, "Cài đặt", () {}),
                  _drawerItem(Icons.help, "Hỗ trợ", () {}),
                  _drawerItem(Icons.light_mode, "Chế độ sáng", () {}),
                  _drawerItem(Icons.logout, "Đăng xuất",
                      () => _logout(context)),
                  const Spacer(),
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
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatar(
            username: username,
            isLoading: isLoading,
            backgroundColor: Colors.white,
            textColor: Colors.orange,
            onTap: () {
              debugPrint("Click avatar"); 
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "0 Người theo dõi",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: color ?? Colors.black87, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}