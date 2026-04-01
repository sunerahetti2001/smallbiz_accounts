import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/colors.dart';
import '../../utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/stat_card.dart';

class ThreeMonthAnalysisScreen extends StatefulWidget {
  const ThreeMonthAnalysisScreen({super.key});

  @override
  State<ThreeMonthAnalysisScreen> createState() => _ThreeMonthAnalysisScreenState();
}

class _ThreeMonthAnalysisScreenState extends State<ThreeMonthAnalysisScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _monthlyData = [];

  @override
  void initState() {
    super.initState();
    _loadAnalysisData();
  }

  Future<void> _loadAnalysisData() async {
    setState(() {
      _isLoading = true;
    });

    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    await transactionProvider.loadTransactions();
    final allTransactions = transactionProvider.transactions;

    DateTime today = DateTime.now();
    List<DateTime> months = [];

    for (int i = 1; i <= 3; i++) {
      int month = today.month - i;
      int year = today.year;

      if (month <= 0) {
        month += 12;
        year -= 1;
      }

      months.add(DateTime(year, month, 1));
    }

    months = months.reversed.toList();
    List<Map<String, dynamic>> monthlyDataList = [];

    for (var monthStart in months) {
      int month = monthStart.month;
      int year = monthStart.year;
      DateTime monthEnd = DateTime(year, month + 1, 0);

      double income = 0.0;
      double expense = 0.0;
      double credit = 0.0;

      for (var t in allTransactions) {
        if (t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            t.date.isBefore(monthEnd.add(const Duration(days: 1)))) {

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
      }

      double margin = 0.0;
      if (income > 0) {
        margin = (income - expense) / income * 100;
      }

      monthlyDataList.add({
        'month': month,
        'year': year,
        'monthName': _getMonthName(month),
        'income': income,
        'expense': expense,
        'credit': credit,
        'profit': income - expense,
        'margin': margin,
      });
    }

    setState(() {
      _monthlyData = monthlyDataList;
      _isLoading = false;
    });
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_monthlyData.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insights,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No data for analysis',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add some transactions first',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    double totalIncome = 0.0;
    double totalExpense = 0.0;
    double totalProfit = 0.0;
    double totalCredit = 0.0;

    for (var month in _monthlyData) {
      totalIncome += month['income'] as double;
      totalExpense += month['expense'] as double;
      totalProfit += month['profit'] as double;
      totalCredit += month['credit'] as double;
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAnalysisData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GradientBackground(
                hasBottomRadius: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3-Month Analysis',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last 3 months performance review',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Income',
                          value: totalIncome,
                          icon: Icons.trending_down,
                          color: AppColors.income,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Total Expense',
                          value: totalExpense,
                          icon: Icons.trending_up,
                          color: AppColors.expense,
                          isCompact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Net Profit',
                          value: totalProfit,
                          icon: Icons.trending_up,
                          color: totalProfit >= 0 ? AppColors.success : AppColors.error,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Credit Given',
                          value: totalCredit,
                          icon: Icons.receipt,
                          color: AppColors.credit,
                          isCompact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Monthly Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._monthlyData.map((month) => _buildMonthlyCard(month)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCard(Map<String, dynamic> month) {
    double profit = month['profit'] as double;
    bool isProfit = profit >= 0;
    double margin = month['margin'] as double;
    double income = month['income'] as double;
    double expense = month['expense'] as double;
    double credit = month['credit'] as double;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${month['monthName']} ${month['year']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isProfit
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isProfit ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: isProfit ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${margin.toStringAsFixed(1)}% margin',
                        style: TextStyle(
                          fontSize: 11,
                          color: isProfit ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Income',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatCompact(income),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatCompact(expense),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profit',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatCompact(profit),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isProfit ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (credit > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.receipt, size: 16, color: AppColors.credit),
                  const SizedBox(width: 8),
                  Text(
                    'Credit Outstanding: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatLKR(credit),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.credit,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (income / (income + expense)).clamp(0.0, 1.0),
                backgroundColor: AppColors.expense.withOpacity(0.3),
                color: AppColors.income,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}