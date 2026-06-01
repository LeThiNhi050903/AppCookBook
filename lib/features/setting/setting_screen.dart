import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/notification/notification_screen.dart';
import '../../core/widgets/bottomnav.dart';
import 'new_password.dart';
import 'terms_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String username = "";
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

        if (!mounted) return;

        setState(() {
          username = doc.data()?['username'] ?? "User";
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        username = "User";
        isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đăng xuất thất bại"),
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text(
          "Bạn có chắc muốn đăng xuất không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleLogout();
            },
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    VoidCallback? onArrowTap,
    Widget? trailing,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      leading: Icon(
        icon,
        size: 22,
        color: Colors.black87,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 2,
      ),
      trailing: trailing ??
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              size: 20,
            ),
            onPressed: onArrowTap,
          ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cài đặt",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            _buildSection([
              _buildItem(
                icon: Icons.person_outline,
                title: "Tài khoản",
              ),
              const Divider(
                height: 1,
                thickness: 0.5,
              ),
              _buildItem(
                icon: Icons.lock_outline,
                title: "Đổi mật khẩu",
                onArrowTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const Divider(
                height: 1,
                thickness: 0.5,
              ),

              _buildItem(
                icon: Icons.description_outlined,
                title: "Điều khoản & Chính sách",
                onArrowTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const TermsPolicyScreen(),
                    ),
                  );
                },
              ),
            ]),
            _buildSection([
              _buildItem(
                icon: Icons.notifications_none,
                title: "Thông báo",
                onArrowTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationScreen(),
                    ),
                  );
                },
              ),
              const Divider(
                height: 1,
                thickness: 0.5,
              ),
              _buildItem(
                icon: Icons.language,
                title: "Ngôn ngữ",
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Tiếng Việt",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),

              const Divider(
                height: 1,
                thickness: 0.5,
              ),
              _buildItem(
                icon: Icons.dark_mode_outlined,
                title: "Chế độ sáng/tối",
              ),
            ]),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                10,
                24,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirmLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    elevation: 4,
                    shadowColor:
                        Colors.black.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "ĐĂNG XUẤT",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const AppBottomNav(currentIndex: 1),
    );
  }
}