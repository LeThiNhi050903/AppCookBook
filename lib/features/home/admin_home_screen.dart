import 'package:flutter/material.dart';
import 'home.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen(isAdmin: true);
  }
}
