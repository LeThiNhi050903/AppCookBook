import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/login.dart';
import 'features/auth/signup.dart';
import 'features/home/home.dart';
import 'features/auth/forgotpass.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CookBook',
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus(); // ẩn bàn phím toàn app
          },
          child: child,
        );
      },

      initialRoute: "/login",
      routes: {
        "/login": (context) => const LoginPage(),
        "/signup": (context) => const SignupPage(),
        "/home": (context) => const HomeScreen(),
        "/forgot": (context) => const ForgotPasswordPage(),
      },
    );
  }
}