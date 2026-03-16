import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {

  final TextEditingController emailController = TextEditingController();

  Future<void> handleSubmit() async {

    String email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage("Vui lòng nhập email");
      return;
    }

    try {

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      showMessage("Đã gửi email đặt lại mật khẩu");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );

    } on FirebaseAuthException catch (e) {

      if (e.code == 'user-not-found') {
        showMessage("Email chưa được đăng ký");
      } else if (e.code == 'invalid-email') {
        showMessage("Email không hợp lệ");
      } else {
        showMessage("Có lỗi xảy ra");
      }

    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
        title: const Text(
          "Quên mật khẩu",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [

            const SizedBox(height: 40),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: "Email address",
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),

                onPressed: handleSubmit,

                child: const Text(
                  "GỬI",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("Hoặc"),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 30),

            _buildSocialLoginButtons(context, maxWidth: 250),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLoginButtons(BuildContext context, {double? maxWidth}) {
    return SizedBox(
      width: maxWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSocialIconButton(
            icon: FontAwesomeIcons.facebookF,
            backgroundColor: const Color(0xFF1877F2),
            onTap: () {
              showMessage("Facebook signup clicked");
            },
          ),
          _buildSocialIconButton(
            icon: FontAwesomeIcons.google,
            backgroundColor: const Color(0xFFEA4335),
            onTap: () {
              showMessage("Google signup clicked");
            },
          ),
          _buildSocialIconButton(
            icon: FontAwesomeIcons.apple,
            backgroundColor: Colors.black,
            onTap: () {
              showMessage("Apple login clicked");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIconButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withAlpha((0.3 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}