import 'dart:io';

import 'package:flutter/material.dart';

import '../services/profile_image_service.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;
  final double radius; 
  final String? imagePath; // optional override
  const UserAvatar({
    super.key,
    required this.username,
    required this.isLoading,
    this.onTap,
    this.backgroundColor = Colors.orange,
    this.textColor = Colors.white,
    this.radius = 22, 
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    String displayLetter = "";
    if (username.trim().isNotEmpty) {
      displayLetter = username.trim()[0].toUpperCase();
    }

    return GestureDetector(
      onTap: onTap,
      child: imagePath != null
          ? CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor,
              backgroundImage: File(imagePath!).existsSync()
                  ? FileImage(File(imagePath!))
                  : null,
              child: _buildChild(displayLetter),
            )
          : ValueListenableBuilder<String?>(
              valueListenable: ProfileImageService.instance.avatarPath,
              builder: (context, value, _) {
                if (value != null && File(value).existsSync()) {
                  return CircleAvatar(
                    radius: radius,
                    backgroundColor: backgroundColor,
                    backgroundImage: FileImage(File(value)),
                  );
                }
                return CircleAvatar(
                  radius: radius,
                  backgroundColor: backgroundColor,
                  child: _buildChild(displayLetter),
                );
              },
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