import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/adaptive_modal.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../viewmodels/finance_viewmodel.dart';

/// Pantalla de Finanzas — cuentas, transacciones y balance total.
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceViewModel>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();

    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.finance),
      );
    }

    return Scaffold(
      body: vm.accounts.isEmpty
          ? _buildEmptyState(context)
          : _buildContent(context, vm),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.finance,
        onPressed: () => _showAddMenu(context, vm),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            '¡Tu tesoro está vacío!\nCrea tu primera cuenta.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, FinanceViewModel vm) {
    if (context.isWeb) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: balance + cuentas
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _BalanceHeader(total: vm.totalBalance),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    '💰 Cuentas',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...vm.accounts.map((a) => _AccountTile(account: a, vm: vm)),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          // Right: transacciones
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    '📜 Transacciones recientes',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (vm.transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aún no hay transacciones.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ...vm.transactions
                      .take(20)
                      .map((t) => _TransactionTile(txn: t, vm: vm)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _BalanceHeader(total: vm.totalBalance),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            '💰 Cuentas',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...vm.accounts.map((a) => _AccountTile(account: a, vm: vm)),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            '📜 Transacciones recientes',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (vm.transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aún no hay transacciones.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          )
        else
          ...vm.transactions
              .take(20)
              .map((t) => _TransactionTile(txn: t, vm: vm)),
      ],
    );
  }

  void _showAddMenu(BuildContext context, FinanceViewModel vm) {
    showAdaptiveModal<void>(
      context,
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.account_balance,
                color: AppColors.finance,
              ),
              title: const Text(
                'Nueva Cuenta',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCreateAccount(context, vm);
              },
            ),
            if (vm.accounts.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: AppColors.finance),
                title: const Text(
                  'Nueva Transacción',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateTransaction(context, vm);
                },
              ),
            if (vm.accounts.length >= 2)
              ListTile(
                leading: const Icon(Icons.sync_alt, color: AppColors.finance),
                title: const Text(
                  'Transferir entre cuentas',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateTransfer(context, vm);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateAccount(BuildContext context, FinanceViewModel vm) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    String type = 'Cash';

    showAdaptiveModal<void>(
      context,
      StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nueva Cuenta',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ej: Banco, Cartera',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Saldo inicial (€)',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tipo',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Cash', 'Bank', 'Investment'].map((t) {
                  final isActive = type == t;
                  final label = switch (t) {
                    'Cash' => '💵 Efectivo',
                    'Bank' => '🏦 Banco',
                    'Investment' => '📈 Inversión',
                    _ => t,
                  };
                  return ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary.withValues(alpha: 0.1),
                        fontSize: 12,
                      ),
                    ),
                    selected: isActive,
                    selectedColor: AppColors.finance,
                    backgroundColor: AppColors.scaffold,
                    onSelected: (_) => setSheetState(() => type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.finance,
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final balance =
                        double.tryParse(balanceCtrl.text.trim()) ?? 0;
                    vm.createAccount(
                      name: name,
                      type: type,
                      initialBalance: balance,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Crear Cuenta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTransaction(BuildContext context, FinanceViewModel vm) {
    if (vm.accounts.isEmpty) return;

    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? selectedAccountId = vm.accounts.first.id;
    bool isExpense = true;

    List<CategoryEntity> categoriesFor(String? accId, bool isExp) {
      final acc = vm.accounts.where((a) => a.id == accId).firstOrNull;
      return vm.categoriesFor(acc?.type, isExp);
    }

    String category =
        categoriesFor(selectedAccountId, isExpense).firstOrNull?.name ??
        'General';

    showAdaptiveModal<void>(
      context,
      StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nueva Transacción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showManageCategories(context, vm),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Gestionar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.finance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tipo: ingreso/gasto
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          'Gasto',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      selected: isExpense,
                      selectedColor: AppColors.danger,
                      onSelected: (_) => setSheetState(() {
                        isExpense = true;
                        category =
                            categoriesFor(
                              selectedAccountId,
                              isExpense,
                            ).firstOrNull?.name ??
                            'General';
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          'Ingreso',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      selected: !isExpense,
                      selectedColor: Colors.green,
                      onSelected: (_) => setSheetState(() {
                        isExpense = false;
                        category =
                            categoriesFor(
                              selectedAccountId,
                              isExpense,
                            ).firstOrNull?.name ??
                            'General';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.euro, color: AppColors.finance),
                  filled: true,
                  fillColor: AppColors.scaffold,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedAccountId,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Cuenta',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.scaffold,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: vm.accounts.map((a) {
                  final typeName = switch (a.type) {
                    'Bank' => 'Banco',
                    'Investment' => 'Inversión',
                    'Cash' => 'Efectivo',
                    _ => a.type,
                  };
                  return DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.name} ($typeName)'),
                  );
                }).toList(),
                onChanged: (v) => setSheetState(() {
                  selectedAccountId = v;
                  category =
                      categoriesFor(v, isExpense).firstOrNull?.name ??
                      'General';
                }),
              ),
              const SizedBox(height: 12),
              const Text(
                'Categoría',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categoriesFor(selectedAccountId, isExpense).map((c) {
                  final isSelected = category == c.name;
                  return ChoiceChip(
                    label: Text('${c.icon} ${c.name}'),
                    selected: isSelected,
                    selectedColor: AppColors.finance.withValues(alpha: 0.3),
                    backgroundColor: AppColors.scaffold,
                    onSelected: (_) => setSheetState(() => category = c.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nota (opcional)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.scaffold,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text) ?? 0;
                    if (amount <= 0 || selectedAccountId == null) return;
                    vm.addTransaction(
                      accountId: selectedAccountId!,
                      amount: isExpense ? -amount : amount,
                      category: category,
                      note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.finance,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTransfer(BuildContext context, FinanceViewModel vm) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? fromId = vm.accounts.first.id;
    String? toId = vm.accounts.length > 1 ? vm.accounts[1].id : null;

    showAdaptiveModal<void>(
      context,
      StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transferir entre cuentas',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Cuenta origen
              DropdownButtonFormField<String>(
                initialValue: fromId,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Desde',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: vm.accounts.map((a) {
                  final typeName = switch (a.type) {
                    'Bank' => 'Banco',
                    'Investment' => 'Inversión',
                    'Cash' => 'Efectivo',
                    _ => a.type,
                  };
                  return DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.name} ($typeName)'),
                  );
                }).toList(),
                onChanged: (v) => setSheetState(() => fromId = v),
              ),
              const SizedBox(height: 12),
              // Cuenta destino
              DropdownButtonFormField<String>(
                initialValue: toId,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Hacia',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: vm.accounts.map((a) {
                  final typeName = switch (a.type) {
                    'Bank' => 'Banco',
                    'Investment' => 'Inversión',
                    'Cash' => 'Efectivo',
                    _ => a.type,
                  };
                  return DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.name} ($typeName)'),
                  );
                }).toList(),
                onChanged: (v) => setSheetState(() => toId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Cantidad (€)',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Nota (opcional)',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.finance,
                  ),
                  onPressed: () {
                    final raw = double.tryParse(amountCtrl.text.trim());
                    if (raw == null ||
                        raw <= 0 ||
                        fromId == null ||
                        toId == null ||
                        fromId == toId) {
                      return;
                    }
                    vm.transferMoney(
                      fromAccountId: fromId!,
                      toAccountId: toId!,
                      amount: raw,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Transferir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManageCategories(BuildContext context, FinanceViewModel vm) {
    showAdaptiveModal<void>(
      context,
      StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gestionar Categorías',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: vm.categories.length,
                  itemBuilder: (context, index) {
                    final cat = vm.categories[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        cat.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(
                        cat.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${cat.isExpense ? 'Gasto' : 'Ingreso'}${cat.accountType != null ? ' • ${cat.accountType}' : ''}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                          size: 20,
                        ),
                        onPressed: () async {
                          await vm.deleteCategory(cat.id);
                          setSheetState(() {});
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: AppColors.scaffold, height: 24),
              const Text(
                'Nueva Categoría',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              _NewCategoryForm(
                onAdd: (name, icon, isExp, accType) async {
                  await vm.addCategory(
                    name: name,
                    icon: icon,
                    isExpense: isExp,
                    accountType: accType,
                  );
                  setSheetState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets privados ───

class _BalanceHeader extends StatelessWidget {
  final double total;
  const _BalanceHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tesoro Real',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${total.toStringAsFixed(2)} G',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final AccountEntity account;
  final FinanceViewModel vm;

  const _AccountTile({required this.account, required this.vm});

  @override
  Widget build(BuildContext context) {
    final icon = switch (account.type) {
      'Bank' => Icons.account_balance,
      'Investment' => Icons.trending_up,
      _ => Icons.wallet,
    };

    return Dismissible(
      key: ValueKey(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Borrar cuenta',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            '¿Eliminar "${account.name}" y todas sus transacciones?',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Borrar',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => vm.deleteAccount(account.id),
      child: ListTile(
        leading: Icon(icon, color: AppColors.finance),
        title: Text(
          account.name,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        trailing: Text(
          '${account.balance.toStringAsFixed(2)} ${account.currency}',
          style: TextStyle(
            color: account.balance >= 0 ? Colors.green : AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionEntity txn;
  final FinanceViewModel vm;

  const _TransactionTile({required this.txn, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.isIncome;
    final isTransfer = txn.isTransfer;

    return Dismissible(
      key: ValueKey(txn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => vm.removeTransaction(txn.id),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (isTransfer
                      ? AppColors.finance
                      : isIncome
                      ? Colors.green
                      : AppColors.danger)
                  .withValues(alpha: 0.15),
          child: Icon(
            isTransfer
                ? Icons.sync_alt
                : isIncome
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isTransfer
                ? AppColors.finance
                : isIncome
                ? Colors.green
                : AppColors.danger,
            size: 18,
          ),
        ),
        title: Text(
          txn.category,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        subtitle: Text(
          txn.note ?? '${txn.date.day}/${txn.date.month}/${txn.date.year}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Text(
          '${isIncome ? '+' : ''}${txn.amount.toStringAsFixed(2)} G',
          style: TextStyle(
            color: isIncome ? Colors.green : AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _NewCategoryForm extends StatefulWidget {
  final Function(String, String, bool, String?) onAdd;
  const _NewCategoryForm({required this.onAdd});

  @override
  State<_NewCategoryForm> createState() => _NewCategoryFormState();
}

class _NewCategoryFormState extends State<_NewCategoryForm> {
  final nameCtrl = TextEditingController();
  final iconCtrl = TextEditingController(text: '🏷️');
  bool isExpense = true;
  String? accountType;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 50,
              child: TextField(
                controller: iconCtrl,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.scaffold,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ej: Gym, Comida...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.scaffold,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Gasto')),
                selected: isExpense,
                onSelected: (_) => setState(() => isExpense = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Ingreso')),
                selected: !isExpense,
                onSelected: (_) => setState(() => isExpense = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          initialValue: accountType,
          dropdownColor: AppColors.surface,
          hint: const Text(
            'Tipo Cuenta (Opcional)',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.scaffold,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Todas')),
            DropdownMenuItem(value: 'Bank', child: Text('Banco')),
            DropdownMenuItem(value: 'Investment', child: Text('Inversión')),
          ],
          onChanged: (v) => setState(() => accountType = v),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              widget.onAdd(
                nameCtrl.text,
                iconCtrl.text,
                isExpense,
                accountType,
              );
              nameCtrl.clear();
              setState(() {
                isExpense = true;
                accountType = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.finance,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Añadir Categoría',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
