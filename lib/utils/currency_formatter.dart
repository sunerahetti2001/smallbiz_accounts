import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatLKR(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'si_LK',
      symbol: 'Rs ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return 'Rs ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'Rs ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs ${amount.toStringAsFixed(0)}';
  }

  static String formatWithSign(double amount, {bool isIncome = true}) {
    final sign = isIncome ? '+' : '-';
    return '$sign ${formatLKR(amount.abs())}';
  }
}