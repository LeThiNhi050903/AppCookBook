import 'package:flutter/material.dart';
import 'package:dantn_app_cookbook/features/home/home.dart';
import 'package:dantn_app_cookbook/features/create_recipe/create_recipe.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;

      case 1:
        // Chỗ này Nhi có thể thêm điều hướng đến NotificationScreen nếu muốn
        break;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
        );
        break;
    }
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
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: iconSize),
          activeIcon: Icon(Icons.home, size: iconSize),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.storage_outlined, size: iconSize),
          activeIcon: Icon(Icons.storage, size: iconSize),
          label: "Storage",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box, size: iconSize),
          activeIcon: Icon(Icons.add_box, size: iconSize),
          label: "Add",
        ),
      ],
    );
  } // Kết thúc hàm build
} // Kết thúc class AppBottomNav