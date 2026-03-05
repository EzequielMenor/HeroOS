/// Entidad de dominio para Cuentas financieras.
class AccountEntity {
  final String id;
  final String userId;
  final String name;
  final String type; // 'Bank', 'Cash'
  final String currency;
  final double balance;

  const AccountEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.type = 'Cash',
    this.currency = 'EUR',
    this.balance = 0,
  });

  AccountEntity copyWith({
    String? name,
    String? type,
    String? currency,
    double? balance,
  }) {
    return AccountEntity(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
    );
  }
}
