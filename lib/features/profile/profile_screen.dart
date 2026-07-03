import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/widgets/avatar.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text("Chưa đăng nhập"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Hồ sơ",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final username =
              data['username'] ?? 'Người dùng';

          final location =
              data['location'] ?? '';

          final bio =
              data['bio'] ?? '';

          final followers =
              data['followersCount'] ?? 0;

          final following =
              data['followingCount'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                Row(
                  children: [
                    UserAvatar(
                      username: username,
                      isLoading: false,
                      radius: 26,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  location.isEmpty
                                      ? "Chưa cập nhật địa chỉ"
                                      : location,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _BioWidget(
                  bio: bio,
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Text(
                      "$following",
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Bạn bếp",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(width: 40),

                    Text(
                      "$followers",
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Người quan tâm",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xffF9B21D),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const EditProfileScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sửa thông tin cá nhân",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Công thức (0)",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Container(
                  margin:
                      const EdgeInsets.only(top: 4),
                  width: 85,
                  height: 2,
                  color: const Color(0xffF9B21D),
                ),

                const SizedBox(height: 40),

                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        size: 90,
                        color: Colors.black54,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Chưa có món nào",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(
                                  0xffF9B21D),
                        ),
                        onPressed: () {},
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          child: Text(
                            "Viết món mới",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BioWidget extends StatefulWidget {
  final String bio;

  const _BioWidget({required this.bio});

  @override
  State<_BioWidget> createState() =>
      _BioWidgetState();
}

class _BioWidgetState extends State<_BioWidget> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final bio = widget.bio.isEmpty
        ? "Chưa cập nhật tiểu sử"
        : widget.bio;

    final longBio = bio.length > 90;

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        children: [
          TextSpan(
            text: expanded || !longBio
                ? bio
                : "${bio.substring(0, 90)}...",
          ),
          if (longBio)
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                child: Text(
                  expanded
                      ? " Thu gọn"
                      : " đọc thêm",
                  style: const TextStyle(
                    color: Color(0xffF9B21D),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}