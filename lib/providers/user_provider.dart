import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/mock_database.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _user != null;

  final MockDatabase _db = MockDatabase();

  Future<void> loadUser() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _user = await _db.getUser();
      _isInitialized = true;
    } catch (e) {
      print('Error loading user: $e');
      _user = null;
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

    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      businessName: businessName,
      currency: currency,
      openingBalance: openingBalance,
      accountType: accountType,
      createdAt: DateTime.now(),
    );

    await _db.saveUser(user);
    _user = user;
    _isInitialized = true;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(UserModel updatedUser) async {
    await _db.saveUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _isInitialized = false;
    notifyListeners();
  }
}