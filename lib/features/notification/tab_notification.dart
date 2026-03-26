import 'package:flutter/material.dart';

class TabNotification extends StatelessWidget {
  const TabNotification({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> notifications = [];
    if (notifications.isEmpty) {
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final item = notifications[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.notifications, color: Colors.orange),
            title: Text(item),
            subtitle: const Text("Nội dung thông báo..."),
          ),
        );
      },
    );
  }
}
