import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Google sign-in instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // 🔹 Sign in with Email & Password
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 🔹 Sign up with Email & Password
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 🔹 Send Password Reset Email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // 🔹 Sign out (email + Google + Facebook)
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  // 🔹 Current User
  User? get currentUser => _auth.currentUser;

  // 🔹 Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Cancelled by user

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      rethrow;
    }
  }

  // 🔹 Sign in with Facebook
  Future<UserCredential> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential =
        FacebookAuthProvider.credential(accessToken.token); // ✅ FIXED HERE

        return await FirebaseAuth.instance.signInWithCredential(credential);
      } else if (result.status == LoginStatus.cancelled) {
        throw Exception("Facebook login cancelled by user");
      } else {
        throw Exception(result.message ?? "Facebook login failed");
      }
    } catch (e) {
      print("❌ Facebook sign-in failed: $e");
      rethrow;
    }
  }

}
