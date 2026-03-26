import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onNewChat;
  const Sidebar({super.key, required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 270,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: "Tìm kiếm",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Cuộc trò chuyện mới"),
                onTap: onNewChat,
              ),
            ],
          ),
        ),
      ),
    );
  }
}