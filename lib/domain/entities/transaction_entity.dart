import 'sync_status.dart';

/// Tipo de transacción para la base de datos.
/// Mapea al CHECK constraint en PostgreSQL:
///   type = ANY (ARRAY['income'::text, 'expense'::text, 'transfer'::text])
enum TransactionType { income, expense, transfer }

/// Entidad de dominio para Transacciones.
class TransactionEntity {
  final String id;
  final String userId;
  final String accountId;
  final double amount;
  final String category;
  final String? note;
  final DateTime date;
  final String? relatedTransactionId;
  final SyncStatus? syncStatus;

  TransactionEntity({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.amount,
    this.category = 'General',
    this.note,
    required this.date,
    this.relatedTransactionId,
    this.syncStatus,
  });

  /// Positivo = ingreso, negativo = gasto.
  bool get isIncome => amount > 0;

  /// True si es parte de una transferencia entre cuentas.
  bool get isTransfer => relatedTransactionId != null;

  /// Tipo inferido de la transacción (mapea al campo `type` de la BD).
  /// Lógica:
  /// - Si tiene relatedTransactionId → 'transfer'
  /// - Si amount > 0 → 'income'
  /// - Si amount <= 0 → 'expense'
  String get dbType {
    if (isTransfer) return 'transfer';
    return isIncome ? 'income' : 'expense';
  }

  TransactionEntity copyWith({
    String? id,
    String? userId,
    String? accountId,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    String? relatedTransactionId,
    SyncStatus? syncStatus,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      relatedTransactionId: relatedTransactionId ?? this.relatedTransactionId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
