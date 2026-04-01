import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/sqlite_service.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool _isLoading = false;

  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<CategoryModel> get incomeCategories => _incomeCategories;
  bool get isLoading => _isLoading;

  final SqliteService _sqlite = SqliteService();

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final all = await _sqlite.getCategories();
      _expenseCategories = all.where((c) => c.type == CategoryType.expense).toList();
      _incomeCategories = all.where((c) => c.type == CategoryType.income).toList();
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    _isLoading = true;
    notifyListeners();

    await _sqlite.insertCategory(category);
    await loadCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel category) async {
    _isLoading = true;
    notifyListeners();

    await _sqlite.insertCategory(category);
    await loadCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _isLoading = true;
    notifyListeners();

    await _sqlite.deleteCategory(id);
    await loadCategories();

    _isLoading = false;
    notifyListeners();
  }
}