import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../../domain/entities/task_entity.dart';


class GlobalAddScreen extends StatefulWidget {
  const GlobalAddScreen({super.key});

  @override
  State<GlobalAddScreen> createState() => _GlobalAddScreenState();
}

class _GlobalAddScreenState extends State<GlobalAddScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NUEVO REGISTRO',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accent,
          indicatorWeight: 2,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'NOTA'),
            Tab(text: 'MISIÓN'),
            Tab(text: 'FINANZAS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NoteForm(),
          _TaskForm(),
          _FinanceForm(),
        ],
      ),
    );
  }
}

// ── Form Components ────────────────────────────────────────────────────────

class _ZenInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autoFocus;

  const _ZenInput({required this.controller, required this.hint, this.autoFocus = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autoFocus,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
      ),
    );
  }
}

class _ZenButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ZenButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: AppColors.textPrimary,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.scaffold,
            fontSize: 12,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Tarea ────────────────────────────────────────────────────────

class _TaskForm extends StatefulWidget {
  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _titleCtrl = TextEditingController();
  Energy _energy = Energy.medium;
  DateTime? _dueDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ZenInput(controller: _titleCtrl, hint: 'Nombre de la misión', autoFocus: true),
          const SizedBox(height: 32),
          Text('ENERGÍA', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 2.0)),
          const SizedBox(height: 16),
          Row(
            children: Energy.values.map((e) {
              final labels = ['BAJA', 'MEDIA', 'ALTA'];
              final isActive = _energy == e;
              return GestureDetector(
                onTap: () => setState(() => _energy = e),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: isActive ? AppColors.textPrimary : Colors.transparent, width: 2)),
                    ),
                    child: Text(
                      labels[e.index],
                      style: TextStyle(color: isActive ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: AppColors.accent,
                      onPrimary: Colors.black,
                      surface: AppColors.surface,
                      onSurface: AppColors.textPrimary,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (d != null) setState(() => _dueDate = d);
            },
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  _dueDate != null ? DateFormat('d MMM yyyy', 'es').format(_dueDate!) : 'Añadir fecha límite',
                  style: TextStyle(color: _dueDate != null ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const Spacer(),
          _ZenButton(
            label: 'CREAR MISIÓN',
            onTap: () {
              if (_titleCtrl.text.isEmpty) return;
              context.read<TasksViewModel>().createTask(
                title: _titleCtrl.text.trim(),
                energy: _energy,
                dueDate: _dueDate,
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}



// ── Finanzas ────────────────────────────────────────────────────────

class _FinanceForm extends StatefulWidget {
  @override
  State<_FinanceForm> createState() => _FinanceFormState();
}

class _FinanceFormState extends State<_FinanceForm> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isIncome = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isIncome = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: !_isIncome ? AppColors.danger : AppColors.divider, width: 2)),
                    ),
                    child: Text('GASTO', style: TextStyle(color: !_isIncome ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 12)),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isIncome = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _isIncome ? AppColors.habits : AppColors.divider, width: 2)),
                    ),
                    child: Text('INGRESO', style: TextStyle(color: _isIncome ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: GoogleFonts.inter(color: _isIncome ? AppColors.habits : AppColors.danger, fontSize: 48, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.3), fontSize: 48),
              border: InputBorder.none,
              prefixText: '€ ',
              prefixStyle: GoogleFonts.inter(color: _isIncome ? AppColors.habits : AppColors.danger, fontSize: 48),
            ),
          ),
          const SizedBox(height: 16),
          _ZenInput(controller: _noteCtrl, hint: 'Concepto (ej. Comida, Sueldo)'),
          const Spacer(),
          _ZenButton(
            label: 'AÑADIR TRANSACCIÓN',
            onTap: () {
              final amountStr = _amountCtrl.text.replaceAll(',', '.');
              final amount = double.tryParse(amountStr) ?? 0.0;
              if (amount <= 0 || _noteCtrl.text.isEmpty) return;
              final vm = context.read<FinanceViewModel>();
              if (vm.accounts.isEmpty) return; // Need an account
              vm.addTransaction(
                accountId: vm.accounts.first.id,
                amount: _isIncome ? amount : -amount,
                note: _noteCtrl.text.trim(),
                category: 'General',
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ── Notas ────────────────────────────────────────────────────────

class _NoteForm extends StatefulWidget {
  @override
  State<_NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<_NoteForm> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ZenInput(controller: _titleCtrl, hint: 'Título de la nota', autoFocus: true),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              expands: true,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.6),
              decoration: InputDecoration(
                hintText: 'Empieza a escribir...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
          _ZenButton(
            label: 'GUARDAR NOTA',
            onTap: () {
              if (_titleCtrl.text.isEmpty) return;
              context.read<NotesViewModel>().createNote(
                title: _titleCtrl.text.trim(),
                content: _contentCtrl.text,
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

