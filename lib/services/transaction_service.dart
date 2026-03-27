import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  // Add transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await getTransactions();

    transactions.add(transaction);
    await _saveTransactions(transactions);
  }

  // Get all transactions
  Future<List<TransactionModel>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(AppConstants.transactionsKey) ?? [];

    return transactionsJson.map((jsonStr) {
      return TransactionModel.fromJson(jsonDecode(jsonStr));
    }).toList();
  }

  // Get transactions by date range
  Future<List<TransactionModel>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final all = await getTransactions();
    return all.where((t) =>
    t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  // Get transactions by type
  Future<List<TransactionModel>> getTransactionsByType(TransactionType type) async {
    final all = await getTransactions();
    return all.where((t) => t.type == type).toList();
  }

  // Get transactions by category
  Future<List<TransactionModel>> getTransactionsByCategory(String category) async {
    final all = await getTransactions();
    return all.where((t) => t.category == category).toList();
  }

  // Get today's transactions
  Future<List<TransactionModel>> getTodayTransactions() async {
    final all = await getTransactions();
    final today = DateTime.now();
    return all.where((t) =>
    t.date.year == today.year &&
        t.date.month == today.month &&
        t.date.day == today.day
    ).toList();
  }

  // Get pending credit sales
  Future<List<TransactionModel>> getPendingCredits() async {
    final all = await getTransactions();
    return all.where((t) =>
    t.type == TransactionType.creditSale && !t.isPaid
    ).toList();
  }

  // Get credits by customer
  Future<List<TransactionModel>> getCreditsByCustomer(String customerName) async {
    final all = await getTransactions();
    return all.where((t) =>
    (t.type == TransactionType.creditSale || t.type == TransactionType.creditPayment) &&
        t.customerName == customerName
    ).toList();
  }

  // Update transaction (mark credit as paid)
  Future<void> updateTransaction(TransactionModel updatedTransaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await getTransactions();

    final index = transactions.indexWhere((t) => t.id == updatedTransaction.id);
    if (index != -1) {
      transactions[index] = updatedTransaction;
      await _saveTransactions(transactions);
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await getTransactions();

    transactions.removeWhere((t) => t.id == id);
    await _saveTransactions(transactions);
  }

  // Calculate balance
  Future<double> calculateBalance(DateTime? asOnDate) async {
    final all = await getTransactions();
    final transactions = asOnDate != null
        ? all.where((t) => !t.date.isAfter(asOnDate)).toList()
        : all;

    double balance = 0;

    for (var t in transactions) {
      switch (t.type) {
        case TransactionType.income:
          balance += t.amount;
          break;
        case TransactionType.expense:
          balance -= t.amount;
          break;
        case TransactionType.creditPayment:
          balance += t.amount;
          break;
        case TransactionType.creditSale:
        // Don't affect cash balance until paid
          break;
      }
    }

    return balance;
  }

  // Get summary by date
  Future<Map<String, double>> getSummaryByDate(DateTime date) async {
    final transactions = await getTransactionsByDateRange(
      startDate: date,
      endDate: date,
    );

    double income = 0;
    double expense = 0;
    double credit = 0;

    for (var t in transactions) {
      switch (t.type) {
        case TransactionType.income:
          income += t.amount;
          break;
        case TransactionType.expense:
          expense += t.amount;
          break;
        case TransactionType.creditSale:
          if (!t.isPaid) credit += t.amount;
          break;
        case TransactionType.creditPayment:
          income += t.amount; // Count as income when paid
          break;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'credit': credit,
      'net': income - expense,
    };
  }

  // Get monthly summary
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    return getSummaryByDateRange(startDate: startDate, endDate: endDate);
  }

  // Get summary by date range
  Future<Map<String, double>> getSummaryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = await getTransactionsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    double income = 0;
    double expense = 0;
    double credit = 0;

    for (var t in transactions) {
      switch (t.type) {
        case TransactionType.income:
          income += t.amount;
          break;
        case TransactionType.expense:
          expense += t.amount;
          break;
        case TransactionType.creditSale:
          if (!t.isPaid) credit += t.amount;
          break;
        case TransactionType.creditPayment:
          income += t.amount;
          break;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'credit': credit,
      'net': income - expense,
    };
  }

  // Save transactions to SharedPreferences
  Future<void> _saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = transactions.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(AppConstants.transactionsKey, transactionsJson);
  }
}