import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/mock_database.dart';
import '../utils/accounting_helper.dart';

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

  final MockDatabase _db = MockDatabase();

  Future<void> loadTransactions() async {
    if (_isLoading) return;

    _isLoading = true;
    // Don't notify during load to avoid build issues
    // notifyListeners();

    try {
      _transactions = await _db.getTransactions();
      _currentBalance = await _db.getCurrentBalance();
      _creditOutstanding = await _db.getTotalCreditOutstanding();
      _todaySummary = await _db.getTodaySummary();
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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