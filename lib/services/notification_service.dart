import '../models/transaction_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<Map<String, dynamic>> _notifications = [];

  List<Map<String, dynamic>> get notifications => _notifications;

  int get pendingCount =>
      _notifications.where((n) => !(n['isDismissed'] as bool)).length;

  /// Check all credit sales and add overdue/due-soon notifications
  void checkCreditReminders(List<TransactionModel> transactions) {
    _notifications.clear();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    for (var t in transactions) {
      if (t.type == TransactionType.creditSale && !t.isPaid && t.dueDate != null) {
        final dueDate = t.dueDate!;
        final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
        final isOverdue = dueDateDay.isBefore(DateTime(now.year, now.month, now.day));
        final isDueTomorrow = dueDateDay == tomorrow;

        if (isOverdue || isDueTomorrow) {
          _notifications.add({
            'id': t.id.hashCode,
            'customerName': t.customerName ?? 'Unknown',
            'amount': t.amount,
            'dueDate': dueDate,
            'isOverdue': isOverdue,
            'isDismissed': false,
            'transactionId': t.id,
          });
        }
      }
    }

    // Sort: overdue first, then due tomorrow
    _notifications.sort((a, b) {
      if ((a['isOverdue'] as bool) && !(b['isOverdue'] as bool)) return -1;
      if (!(a['isOverdue'] as bool) && (b['isOverdue'] as bool)) return 1;
      return 0;
    });
  }

  void dismissNotification(int id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['isDismissed'] = true;
    }
  }

  void clearAll() {
    _notifications.clear();
  }
}