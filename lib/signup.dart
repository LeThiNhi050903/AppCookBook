import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu phải ít nhất 6 ký tự")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );

    } on FirebaseAuthException catch (e) {

      String message = "";
      if (e.code == 'email-already-in-use') {
        message = "Email đã tồn tại";
      }
      else if (e.code == 'invalid-email') {
        message = "Email không hợp lệ";
      }
      else if (e.code == 'weak-password') {
        message = "Mật khẩu quá yếu";
      }
      else {
        message = e.message ?? "Đăng ký thất bại";
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final logoSize = w * 0.5;
            final fieldWidth = w * 0.85;
            final gapSmall = h * 0.015;
            final gapMedium = h * 0.025;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: h),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 1),
                      _buildLogoSection(size: logoSize),
                      SizedBox(height: gapMedium),
                      _buildInputField(
                        controller: _usernameController,
                        hintText: 'User name',
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.text,
                        width: fieldWidth,
                      ),
                      SizedBox(height: gapSmall),
                      _buildInputField(
                        controller: _emailController,
                        hintText: 'Email address',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        width: fieldWidth,
                      ),
                      SizedBox(height: gapSmall),
                      _buildPasswordField(width: fieldWidth),
                      SizedBox(height: gapMedium),
                      _buildSignupButton(width: fieldWidth),
                      SizedBox(height: gapSmall),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Đã có tài khoản? ',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                color: Color(0xFFFFA500),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: gapMedium),
                      _buildDividerWithText(),
                      SizedBox(height: gapMedium),
                      _buildSocialLoginButtons(maxWidth: fieldWidth),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoSection({double? size}) {
    final logoDim = size ?? 240;
    return Column(
      children: [
        Image.asset(
          'images/Logo.png',
          width: logoDim,
          height: logoDim,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    double? width,
  }) {
    return SizedBox(
      width: width ?? 150,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.black,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFFFA500), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({double? width}) {
    return SizedBox(
      width: width ?? 150,
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Colors.black,
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            child: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF9E9E9E),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFFFA500), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupButton({double? width}) {
    return SizedBox(
      width: width ?? 150,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signup,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFA500),
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 6,
          shadowColor: const Color(0x33000000),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ĐĂNG KÝ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDividerWithText() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Hoặc',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons({double? maxWidth}) {
    return SizedBox(
      width: maxWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSocialIconButton(
            icon: FontAwesomeIcons.facebookF,
            backgroundColor: const Color(0xFF1877F2),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Facebook signup clicked')),
              );
            },
          ),
          _buildSocialIconButton(
            icon: FontAwesomeIcons.google,
            backgroundColor: const Color(0xFFEA4335),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google signup clicked')),
              );
            },
          ),
          _buildSocialIconButton(
            icon: FontAwesomeIcons.apple,
            backgroundColor: Colors.black,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Apple login clicked')),
              );
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
