import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  Future<List<CategoryModel>> getCategories({CategoryType? type}) async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString(AppConstants.categoriesKey);

    if (categoriesJson != null) {
      List<CategoryModel> all = (jsonDecode(categoriesJson) as List)
          .map((c) => CategoryModel.fromJson(c))
          .toList();

      if (type != null) {
        return all.where((c) => c.type == type).toList();
      }
      return all;
    }
    return [];
  }

  Future<void> addCategory(CategoryModel category) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();

    categories.add(category);
    await _saveCategories(categories);
  }

  Future<void> updateCategory(CategoryModel updatedCategory) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();

    final index = categories.indexWhere((c) => c.id == updatedCategory.id);
    if (index != -1) {
      categories[index] = updatedCategory;
      await _saveCategories(categories);
    }
  }

  Future<void> deleteCategory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();

    categories.removeWhere((c) => c.id == id);
    await _saveCategories(categories);
  }

  Future<bool> isCategoryInUse(String categoryName) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(AppConstants.transactionsKey) ?? [];

    for (var jsonStr in transactionsJson) {
      final transaction = jsonDecode(jsonStr);
      if (transaction['category'] == categoryName) {
        return true;
      }
    }
    return false;
  }

  Future<CategoryModel?> getCategoryByName(String name) async {
    final categories = await getCategories();
    try {
      return categories.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }

  Future<void> initializeDefaultCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool('categories_initialized') ?? false;

    if (!isInitialized) {
      final List<CategoryModel> defaultCategories = [];

      for (var cat in AppConstants.defaultExpenseCategories) {
        defaultCategories.add(CategoryModel(
          id: 'expense_${DateTime.now().millisecondsSinceEpoch}_${cat['name']}',
          name: cat['name']!,
          type: CategoryType.expense,
          icon: cat['icon']!,
          isDefault: true,
        ));
      }

      for (var cat in AppConstants.defaultIncomeCategories) {
        defaultCategories.add(CategoryModel(
          id: 'income_${DateTime.now().millisecondsSinceEpoch}_${cat['name']}',
          name: cat['name']!,
          type: CategoryType.income,
          icon: cat['icon']!,
          isDefault: true,
        ));
      }

      await _saveCategories(defaultCategories);
      await prefs.setBool('categories_initialized', true);
    }
  }

  Future<void> _saveCategories(List<CategoryModel> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = categories.map((c) => c.toJson()).toList();
    await prefs.setString(AppConstants.categoriesKey, jsonEncode(categoriesJson));
  }

  Future<Map<String, int>> getCategoryStats() async {
    final categories = await getCategories();
    return {
      'total': categories.length,
      'expense': categories.where((c) => c.type == CategoryType.expense).length,
      'income': categories.where((c) => c.type == CategoryType.income).length,
      'default': categories.where((c) => c.isDefault).length,
      'custom': categories.where((c) => !c.isDefault).length,
    };
  }
}