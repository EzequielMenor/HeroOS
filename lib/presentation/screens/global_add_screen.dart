import 'package:flutter/material.dart';
import '../widgets/zen_glass.dart';
import '../widgets/zen_solid_card.dart';
import '../widgets/glass_input.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../viewmodels/habits_viewmodel.dart';
import '../viewmodels/notes_viewmodel.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/glass_action_button.dart';
import '../viewmodels/quick_capture_viewmodel.dart';

void showGlobalAdd(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    barrierDismissible: true,
    builder: (_) => const GlobalAddScreen(),
  );
}

/// Lightweight account summary for the picker.
class AccountSummary {
  final String id;
  final String name;
  final String type;
  const AccountSummary({
    required this.id,
    required this.name,
    required this.type,
  });
}

/// Phase 1: Initial state with 3 glass action buttons.
class _PhaseOne extends StatelessWidget {
  final void Function(CaptureMode) onSelectMode;
  final VoidCallback onClose;

  const _PhaseOne({required this.onSelectMode, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: title + close button
          Row(
            children: [
              Expanded(
                child: Text(
                  'CAPTURA RÁPIDA',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Three action buttons stacked vertically
          GlassActionButton(
            icon: Icons.check_circle_outline,
            label: 'Nueva Misión',
            iconColor: AppColors.tasks,
            onTap: () => onSelectMode(CaptureMode.mission),
          ),
          const SizedBox(height: 8),
          GlassActionButton(
            icon: Icons.attach_money,
            label: 'Registrar Gasto',
            iconColor: AppColors.finance,
            onTap: () => onSelectMode(CaptureMode.expense),
          ),
          const SizedBox(height: 8),
          GlassActionButton(
            icon: Icons.edit_note,
            label: 'Apunte Rápido',
            iconColor: AppColors.textSecondary,
            onTap: () => onSelectMode(CaptureMode.note),
          ),
        ],
      ),
    );
  }
}

/// Phase 2: Expanded form with mode-specific fields.
class _PhaseTwo extends StatefulWidget {
  final CaptureMode mode;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onClose;
  final bool isSaving;
  final List<AccountSummary> accounts;

  const _PhaseTwo({
    super.key,
    required this.mode,
    required this.onBack,
    required this.onSave,
    required this.onClose,
    required this.isSaving,
    required this.accounts,
  });

  @override
  State<_PhaseTwo> createState() => _PhaseTwoState();
}

class _PhaseTwoState extends State<_PhaseTwo> {
  late final TextEditingController _primaryController;
  late final TextEditingController _secondaryController;
  late final FocusNode _primaryFocusNode;
  bool _isExpense = true;
  String? _selectedAccountId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _primaryController = TextEditingController();
    _secondaryController = TextEditingController();
    _primaryFocusNode = FocusNode();

    // Default to first account if available
    if (widget.accounts.isNotEmpty) {
      _selectedAccountId = widget.accounts.first.id;
    }

    // Auto-focus the primary field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primaryFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _primaryFocusNode.dispose();
    super.dispose();
  }

  String get _title {
    return switch (widget.mode) {
      CaptureMode.mission => 'Nueva Misión',
      CaptureMode.expense => 'Registrar Gasto',
      CaptureMode.note => 'Apunte Rápido',
    };
  }

  String get _primaryHint {
    return switch (widget.mode) {
      CaptureMode.mission => '¿Qué tienes que hacer?',
      CaptureMode.expense => '¿En qué gastaste?',
      CaptureMode.note => 'Escribe tu apunte...',
    };
  }

  String get _secondaryHint {
    return switch (widget.mode) {
      CaptureMode.mission => 'Fecha límite (opcional)',
      CaptureMode.expense => 'Cantidad (€)',
      CaptureMode.note => 'Tags separados por coma',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back and close buttons
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.isSaving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.habits,
                      strokeWidth: 2,
                    ),
                  )
                else
                  InkWell(
                    onTap: widget.onSave,
                    child: const Text(
                      'GUARDAR',
                      style: TextStyle(
                        color: AppColors.scaffold,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                // Close button
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Expense/Income toggle (expense mode only)
            if (widget.mode == CaptureMode.expense) ...[
              Row(
                children: [
                  _ExpenseToggle(
                    label: 'GASTO',
                    isActive: _isExpense,
                    activeColor: AppColors.danger,
                    onTap: () => setState(() => _isExpense = true),
                  ),
                  const SizedBox(width: 10),
                  _ExpenseToggle(
                    label: 'INGRESO',
                    isActive: !_isExpense,
                    activeColor: AppColors.habits,
                    onTap: () => setState(() => _isExpense = false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Account selector
              _AccountSelector(
                accounts: widget.accounts,
                selectedId: _selectedAccountId,
                onTap: _showAccountPicker,
              ),
              const SizedBox(height: 12),
            ],

            // Primary field
            GlassInput(
              controller: _primaryController,
              focusNode: _primaryFocusNode,
              hint: _primaryHint,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Secondary field - mode-specific
            if (widget.mode == CaptureMode.expense) ...[
              // Amount field for expense
              GlassInput(
                controller: _secondaryController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                hint: _secondaryHint,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => widget.onSave(),
              ),
            ] else if (widget.mode == CaptureMode.mission) ...[
              // Date picker for mission
              _DatePickerField(
                date: _selectedDate,
                onTap: _showDatePicker,
                onClear: () {
                  setState(() {
                    _selectedDate = null;
                    _secondaryController.clear();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get primaryText => _primaryController.text.trim();
  String get secondaryText => _secondaryController.text.trim();
  String? get selectedAccountId => _selectedAccountId;
  DateTime? get selectedDate => _selectedDate;
  bool get isExpense => _isExpense;

  /// Show account picker bottom sheet.
  Future<void> _showAccountPicker() async {
    if (widget.accounts.isEmpty) return;
    HapticFeedback.lightImpact();

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ZenGlass(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Text(
                      'CUENTA',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ...widget.accounts.map((acc) {
                final isActive = acc.id == _selectedAccountId;
                final typeName = switch (acc.type) {
                  'Bank' => 'Banco',
                  'Investment' => 'Inversión',
                  'Cash' => 'Efectivo',
                  _ => acc.type,
                };
                return GestureDetector(
                  onTap: () => Navigator.pop(ctx, acc.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.habits.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: isActive
                              ? AppColors.habits
                              : AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            acc.name,
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.habits
                                  : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          typeName,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check, color: AppColors.habits, size: 16),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedAccountId = selected;
      });
    }
  }

  /// Show date picker for mission due date.
  Future<void> _showDatePicker() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.habits,
            onPrimary: Colors.black,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        // Also update the secondary field text to show the date
        _secondaryController.text = DateFormat(
          'd MMM yyyy',
          'es',
        ).format(picked);
      });
    }
  }
}

class _ExpenseToggle extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ExpenseToggle({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Account selector field for the expense mode.
class _AccountSelector extends StatelessWidget {
  final List<AccountSummary> accounts;
  final String? selectedId;
  final VoidCallback onTap;

  const _AccountSelector({
    required this.accounts,
    required this.selectedId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = accounts.where((a) => a.id == selectedId).firstOrNull;
    final label = selected?.name ?? 'Seleccionar cuenta';

    return GestureDetector(
      onTap: accounts.isEmpty ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: selected != null
                  ? AppColors.habits
                  : AppColors.textSecondary.withValues(alpha: 0.5),
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (accounts.isEmpty)
              Text(
                'Sin cuentas',
                style: TextStyle(
                  color: AppColors.danger.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              )
            else
              Icon(
                Icons.arrow_drop_down,
                color: AppColors.textSecondary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

/// Date picker field for mission mode. Tappable to show calendar.
class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DatePickerField({
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: date != null
                  ? AppColors.habits
                  : AppColors.textSecondary.withValues(alpha: 0.5),
              size: 15,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('d MMM yyyy', 'es').format(date!)
                    : 'Fecha límite (opcional)',
                style: TextStyle(
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              )
            else
              Icon(
                Icons.arrow_drop_down,
                color: AppColors.textSecondary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

/// Global Add Screen - Two-phase quick capture with glass morphism.
class GlobalAddScreen extends StatefulWidget {
  const GlobalAddScreen({super.key});

  @override
  State<GlobalAddScreen> createState() => _GlobalAddScreenState();
}

class _GlobalAddScreenState extends State<GlobalAddScreen> {
  CaptureMode? _selectedMode;
  bool _isSaving = false;
  final _phaseTwoKey = GlobalKey<_PhaseTwoState>();

  @override
  void initState() {
    super.initState();
    // Pre-load accounts in case the user selects expense mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FinanceViewModel>().loadAll();
      }
    });
  }

  void _selectMode(CaptureMode mode) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMode = mode;
    });
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _goBack() {
    setState(() {
      _selectedMode = null;
    });
  }

  Future<void> _save() async {
    if (_selectedMode == null) return;

    final phaseTwoState = _phaseTwoKey.currentState;
    if (phaseTwoState == null) return;

    final primaryText = phaseTwoState.primaryText;
    if (primaryText.isEmpty) return;

    // For expense mode, parse the amount. If user did not provide one, default to 0.
    double? expenseAmount;
    if (_selectedMode == CaptureMode.expense &&
        phaseTwoState.secondaryText.isNotEmpty) {
      expenseAmount =
          double.tryParse(phaseTwoState.secondaryText.replaceAll(',', '.')) ??
          0.0;
    }

    setState(() => _isSaving = true);

    try {
      final qcVm = Provider.of<QuickCaptureViewModel>(context, listen: false);
      final financeVm = Provider.of<FinanceViewModel>(context, listen: false);

      // For expense mode, make sure accounts are loaded
      if (_selectedMode == CaptureMode.expense && financeVm.accounts.isEmpty) {
        await financeVm.loadAll();
      }

      // For expense mode, the `primaryText` is the note (description),
      // and the amount goes separately in its own field.
      // This keeps the note clean (no "€12.50" appended).
      await qcVm.captureByMode(
        _selectedMode!,
        primaryText,
        accountId: phaseTwoState.selectedAccountId,
        dueDate: phaseTwoState.selectedDate,
        isIncome:
            _selectedMode == CaptureMode.expense && !phaseTwoState.isExpense,
        amount: expenseAmount,
      );

      if (!mounted) return;

      if (qcVm.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${qcVm.error}'),
            backgroundColor: AppColors.danger,
          ),
        );
      } else {
        // Refresh viewmodels
        Provider.of<TasksViewModel>(context, listen: false).loadTasks();
        Provider.of<FinanceViewModel>(context, listen: false).loadAll();
        Provider.of<HabitsViewModel>(context, listen: false).loadHabits();
        Provider.of<NotesViewModel>(context, listen: false).loadNotes();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(qcVm.lastResult ?? 'Guardado con éxito'),
            backgroundColor: AppColors.habits,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load accounts if needed and convert to summary list
    final financeVm = context.watch<FinanceViewModel>();
    final accountSummaries = financeVm.accounts
        .map((a) => AccountSummary(id: a.id, name: a.name, type: a.type))
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ZenGlass(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              child: _selectedMode == null
                  ? _PhaseOne(onSelectMode: _selectMode, onClose: _close)
                  : _PhaseTwo(
                      key: _phaseTwoKey,
                      mode: _selectedMode!,
                      onBack: _goBack,
                      onSave: _save,
                      onClose: _close,
                      isSaving: _isSaving,
                      accounts: accountSummaries,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
