import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/adaptive_modal.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../viewmodels/finance_viewmodel.dart';

// ─── Tokens Zen OS ──────────────────────────────────────────────────────────
Color get _kSageGreen => AppColors.habits;
Color get _kDanger => AppColors.danger;
Color get _kTextPrim => AppColors.textPrimary;
Color get _kTextSec => AppColors.textSecondary;
Color get _kDivider => AppColors.divider;
Color get _kSurface => AppColors.surface;
Color get _kScaffold => AppColors.scaffold;

/// Underline-only InputDecoration — Zen OS
InputDecoration _zenInput({
  required String hint,
  String? label,
  Widget? prefixIcon,
}) =>
    InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: TextStyle(color: _kTextSec, fontSize: 14),
      labelStyle: TextStyle(color: _kTextSec, fontSize: 13),
      prefixIcon: prefixIcon,
      filled: false,
      contentPadding: EdgeInsets.symmetric(vertical: 10),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: _kDivider),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: _kDivider),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: _kTextPrim.withValues(alpha: 0.5)),
      ),
    );

/// Pantalla de Finanzas — cuentas, transacciones y balance total.
/// Sin FloatingActionButton propio: el FAB global lo gestiona el Dashboard.
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  // Filtro: 0=Todo, 1=Ingresos, 2=Gastos
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceViewModel>().loadAll();
    });
  }

  List<TransactionEntity> _filteredTxns(List<TransactionEntity> all) =>
      switch (_filter) {
        1 => all.where((t) => t.isIncome).toList(),
        2 => all.where((t) => !t.isIncome && !t.isTransfer).toList(),
        _ => all,
      };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();

    if (vm.isLoading) {
      return Scaffold(
        backgroundColor: _kScaffold,
        body: Center(
          child: CircularProgressIndicator(color: _kSageGreen, strokeWidth: 1),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kScaffold,
      body: SafeArea(
        child: vm.accounts.isEmpty
            ? _buildEmptyState(context, vm)
            : _buildContent(context, vm),
      ),
      // Sin FAB: lo gestiona el Dashboard globalmente.
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty state
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, FinanceViewModel vm) {
    return Column(
      children: [
        _ZenHeader(
          vm: vm,
          onAdd: () => showFinanceAddMenu(context, vm),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 40,
                  color: _kTextSec,
                ),
                SizedBox(height: 20),
                Text(
                  'SIN CUENTAS',
                  style: TextStyle(
                    color: _kTextSec,
                    fontSize: 9,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Crea tu primera cuenta\npara empezar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kTextSec, fontSize: 14, height: 1.7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Content layout
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, FinanceViewModel vm) {
    if (context.isWeb) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _LeftPanel(vm: vm, onAdd: () => showFinanceAddMenu(context, vm))),
          Container(width: 1, color: _kDivider),
          Expanded(
            child: _TransactionPanel(
              vm: vm,
              filter: _filter,
              filteredTxns: _filteredTxns(vm.transactions),
              onFilterChanged: (v) => setState(() => _filter = v),
            ),
          ),
        ],
      );
    }

    // ── Mobile layout ───────────────────────────────────────────────────
    return CustomScrollView(
      slivers: [
        // Header: label + balance + botón añadir
        SliverToBoxAdapter(
          child: _ZenHeader(vm: vm, onAdd: () => showFinanceAddMenu(context, vm)),
        ),
        // Cuentas
        SliverToBoxAdapter(child: _AccountsSection(vm: vm)),
        // Filtros
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: _FilterBar(
              selected: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 4)),
        // Lista transacciones
        if (_filteredTxns(vm.transactions).isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Text(
                'Sin transacciones.',
                style: TextStyle(color: _kTextSec, fontSize: 13),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final list = _filteredTxns(vm.transactions);
                return _ZenTransactionTile(txn: list[i], vm: vm);
              },
              childCount: _filteredTxns(vm.transactions).length,
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }


  // ─────────────────────────────────────────────────────────────────────────
  // Modales
  // ─────────────────────────────────────────────────────────────────────────





}

// ─── Header Zen ─────────────────────────────────────────────────────────────
// Label BALANCE + importe en Cormorant + ingresos mes + botón añadir (+)

class _ZenHeader extends StatelessWidget {
  final FinanceViewModel vm;
  final VoidCallback onAdd;

  const _ZenHeader({required this.vm, required this.onAdd});


  bool _isSameMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = vm.totalBalance >= 0;
    final monthlyIncome = vm.transactions
        .where((t) => t.isIncome && _isSameMonth(t.date))
        .fold(0.0, (s, t) => s + t.amount);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + botón añadir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'BALANCE',
                style: TextStyle(
                  color: _kTextSec,
                  fontSize: 9,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Botón añadir en el header — icono pequeño textSecondary
              GestureDetector(
                onTap: onAdd,
                child: Icon(
                  Icons.add,
                  size: 18,
                  color: _kTextSec,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          // Balance en Cormorant Garamond 42px w300
          Text(
            '${isPositive ? '' : '-'}€${vm.totalBalance.abs().toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 42,
              fontWeight: FontWeight.w600,
              color: isPositive ? _kTextPrim : _kDanger,
              height: 1.0,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ingresos este mes: +€${monthlyIncome.toStringAsFixed(2)}',
            style: TextStyle(color: _kTextSec, fontSize: 12),
          ),
          SizedBox(height: 20),
          Container(height: 1, color: _kDivider),
        ],
      ),
    );
  }
}

// ─── Panel izquierdo (Web) ──────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  final FinanceViewModel vm;
  final VoidCallback onAdd;

  const _LeftPanel({required this.vm, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _ZenHeader(vm: vm, onAdd: onAdd),
        _AccountsSection(vm: vm),
      ],
    );
  }
}

// ─── Panel derecho (Web) ────────────────────────────────────────────────────

class _TransactionPanel extends StatelessWidget {
  final FinanceViewModel vm;
  final int filter;
  final List<TransactionEntity> filteredTxns;
  final ValueChanged<int> onFilterChanged;

  const _TransactionPanel({
    required this.vm,
    required this.filter,
    required this.filteredTxns,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 36, 20, 0),
          child: _FilterBar(selected: filter, onChanged: onFilterChanged),
        ),
        SizedBox(height: 8),
        if (filteredTxns.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Text(
              'Sin transacciones.',
              style: TextStyle(color: _kTextSec, fontSize: 13),
            ),
          )
        else
          ...filteredTxns.map((t) => _ZenTransactionTile(txn: t, vm: vm)),
      ],
    );
  }
}

// ─── Sección Cuentas ────────────────────────────────────────────────────────

class _AccountsSection extends StatelessWidget {
  final FinanceViewModel vm;
  const _AccountsSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            'CUENTAS',
            style: TextStyle(
              color: _kTextSec,
              fontSize: 9,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ...vm.accounts.map((a) => _ZenAccountTile(account: a, vm: vm)),
      ],
    );
  }
}

// ─── Tile de Cuenta ────────────────────────────────────────────────────────

class _ZenAccountTile extends StatelessWidget {
  final AccountEntity account;
  final FinanceViewModel vm;

  const _ZenAccountTile({required this.account, required this.vm});

  @override
  Widget build(BuildContext context) {
    final icon = switch (account.type) {
      'Bank'       => Icons.account_balance_outlined,
      'Investment' => Icons.trending_up,
      _            => Icons.account_balance_wallet_outlined,
    };
    final isNeg = account.balance < 0;

    return Dismissible(
      key: ValueKey(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: _kDanger.withValues(alpha: 0.10),
        child: Icon(Icons.delete_outline, color: _kDanger, size: 18),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _kSurface,
          title: Text(
            'Borrar cuenta',
            style: TextStyle(color: _kTextPrim, fontSize: 16),
          ),
          content: Text(
            '¿Eliminar "${account.name}" y todas sus transacciones?',
            style: TextStyle(color: _kTextSec, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'CANCELAR',
                style: TextStyle(
                  color: _kTextSec,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'BORRAR',
                style: TextStyle(
                  color: _kDanger,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => vm.deleteAccount(account.id),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _kDivider)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _kTextSec, size: 16),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                account.name,
                style: TextStyle(color: _kTextPrim, fontSize: 14),
              ),
            ),
            Text(
              '${isNeg ? '-' : ''}€${account.balance.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: isNeg ? _kDanger : _kTextPrim,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Barra de filtros ───────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['TODO', 'INGRESOS', 'GASTOS'];

    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = selected == i;
        return Padding(
          padding: EdgeInsets.only(right: i < labels.length - 1 ? 24 : 0),
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 180),
                  style: TextStyle(
                    color: isActive ? _kTextPrim : _kTextSec,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                  child: Text(labels[i]),
                ),
                SizedBox(height: 4),
                AnimatedContainer(
                  duration: Duration(milliseconds: 180),
                  height: 1.5,
                  width: isActive ? 40 : 0,
                  color: _kTextPrim,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Tile de Transacción ────────────────────────────────────────────────────

class _ZenTransactionTile extends StatefulWidget {
  final TransactionEntity txn;
  final FinanceViewModel vm;

  const _ZenTransactionTile({required this.txn, required this.vm});

  @override
  State<_ZenTransactionTile> createState() => _ZenTransactionTileState();
}

class _ZenTransactionTileState extends State<_ZenTransactionTile> {
  OverlayEntry? _categoryOverlay;

  void _showCategoryPopover(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _categoryOverlay?.remove();

    _categoryOverlay = OverlayEntry(
      builder: (context) => _CategoryPopover(
        anchorPosition: position,
        anchorSize: size,
        currentCategory: widget.txn.category,
        isExpense: !widget.txn.isIncome,
        categories: widget.vm.categoriesFor(
          widget.vm.accounts.firstWhere(
            (a) => a.id == widget.txn.accountId,
            orElse: () => widget.vm.accounts.first,
          ).type,
          !widget.txn.isIncome,
        ),
        onCategorySelected: (category) {
          widget.vm.updateTransactionCategory(widget.txn.id, category);
          _hideCategoryPopover();
        },
        onDismiss: _hideCategoryPopover,
      ),
    );

    Overlay.of(context).insert(_categoryOverlay!);
  }

  void _hideCategoryPopover() {
    _categoryOverlay?.remove();
    _categoryOverlay = null;
  }

  @override
  void dispose() {
    _hideCategoryPopover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome   = widget.txn.isIncome;
    final isTransfer = widget.txn.isTransfer;

    final iconColor   = isTransfer ? _kTextSec : isIncome ? _kSageGreen : _kDanger;
    final amountColor = isTransfer ? _kTextSec : isIncome ? _kSageGreen : _kDanger;

    final arrowIcon = isTransfer
        ? Icons.sync_alt
        : isIncome
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    return Dismissible(
      key: ValueKey(widget.txn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: _kDanger.withValues(alpha: 0.08),
        child: Icon(Icons.delete_outline, color: _kDanger, size: 18),
      ),
      onDismissed: (_) => widget.vm.removeTransaction(widget.txn.id),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _kDivider)),
        ),
        child: Row(
          children: [
            // Icono cuadrado 34×34, sin bordes redondeados
            Container(
              width: 34,
              height: 34,
              color: iconColor.withValues(alpha: 0.08),
              child: Icon(arrowIcon, size: 15, color: iconColor),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tappable category
                  GestureDetector(
                    onTap: () => _showCategoryPopover(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.txn.category,
                          style: TextStyle(
                            color: _kTextPrim,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: _kTextSec,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    (widget.txn.note != null && widget.txn.note!.isNotEmpty)
                        ? widget.txn.note!.toUpperCase()
                        : '${widget.txn.date.day.toString().padLeft(2, '0')}/'
                            '${widget.txn.date.month.toString().padLeft(2, '0')}/'
                            '${widget.txn.date.year}',
                    style: TextStyle(
                      color: _kTextSec,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : isTransfer ? '' : '-'}€${widget.txn.amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: amountColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Translucent popover for category selection on transaction tiles.
class _CategoryPopover extends StatelessWidget {
  final Offset anchorPosition;
  final Size anchorSize;
  final String currentCategory;
  final bool isExpense;
  final List<CategoryEntity> categories;
  final void Function(String) onCategorySelected;
  final VoidCallback onDismiss;

  const _CategoryPopover({
    required this.anchorPosition,
    required this.anchorSize,
    required this.currentCategory,
    required this.isExpense,
    required this.categories,
    required this.onCategorySelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    // Popover dimensions
    const double popoverWidth = 260;
    const double popoverMaxHeight = 320;

    // Smart positioning: anchor below the category, but clamp to screen.
    double left = anchorPosition.dx;
    // If the popover would overflow the right side, shift it left.
    if (left + popoverWidth > mediaSize.width - 12) {
      left = mediaSize.width - popoverWidth - 12;
    }
    if (left < 12) left = 12;

    double top = anchorPosition.dy + anchorSize.height + 6;
    // If it would overflow the bottom, show it above the anchor instead.
    if (top + popoverMaxHeight > mediaSize.height - 12) {
      top = anchorPosition.dy - popoverMaxHeight - 6;
    }
    if (top < 12) top = 12;

    return Stack(
      children: [
        // Light scrim (only around the popover, not full screen)
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        // Popover
        Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            onTap: () {}, // Prevent dismiss when tapping inside
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: popoverWidth,
                constraints: BoxConstraints(maxHeight: popoverMaxHeight),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    width: 0.5,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                      child: Row(
                        children: [
                          Icon(
                            isExpense
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isExpense ? _kDanger : _kSageGreen,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CATEGORÍA',
                            style: TextStyle(
                              color: _kTextSec,
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // Close X button
                          GestureDetector(
                            onTap: onDismiss,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                color: _kTextSec,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      height: 0.5,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    // Categories list
                    Flexible(
                      child: categories.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Sin categorías disponibles',
                                style: TextStyle(
                                  color: _kTextSec,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: categories.map((cat) {
                                  final isSelected =
                                      cat.name == currentCategory;
                                  return InkWell(
                                    onTap: () =>
                                        onCategorySelected(cat.name),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            cat.icon,
                                            style: const TextStyle(
                                                fontSize: 16),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              cat.name,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? _kSageGreen
                                                    : _kTextPrim,
                                                fontSize: 13,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check,
                                              color: _kSageGreen,
                                              size: 16,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sheet Zen OS base ──────────────────────────────────────────────────────

class ZenSheet extends StatelessWidget {
  final String title;
  final BuildContext ctx;
  final List<Widget> children;
  final Widget? trailing;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final String confirmLabel;

  const ZenSheet({
    super.key,
    required this.title,
    required this.ctx,
    required this.children,
    this.trailing,
    this.onCancel,
    this.onConfirm,
    this.confirmLabel = 'AÑADIR',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: Color(0x14FFFFFF), width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        26,
        22,
        MediaQuery.of(ctx).viewInsets.bottom + 44,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + trailing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrim,
                  height: 1.0,
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: 24),
          // Contenido
          ...children,
          // Botones
          if (onConfirm != null) ...[
            SizedBox(height: 28),
            Row(
              children: [
                if (onCancel != null) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          'CANCELAR',
                          style: TextStyle(
                            color: _kTextSec,
                            fontSize: 11,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      height: 48,
                      color: _kTextPrim,
                      alignment: Alignment.center,
                      child: Text(
                        confirmLabel,
                        style: TextStyle(
                          color: AppColors.scaffold,
                          fontSize: 11,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Toggle chip ─────────────────────────────────────────────────────────────

class _ZenToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ZenToggleChip({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? activeColor.withValues(alpha: 0.5) : _kDivider,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? activeColor : _kTextSec,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Row de categoría ────────────────────────────────────────────────────────

class _ZenCategoryRow extends StatelessWidget {
  final CategoryEntity cat;
  final VoidCallback onDelete;

  const _ZenCategoryRow({required this.cat, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: [
          Text(cat.icon, style: TextStyle(fontSize: 18)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.name,
                  style: TextStyle(color: _kTextPrim, fontSize: 14),
                ),
                Text(
                  '${cat.isExpense ? 'GASTO' : 'INGRESO'}'
                  '${cat.accountType != null ? ' · ${cat.accountType!.toUpperCase()}' : ''}',
                  style: TextStyle(
                    color: _kTextSec,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, color: _kDanger, size: 16),
          ),
        ],
      ),
    );
  }
}

// ─── Opción de menú ─────────────────────────────────────────────────────────

class ZenMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ZenMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _kDivider)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _kTextSec, size: 16),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: _kTextPrim,
                fontSize: 11,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulario nueva categoría ─────────────────────────────────────────────

class _NewCategoryForm extends StatefulWidget {
  final Function(String, String, bool, String?) onAdd;
  const _NewCategoryForm({required this.onAdd});

  @override
  State<_NewCategoryForm> createState() => _NewCategoryFormState();
}

class _NewCategoryFormState extends State<_NewCategoryForm> {
  final nameCtrl  = TextEditingController();
  final iconCtrl  = TextEditingController(text: '🏷️');
  bool isExpense  = true;
  String? accountType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 48,
              child: TextField(
                controller: iconCtrl,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
                decoration: _zenInput(hint: ''),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: nameCtrl,
                style: TextStyle(color: _kTextPrim, fontSize: 14),
                decoration: _zenInput(hint: 'Ej: Gym, Comida…'),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Row(
          children: [
            _ZenToggleChip(
              label: 'GASTO',
              selected: isExpense,
              activeColor: _kDanger,
              onTap: () => setState(() => isExpense = true),
            ),
            SizedBox(width: 8),
            _ZenToggleChip(
              label: 'INGRESO',
              selected: !isExpense,
              activeColor: _kSageGreen,
              onTap: () => setState(() => isExpense = false),
            ),
          ],
        ),
        SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: accountType,
          dropdownColor: _kSurface,
          hint: Text(
            'TIPO CUENTA (OPCIONAL)',
            style: TextStyle(
              color: _kTextSec,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          style: TextStyle(color: _kTextPrim, fontSize: 14),
          decoration: _zenInput(hint: ''),
          items: [
            DropdownMenuItem(value: null,         child: Text('Todas')),
            DropdownMenuItem(value: 'Bank',       child: Text('Banco')),
            DropdownMenuItem(value: 'Investment', child: Text('Inversión')),
          ],
          onChanged: (v) => setState(() => accountType = v),
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            if (nameCtrl.text.isEmpty) return;
            widget.onAdd(nameCtrl.text, iconCtrl.text, isExpense, accountType);
            nameCtrl.clear();
            setState(() {
              isExpense   = true;
              accountType = null;
            });
          },
          child: Container(
            width: double.infinity,
            height: 44,
            color: _kTextPrim,
            alignment: Alignment.center,
            child: Text(
              'AÑADIR CATEGORÍA',
              style: TextStyle(
                color: AppColors.scaffold,
                fontSize: 10,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


  void showFinanceAddMenu(BuildContext context, FinanceViewModel vm) {
    showAdaptiveModal<void>(
      context,
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: _kSurface,
            border: Border(top: BorderSide(color: Color(0x14FFFFFF), width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 28),
              ZenMenuTile(
                icon: Icons.account_balance_outlined,
                label: 'NUEVA CUENTA',
                onTap: () {
                  Navigator.pop(context);
                  showCreateAccount(context, vm);
                },
              ),
              if (vm.accounts.isNotEmpty)
                ZenMenuTile(
                  icon: Icons.swap_vert,
                  label: 'NUEVA TRANSACCIÓN',
                  onTap: () {
                    Navigator.pop(context);
                    showCreateTransaction(context, vm);
                  },
                ),
              if (vm.accounts.length >= 2)
                ZenMenuTile(
                  icon: Icons.sync_alt,
                  label: 'TRANSFERIR',
                  onTap: () {
                    Navigator.pop(context);
                    showCreateTransfer(context, vm);
                  },
                ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }


  void showCreateAccount(BuildContext context, FinanceViewModel vm) {
    final nameCtrl    = TextEditingController();
    final balanceCtrl = TextEditingController();
    String type       = 'Cash';

    showAdaptiveModal<void>(
      context,
      StatefulBuilder(
        builder: (ctx, setSheetState) => ZenSheet(
          title: 'Nueva Cuenta',
          ctx: ctx,
          onCancel: () => Navigator.pop(ctx),
          onConfirm: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final balance = double.tryParse(balanceCtrl.text.trim()) ?? 0;
            vm.createAccount(name: name, type: type, initialBalance: balance);
            Navigator.pop(ctx);
          },
          confirmLabel: 'CREAR',
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: _kTextPrim),
              decoration: _zenInput(hint: 'Ej: Banco, Cartera'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: balanceCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: _kTextPrim),
              decoration: _zenInput(hint: 'Saldo inicial (€)'),
            ),
            SizedBox(height: 24),
            Text(
              'TIPO',
              style: TextStyle(
                color: _kTextSec,
                fontSize: 9,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: ['Cash', 'Bank', 'Investment'].map((t) {
                final isActive = type == t;
                final label = switch (t) {
                  'Cash'       => 'EFECTIVO',
                  'Bank'       => 'BANCO',
                  'Investment' => 'INVERSIÓN',
                  _            => t.toUpperCase(),
                };
                return GestureDetector(
                  onTap: () => setSheetState(() => type = t),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive
                            ? _kTextPrim.withValues(alpha: 0.35)
                            : _kDivider,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isActive ? _kTextPrim : _kTextSec,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }


  void showCreateTransaction(BuildContext context, FinanceViewModel vm) {
    if (vm.accounts.isEmpty) return;

    final amountCtrl      = TextEditingController();
    final noteCtrl        = TextEditingController();
    String? selectedAccId = vm.accounts.first.id;
    bool isExpense        = true;

    List<CategoryEntity> categoriesFor(String? accId, bool isExp) {
      final acc = vm.accounts.where((a) => a.id == accId).firstOrNull;
      return vm.categoriesFor(acc?.type, isExp);
    }

    String category =
        categoriesFor(selectedAccId, isExpense).firstOrNull?.name ?? 'General';

    showAdaptiveModal<void>(
      context,
      StatefulBuilder(
        builder: (ctx, setSheetState) => ZenSheet(
          title: 'Nueva Transacción',
          ctx: ctx,
          trailing: GestureDetector(
            onTap: () => showManageCategories(context, vm),
            child: Text(
              'GESTIONAR',
              style: TextStyle(
                color: _kSageGreen,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ),
          onCancel: () => Navigator.pop(ctx),
          onConfirm: () {
            final amount = double.tryParse(amountCtrl.text) ?? 0;
            if (amount <= 0 || selectedAccId == null) return;
            vm.addTransaction(
              accountId: selectedAccId!,
              amount: isExpense ? -amount : amount,
              category: category,
              note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
            );
            Navigator.pop(ctx);
          },
          confirmLabel: 'AÑADIR',
          children: [
            // Tipo
            Row(
              children: [
                _ZenToggleChip(
                  label: 'GASTO',
                  selected: isExpense,
                  activeColor: _kDanger,
                  onTap: () => setSheetState(() {
                    isExpense = true;
                    category = categoriesFor(selectedAccId, isExpense)
                            .firstOrNull
                            ?.name ??
                        'General';
                  }),
                ),
                SizedBox(width: 8),
                _ZenToggleChip(
                  label: 'INGRESO',
                  selected: !isExpense,
                  activeColor: _kSageGreen,
                  onTap: () => setSheetState(() {
                    isExpense = false;
                    category = categoriesFor(selectedAccId, isExpense)
                            .firstOrNull
                            ?.name ??
                        'General';
                  }),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Cantidad
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: _kTextPrim, fontSize: 22),
              decoration: _zenInput(hint: '0.00', label: 'Cantidad (€)'),
            ),
            SizedBox(height: 16),
            // Cuenta
            DropdownButtonFormField<String>(
              initialValue: selectedAccId,
              dropdownColor: _kSurface,
              style: TextStyle(color: _kTextPrim, fontSize: 14),
              decoration: _zenInput(hint: '', label: 'Cuenta'),
              items: vm.accounts.map((a) {
                final typeName = switch (a.type) {
                  'Bank'       => 'Banco',
                  'Investment' => 'Inversión',
                  'Cash'       => 'Efectivo',
                  _            => a.type,
                };
                return DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.name} ($typeName)'),
                );
              }).toList(),
              onChanged: (v) => setSheetState(() {
                selectedAccId = v;
                category = categoriesFor(v, isExpense).firstOrNull?.name ??
                    'General';
              }),
            ),
            SizedBox(height: 20),
            // Categorías
            Text(
              'CATEGORÍA',
              style: TextStyle(
                color: _kTextSec,
                fontSize: 9,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoriesFor(selectedAccId, isExpense).map((c) {
                final isSelected = category == c.name;
                return GestureDetector(
                  onTap: () => setSheetState(() => category = c.name),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? _kTextPrim.withValues(alpha: 0.35)
                            : _kDivider,
                      ),
                    ),
                    child: Text(
                      '${c.icon} ${c.name.toUpperCase()}',
                      style: TextStyle(
                        color: isSelected ? _kTextPrim : _kTextSec,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            // Nota
            TextField(
              controller: noteCtrl,
              style: TextStyle(color: _kTextPrim, fontSize: 14),
              decoration: _zenInput(hint: 'Nota (opcional)'),
            ),
          ],
        ),
      ),
    );
  }


  void showCreateTransfer(BuildContext context, FinanceViewModel vm) {
    final amountCtrl = TextEditingController();
    final noteCtrl   = TextEditingController();
    String? fromId   = vm.accounts.first.id;
    String? toId     = vm.accounts.length > 1 ? vm.accounts[1].id : null;

    showAdaptiveModal<void>(
      context,
      StatefulBuilder(
        builder: (ctx, setSheetState) => ZenSheet(
          title: 'Transferir',
          ctx: ctx,
          onCancel: () => Navigator.pop(ctx),
          onConfirm: () {
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
          confirmLabel: 'TRANSFERIR',
          children: [
            DropdownButtonFormField<String>(
              initialValue: fromId,
              dropdownColor: _kSurface,
              style: TextStyle(color: _kTextPrim, fontSize: 14),
              decoration: _zenInput(hint: '', label: 'Desde'),
              items: vm.accounts.map((a) {
                final typeName = switch (a.type) {
                  'Bank'       => 'Banco',
                  'Investment' => 'Inversión',
                  'Cash'       => 'Efectivo',
                  _            => a.type,
                };
                return DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.name} ($typeName)'),
                );
              }).toList(),
              onChanged: (v) => setSheetState(() => fromId = v),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: toId,
              dropdownColor: _kSurface,
              style: TextStyle(color: _kTextPrim, fontSize: 14),
              decoration: _zenInput(hint: '', label: 'Hacia'),
              items: vm.accounts.map((a) {
                final typeName = switch (a.type) {
                  'Bank'       => 'Banco',
                  'Investment' => 'Inversión',
                  'Cash'       => 'Efectivo',
                  _            => a.type,
                };
                return DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.name} ($typeName)'),
                );
              }).toList(),
              onChanged: (v) => setSheetState(() => toId = v),
            ),
            SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: _kTextPrim, fontSize: 22),
              decoration: _zenInput(hint: '0.00', label: 'Cantidad (€)'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              style: TextStyle(color: _kTextPrim, fontSize: 14),
              decoration: _zenInput(hint: 'Nota (opcional)'),
            ),
          ],
        ),
      ),
    );
  }


  void showManageCategories(BuildContext context, FinanceViewModel vm) {
    showAdaptiveModal<void>(
      context,
      StatefulBuilder(
        builder: (ctx, setSheetState) => ZenSheet(
          title: 'Categorías',
          ctx: ctx,
          onCancel: () => Navigator.pop(ctx),
          children: [
            SizedBox(
              height: 260,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: vm.categories.length,
                itemBuilder: (context, index) {
                  final cat = vm.categories[index];
                  return _ZenCategoryRow(
                    cat: cat,
                    onDelete: () async {
                      await vm.deleteCategory(cat.id);
                      setSheetState(() {});
                    },
                  );
                },
              ),
            ),
            Container(
              height: 1,
              color: _kDivider,
              margin: EdgeInsets.symmetric(vertical: 16),
            ),
            Text(
              'NUEVA CATEGORÍA',
              style: TextStyle(
                color: _kTextSec,
                fontSize: 9,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
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
    );
  }
