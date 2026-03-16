import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup.dart';
import 'home.dart';
import 'forgotpass.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập email và mật khẩu")),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
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
      String message = "Đăng nhập thất bại";
      if (e.code == 'user-not-found') {
        message = "Không tìm thấy tài khoản";
      } 
      else if (e.code == 'wrong-password') {
        message = "Sai mật khẩu";
      } 
      else if (e.code == 'invalid-email') {
        message = "Email không hợp lệ";
      }
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
                      const Spacer(flex: 2),
                      _buildLogoSection(size: logoSize),
                      SizedBox(height: gapMedium),
                      _buildInputField(
                        controller: _emailController,
                        hintText: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        width: fieldWidth,
                      ),
                      SizedBox(height: gapSmall),
                      _buildPasswordField(width: fieldWidth),
                      SizedBox(height: gapMedium),
                      _buildLoginButton(width: fieldWidth),
                      SizedBox(height: gapSmall),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      SizedBox(height: gapSmall),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Chưa có tài khoản? ",
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
                                  builder: (context) => const SignupPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Đăng ký',
                              style: TextStyle(
                                color: Color(0xFFFFA500),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 1),
                      _buildDividerWithText(),
                      SizedBox(height: gapMedium),
                      _buildSocialLoginButtons(maxWidth: fieldWidth),
                      const Spacer(flex: 3),
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
          prefixIcon: Icon(prefixIcon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
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
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({double? width}) {
    return SizedBox(
      width: width ?? 150,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFA500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'ĐĂNG NHẬP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildDividerWithText() {
    return Row(
      children: [
        Expanded(child: Container(height: 1,color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'HOẶC',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Container(height: 1,color: Colors.grey[300])),
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