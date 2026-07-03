import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;
      if (googleAuth.idToken == null) {
        _logger.w("Google login failed: missing ID token");
        return null;
      }
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      _logger.i("Google login success: ${userCredential.user?.email}");
      return userCredential.user;
    } catch (e) {
      _logger.e("Google login error", error: e);
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      _logger.i("Google sign out success");
    } catch (e) {
      _logger.e("Google sign out error", error: e);
    }
  }
}