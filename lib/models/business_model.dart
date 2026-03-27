class BusinessModel {
  final String id;
  final String name;
  final String type;
  final String registrationNumber;
  final String address;
  final String phone;
  final String email;
  final String taxNumber;
  final DateTime createdAt;

  BusinessModel({
    required this.id,
    required this.name,
    required this.type,
    required this.registrationNumber,
    required this.address,
    required this.phone,
    required this.email,
    required this.taxNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'registrationNumber': registrationNumber,
    'address': address,
    'phone': phone,
    'email': email,
    'taxNumber': taxNumber,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    registrationNumber: json['registrationNumber'],
    address: json['address'],
    phone: json['phone'],
    email: json['email'],
    taxNumber: json['taxNumber'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  BusinessModel copyWith({
    String? name,
    String? type,
    String? registrationNumber,
    String? address,
    String? phone,
    String? email,
    String? taxNumber,
  }) {
    return BusinessModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      taxNumber: taxNumber ?? this.taxNumber,
      createdAt: createdAt,
    );
  }
}