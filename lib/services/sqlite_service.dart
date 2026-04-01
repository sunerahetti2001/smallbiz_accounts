import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
    String path = join(await getDatabasesPath(), 'smallbiz_accounts.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        isDefault INTEGER NOT NULL
      )
    ''');

    // Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        paymentMethod TEXT,
        customerName TEXT,
        customerMobile TEXT,
        items TEXT,
        isPaid INTEGER NOT NULL,
        dueDate TEXT
      )
    ''');

    // User Table (Local Cache)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        businessName TEXT NOT NULL,
        currency TEXT NOT NULL,
        openingBalance REAL NOT NULL,
        accountType TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // User Operations
  Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'businessName': user.businessName,
        'currency': user.currency,
        'openingBalance': user.openingBalance,
        'accountType': user.accountType,
        'createdAt': user.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    if (maps.isEmpty) return null;
    
    return UserModel(
      id: maps[0]['id'],
      name: maps[0]['name'],
      email: maps[0]['email'],
      businessName: maps[0]['businessName'],
      currency: maps[0]['currency'],
      openingBalance: maps[0]['openingBalance'],
      accountType: maps[0]['accountType'],
      createdAt: DateTime.parse(maps[0]['createdAt']),
    );
  }

  Future<void> deleteUser() async {
    final db = await database;
    await db.delete('users');
  }

  // Category Operations
  Future<void> insertCategory(CategoryModel category) async {
    final db = await database;
    await db.insert(
      'categories',
      {
        'id': category.id,
        'name': category.name,
        'type': category.type.name,
        'icon': category.icon,
        'isDefault': category.isDefault ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return CategoryModel(
        id: maps[i]['id'],
        name: maps[i]['name'],
        type: maps[i]['type'] == 'expense' ? CategoryType.expense : CategoryType.income,
        icon: maps[i]['icon'],
        isDefault: maps[i]['isDefault'] == 1,
      );
    });
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Transaction Operations
  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    
    // If credit payment, update linked credit sale
    if (transaction.type == TransactionType.creditPayment && transaction.customerName != null) {
      final List<Map<String, dynamic>> pendingSales = await db.query(
        'transactions',
        where: 'type = ? AND customerName = ? AND isPaid = 0',
        whereArgs: [TransactionType.creditSale.name, transaction.customerName],
      );

      if (pendingSales.isNotEmpty) {
        final t = pendingSales.first;
        final currentAmount = t['amount'] as double;
        final newAmount = currentAmount - transaction.amount;

        if (newAmount <= 0.01) {
          await db.update(
            'transactions',
            {'isPaid': 1},
            where: 'id = ?',
            whereArgs: [t['id']],
          );
        } else {
          await db.update(
            'transactions',
            {'amount': newAmount},
            where: 'id = ?',
            whereArgs: [t['id']],
          );
        }
      }
    }

    await db.insert(
      'transactions',
      {
        'id': transaction.id,
        'type': transaction.type.name,
        'amount': transaction.amount,
        'category': transaction.category,
        'description': transaction.description,
        'date': transaction.date.toIso8601String(),
        'paymentMethod': transaction.paymentMethod,
        'customerName': transaction.customerName,
        'customerMobile': transaction.customerMobile,
        'items': transaction.items != null ? transaction.items.toString() : null, // Simplification for SQLite
        'isPaid': transaction.isPaid ? 1 : 0,
        'dueDate': transaction.dueDate?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) {
      return TransactionModel(
        id: maps[i]['id'],
        type: TransactionType.values.byName(maps[i]['type']),
        amount: maps[i]['amount'],
        category: maps[i]['category'],
        description: maps[i]['description'],
        date: DateTime.parse(maps[i]['date']),
        paymentMethod: maps[i]['paymentMethod'],
        customerName: maps[i]['customerName'],
        customerMobile: maps[i]['customerMobile'],
        isPaid: maps[i]['isPaid'] == 1,
        dueDate: maps[i]['dueDate'] != null ? DateTime.parse(maps[i]['dueDate']) : null,
      );
    });
  }

  Future<void> initDefaultCategories() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories'));
    if (count == 0) {
      for (var cat in AppConstants.defaultExpenseCategories) {
        await insertCategory(CategoryModel(
          id: 'expense_${cat['name']}',
          name: cat['name']!,
          type: CategoryType.expense,
          icon: cat['icon']!,
          isDefault: true,
        ));
      }
      for (var cat in AppConstants.defaultIncomeCategories) {
        await insertCategory(CategoryModel(
          id: 'income_${cat['name']}',
          name: cat['name']!,
          type: CategoryType.income,
          icon: cat['icon']!,
          isDefault: true,
        ));
      }
    }
  }
}