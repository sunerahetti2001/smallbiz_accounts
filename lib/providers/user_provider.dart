import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/sqlite_service.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isGuest => _user != null && _user!.id.startsWith('guest_');
  bool get isFirebaseAuthenticated => _authService.currentUser != null;
  String? get userEmail => _user?.email ?? _authService.currentUser?.email;

  final SqliteService _sqlite = SqliteService();
  final AuthService _authService = AuthService();

  static const String _lastUserIdKey = 'last_user_id';
  static const String _isGuestKey = 'isGuest';

  // ---- Methods called by AuthGate ----

  Future<void> loadUserByUid(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _sqlite.getUser(id: uid);
      if (_user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastUserIdKey, uid);
        await prefs.setBool(_isGuestKey, false);
      }
    } catch (e) {
      debugPrint('Error loading user by UID: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> prepareForOnboarding() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, false);
    notifyListeners();
  }

  Future<void> loadGuestUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUserId = prefs.getString(_lastUserIdKey);
      if (lastUserId != null && lastUserId.startsWith('guest_')) {
        _user = await _sqlite.getUser(id: lastUserId);
      } else {
        _user = null;
      }
    } catch (e) {
      debugPrint('Error loading guest user: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---- Auth methods (return bool: true if user has local record) ----

  /// Returns `true` if a SQLite record exists for the Firebase user.
  /// If no record, signs out and returns `false` so the login screen can show an error.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null || credential.user == null) {
        return false; // cancelled
      }

      final uid = credential.user!.uid;
      final email = credential.user!.email;

      // Check for existing SQLite record
      final existingUser = await _sqlite.getUser(id: uid);
      if (existingUser == null) {
        // No local record – sign out to prevent StreamBuilder from navigating
        await _authService.signOut();
        return false;
      }

      // Update email if needed
      if (existingUser.email == null && email != null) {
        final updated = existingUser.copyWith(email: email);
        await _sqlite.saveUser(updated);
      }

      // Set last user ID (StreamBuilder will load the user)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUserIdKey, uid);
      await prefs.setBool(_isGuestKey, false);

      return true;
    } catch (e) {
      debugPrint('Google Sign In error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns `true` if the email sign‑in found a local record.
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmail(email, password);
      if (credential == null || credential.user == null) {
        return false;
      }

      final uid = credential.user!.uid;
      final existingUser = await _sqlite.getUser(id: uid);
      if (existingUser == null) {
        await _authService.signOut();
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUserIdKey, uid);
      await prefs.setBool(_isGuestKey, false);

      return true;
    } catch (e) {
      debugPrint('Email Sign In error: $e');
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
      await _authService.signUpWithEmail(email, password);
      // The new Firebase user will be picked up by the StreamBuilder → BasicInfoScreen
    } catch (e) {
      debugPrint('Email Sign Up error: $e');
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

    try {
      final firebaseUser = _authService.currentUser;
      final userId = firebaseUser?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final userEmail = email ?? firebaseUser?.email;

      debugPrint('UserProvider.createUser: ID=$userId, Email=$userEmail, Firebase=${firebaseUser != null}');

      final user = UserModel(
        id: userId,
        name: name,
        email: userEmail,
        businessName: businessName,
        currency: currency,
        openingBalance: openingBalance,
        accountType: accountType,
        createdAt: DateTime.now(),
      );

      await _sqlite.saveUser(user);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUserIdKey, userId);

      if (userId.startsWith('guest_')) {
        await prefs.setBool(_isGuestKey, true);
      } else {
        await prefs.setBool(_isGuestKey, false);
      }

      _user = user;
      debugPrint('UserProvider.createUser: Complete');
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(UserModel updatedUser) async {
    await _sqlite.saveUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  Future<void> logout({bool clearGuestData = false}) async {
    final currentUserId = _user?.id;
    final wasGuest = isGuest;

    if (clearGuestData && wasGuest && currentUserId != null) {
      await _sqlite.clearUserData(currentUserId);
      debugPrint('Guest data cleared: $currentUserId');
    }

    await _authService.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUserIdKey);
    await prefs.setBool(_isGuestKey, false);

    _user = null;
    notifyListeners();
  }
}