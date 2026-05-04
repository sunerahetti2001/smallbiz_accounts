import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/colors.dart';
import 'income_screen.dart';
import 'expense_screen.dart';
import 'credit_sale_screen.dart';
import 'credit_payment_screen.dart';

class TransactionTypeScreen extends StatelessWidget {
  const TransactionTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.addTransaction),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.selectTransactionType,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildTypeCard(
              context,
              icon: Icons.arrow_downward,
              title: localizations.income.toUpperCase(),
              subtitle: localizations.incomeDescription,
              color: AppColors.income,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncomeScreen(),
                  ),
                );
              },
            ),
            _buildTypeCard(
              context,
              icon: Icons.arrow_upward,
              title: localizations.expense.toUpperCase(),
              subtitle: localizations.expenseDescription,
              color: AppColors.expense,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExpenseScreen(),
                  ),
                );
              },
            ),
            _buildTypeCard(
              context,
              icon: Icons.receipt,
              title: localizations.creditSale.toUpperCase(),
              subtitle: localizations.creditSaleDescription,
              color: AppColors.credit,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreditSaleScreen(),
                  ),
                );
              },
            ),
            _buildTypeCard(
              context,
              icon: Icons.payment,
              title: localizations.creditPayment.toUpperCase(),
              subtitle: localizations.creditPaymentDescription,
              color: AppColors.income,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreditPaymentScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          radius: 24,
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ),
    );
  }
}