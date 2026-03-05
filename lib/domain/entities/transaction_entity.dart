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

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.amount,
    this.category = 'General',
    this.note,
    required this.date,
    this.relatedTransactionId,
  });

  /// Positivo = ingreso, negativo = gasto.
  bool get isIncome => amount > 0;

  /// True si es parte de una transferencia entre cuentas.
  bool get isTransfer => relatedTransactionId != null;
}
