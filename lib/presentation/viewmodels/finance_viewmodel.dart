import 'package:flutter/material.dart';

import '../../data/repositories/finance_repository.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import 'stats_viewmodel.dart';

/// ViewModel de Finanzas.
/// Gestiona cuentas y transacciones + sincroniza gold via [StatsViewModel].
class FinanceViewModel extends ChangeNotifier {
  final FinanceRepository _repo = FinanceRepository();
  final StatsViewModel _statsVm;

  List<AccountEntity> _accounts = [];
  List<TransactionEntity> _transactions = [];
  List<CategoryEntity> _categories = [];
  bool _isLoading = false;
  String? _error;

  FinanceViewModel(this._statsVm);

  List<AccountEntity> get accounts => _accounts;
  List<TransactionEntity> get transactions => _transactions;
  List<CategoryEntity> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Balance total = suma de todos los balances de las cuentas.
  double get totalBalance => _accounts.fold(0.0, (sum, a) => sum + a.balance);

  /// Carga cuentas y transacciones.
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _accounts = await _repo.getAccounts();
      _transactions = await _repo.getTransactions();
      _categories = await _repo.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea una nueva cuenta.
  Future<void> createAccount({
    required String name,
    String type = 'Cash',
    String currency = 'EUR',
    double initialBalance = 0,
  }) async {
    final userId = _statsVm.profile?.id;
    if (userId == null) return;

    final account = AccountEntity(
      id: '',
      userId: userId,
      name: name,
      type: type,
      currency: currency,
      balance: initialBalance,
    );
    try {
      await _repo.createAccount(account);
      await loadAll();
      // Recargar perfil para sincronizar gold
      await _statsVm.loadProfile();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Elimina una cuenta y todas sus transacciones (CASCADE).
  Future<void> deleteAccount(String accountId) async {
    try {
      await _repo.deleteAccount(accountId);
      await loadAll();
      await _statsVm.loadProfile();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Añade una transacción y actualiza el balance.
  Future<void> addTransaction({
    required String accountId,
    required double amount,
    required String category,
    String? note,
  }) async {
    final userId = _statsVm.profile?.id;
    if (userId == null) return;

    final txn = TransactionEntity(
      id: '',
      userId: userId,
      accountId: accountId,
      amount: amount,
      category: category,
      note: note,
      date: DateTime.now(),
    );
    try {
      await _repo.createTransaction(txn);
      await loadAll();
      await _statsVm.loadProfile();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Elimina una transacción y revierte el balance.
  Future<void> removeTransaction(String txnId) async {
    try {
      await _repo.deleteTransaction(txnId);
      await loadAll();
      await _statsVm.loadProfile();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Transfiere dinero entre dos cuentas.
  Future<void> transferMoney({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? note,
  }) async {
    final userId = _statsVm.profile?.id;
    if (userId == null) return;

    try {
      await _repo.createTransfer(
        userId: userId,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        amount: amount,
        note: note,
      );
      await loadAll();
      await _statsVm.loadProfile();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ─── Categories ───

  /// Filtra categorías por tipo de cuenta y si es gasto/ingreso.
  List<CategoryEntity> categoriesFor(String? accountType, bool isExpense) {
    return _categories.where((c) {
      final matchesExpense = c.isExpense == isExpense;
      final matchesAccount =
          c.accountType == null || c.accountType == accountType;
      return matchesExpense && matchesAccount;
    }).toList();
  }

  Future<void> addCategory({
    required String name,
    required String icon,
    required bool isExpense,
    String? accountType,
  }) async {
    final userId = _statsVm.profile?.id;
    if (userId == null) return;

    final category = CategoryEntity(
      id: '',
      userId: userId,
      name: name,
      icon: icon,
      isExpense: isExpense,
      accountType: accountType,
    );
    try {
      await _repo.createCategory(category);
      _categories = await _repo.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _repo.deleteCategory(categoryId);
      _categories = await _repo.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
