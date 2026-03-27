import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/colors.dart';
import '../../utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../widgets/gradient_background.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _comparisonData = {};

  double _thisMonthIncome = 0;
  double _thisMonthExpense = 0;
  double _thisMonthCredit = 0;
  double _lastMonthIncome = 0;
  double _lastMonthExpense = 0;
  double _lastMonthCredit = 0;

  DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadComparisonData();
  }

  Future<void> _loadComparisonData() async {
    setState(() {
      _isLoading = true;
    });

    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    await transactionProvider.loadTransactions();
    final allTransactions = transactionProvider.transactions;

    DateTime thisMonthStart = DateTime(_today.year, _today.month, 1);
    DateTime lastMonthStart = DateTime(_today.year, _today.month - 1, 1);
    DateTime lastMonthEnd = DateTime(_today.year, _today.month, 0);

    for (var t in allTransactions) {
      if (t.date.isAfter(thisMonthStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(DateTime(_today.year, _today.month + 1, 1))) {
        _addToTotals(t, isThisMonth: true);
      }
      if (t.date.isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(lastMonthEnd.add(const Duration(days: 1)))) {
        _addToTotals(t, isThisMonth: false);
      }
    }

    double incomeChange = _lastMonthIncome > 0
        ? ((_thisMonthIncome - _lastMonthIncome) / _lastMonthIncome * 100)
        : (_thisMonthIncome > 0 ? 100 : 0);

    double expenseChange = _lastMonthExpense > 0
        ? ((_thisMonthExpense - _lastMonthExpense) / _lastMonthExpense * 100)
        : (_thisMonthExpense > 0 ? 100 : 0);

    double profitThisMonth = _thisMonthIncome - _thisMonthExpense;
    double profitLastMonth = _lastMonthIncome - _lastMonthExpense;
    double profitChange = profitLastMonth != 0
        ? ((profitThisMonth - profitLastMonth) / profitLastMonth.abs() * 100)
        : (profitThisMonth > 0 ? 100 : 0);

    setState(() {
      _comparisonData = {
        'thisMonth': {
          'income': _thisMonthIncome,
          'expense': _thisMonthExpense,
          'credit': _thisMonthCredit,
          'profit': profitThisMonth,
        },
        'lastMonth': {
          'income': _lastMonthIncome,
          'expense': _lastMonthExpense,
          'credit': _lastMonthCredit,
          'profit': profitLastMonth,
        },
        'changes': {
          'income': incomeChange,
          'expense': expenseChange,
          'profit': profitChange,
        },
        'period': {
          'thisMonthLabel': _getMonthYear(_today.month, _today.year),
          'lastMonthLabel': _getMonthYear(lastMonthStart.month, lastMonthStart.year),
        },
      };
      _isLoading = false;
    });
  }

  void _addToTotals(TransactionModel t, {required bool isThisMonth}) {
    if (isThisMonth) {
      switch (t.type) {
        case TransactionType.income:
          _thisMonthIncome += t.amount;
          break;
        case TransactionType.expense:
          _thisMonthExpense += t.amount;
          break;
        case TransactionType.creditSale:
          if (!t.isPaid) _thisMonthCredit += t.amount;
          break;
        case TransactionType.creditPayment:
          _thisMonthIncome += t.amount;
          break;
      }
    } else {
      switch (t.type) {
        case TransactionType.income:
          _lastMonthIncome += t.amount;
          break;
        case TransactionType.expense:
          _lastMonthExpense += t.amount;
          break;
        case TransactionType.creditSale:
          if (!t.isPaid) _lastMonthCredit += t.amount;
          break;
        case TransactionType.creditPayment:
          _lastMonthIncome += t.amount;
          break;
      }
    }
  }

  String _getMonthYear(int month, int year) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month - 1]} $year';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadComparisonData,
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
                        'Compare',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Month-to-month financial comparison',
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
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _comparisonData['period']['thisMonthLabel'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Current Month',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _comparisonData['period']['lastMonthLabel'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Previous Month',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildComparisonCard(
                    title: 'Income',
                    icon: Icons.trending_down,
                    color: AppColors.income,
                    thisValue: _comparisonData['thisMonth']['income'],
                    lastValue: _comparisonData['lastMonth']['income'],
                    change: _comparisonData['changes']['income'],
                  ),
                  const SizedBox(height: 16),
                  _buildComparisonCard(
                    title: 'Expense',
                    icon: Icons.trending_up,
                    color: AppColors.expense,
                    thisValue: _comparisonData['thisMonth']['expense'],
                    lastValue: _comparisonData['lastMonth']['expense'],
                    change: _comparisonData['changes']['expense'],
                  ),
                  const SizedBox(height: 16),
                  _buildComparisonCard(
                    title: 'Net Profit',
                    icon: Icons.trending_up,
                    color: AppColors.secondary,
                    thisValue: _comparisonData['thisMonth']['profit'],
                    lastValue: _comparisonData['lastMonth']['profit'],
                    change: _comparisonData['changes']['profit'],
                    isProfit: true,
                  ),
                  const SizedBox(height: 24),
                  if (_comparisonData['thisMonth']['credit'] > 0 || _comparisonData['lastMonth']['credit'] > 0)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Credit Sales Outstanding',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        _comparisonData['period']['thisMonthLabel'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.formatLKR(
                                            _comparisonData['thisMonth']['credit']
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.credit,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        _comparisonData['period']['lastMonthLabel'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.formatLKR(
                                            _comparisonData['lastMonth']['credit']
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.credit,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required IconData icon,
    required Color color,
    required double thisValue,
    required double lastValue,
    required double change,
    bool isProfit = false,
  }) {
    final bool isPositiveChange = change > 0;
    final bool isIncomeOrProfit = title == 'Income' || title == 'Net Profit';
    final bool isGoodChange = (isIncomeOrProfit && isPositiveChange) ||
        (!isIncomeOrProfit && !isPositiveChange);

    return Card(
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isGoodChange
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositiveChange ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: isGoodChange ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${change.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isGoodChange ? AppColors.success : AppColors.error,
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
                        'This Month',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatLKR(thisValue),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isProfit && thisValue < 0 ? AppColors.error : color,
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
                        'Last Month',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatLKR(lastValue),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isProfit && lastValue < 0 ? AppColors.error : color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (lastValue > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (thisValue / lastValue).clamp(0.0, 2.0),
                  backgroundColor: Colors.grey[200],
                  color: isGoodChange ? AppColors.success : AppColors.error,
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}