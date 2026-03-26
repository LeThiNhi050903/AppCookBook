import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;

  const UserAvatar({
    super.key,
    required this.username,
    required this.isLoading,
    this.onTap,
    this.backgroundColor = Colors.orange,
    this.textColor = Colors.white,      
  });

  @override
  Widget build(BuildContext context) {
    String displayLetter = "U";

    if (username.trim().isNotEmpty) {
      displayLetter = username.trim()[0].toUpperCase();
    }

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: backgroundColor,
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: textColor, // đồng bộ màu
                  strokeWidth: 2,
                ),
              )
            : Text(
                displayLetter,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }
}