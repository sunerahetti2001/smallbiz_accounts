class AppConstants {
  static const String appName = 'SmallBiz Accounts';
  static const String appVersion = '1.0.0';

  static const List<String> currencies = [
    'LKR - Sri Lankan Rupee',
    'USD - US Dollar',
    'INR - Indian Rupee',
  ];

  static const List<String> accountTypes = [
    'Cash in Hand',
    'Bank Account',
    'Mobile Money',
  ];

  static const List<Map<String, String>> defaultExpenseCategories = [
    {'name': 'Fuel / Petrol', 'icon': '⛽'},
    {'name': 'Rent', 'icon': '🏠'},
    {'name': 'Utilities', 'icon': '💡'},
    {'name': 'Salaries', 'icon': '👥'},
    {'name': 'Supplies', 'icon': '📦'},
    {'name': 'Maintenance', 'icon': '🔧'},
    {'name': 'Transport', 'icon': '🚗'},
    {'name': 'Phone / Internet', 'icon': '📱'},
    {'name': 'Other', 'icon': '📝'},
  ];

  static const List<Map<String, String>> defaultIncomeCategories = [
    {'name': 'Sales', 'icon': '💰'},
    {'name': 'Services', 'icon': '🛠️'},
    {'name': 'Investment', 'icon': '📈'},
    {'name': 'Owner', 'icon': '👤'},
    {'name': 'Other', 'icon': '📝'},
  ];

  static const String userKey = 'user_data';
  static const String transactionsKey = 'transactions';
  static const String categoriesKey = 'categories';
  static const String isOnboardedKey = 'is_onboarded';
}