import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../utils/colors.dart';
import '../../utils/currency_formatter.dart';
import 'income_screen.dart';
import 'expense_screen.dart';
import 'credit_sale_screen.dart';
import 'credit_payment_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType? initialType;

  const AddTransactionScreen({
    super.key,
    this.initialType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  TransactionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    // If type is already selected, navigate directly to specific screen
    if (_selectedType != null) {
      Widget screen;
      switch (_selectedType!) {
        case TransactionType.income:
          screen = const IncomeScreen();
          break;
        case TransactionType.expense:
          screen = const ExpenseScreen();
          break;
        case TransactionType.creditSale:
          screen = const CreditSaleScreen();
          break;
        case TransactionType.creditPayment:
          screen = const CreditPaymentScreen();
          break;
      }

      return screen;
    }

    // Otherwise show type selection
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Transaction Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the type of transaction you want to record',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Quick Stats Card
              Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Balance',
                                CurrencyFormatter.formatCompact(provider.currentBalance),
                                AppColors.primary,
                              ),
                              _buildStatItem(
                                'Credit',
                                CurrencyFormatter.formatCompact(provider.creditOutstanding),
                                AppColors.credit,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Type Selection Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildTypeCard(
                      'Income',
                      Icons.arrow_downward,
                      AppColors.income,
                      'Money coming in',
                          () => _navigateToScreen(const IncomeScreen()),
                    ),
                    _buildTypeCard(
                      'Expense',
                      Icons.arrow_upward,
                      AppColors.expense,
                      'Money going out',
                          () => _navigateToScreen(const ExpenseScreen()),
                    ),
                    _buildTypeCard(
                      'Credit Sale',
                      Icons.receipt,
                      AppColors.credit,
                      'Customer buys on credit',
                          () => _navigateToScreen(const CreditSaleScreen()),
                    ),
                    _buildTypeCard(
                      'Credit Payment',
                      Icons.payment,
                      AppColors.income,
                      'Customer pays back',
                          () => _navigateToScreen(const CreditPaymentScreen()),
                    ),
                  ],
                ),
              ),

              // Recent Templates (Optional)
              const SizedBox(height: 8),
              Text(
                'Recent Templates',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: Consumer<TransactionProvider>(
                  builder: (context, provider, child) {
                    final recent = provider.getRecentTransactions(limit: 5);

                    if (recent.isEmpty) {
                      return Center(
                        child: Text(
                          'No recent transactions',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recent.length,
                      itemBuilder: (context, index) {
                        final transaction = recent[index];
                        return _buildTemplateChip(transaction);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(
      String title,
      IconData icon,
      Color color,
      String subtitle,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateChip(TransactionModel transaction) {
    Color color;
    IconData icon;

    switch (transaction.type) {
      case TransactionType.income:
        color = AppColors.income;
        icon = Icons.arrow_downward;
        break;
      case TransactionType.expense:
        color = AppColors.expense;
        icon = Icons.arrow_upward;
        break;
      case TransactionType.creditSale:
        color = AppColors.credit;
        icon = Icons.receipt;
        break;
      case TransactionType.creditPayment:
        color = AppColors.income;
        icon = Icons.payment;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        onPressed: () {
          // Navigate to appropriate screen with pre-filled data
          // This would require passing data to the screens
        },
        avatar: Icon(icon, color: color, size: 16),
        label: Text(
          transaction.category.length > 15
              ? '${transaction.category.substring(0, 12)}...'
              : transaction.category,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      // Refresh data when returning
      if (mounted) {
        Provider.of<TransactionProvider>(context, listen: false).loadTransactions();
      }
    });
  }
}