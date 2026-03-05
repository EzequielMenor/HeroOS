import '../../domain/entities/account_entity.dart';

/// Modelo de datos para serializar/deserializar cuentas desde Supabase.
class AccountModel {
  final String id;
  final String userId;
  final String name;
  final String type;
  final String currency;
  final double balance;

  const AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    type: (json['type'] as String?) ?? 'Cash',
    currency: (json['currency'] as String?) ?? 'EUR',
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'type': type,
    'currency': currency,
    'balance': balance,
  };

  AccountEntity toEntity() => AccountEntity(
    id: id,
    userId: userId,
    name: name,
    type: type,
    currency: currency,
    balance: balance,
  );

  factory AccountModel.fromEntity(AccountEntity e) => AccountModel(
    id: e.id,
    userId: e.userId,
    name: e.name,
    type: e.type,
    currency: e.currency,
    balance: e.balance,
  );
}
