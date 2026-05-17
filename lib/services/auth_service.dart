import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('AuthService.signInWithGoogle: Starting Google Sign-In');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('AuthService.signInWithGoogle: User cancelled sign-in');
        return null;
      }

      debugPrint('AuthService.signInWithGoogle: Got Google account: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('AuthService.signInWithGoogle: Signing in to Firebase');

      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('AuthService.signInWithGoogle: Firebase sign-in successful');

      return userCredential;
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      debugPrint('AuthService.signUpWithEmail: Creating account for $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('AuthService.signUpWithEmail: Success');
      return credential;
    } catch (e) {
      debugPrint("Error signing up with email: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      debugPrint('AuthService.signInWithEmail: Signing in $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('AuthService.signInWithEmail: Success');
      return credential;
    } catch (e) {
      debugPrint("Error signing in with email: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('AuthService.signOut: Signing out');
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      debugPrint('AuthService.signOut: Complete');
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  /// Clear any auth state and set guest mode flag (no navigation)
  Future<void> enterGuestMode() async {
    await signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
  }

  User? get currentUser => _auth.currentUser;
}