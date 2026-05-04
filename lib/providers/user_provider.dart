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
  bool _needsOnboarding = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _user != null;
  bool get needsOnboarding => _needsOnboarding;
  bool get isGuest => _user != null && (_user!.id.startsWith('guest_') || _user!.email == null);
  bool get isFirebaseAuthenticated => _auth.currentUser != null;
  String? get userEmail => _user?.email ?? _auth.currentUser?.email;

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

      debugPrint('UserProvider.loadUser: Firebase user: ${firebaseUser?.uid}, email: ${firebaseUser?.email}, LastUserId: $lastUserId');

      if (firebaseUser != null) {
        // Try to load user by Firebase UID
        _user = await _sqlite.getUser(id: firebaseUser.uid);

        if (_user != null) {
          // User found in SQLite
          await prefs.setString(_lastUserIdKey, firebaseUser.uid);
          _needsOnboarding = false;
          debugPrint('UserProvider: Firebase user loaded from SQLite: ${_user!.name}, email: ${_user!.email}');

          // If user email is null but Firebase has email, update it
          if (_user!.email == null && firebaseUser.email != null) {
            final updatedUser = _user!.copyWith(email: firebaseUser.email);
            await _sqlite.saveUser(updatedUser);
            _user = updatedUser;
            debugPrint('UserProvider: Updated user email from Firebase: ${firebaseUser.email}');
          }
        } else {
          // Firebase user exists but no SQLite record
          _needsOnboarding = true;
          _user = null;
          debugPrint('UserProvider: Firebase user exists but no SQLite record - needs onboarding');
        }
      } else if (lastUserId != null && lastUserId.startsWith('guest_')) {
        // Guest user auto-login
        _user = await _sqlite.getUser(id: lastUserId);
        if (_user != null) {
          _needsOnboarding = false;
          debugPrint('UserProvider: Guest user loaded: ${_user!.name}');
        } else {
          await prefs.remove(_lastUserIdKey);
          _needsOnboarding = false;
          _user = null;
        }
      } else {
        _user = null;
        _needsOnboarding = false;
        debugPrint('UserProvider: No user found');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading user: $e');
      _user = null;
      _needsOnboarding = false;
      _isInitialized = true;
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
        final uid = credential.user!.uid;
        final email = credential.user!.email;
        debugPrint('UserProvider.signInWithGoogle: Success, UID: $uid, email: $email');

        _user = await _sqlite.getUser(id: uid);

        if (_user != null) {
          // Existing user found in SQLite
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_lastUserIdKey, uid);
          _needsOnboarding = false;
          _isInitialized = true;

          // Update email if needed
          if (_user!.email == null && email != null) {
            final updatedUser = _user!.copyWith(email: email);
            await _sqlite.saveUser(updatedUser);
            _user = updatedUser;
          }

          debugPrint('UserProvider.signInWithGoogle: Existing user loaded: ${_user!.name}');
        } else {
          // New user - needs onboarding
          _needsOnboarding = true;
          _user = null;
          _isInitialized = true;
          debugPrint('UserProvider.signInWithGoogle: New user - needs onboarding');
        }

        notifyListeners();
      } else {
        debugPrint('UserProvider.signInWithGoogle: Sign-in cancelled or returned null');
        _needsOnboarding = false;
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error during Google Sign In: $e');
      _needsOnboarding = false;
      _user = null;
      notifyListeners();
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
        final uid = credential.user!.uid;
        final userEmail = credential.user!.email;
        debugPrint('UserProvider.signInWithEmail: Success, UID: $uid, email: $userEmail');

        _user = await _sqlite.getUser(id: uid);

        if (_user != null) {
          // Existing user found
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_lastUserIdKey, uid);
          _needsOnboarding = false;
          _isInitialized = true;

          // Update email if needed
          if (_user!.email == null && userEmail != null) {
            final updatedUser = _user!.copyWith(email: userEmail);
            await _sqlite.saveUser(updatedUser);
            _user = updatedUser;
          }

          debugPrint('UserProvider.signInWithEmail: Existing user loaded: ${_user!.name}');
        } else {
          // Check if this was a guest user trying to connect
          final prefs = await SharedPreferences.getInstance();
          final lastUserId = prefs.getString(_lastUserIdKey);

          if (lastUserId != null && lastUserId.startsWith('guest_')) {
            // Guest user is connecting - convert guest to Firebase user
            final guestUser = await _sqlite.getUser(id: lastUserId);
            if (guestUser != null) {
              final newUser = UserModel(
                id: uid,
                name: guestUser.name,
                email: userEmail,
                businessName: guestUser.businessName,
                currency: guestUser.currency,
                openingBalance: guestUser.openingBalance,
                accountType: guestUser.accountType,
                createdAt: guestUser.createdAt,
              );
              await _sqlite.saveUser(newUser);

              // Copy transactions from guest to new user
              await _copyTransactions(lastUserId, uid);

              // Delete guest data
              await _sqlite.clearUserData(lastUserId);

              await prefs.setString(_lastUserIdKey, uid);

              _user = newUser;
              _needsOnboarding = false;
              _isInitialized = true;
              debugPrint('UserProvider.signInWithEmail: Guest converted to Firebase user: ${_user!.name}');
            } else {
              _needsOnboarding = true;
              _user = null;
              _isInitialized = true;
            }
          } else {
            // No SQLite record at all
            _needsOnboarding = true;
            _user = null;
            _isInitialized = true;
            debugPrint('UserProvider.signInWithEmail: No SQLite record - needs onboarding');
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error during Email Sign In: $e');
      _needsOnboarding = false;
      _user = null;
      notifyListeners();
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
      final credential = await _auth.signUpWithEmail(email, password);
      debugPrint('UserProvider.signUpWithEmail: Success, UID: ${credential?.user?.uid}');

      // Check if there's a guest user to convert
      final prefs = await SharedPreferences.getInstance();
      final lastUserId = prefs.getString(_lastUserIdKey);

      if (lastUserId != null && lastUserId.startsWith('guest_') && credential?.user != null) {
        // Convert guest to Firebase user
        final uid = credential!.user!.uid;
        final guestUser = await _sqlite.getUser(id: lastUserId);

        if (guestUser != null) {
          final newUser = UserModel(
            id: uid,
            name: guestUser.name,
            email: email,
            businessName: guestUser.businessName,
            currency: guestUser.currency,
            openingBalance: guestUser.openingBalance,
            accountType: guestUser.accountType,
            createdAt: guestUser.createdAt,
          );
          await _sqlite.saveUser(newUser);

          // Copy transactions
          await _copyTransactions(lastUserId, uid);

          // Delete guest data
          await _sqlite.clearUserData(lastUserId);

          await prefs.setString(_lastUserIdKey, uid);

          _user = newUser;
          _needsOnboarding = false;
          _isInitialized = true;

          // Also initialize default categories if they don't exist
          final sqlite = SqliteService();
          await sqlite.initDefaultCategories(uid);

          debugPrint('UserProvider.signUpWithEmail: Guest converted to Firebase user: ${_user!.name}');
          notifyListeners();
          return;
        }
      }

      // Normal sign up - needs onboarding
      _user = null;
      _needsOnboarding = true;
      _isInitialized = true;
      debugPrint('UserProvider.signUpWithEmail: New user - needs onboarding');
      notifyListeners();
    } catch (e) {
      debugPrint('Error during Email Sign Up: $e');
      _needsOnboarding = false;
      _user = null;
      notifyListeners();
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
      final firebaseUser = _auth.currentUser;
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

      _user = user;
      _needsOnboarding = false;
      _isInitialized = true;
      debugPrint('UserProvider.createUser: Complete');
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Copy transactions from old user ID to new user ID
  Future<void> _copyTransactions(String oldUserId, String newUserId) async {
    try {
      final sqlite = SqliteService();
      final oldTransactions = await sqlite.getTransactions(oldUserId);

      for (var t in oldTransactions) {
        await sqlite.insertTransaction(t, newUserId);
      }
      debugPrint('UserProvider._copyTransactions: Copied ${oldTransactions.length} transactions from $oldUserId to $newUserId');
    } catch (e) {
      debugPrint('Error copying transactions: $e');
    }
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
      debugPrint('Guest data cleared: $currentUserId');
    }

    await _auth.signOut();
    await prefs.remove(_lastUserIdKey);

    _user = null;
    _needsOnboarding = false;
    _isInitialized = false;

    notifyListeners();
  }
}