import 'package:flutter/material.dart';
import '../../core/widgets/ai_plant_button.dart';
import '../../core/widgets/bottomnav.dart';
import 'tab_notification.dart';
import 'tab_friend.dart';
import '../home/home.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
          title: const Text(
            "Hoạt động",
            style: TextStyle(color: Colors.black),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Thông báo"),
              Tab(text: "Bạn bè"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TabNotification(),
            TabFriend(),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AiPlantButton(),
            AppBottomNav(currentIndex: 1), 
          ],
        ),
      ),
    );
  }
}
