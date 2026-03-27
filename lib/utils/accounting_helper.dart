class AccountingHelper {
  static Map<String, dynamic> processIncomeTransaction({
    required double amount,
    required String category,
    required String paymentMethod,
  }) {
    return {
      'debit': {'account': paymentMethod, 'amount': amount},
      'credit': {'account': category, 'amount': amount},
      'equation': 'Assets increase, Equity increase',
    };
  }

  static Map<String, dynamic> processExpenseTransaction({
    required double amount,
    required String category,
    required String paymentMethod,
  }) {
    return {
      'debit': {'account': category, 'amount': amount},
      'credit': {'account': paymentMethod, 'amount': amount},
      'equation': 'Assets decrease, Equity decrease',
    };
  }

  static Map<String, dynamic> processCreditSale({
    required double amount,
    required String customerName,
    required List<Map<String, dynamic>> items,
  }) {
    return {
      'debit': {'account': 'Accounts Receivable - $customerName', 'amount': amount},
      'credit': {'account': 'Sales Revenue', 'amount': amount},
      'inventory': items.map((item) => {
        'item': item['name'],
        'quantity': item['quantity'],
        'cost': item['cost'],
      }).toList(),
      'equation': 'Assets (Receivable) increase, Equity increase, Inventory decrease',
    };
  }

  static double calculateBalance({
    required double openingBalance,
    required List<Map<String, dynamic>> transactions,
  }) {
    double balance = openingBalance;
    for (var transaction in transactions) {
      if (transaction['type'] == 'income') {
        balance += transaction['amount'];
      } else if (transaction['type'] == 'expense') {
        balance -= transaction['amount'];
      }
    }
    return balance;
  }

  static double calculateProfit({
    required List<Map<String, dynamic>> income,
    required List<Map<String, dynamic>> expenses,
  }) {
    double totalIncome = income.fold(0, (sum, item) => sum + item['amount']);
    double totalExpenses = expenses.fold(0, (sum, item) => sum + item['amount']);
    return totalIncome - totalExpenses;
  }
}