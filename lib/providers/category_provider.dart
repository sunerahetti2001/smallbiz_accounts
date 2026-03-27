import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/mock_database.dart';
import '../utils/constants.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool _isLoading = false;

  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<CategoryModel> get incomeCategories => _incomeCategories;
  bool get isLoading => _isLoading;

  final MockDatabase _db = MockDatabase();

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    final all = await _db.getCategories();
    _expenseCategories = all.where((c) => c.type == CategoryType.expense).toList();
    _incomeCategories = all.where((c) => c.type == CategoryType.income).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(CategoryModel category) async {
    _isLoading = true;
    notifyListeners();

    await _db.addCategory(category);
    await loadCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel category) async {
    _isLoading = true;
    notifyListeners();

    await _db.deleteCategory(category.id);
    await _db.addCategory(category);
    await loadCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _isLoading = true;
    notifyListeners();

    await _db.deleteCategory(id);
    await loadCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> ensureDefaultCategories() async {
    await _db.initDefaultData();
    await loadCategories();
  }
}