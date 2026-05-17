import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class SqliteService {
  static final SqliteService _instance = SqliteService._internal();
  factory SqliteService() => _instance;
  SqliteService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'smallbiz_accounts.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        business_name TEXT NOT NULL,
        currency TEXT NOT NULL,
        opening_balance REAL NOT NULL,
        account_type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        payment_method TEXT,
        customer_name TEXT,
        customer_mobile TEXT,
        items TEXT,
        is_paid INTEGER NOT NULL DEFAULT 0,
        due_date TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add user_id column to existing tables
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN user_id TEXT DEFAULT "legacy"');
        await db.execute('ALTER TABLE categories ADD COLUMN user_id TEXT DEFAULT "legacy"');
      } catch (e) {
        // If columns already exist, ignore
        debugPrint('Migration warning: $e');
      }
    }
  }

  // ==================== USER OPERATIONS ====================

  Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'business_name': user.businessName,
        'currency': user.currency,
        'opening_balance': user.openingBalance,
        'account_type': user.accountType,
        'created_at': user.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser({String? id}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (id != null) {
      maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    } else {
      // Get the most recent user
      maps = await db.query('users', limit: 1);
    }

    if (maps.isEmpty) return null;

    final user = maps.first;
    return UserModel(
      id: user['id'],
      name: user['name'],
      email: user['email'],
      businessName: user['business_name'],
      currency: user['currency'],
      openingBalance: user['opening_balance'] is int
          ? (user['opening_balance'] as int).toDouble()
          : user['opening_balance'],
      accountType: user['account_type'],
      createdAt: DateTime.parse(user['created_at']),
    );
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CATEGORY OPERATIONS ====================

  Future<void> insertCategory(CategoryModel category, String userId) async {
    final db = await database;
    await db.insert(
      'categories',
      {
        'id': category.id,
        'user_id': userId,
        'name': category.name,
        'type': category.type == CategoryType.expense ? 'expense' : 'income',
        'icon': category.icon,
        'is_default': category.isDefault ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CategoryModel>> getCategories(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'user_id = ? OR is_default = 1',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return maps.map((map) {
      return CategoryModel(
        id: map['id'],
        name: map['name'],
        type: map['type'] == 'expense' ? CategoryType.expense : CategoryType.income,
        icon: map['icon'],
        isDefault: map['is_default'] == 1,
      );
    }).toList();
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      type: map['type'] == 'expense' ? CategoryType.expense : CategoryType.income,
      icon: map['icon'],
      isDefault: map['is_default'] == 1,
    );
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await database;
    await db.update(
      'categories',
      {
        'name': category.name,
        'icon': category.icon,
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== TRANSACTION OPERATIONS ====================

  Future<void> insertTransaction(TransactionModel transaction, String userId) async {
    final db = await database;

    // Handle credit payment – do not reduce the credit sale amount
    if (transaction.type == TransactionType.creditPayment && transaction.customerName != null) {
      final List<Map<String, dynamic>> pendingSales = await db.query(
        'transactions',
        where: 'user_id = ? AND type = ? AND customer_name = ? AND is_paid = 0',
        whereArgs: [userId, 'creditSale', transaction.customerName],
        orderBy: 'date ASC',
      );

      if (pendingSales.isNotEmpty) {
        final sale = pendingSales.first;
        final double saleAmount = (sale['amount'] as num).toDouble();
        if (transaction.amount >= saleAmount) {
          // Full payment – mark the sale as paid
          await db.update(
            'transactions',
            {'is_paid': 1},
            where: 'id = ?',
            whereArgs: [sale['id']],
          );
        }
        // Partial payment: do not modify the credit sale amount
      }
    }

    // Insert the new transaction
    await db.insert(
      'transactions',
      {
        'id': transaction.id,
        'user_id': userId,
        'type': transaction.type.name,
        'amount': transaction.amount,
        'category': transaction.category,
        'description': transaction.description,
        'date': transaction.date.toIso8601String(),
        'payment_method': transaction.paymentMethod,
        'customer_name': transaction.customerName,
        'customer_mobile': transaction.customerMobile,
        'items': transaction.items != null ? transaction.items.toString() : null,
        'is_paid': transaction.isPaid ? 1 : 0,
        'due_date': transaction.dueDate?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getTransactions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return maps.map((map) {
      return TransactionModel(
        id: map['id'],
        type: _parseTransactionType(map['type']),
        amount: map['amount'] is int
            ? (map['amount'] as int).toDouble()
            : map['amount'],
        category: map['category'],
        description: map['description'],
        date: DateTime.parse(map['date']),
        paymentMethod: map['payment_method'],
        customerName: map['customer_name'],
        customerMobile: map['customer_mobile'],
        isPaid: map['is_paid'] == 1,
        dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      );
    }).toList();
  }

  Future<List<TransactionModel>> getCreditSales(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'user_id = ? AND type = ? AND is_paid = 0',
      whereArgs: [userId, 'creditSale'],
      orderBy: 'due_date ASC, date DESC',
    );

    return maps.map((map) {
      return TransactionModel(
        id: map['id'],
        type: TransactionType.creditSale,
        amount: map['amount'] is int
            ? (map['amount'] as int).toDouble()
            : map['amount'],
        category: map['category'],
        description: map['description'],
        date: DateTime.parse(map['date']),
        paymentMethod: map['payment_method'],
        customerName: map['customer_name'],
        customerMobile: map['customer_mobile'],
        isPaid: map['is_paid'] == 1,
        dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      );
    }).toList();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      {
        'amount': transaction.amount,
        'category': transaction.category,
        'description': transaction.description,
        'payment_method': transaction.paymentMethod,
        'customer_name': transaction.customerName,
        'customer_mobile': transaction.customerMobile,
        'items': transaction.items?.toString(),
        'is_paid': transaction.isPaid ? 1 : 0,
        'due_date': transaction.dueDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== BUSINESS SUMMARY QUERIES ====================

  Future<double> getCurrentBalance(String userId) async {
    final user = await getUser(id: userId);
    final transactions = await getTransactions(userId);

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

  Future<double> getTotalCreditOutstanding(String userId) async {
    final transactions = await getTransactions(userId);
    Map<String, double> creditByCustomer = {};
    Map<String, double> paymentByCustomer = {};

    for (var t in transactions) {
      final customer = t.customerName ?? '';
      if (t.type == TransactionType.creditSale && !t.isPaid) {
        creditByCustomer[customer] = (creditByCustomer[customer] ?? 0) + t.amount;
      } else if (t.type == TransactionType.creditPayment) {
        paymentByCustomer[customer] = (paymentByCustomer[customer] ?? 0) + t.amount;
      }
    }

    double total = 0;
    for (var customer in creditByCustomer.keys) {
      double totalCredit = creditByCustomer[customer] ?? 0;
      double totalPayments = paymentByCustomer[customer] ?? 0;
      total += (totalCredit - totalPayments).clamp(0.0, totalCredit);
    }
    return total;
  }

  Future<Map<String, double>> getTodaySummary(String userId) async {
    final today = DateTime.now();
    final transactions = await getTransactions(userId);

    double income = 0;
    double expense = 0;
    double credit = 0;

    for (var t in transactions) {
      final isToday = t.date.year == today.year &&
          t.date.month == today.month &&
          t.date.day == today.day;

      if (isToday) {
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
    }

    return {
      'income': income,
      'expense': expense,
      'credit': credit,
    };
  }

  // ==================== UTILITY METHODS ====================

  TransactionType _parseTransactionType(String type) {
    switch (type) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'creditSale':
        return TransactionType.creditSale;
      case 'creditPayment':
        return TransactionType.creditPayment;
      default:
        return TransactionType.expense;
    }
  }

  Future<void> initDefaultCategories(String userId) async {
    final existingCategories = await getCategories(userId);
    if (existingCategories.isNotEmpty) return;

    // Add default expense categories
    for (var cat in AppConstants.defaultExpenseCategories) {
      await insertCategory(
        CategoryModel(
          id: 'expense_${cat['name']}_${DateTime.now().millisecondsSinceEpoch}',
          name: cat['name']!,
          type: CategoryType.expense,
          icon: cat['icon']!,
          isDefault: true,
        ),
        userId,
      );
    }

    // Add default income categories
    for (var cat in AppConstants.defaultIncomeCategories) {
      await insertCategory(
        CategoryModel(
          id: 'income_${cat['name']}_${DateTime.now().millisecondsSinceEpoch}',
          name: cat['name']!,
          type: CategoryType.income,
          icon: cat['icon']!,
          isDefault: true,
        ),
        userId,
      );
    }
  }

  Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.delete('transactions', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('categories', where: 'user_id = ? AND is_default = 0', whereArgs: [userId]);
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}