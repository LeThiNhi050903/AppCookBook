import 'package:flutter/material.dart';

class TabFriend extends StatelessWidget {
  const TabFriend({super.key});
  @override
  Widget build(BuildContext context) {
    final List<String> notificationFriends = [];
    if (notificationFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/notification.png',
              width: 200,
            ),
            const SizedBox(height: 16),
            const Text(
              "Chưa có thông báo nào",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: notificationFriends.length,
      itemBuilder: (context, index) {
        final friend = notificationFriends[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(friend),
            subtitle: const Text("Nội dung thông báo..."),
          ),
        );
      },
    );
  }
}