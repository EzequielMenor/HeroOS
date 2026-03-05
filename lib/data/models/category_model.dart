import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.icon,
    super.isExpense,
    super.accountType,
    super.isDefault,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      icon: json['icon'] ?? '🏷️',
      isExpense: json['is_expense'] ?? true,
      accountType: json['account_type'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'is_expense': isExpense,
      'account_type': accountType,
      'is_default': isDefault,
    };
  }

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      icon: entity.icon,
      isExpense: entity.isExpense,
      accountType: entity.accountType,
      isDefault: entity.isDefault,
    );
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      userId: userId,
      name: name,
      icon: icon,
      isExpense: isExpense,
      accountType: accountType,
      isDefault: isDefault,
    );
  }
}
