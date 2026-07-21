import 'package:flutter/material.dart';

class StatusRecipeScreen extends StatelessWidget {
  const StatusRecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Đơn đã tạo",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: const Center(
        child: Text(
          "Chưa có đơn nào",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}