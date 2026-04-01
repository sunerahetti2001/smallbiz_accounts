class UserModel {
  final String id;
  final String name;
  final String? email;
  final String businessName;
  final String currency;
  final double openingBalance;
  final String accountType;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.businessName,
    required this.currency,
    required this.openingBalance,
    required this.accountType,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'businessName': businessName,
    'currency': currency,
    'openingBalance': openingBalance,
    'accountType': accountType,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    businessName: json['businessName'],
    currency: json['currency'],
    openingBalance: json['openingBalance'].toDouble(),
    accountType: json['accountType'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  UserModel copyWith({
    String? name,
    String? email,
    String? businessName,
    double? openingBalance,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      currency: currency,
      openingBalance: openingBalance ?? this.openingBalance,
      accountType: accountType,
      createdAt: createdAt,
    );
  }
}