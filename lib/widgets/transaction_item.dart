import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/colors.dart';
import '../utils/currency_formatter.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String prefix;
    String statusText = '';

    switch (transaction.type) {
      case TransactionType.income:
        color = AppColors.income;
        icon = Icons.arrow_downward;
        prefix = '+';
        break;
      case TransactionType.expense:
        color = AppColors.expense;
        icon = Icons.arrow_upward;
        prefix = '-';
        break;
      case TransactionType.creditSale:
        color = AppColors.credit;
        icon = Icons.receipt;
        prefix = '';
        if (!transaction.isPaid && transaction.dueDate != null) {
          if (transaction.dueDate!.isBefore(DateTime.now())) {
            statusText = ' • Overdue';
          } else {
            statusText = ' • Due ${transaction.dueDate!.day}/${transaction.dueDate!.month}';
          }
        }
        break;
      case TransactionType.creditPayment:
        color = AppColors.income;
        icon = Icons.payment;
        prefix = '+';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getIconForTransaction(transaction),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          transaction.customerName != null
                              ? '${transaction.customerName} • ${transaction.category}'
                              : transaction.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (statusText.isNotEmpty)
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusText.contains('Overdue')
                                ? AppColors.error
                                : AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transaction.type == TransactionType.creditSale
                    ? CurrencyFormatter.formatLKR(transaction.amount)
                    : CurrencyFormatter.formatWithSign(
                  transaction.amount,
                  isIncome: transaction.type == TransactionType.income ||
                      transaction.type == TransactionType.creditPayment,
                ),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIconForTransaction(TransactionModel transaction) {
    if (transaction.type == TransactionType.income) return '💰';
    if (transaction.type == TransactionType.expense) return '⛽';
    if (transaction.type == TransactionType.creditSale) return '📝';
    if (transaction.type == TransactionType.creditPayment) return '💳';
    return '📦';
  }
}