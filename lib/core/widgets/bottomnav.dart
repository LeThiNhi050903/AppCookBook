import 'package:flutter/material.dart';
import 'package:dantn_app_cookbook/features/home/home.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double iconSize = 28.0;
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 10,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: iconSize, color: Colors.black),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.storage, size: iconSize, color: Colors.black),
          label: "Storage",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box_outlined, size: iconSize, color: Colors.black),
          label: "Add",
        ),
      ],
    );
  }
}
