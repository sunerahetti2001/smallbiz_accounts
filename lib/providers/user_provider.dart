import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/sqlite_service.dart';
import '../services/auth_service.dart';
=======
import '../models/user_model.dart';
import '../services/mock_database.dart';
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _user != null;

<<<<<<< HEAD
  final SqliteService _sqlite = SqliteService();
  final AuthService _auth = AuthService();
=======
  final MockDatabase _db = MockDatabase();
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a

  Future<void> loadUser() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
<<<<<<< HEAD
      // First, check if Firebase has a user
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        // Try to load cached user from SQLite
        _user = await _sqlite.getUser();
      } else {
        _user = null;
      }
=======
      _user = await _db.getUser();
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
      _isInitialized = true;
    } catch (e) {
      print('Error loading user: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

<<<<<<< HEAD
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithGoogle();
      if (credential != null && credential.user != null) {
        // Check if we already have this user in SQLite
        _user = await _sqlite.getUser();
        if (_user == null) {
          // If no user in SQLite, we might need to go to onboarding
          // This will be handled by the UI based on isOnboarded
        }
      }
    } catch (e) {
      print('Error during Google Sign In: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

=======
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
  Future<void> createUser({
    required String name,
    String? email,
    required String businessName,
    required String currency,
    required double openingBalance,
    required String accountType,
  }) async {
    _isLoading = true;
    notifyListeners();

<<<<<<< HEAD
    final firebaseUser = _auth.currentUser;
    final userId = firebaseUser?.uid ?? DateTime.now().millisecondsSinceEpoch.toString();

    final user = UserModel(
      id: userId,
      name: name,
      email: email ?? firebaseUser?.email,
=======
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
      businessName: businessName,
      currency: currency,
      openingBalance: openingBalance,
      accountType: accountType,
      createdAt: DateTime.now(),
    );

<<<<<<< HEAD
    await _sqlite.saveUser(user);
=======
    await _db.saveUser(user);
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
    _user = user;
    _isInitialized = true;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(UserModel updatedUser) async {
<<<<<<< HEAD
    await _sqlite.saveUser(updatedUser);
=======
    await _db.saveUser(updatedUser);
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
    _user = updatedUser;
    notifyListeners();
  }

<<<<<<< HEAD
  Future<void> logout() async {
    await _auth.signOut();
    await _sqlite.deleteUser(); // Optional: clear local cache on logout
=======
  void logout() {
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
    _user = null;
    _isInitialized = false;
    notifyListeners();
  }
}