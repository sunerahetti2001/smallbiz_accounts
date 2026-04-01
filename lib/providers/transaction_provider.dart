import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
<<<<<<< HEAD
import '../services/sqlite_service.dart';
=======
import '../models/category_model.dart';
import '../services/mock_database.dart';
import '../utils/accounting_helper.dart';
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  double _currentBalance = 0;
  double _creditOutstanding = 0;
  Map<String, double> _todaySummary = {};

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get currentBalance => _currentBalance;
  double get creditOutstanding => _creditOutstanding;
  Map<String, double> get todaySummary => _todaySummary;

<<<<<<< HEAD
  final SqliteService _sqlite = SqliteService();
=======
  final MockDatabase _db = MockDatabase();
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a

  Future<void> loadTransactions() async {
    if (_isLoading) return;

    _isLoading = true;
<<<<<<< HEAD
    // We notify after data is loaded to avoid build issues
    
    try {
      _transactions = await _sqlite.getTransactions();
      await _calculateSummaries();
=======
    // Don't notify during load to avoid build issues
    // notifyListeners();

    try {
      _transactions = await _db.getTransactions();
      _currentBalance = await _db.getCurrentBalance();
      _creditOutstanding = await _db.getTotalCreditOutstanding();
      _todaySummary = await _db.getTodaySummary();
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

<<<<<<< HEAD
  Future<void> _calculateSummaries() async {
    // Current Balance
    double balance = 0; // In a real app, you'd add the user's opening balance here
    // Note: You might want to fetch opening balance from UserProvider
    
    double credit = 0;
    double todayIncome = 0;
    double todayExpense = 0;
    double todayCredit = 0;
    
    final today = DateTime.now();

    for (var t in _transactions) {
      bool isToday = t.date.year == today.year && 
                     t.date.month == today.month && 
                     t.date.day == today.day;

      if (t.type == TransactionType.income) {
        balance += t.amount;
        if (isToday) todayIncome += t.amount;
      } else if (t.type == TransactionType.expense) {
        balance -= t.amount;
        if (isToday) todayExpense += t.amount;
      } else if (t.type == TransactionType.creditPayment) {
        balance += t.amount;
        if (isToday) todayIncome += t.amount;
      } else if (t.type == TransactionType.creditSale) {
        if (!t.isPaid) {
          credit += t.amount;
          if (isToday) todayCredit += t.amount;
        }
      }
    }

    _currentBalance = balance;
    _creditOutstanding = credit;
    _todaySummary = {
      'income': todayIncome,
      'expense': todayExpense,
      'credit': todayCredit,
    };
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _sqlite.insertTransaction(transaction);
    await loadTransactions();
=======
  Future<void> addTransaction(TransactionModel transaction) async {
    if (_isLoading) return;

    _isLoading = true;
    // Don't notify during load to avoid build issues
    // notifyListeners();

    try {
      await _db.addTransaction(transaction);
      // Reload all data after adding
      await loadTransactions();
    } catch (e) {
      print('Error adding transaction: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
  }

  List<TransactionModel> getRecentTransactions({int limit = 10}) {
    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sorted.length > limit) {
      return sorted.sublist(0, limit);
    }
    return sorted;
  }

  Map<String, List<TransactionModel>> getTransactionsByDate() {
    final Map<String, List<TransactionModel>> grouped = {};

    for (var transaction in _transactions) {
      final dateKey = '${transaction.date.year}-${transaction.date.month}-${transaction.date.day}';

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    grouped.forEach((key, value) {
      value.sort((a, b) => b.date.compareTo(a.date));
    });

    return grouped;
  }
}