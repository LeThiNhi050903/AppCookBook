import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';

class TabFriend extends StatelessWidget {
  const TabFriend({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Bạn cần đăng nhập để xem thông báo'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final requestIds = (data['friendRequests'] as List?)?.whereType<String>().toList() ?? <String>[];

        if (requestIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/notification.png', width: 200),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có thông báo nào',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<Map<String, dynamic>?>>(
          future: Future.wait<Map<String, dynamic>?>(
            requestIds.map((requestId) => FirebaseService().getUserByUid(requestId)),
          ),
          builder: (context, userSnapshot) {
            final users = (userSnapshot.data ?? <Map<String, dynamic>?>[])
                .whereType<Map<String, dynamic>>()
                .toList();
            if (users.isEmpty) {
              return const Center(child: Text('Đang tải...'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final username = user['username'] ?? 'Người dùng';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: const Text('Bạn đã nhận được lời mời kết bạn'),
                    subtitle: Text('Từ $username'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}