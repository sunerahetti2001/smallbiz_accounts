import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/colors.dart';
import '../../utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../services/pdf_export_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/transaction_item.dart';

class MonthlyStatementsScreen extends StatefulWidget {
  const MonthlyStatementsScreen({super.key});

  @override
  State<MonthlyStatementsScreen> createState() => _MonthlyStatementsScreenState();
}

class _MonthlyStatementsScreenState extends State<MonthlyStatementsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _monthlyStatements = [];

  @override
  void initState() {
    super.initState();
    _loadStatements();
  }

  Future<void> _loadStatements() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

    if (userProvider.user != null) {
      await transactionProvider.loadTransactions(userProvider.user!.id);
    }
    final allTransactions = transactionProvider.transactions;

    Map<String, Map<String, dynamic>> monthlyData = {};

    for (var t in allTransactions) {
      String key = '${t.date.year}-${t.date.month}';

      if (!monthlyData.containsKey(key)) {
        monthlyData[key] = {
          'year': t.date.year,
          'month': t.date.month,
          'monthName': _getMonthName(t.date.month),
          'income': 0.0,
          'expense': 0.0,
          'credit': 0.0,
          'transactions': <TransactionModel>[],
        };
      }

      var data = monthlyData[key]!;

      switch (t.type) {
        case TransactionType.income:
          data['income'] = (data['income'] as double) + t.amount;
          break;
        case TransactionType.expense:
          data['expense'] = (data['expense'] as double) + t.amount;
          break;
        case TransactionType.creditSale:
          if (!t.isPaid) {
            data['credit'] = (data['credit'] as double) + t.amount;
          }
          break;
        case TransactionType.creditPayment:
          data['income'] = (data['income'] as double) + t.amount;
          break;
      }

      (data['transactions'] as List<TransactionModel>).add(t);
    }

    List<Map<String, dynamic>> statements = monthlyData.values.toList();
    statements.sort((a, b) {
      if (a['year'] != b['year']) {
        return (b['year'] as int).compareTo(a['year'] as int);
      }
      return (b['month'] as int).compareTo(a['month'] as int);
    });

    setState(() {
      _monthlyStatements = statements;
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

  Future<void> _generateAndShowSummaryPdf(Map<String, dynamic> statement) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user!;
    final localizations = AppLocalizations.of(context);

    final transactions = statement['transactions'] as List<TransactionModel>;

    Map<String, double> incomeBreakdown = {};
    Map<String, double> expenseBreakdown = {};

    for (var t in transactions) {
      if (t.type == TransactionType.income || t.type == TransactionType.creditPayment) {
        incomeBreakdown[t.category] = (incomeBreakdown[t.category] ?? 0) + t.amount;
      } else if (t.type == TransactionType.expense) {
        expenseBreakdown[t.category] = (expenseBreakdown[t.category] ?? 0) + t.amount;
      }
    }

    final pendingCredits = transactions.where((t) =>
    t.type == TransactionType.creditSale && !t.isPaid
    ).toList();

    final year = statement['year'] as int;
    final month = statement['month'] as int;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(localizations.pleaseWait, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final pdfFile = await PdfExportService.generateSummaryPdf(
        businessName: user.businessName,
        ownerName: user.name,
        monthYear: '${statement['monthName']} ${statement['year']}',
        startDate: startDate,
        endDate: endDate,
        openingBalance: 0,
        totalIncome: statement['income'],
        totalExpense: statement['expense'],
        closingBalance: (statement['income'] as double) - (statement['expense'] as double),
        creditOutstanding: statement['credit'],
        incomeBreakdown: incomeBreakdown,
        expenseBreakdown: expenseBreakdown,
        pendingCredits: pendingCredits,
        transactionCount: transactions.length,
      );

      if (context.mounted) {
        Navigator.pop(context);
        await PdfExportService.showPdfPreview(
          context: context,
          pdfFile: pdfFile,
          title: '${localizations.monthlyStatement} - ${statement['monthName']} ${statement['year']}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _generateAndShowDetailedPdf(Map<String, dynamic> statement) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user!;
    final localizations = AppLocalizations.of(context);

    final transactions = statement['transactions'] as List<TransactionModel>;
    final year = statement['year'] as int;
    final month = statement['month'] as int;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(localizations.pleaseWait, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final pdfFile = await PdfExportService.generateDetailedPdf(
        businessName: user.businessName,
        ownerName: user.name,
        monthYear: '${statement['monthName']} ${statement['year']}',
        startDate: startDate,
        endDate: endDate,
        transactions: transactions,
      );

      if (context.mounted) {
        Navigator.pop(context);
        await PdfExportService.showPdfPreview(
          context: context,
          pdfFile: pdfFile,
          title: '${localizations.details} - ${statement['monthName']} ${statement['year']}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

    if (_monthlyStatements.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                localizations.noStatements,
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStatements,
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
                        localizations.statements,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate and download financial statements',
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
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A4D8C), Color(0xFF1E3A8A)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.file_copy, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizations.generateStatement,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Create a new financial statement',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showGenerateDialog(localizations),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              localizations.generateNewStatement,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localizations.previousStatements,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._monthlyStatements.map((statement) => _buildStatementCard(statement, localizations)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementCard(Map<String, dynamic> statement, AppLocalizations localizations) {
    double profit = (statement['income'] as double) - (statement['expense'] as double);
    bool isProfit = profit >= 0;
    String monthYear = '${statement['monthName']} ${statement['year']}';
    int transactionCount = (statement['transactions'] as List).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      statement['month'].toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthYear,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$transactionCount ${localizations.transactions}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isProfit
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isProfit ? localizations.profit : localizations.loss,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isProfit ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMiniStat(localizations.income, statement['income'], AppColors.income),
                const SizedBox(width: 16),
                _buildMiniStat(localizations.expense, statement['expense'], AppColors.expense),
                const SizedBox(width: 16),
                _buildMiniStat(localizations.profit, profit, isProfit ? AppColors.success : AppColors.error),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ((statement['income'] as double) /
                    ((statement['income'] as double) + (statement['expense'] as double)))
                    .clamp(0.0, 1.0),
                backgroundColor: AppColors.expense.withValues(alpha: 0.3),
                color: AppColors.income,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _generateAndShowSummaryPdf(statement),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: Text(localizations.summary),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _generateAndShowDetailedPdf(statement),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: Text(localizations.details),
                    style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatCompact(value),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _showGenerateDialog(AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.generateStatement),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.selectPeriod),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDownloadSuccess(localizations.monthlyStatement, localizations);
                    },
                    child: Text(localizations.thisMonth),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDownloadSuccess(localizations.quarterlyStatement, localizations);
                    },
                    child: Text('Quarter'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDownloadSuccess(localizations.yearlyStatement, localizations);
              },
              child: Text('Yearly'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadSuccess(String format, AppLocalizations localizations) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.statementGenerated),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}