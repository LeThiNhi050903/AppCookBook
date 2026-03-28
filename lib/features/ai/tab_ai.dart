import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onNewChat;
  final List<List<Map<String, String>>> chatHistory;
  final Function(int) onSelectChat;
  final Function(int) onDeleteChat;

  const Sidebar({
    super.key,
    required this.onNewChat,
    required this.chatHistory,
    required this.onSelectChat,
    required this.onDeleteChat,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: onNewChat,
                icon: const Icon(Icons.add),
                label: const Text("Cuộc trò chuyện mới"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: chatHistory.isEmpty
                ? const Center(child: Text("Chưa có lịch sử chat"))
                : ListView.builder(
                    itemCount: chatHistory.length,
                    itemBuilder: (context, index) {
                      final chat = chatHistory[index];
                      String title = chat.isNotEmpty 
                          ? chat.firstWhere((m) => m["role"] == "user")["content"]!
                          : "Chat trống";

                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, size: 20),
                        title: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => onDeleteChat(index),
                        ),
                        onTap: () => onSelectChat(index),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}