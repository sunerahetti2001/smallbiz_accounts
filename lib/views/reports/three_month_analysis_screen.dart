import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';
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

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

    if (userProvider.user != null) {
      await transactionProvider.loadTransactions(userProvider.user!.id);
    }
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
    final localizations = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(localizations.loading),
            ],
          ),
        ),
      );
    }

    if (_monthlyData.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insights, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                localizations.noDataAnalysis,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.addFirstTransaction,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                      Text(
                        localizations.threeMonthAnalysis,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.last3Months,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
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
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: localizations.totalIncome,
                          value: totalIncome,
                          icon: Icons.trending_up,
                          color: AppColors.income,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: localizations.totalExpense,
                          value: totalExpense,
                          icon: Icons.trending_down,
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
                          title: localizations.netProfit,
                          value: totalProfit,
                          icon: Icons.trending_up,
                          color: totalProfit >= 0 ? AppColors.success : AppColors.error,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: localizations.creditGiven,
                          value: totalCredit,
                          icon: Icons.receipt,
                          color: AppColors.credit,
                          isCompact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localizations.monthlyBreakdown,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._monthlyData.map((month) => _buildMonthlyCard(month, localizations)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCard(Map<String, dynamic> month, AppLocalizations localizations) {
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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
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
                        '${margin.toStringAsFixed(1)}% ${localizations.margin}',
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
                        localizations.income,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                        localizations.expense,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                        localizations.profit,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                  const Icon(Icons.receipt, size: 16, color: AppColors.credit),
                  const SizedBox(width: 8),
                  Text(
                    '${localizations.creditOutstanding}: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    CurrencyFormatter.formatLKR(credit),
                    style: const TextStyle(
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
                backgroundColor: AppColors.expense.withValues(alpha: 0.3),
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