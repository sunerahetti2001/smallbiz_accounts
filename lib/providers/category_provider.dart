import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/category_model.dart';
import '../services/sqlite_service.dart';
import '../services/backup_service.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool _isLoading = false;

  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<CategoryModel> get incomeCategories => _incomeCategories;
  bool get isLoading => _isLoading;

  final SqliteService _sqlite = SqliteService();

  Future<void> loadCategories(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final all = await _sqlite.getCategories(userId);
      _expenseCategories = all.where((c) => c.type == CategoryType.expense).toList();
      _incomeCategories = all.where((c) => c.type == CategoryType.income).toList();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(CategoryModel category, String userId) async {
    _isLoading = true;
    notifyListeners();

    await _sqlite.insertCategory(category, userId);
    await loadCategories(userId);

    // Backup single category if user is signed in and online
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null && userId == auth.currentUser!.uid) {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
        final backupService = BackupService();
        if (await backupService.isAutoBackupEnabled()) {
          await backupService.backupSingleCategory(category);
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel category, String userId) async {
    _isLoading = true;
    notifyListeners();

    await _sqlite.insertCategory(category, userId);
    await loadCategories(userId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteCategory(String id, String userId) async {
    _isLoading = true;
    notifyListeners();

    await _sqlite.deleteCategory(id);
    await loadCategories(userId);

    _isLoading = false;
    notifyListeners();
  }
}