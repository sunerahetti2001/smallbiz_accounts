import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/sqlite_service.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  double _currentBalance = 0;
  double _creditOutstanding = 0;
  Map<String, double> _todaySummary = {};
  String? _currentUserId;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get currentBalance => _currentBalance;
  double get creditOutstanding => _creditOutstanding;
  Map<String, double> get todaySummary => _todaySummary;

  final SqliteService _sqlite = SqliteService();

  Future<void> loadTransactions(String userId) async {
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _sqlite.getTransactions(userId);
      await _calculateSummaries(userId);
      debugPrint('TransactionProvider: Loaded ${_transactions.length} transactions for user $userId');
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _calculateSummaries(String userId) async {
    try {
      final user = await _sqlite.getUser(id: userId);
      double balance = user?.openingBalance ?? 0;

      double todayIncome = 0;
      double todayExpense = 0;
      double todayCredit = 0;

      final today = DateTime.now();

      // First pass: compute cash balance and today's income/expense
      for (var t in _transactions) {
        final bool isToday = t.date.year == today.year &&
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
          if (isToday) todayIncome += t.amount;   // payments count as income today
        } else if (t.type == TransactionType.creditSale) {
          if (!t.isPaid && isToday) {
            todayCredit += t.amount;   // new credits issued today
          }
        }
      }

      // Second pass: compute net credit outstanding per customer
      Map<String, double> creditByCustomer = {};
      Map<String, double> paymentByCustomer = {};
      for (var t in _transactions) {
        final customer = t.customerName ?? '';
        if (t.type == TransactionType.creditSale && !t.isPaid) {
          creditByCustomer[customer] = (creditByCustomer[customer] ?? 0) + t.amount;
        } else if (t.type == TransactionType.creditPayment) {
          paymentByCustomer[customer] = (paymentByCustomer[customer] ?? 0) + t.amount;
        }
      }

      double credit = 0;
      for (var customer in creditByCustomer.keys) {
        double totalCredit = creditByCustomer[customer] ?? 0;
        double totalPayments = paymentByCustomer[customer] ?? 0;
        credit += (totalCredit - totalPayments).clamp(0.0, totalCredit);
      }

      _currentBalance = balance;
      _creditOutstanding = credit;
      _todaySummary = {
        'income': todayIncome,
        'expense': todayExpense,
        'credit': todayCredit,
      };
    } catch (e) {
      debugPrint('Error calculating summaries: $e');
    }
  }

  Future<void> addTransaction(TransactionModel transaction, String userId) async {
    debugPrint('TransactionProvider: Adding transaction for user $userId');
    await _sqlite.insertTransaction(transaction, userId);
    await loadTransactions(userId);
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

  // Clear data (useful for logout)
  void clear() {
    _transactions = [];
    _currentBalance = 0;
    _creditOutstanding = 0;
    _todaySummary = {};
    _currentUserId = null;
    notifyListeners();
  }
}