import 'package:flutter/material.dart';

class MyRecipeTab extends StatelessWidget { 
  const MyRecipeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget();
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Dùng SingleChildScrollView để chống tràn tuyệt đối
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60), 
            Image.asset(
              'images/no_recipe.jpg',
              width: 180,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              "Chưa có món nào",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Tất cả công thức bạn viết sẽ xuất hiện ở đây",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black, fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 20), 
          ],
        ),
      ),
    );
  }
}