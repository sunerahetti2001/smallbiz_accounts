import 'package:flutter/material.dart';
import '../models/category_model.dart';
<<<<<<< HEAD
import '../services/sqlite_service.dart';
=======
import '../services/mock_database.dart';
import '../utils/constants.dart';
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool _isLoading = false;

  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<CategoryModel> get incomeCategories => _incomeCategories;
  bool get isLoading => _isLoading;

<<<<<<< HEAD
  final SqliteService _sqlite = SqliteService();
=======
  final MockDatabase _db = MockDatabase();
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

<<<<<<< HEAD
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
=======
    final all = await _db.getCategories();
    _expenseCategories = all.where((c) => c.type == CategoryType.expense).toList();
    _incomeCategories = all.where((c) => c.type == CategoryType.income).toList();

    _isLoading = false;
    notifyListeners();
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
  }

  Future<void> addCategory(CategoryModel category) async {
    _isLoading = true;
    notifyListeners();

<<<<<<< HEAD
    await _sqlite.insertCategory(category);
=======
    await _db.addCategory(category);
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
    await loadCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel category) async {
    _isLoading = true;
    notifyListeners();

<<<<<<< HEAD
    await _sqlite.insertCategory(category);
=======
    await _db.deleteCategory(category.id);
    await _db.addCategory(category);
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
    await loadCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _isLoading = true;
    notifyListeners();

<<<<<<< HEAD
    await _sqlite.deleteCategory(id);
=======
    await _db.deleteCategory(id);
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
    await loadCategories();

    _isLoading = false;
    notifyListeners();
  }
<<<<<<< HEAD
=======

  Future<void> ensureDefaultCategories() async {
    await _db.initDefaultData();
    await loadCategories();
  }
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
}