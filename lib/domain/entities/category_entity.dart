/// Entidad de dominio para las categorías de finanzas.
class CategoryEntity {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final bool isExpense;
  final String? accountType;
  final bool isDefault;

  const CategoryEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    this.isExpense = true,
    this.accountType,
    this.isDefault = false,
  });
}
