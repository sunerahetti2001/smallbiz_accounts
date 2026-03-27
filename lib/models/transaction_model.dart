enum TransactionType { income, expense, creditSale, creditPayment }

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String? paymentMethod;
  final String? customerName;
  final String? customerMobile;
  final List<Map<String, dynamic>>? items;
  final bool isPaid;
  final DateTime? dueDate;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.paymentMethod,
    this.customerName,
    this.customerMobile,
    this.items,
    this.isPaid = false,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'amount': amount,
    'category': category,
    'description': description,
    'date': date.toIso8601String(),
    'paymentMethod': paymentMethod,
    'customerName': customerName,
    'customerMobile': customerMobile,
    'items': items,
    'isPaid': isPaid,
    'dueDate': dueDate?.toIso8601String(),
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String typeStr = json['type'].toString().split('.').last;
    return TransactionModel(
      id: json['id'],
      type: TransactionType.values.firstWhere(
            (e) => e.toString() == 'TransactionType.$typeStr' || e.toString() == typeStr,
        orElse: () => TransactionType.expense,
      ),
      amount: json['amount'].toDouble(),
      category: json['category'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      paymentMethod: json['paymentMethod'],
      customerName: json['customerName'],
      customerMobile: json['customerMobile'],
      items: json['items'] != null ? List<Map<String, dynamic>>.from(json['items']) : null,
      isPaid: json['isPaid'] ?? false,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    );
  }

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? paymentMethod,
    String? customerName,
    String? customerMobile,
    List<Map<String, dynamic>>? items,
    bool? isPaid,
    DateTime? dueDate,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      items: items ?? this.items,
      isPaid: isPaid ?? this.isPaid,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}