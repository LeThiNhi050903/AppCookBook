import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;
  final double radius; 

  const UserAvatar({
    super.key,
    required this.username,
    required this.isLoading,
    this.onTap,
    this.backgroundColor = Colors.orange,
    this.textColor = Colors.white,
    this.radius = 22, 
  });

  @override
  Widget build(BuildContext context) {
    String displayLetter = "";
    if (username.trim().isNotEmpty) {
      displayLetter = username.trim()[0].toUpperCase();
    }

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: _buildChild(displayLetter),
      ),
    );
  }

  Widget _buildChild(String displayLetter) {
    if (isLoading && displayLetter.isEmpty) {
      return SizedBox(
        width: radius * 0.8,
        height: radius * 0.8,
        child: CircularProgressIndicator(
          color: textColor,
          strokeWidth: 2,
        ),
      );
    }
    return Text(
      displayLetter.isEmpty ? "?" : displayLetter, 
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.8, 
      ),
    );
  }
}