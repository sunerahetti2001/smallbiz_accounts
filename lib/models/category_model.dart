enum CategoryType { expense, income }

class CategoryModel {
  final String id;
  final String name;
  final CategoryType type;
  final String icon;
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString(),
    'icon': icon,
    'isDefault': isDefault,
  };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String typeStr = json['type'].toString().split('.').last;
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      type: CategoryType.values.firstWhere(
            (e) => e.toString() == 'CategoryType.$typeStr' || e.toString() == typeStr,
        orElse: () => CategoryType.expense,
      ),
      icon: json['icon'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  CategoryModel copyWith({
    String? name,
    String? icon,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      type: type,
      icon: icon ?? this.icon,
      isDefault: isDefault,
    );
  }
}