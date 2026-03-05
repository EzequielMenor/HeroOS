import '../../domain/entities/transaction_entity.dart';

/// Modelo de datos para serializar/deserializar transacciones desde Supabase.
class TransactionModel {
  final String id;
  final String userId;
  final String accountId;
  final double amount;
  final String category;
  final String? note;
  final DateTime date;
  final String? relatedTransactionId;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    this.relatedTransactionId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        accountId: json['account_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: (json['category'] as String?) ?? 'General',
        note: json['note'] as String?,
        date: DateTime.parse(json['date'] as String),
        relatedTransactionId: json['related_transaction_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'account_id': accountId,
    'amount': amount,
    'category': category,
    'note': note,
    'date': date.toIso8601String(),
    if (relatedTransactionId != null)
      'related_transaction_id': relatedTransactionId,
  };

  TransactionEntity toEntity() => TransactionEntity(
    id: id,
    userId: userId,
    accountId: accountId,
    amount: amount,
    category: category,
    note: note,
    date: date,
    relatedTransactionId: relatedTransactionId,
  );

  factory TransactionModel.fromEntity(TransactionEntity e) => TransactionModel(
    id: e.id,
    userId: e.userId,
    accountId: e.accountId,
    amount: e.amount,
    category: e.category,
    note: e.note,
    date: e.date,
    relatedTransactionId: e.relatedTransactionId,
  );
}
