import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/account_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/i_finance_repository.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/supabase_service.dart';

/// Implementación Supabase del repositorio de finanzas.
class FinanceRepository implements IFinanceRepository {
  final SupabaseClient _client = SupabaseService.client;

  // ─── Accounts ───

  @override
  Future<List<AccountEntity>> getAccounts() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .order('name');

    return data.map((j) => AccountModel.fromJson(j).toEntity()).toList();
  }

  @override
  Future<void> createAccount(AccountEntity account) async {
    final model = AccountModel.fromEntity(account);
    await _client.from('accounts').insert(model.toJson());
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    await _client.from('accounts').delete().eq('id', accountId);
  }

  // ─── Transactions ───

  @override
  Future<List<TransactionEntity>> getTransactions({String? accountId}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    var query = _client.from('transactions').select().eq('user_id', userId);
    if (accountId != null) {
      query = query.eq('account_id', accountId);
    }
    final data = await query.order('date', ascending: false);

    return data.map((j) => TransactionModel.fromJson(j).toEntity()).toList();
  }

  @override
  Future<void> createTransaction(TransactionEntity txn) async {
    final model = TransactionModel.fromEntity(txn);
    await _client.from('transactions').insert(model.toJson());

    // Actualizar balance de la cuenta
    final accData = await _client
        .from('accounts')
        .select('balance')
        .eq('id', txn.accountId)
        .single();
    final currentBalance = (accData['balance'] as num).toDouble();
    await _client
        .from('accounts')
        .update({'balance': currentBalance + txn.amount})
        .eq('id', txn.accountId);
  }

  @override
  Future<void> deleteTransaction(String txnId) async {
    // Obtener transacción antes de borrar para revertir balance
    final txnData = await _client
        .from('transactions')
        .select()
        .eq('id', txnId)
        .single();
    final txn = TransactionModel.fromJson(txnData);

    await _client.from('transactions').delete().eq('id', txnId);

    // Revertir balance
    final accData = await _client
        .from('accounts')
        .select('balance')
        .eq('id', txn.accountId)
        .single();
    final currentBalance = (accData['balance'] as num).toDouble();
    await _client
        .from('accounts')
        .update({'balance': currentBalance - txn.amount})
        .eq('id', txn.accountId);
  }

  // ─── Transfers ───

  @override
  Future<void> createTransfer({
    required String userId,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? note,
  }) async {
    final now = DateTime.now().toIso8601String();
    final transferNote = note ?? 'Transferencia';

    // 1. Insertar gasto en cuenta origen
    final fromData = await _client
        .from('transactions')
        .insert({
          'user_id': userId,
          'account_id': fromAccountId,
          'amount': -amount,
          'category': 'Transfer',
          'note': transferNote,
          'date': now,
        })
        .select()
        .single();

    // 2. Insertar ingreso en cuenta destino, vinculado al gasto
    final toData = await _client
        .from('transactions')
        .insert({
          'user_id': userId,
          'account_id': toAccountId,
          'amount': amount,
          'category': 'Transfer',
          'note': transferNote,
          'date': now,
          'related_transaction_id': fromData['id'],
        })
        .select()
        .single();

    // 3. Vincular la primera transacción con la segunda
    await _client
        .from('transactions')
        .update({'related_transaction_id': toData['id']})
        .eq('id', fromData['id'] as String);

    // 4. Actualizar balances de ambas cuentas
    final fromAcc = await _client
        .from('accounts')
        .select('balance')
        .eq('id', fromAccountId)
        .single();
    await _client
        .from('accounts')
        .update({'balance': (fromAcc['balance'] as num).toDouble() - amount})
        .eq('id', fromAccountId);

    final toAcc = await _client
        .from('accounts')
        .select('balance')
        .eq('id', toAccountId)
        .single();
    await _client
        .from('accounts')
        .update({'balance': (toAcc['balance'] as num).toDouble() + amount})
        .eq('id', toAccountId);
  }

  // ─── Categories ───

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('finance_categories')
        .select()
        .eq('user_id', userId)
        .order('name');

    if (data.isEmpty) {
      // Si no hay categorías, hacemos seed de las básicas
      await _seedCategories(userId);
      return getCategories();
    }

    return data.map((j) => CategoryModel.fromJson(j).toEntity()).toList();
  }

  Future<void> createCategory(CategoryEntity category) async {
    final model = CategoryModel.fromEntity(category);
    final json = model.toJson()..remove('id'); // Supabase genera el UUID
    await _client.from('finance_categories').insert(json);
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    final model = CategoryModel.fromEntity(category);
    await _client
        .from('finance_categories')
        .update(model.toJson())
        .eq('id', category.id);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _client.from('finance_categories').delete().eq('id', categoryId);
  }

  Future<void> _seedCategories(String userId) async {
    final defaults = [
      {
        'name': 'Comida',
        'icon': '🍔',
        'is_expense': true,
        'account_type': null,
      },
      {
        'name': 'Transporte',
        'icon': '🚗',
        'is_expense': true,
        'account_type': null,
      },
      {'name': 'Tech', 'icon': '💻', 'is_expense': true, 'account_type': null},
      {'name': 'Ocio', 'icon': '🎮', 'is_expense': true, 'account_type': null},
      {'name': 'Salud', 'icon': '💊', 'is_expense': true, 'account_type': null},
      {
        'name': 'Sueldo',
        'icon': '💼',
        'is_expense': false,
        'account_type': null,
      },
      {
        'name': 'Intereses',
        'icon': '💰',
        'is_expense': false,
        'account_type': 'Bank',
      },
      {
        'name': 'Rendimiento',
        'icon': '📈',
        'is_expense': false,
        'account_type': 'Investment',
      },
      {
        'name': 'Caída Mercado',
        'icon': '📉',
        'is_expense': true,
        'account_type': 'Investment',
      },
      {
        'name': 'Comisiones',
        'icon': '💸',
        'is_expense': true,
        'account_type': 'Investment',
      },
    ];

    final seedData = defaults
        .map((d) => {...d, 'user_id': userId, 'is_default': true})
        .toList();

    await _client.from('finance_categories').insert(seedData);
  }
}
