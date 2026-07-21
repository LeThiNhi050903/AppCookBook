import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'features/auth/login.dart';
import 'features/auth/signup.dart';
import 'features/home/home.dart';
import 'features/home/admin_home_screen.dart';
import 'features/auth/forgotpass.dart';
import 'package:google_sign_in/google_sign_in.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: true,
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    logger.i("File .env loaded successfully");
  } catch (e) {
    logger.e("Could not load .env: $e");
  }

  try {
    await Firebase.initializeApp();
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '701455481856-ioi9i1n44vnogtnv3761cfqhks29i1b0.apps.googleusercontent.com',
    );
    logger.i("Firebase initialized");
  } catch (e) {
    logger.e("Firebase init error: $e");
  }

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
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: "/login",
      routes: {
        "/login": (context) => const LoginPage(),
        "/signup": (context) => const SignupPage(),
        "/home": (context) => const HomeScreen(),
        "/admin_home": (context) => const AdminHomeScreen(),
        "/forgot": (context) => const ForgotPasswordPage(),
      },
    );
  }
}
