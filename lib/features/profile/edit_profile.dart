import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/widgets/avatar.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/profile_image_service.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final locationController = TextEditingController();
  final bioController = TextEditingController();

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    ProfileImageService.instance.init();
    loadUser();
  }

  Future<void> loadUser() async {
    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();

    if (data == null) {
      return;
    }

    nameController.text = data['username'] ?? '';
    emailController.text = FirebaseAuth.instance.currentUser?.email ?? data['email'] ?? '';
    locationController.text = data['location'] ?? '';
    bioController.text = data['bio'] ?? '';

    setState(() {
      loading = false;
    });
  }

  Future<void> updateProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    setState(() {
      saving = true;
    });
    final updatedEmail = emailController.text.trim();
    final updatedName = nameController.text.trim();

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'username': updatedName,
      'email': updatedEmail,
      'location': locationController.text.trim(),
      'bio': bioController.text.trim(),
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (currentUser.email != updatedEmail && updatedEmail.isNotEmpty) {
        await currentUser.verifyBeforeUpdateEmail(updatedEmail);
      }
      await currentUser.updateDisplayName(updatedName);
    }

    if (!mounted) return;

    navigator.pop();
    if (messenger != null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Cập nhật hồ sơ thành công"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chỉnh sửa hồ sơ"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  UserAvatar(
                    username: nameController.text,
                    isLoading: false,
                    radius: 42,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowMultiple: false,
                          allowedExtensions: ['img', 'jpg'],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final path = result.files.first.path;
                          if (path != null && File(path).existsSync()) {
                            await ProfileImageService.instance.setImagePath(path);
                            if (!mounted) return;
                            if (messenger != null) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Ảnh đại diện đã được cập nhật')),
                              );
                            }
                          }
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(153),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildField(
              "Họ và tên",
              nameController,
            ),

            const SizedBox(height: 16),

            _buildField(
              "Email",
              emailController,
            ),

            const SizedBox(height: 16),

            _buildField(
              "Nơi ở",
              locationController,
            ),

            const SizedBox(height: 16),

            _buildField(
              "Tiểu sử",
              bioController,
              maxLines: 3,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: saving ? null : updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF9B21D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Cập nhật",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Bỏ qua",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String title,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFF6F6F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            hintText: 'Nhập $title',
          ),
        ),
      ],
    );
  }
}