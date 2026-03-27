import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';

class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal();

  static const Uuid _uuid = Uuid();

  Future<void> initDefaultData() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool('db_initialized') ?? false;

    if (!isInitialized) {
      final List<CategoryModel> defaultCategories = [];

      for (var cat in AppConstants.defaultExpenseCategories) {
        defaultCategories.add(CategoryModel(
          id: _uuid.v4(),
          name: cat['name']!,
          type: CategoryType.expense,
          icon: cat['icon']!,
          isDefault: true,
        ));
      }

      for (var cat in AppConstants.defaultIncomeCategories) {
        defaultCategories.add(CategoryModel(
          id: _uuid.v4(),
          name: cat['name']!,
          type: CategoryType.income,
          icon: cat['icon']!,
          isDefault: true,
        ));
      }

      final categoriesJson = defaultCategories.map((c) => c.toJson()).toList();
      await prefs.setString(AppConstants.categoriesKey, jsonEncode(categoriesJson));
      await prefs.setBool('db_initialized', true);
    }
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
    await prefs.setBool(AppConstants.isOnboardedKey, true);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();

    // First, get all existing transactions
    List<TransactionModel> allTransactions = await getTransactions();

    // If this is a credit payment, update the corresponding credit sale
    if (transaction.type == TransactionType.creditPayment && transaction.customerName != null) {
      for (int i = 0; i < allTransactions.length; i++) {
        final t = allTransactions[i];
        if (t.type == TransactionType.creditSale &&
            t.customerName == transaction.customerName &&
            !t.isPaid) {

          final remainingAmount = t.amount - transaction.amount;

          if (remainingAmount <= 0.01) {
            // Full payment - mark as paid
            final updatedCredit = t.copyWith(isPaid: true);
            allTransactions[i] = updatedCredit;
          } else {
            // Partial payment - update the remaining amount
            final updatedCredit = t.copyWith(amount: remainingAmount);
            allTransactions[i] = updatedCredit;
          }
          break;
        }
      }
    }

    // Add the new payment transaction
    allTransactions.add(transaction);

    // Save all transactions back to storage
    await _saveTransactions(allTransactions);
  }

  Future<List<TransactionModel>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(AppConstants.transactionsKey) ?? [];

    return transactionsJson.map((jsonStr) {
      return TransactionModel.fromJson(jsonDecode(jsonStr));
    }).toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString(AppConstants.categoriesKey);
    List<CategoryModel> categories = [];

    if (categoriesJson != null) {
      categories = (jsonDecode(categoriesJson) as List)
          .map((c) => CategoryModel.fromJson(c))
          .toList();
    }

    categories.add(category);
    await prefs.setString(
        AppConstants.categoriesKey,
        jsonEncode(categories.map((c) => c.toJson()).toList())
    );
  }

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

  Future<void> deleteCategory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString(AppConstants.categoriesKey);

    if (categoriesJson != null) {
      List<CategoryModel> categories = (jsonDecode(categoriesJson) as List)
          .map((c) => CategoryModel.fromJson(c))
          .where((c) => c.id != id)
          .toList();

      await prefs.setString(
          AppConstants.categoriesKey,
          jsonEncode(categories.map((c) => c.toJson()).toList())
      );
    }
  }

  Future<double> getCurrentBalance() async {
    final user = await getUser();
    final transactions = await getTransactions();

    double balance = user?.openingBalance ?? 0;

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        balance += t.amount;
      } else if (t.type == TransactionType.expense) {
        balance -= t.amount;
      } else if (t.type == TransactionType.creditPayment) {
        balance += t.amount;
      }
      // Credit sales don't affect cash balance until paid
    }

    return balance;
  }

  Future<double> getTotalCreditOutstanding() async {
    final transactions = await getTransactions();

    double total = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.creditSale && !t.isPaid) {
        total += t.amount;
      }
    }
    return total;
  }

  Future<Map<String, double>> getTodaySummary() async {
    final today = DateTime.now();
    final transactions = await getTransactions();
    final todayTx = transactions.where((t) =>
    t.date.year == today.year &&
        t.date.month == today.month &&
        t.date.day == today.day
    );

    double income = 0;
    double expense = 0;
    double credit = 0;

    for (var t in todayTx) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else if (t.type == TransactionType.expense) {
        expense += t.amount;
      } else if (t.type == TransactionType.creditSale && !t.isPaid) {
        credit += t.amount;
      } else if (t.type == TransactionType.creditPayment) {
        income += t.amount;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'credit': credit,
    };
  }

  Future<void> _saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = transactions.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(AppConstants.transactionsKey, transactionsJson);
  }
}