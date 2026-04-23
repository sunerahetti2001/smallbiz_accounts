import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/sqlite_service.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _user != null;
  bool get isGuest => _user != null && (_user!.id.startsWith('guest_') || _user!.email == null);

  final SqliteService _sqlite = SqliteService();
  final AuthService _auth = AuthService();
  static const String _lastUserIdKey = 'last_user_id';

  Future<void> loadUser() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUserId = prefs.getString(_lastUserIdKey);
      
      final firebaseUser = _auth.currentUser;
      
      if (firebaseUser != null) {
        // Authenticated user
        _user = await _sqlite.getUser(id: firebaseUser.uid);
        if (_user != null) {
          await prefs.setString(_lastUserIdKey, firebaseUser.uid);
        }
      } else if (lastUserId != null && lastUserId.startsWith('guest_')) {
        // Guest user auto-login
        _user = await _sqlite.getUser(id: lastUserId);
      } else {
        _user = null;
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading user: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithGoogle();
      if (credential != null && credential.user != null) {
        _user = await _sqlite.getUser(id: credential.user!.uid);
        if (_user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_lastUserIdKey, credential.user!.uid);
        }
      }
    } catch (e) {
      debugPrint('Error during Google Sign In: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmail(email, password);
      if (credential != null && credential.user != null) {
        _user = await _sqlite.getUser(id: credential.user!.uid);
        if (_user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_lastUserIdKey, credential.user!.uid);
        }
      }
    } catch (e) {
      debugPrint('Error during Email Sign In: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signUpWithEmail(email, password);
      _user = null; // Forces onboarding
    } catch (e) {
      debugPrint('Error during Email Sign Up: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

    final firebaseUser = _auth.currentUser;
    final userId = firebaseUser?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

    final user = UserModel(
      id: userId,
      name: name,
      email: email ?? firebaseUser?.email,
      businessName: businessName,
      currency: currency,
      openingBalance: openingBalance,
      accountType: accountType,
      createdAt: DateTime.now(),
    );

    await _sqlite.saveUser(user);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserIdKey, userId);
    
    _user = user;
    _isInitialized = true;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(UserModel updatedUser) async {
    await _sqlite.saveUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  Future<void> logout({bool clearGuestData = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = _user?.id;
    
    if (clearGuestData && currentUserId != null && currentUserId.startsWith('guest_')) {
      await _sqlite.clearUserData(currentUserId);
    }
    
    await _auth.signOut();
    await prefs.remove(_lastUserIdKey);

    _user = null;
    _isInitialized = false;
    notifyListeners();
  }
}
