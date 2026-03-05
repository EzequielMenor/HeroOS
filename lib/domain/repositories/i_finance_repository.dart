import '../entities/account_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/category_entity.dart';

/// Contrato del repositorio de finanzas.
abstract interface class IFinanceRepository {
  Future<List<AccountEntity>> getAccounts();
  Future<void> createAccount(AccountEntity account);
  Future<void> deleteAccount(String accountId);
  Future<List<TransactionEntity>> getTransactions({String? accountId});
  Future<void> createTransaction(TransactionEntity txn);
  Future<void> deleteTransaction(String txnId);
  Future<void> createTransfer({
    required String userId,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? note,
  });

  // ─── Categories ───
  Future<List<CategoryEntity>> getCategories();
  Future<void> createCategory(CategoryEntity category);
  Future<void> updateCategory(CategoryEntity category);
  Future<void> deleteCategory(String categoryId);
}
