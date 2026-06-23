import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/adaptive_modal.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/task_entity.dart';
import '../viewmodels/tasks_viewmodel.dart';

/// Pantalla de Tareas (Misiones) — vista lista + calendario.
/// En web muestra ambos lados simultáneamente (split-panel).
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _showCalendar = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksViewModel>().loadTasks();
    });
  }

  Map<DateTime, List<TaskEntity>> _groupByDay(List<TaskEntity> tasks) {
    final map = <DateTime, List<TaskEntity>>{};
    for (final t in tasks) {
      if (t.dueDate == null) continue;
      final key = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  List<TaskEntity> _tasksForDay(
    DateTime day,
    Map<DateTime, List<TaskEntity>> grouped,
  ) {
    final key = DateTime(day.year, day.month, day.day);
    return grouped[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TasksViewModel>();

    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.rpg),
      );
    }

    if (context.isWeb) {
      return _buildWebLayout(vm);
    }
    return _buildMobileLayout(vm);
  }

  // ── WEB: split panel ────────────────────────────────────────────────────────

  Widget _buildWebLayout(TasksViewModel vm) {
    final grouped = _groupByDay(vm.tasks);
    final selectedTasks = _tasksForDay(_selectedDay, grouped);
    final unscheduled = vm.tasks.where((t) => t.dueDate == null && !t.isDone).toList();

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: calendar
          SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: _buildCalendarWidget(vm, grouped),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          // Right: task list for selected day
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '⚔️ ${DateFormat('EEEE d MMMM', 'es').format(_selectedDay)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      if (selectedTasks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            'Sin misiones para este día.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        ...selectedTasks.map((t) => _TaskTile(task: t, vm: vm)),
                      if (unscheduled.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            '📥 Sin fecha asignada',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...unscheduled.map((t) => _TaskTile(task: t, vm: vm)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.rpg,
        onPressed: () => _showCreateSheet(context, vm),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── MOBILE: toggle lista/calendario ────────────────────────────────────────

  Widget _buildMobileLayout(TasksViewModel vm) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _ViewToggle(
                  icon: Icons.list,
                  label: 'Lista',
                  isActive: !_showCalendar,
                  onTap: () => setState(() => _showCalendar = false),
                ),
                const SizedBox(width: 8),
                _ViewToggle(
                  icon: Icons.calendar_month,
                  label: 'Calendario',
                  isActive: _showCalendar,
                  onTap: () => setState(() => _showCalendar = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _showCalendar
                ? _buildCalendarViewMobile(vm)
                : _buildListView(vm),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.rpg,
        onPressed: () => _showCreateSheet(context, vm),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Shared widgets ──────────────────────────────────────────────────────────

  Widget _buildListView(TasksViewModel vm) {
    if (vm.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.explore_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              '¡Sin misiones activas!\nCrea tu primera quest.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (vm.pendingTasks.isNotEmpty) ...[
          const _SectionHeader('⚔️ Pendientes'),
          ...vm.pendingTasks.map((t) => _TaskTile(task: t, vm: vm)),
        ],
        if (vm.doneTasks.isNotEmpty) ...[
          const _SectionHeader('✅ Completadas'),
          ...vm.doneTasks.map((t) => _TaskTile(task: t, vm: vm)),
        ],
      ],
    );
  }

  Widget _buildCalendarViewMobile(TasksViewModel vm) {
    final grouped = _groupByDay(vm.tasks);
    final selectedTasks = _tasksForDay(_selectedDay, grouped);
    final unscheduled = vm.tasks
        .where((t) => t.dueDate == null && !t.isDone)
        .toList();

    return ListView(
      children: [
        _buildCalendarWidget(vm, grouped),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            '⚔️ ${DateFormat('EEEE d MMMM', 'es').format(_selectedDay)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (selectedTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Sin misiones para este día.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          )
        else
          ...selectedTasks.map((t) => _TaskTile(task: t, vm: vm)),
        if (unscheduled.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              '📥 Sin fecha asignada',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...unscheduled.map((t) => _TaskTile(task: t, vm: vm)),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildCalendarWidget(
    TasksViewModel vm,
    Map<DateTime, List<TaskEntity>> grouped,
  ) {
    return TableCalendar<TaskEntity>(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = selected;
          _focusedDay = focused;
        });
      },
      onPageChanged: (focused) => _focusedDay = focused,
      eventLoader: (day) => _tasksForDay(day, grouped),
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: AppColors.textSecondary,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        weekendStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
        weekendTextStyle: const TextStyle(color: AppColors.textPrimary),
        outsideTextStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.4),
        ),
        todayDecoration: BoxDecoration(
          color: AppColors.rpg.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppColors.rpg,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        markerDecoration: const BoxDecoration(
          color: AppColors.rpg,
          shape: BoxShape.circle,
        ),
        markerSize: 6,
        markersMaxCount: 3,
        markerMargin: const EdgeInsets.symmetric(horizontal: 1),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return null;
          final hasPending = events.any((t) => !t.isDone);
          final hasOverdue = events.any((t) => t.isOverdue);
          final dotColor = hasOverdue
              ? AppColors.danger
              : hasPending
              ? AppColors.rpg
              : Colors.green;
          return Positioned(
            bottom: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                events.length.clamp(0, 3),
                (_) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Modal Crear Tarea ───────────────────────────────────────────────────────

  void _showCreateSheet(BuildContext context, TasksViewModel vm) {
    final titleCtrl = TextEditingController();
    int difficulty = 1;
    // En web el calendario siempre está visible → preasignar día seleccionado
    DateTime? dueDate =
        (context.isWeb || _showCalendar) ? _selectedDay : null;

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
                'Nueva Misión',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ej: Entregar proyecto final',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Dificultad',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: List.generate(3, (i) {
                  final d = i + 1;
                  final labels = ['Fácil', 'Media', 'Difícil'];
                  final isActive = difficulty == d;
                  return ChoiceChip(
                    label: Text(
                      '${labels[i]} (+${d * 10} XP)',
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    selected: isActive,
                    selectedColor: AppColors.rpg,
                    backgroundColor: AppColors.scaffold,
                    onSelected: (_) => setSheetState(() => difficulty = d),
                  );
                }),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  dueDate != null
                      ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                      : 'Fecha límite (opcional)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate:
                        dueDate ??
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setSheetState(() => dueDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.rpg,
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    vm.createTask(
                      title: title,
                      difficulty: difficulty,
                      dueDate: dueDate,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Crear Misión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets privados ─────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggle({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.rpg.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.rpg : AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.rpg : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.rpg : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskEntity task;
  final TasksViewModel vm;

  const _TaskTile({required this.task, required this.vm});

  static const _diffColors = [Colors.green, Colors.orange, Colors.redAccent];
  static const _diffLabels = ['Fácil', 'Media', 'Difícil'];

  @override
  Widget build(BuildContext context) {
    final diffIdx = (task.difficulty - 1).clamp(0, 2);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => vm.deleteTask(task.id),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            task.isDone ? Icons.task_alt : Icons.radio_button_unchecked,
            color: task.isDone
                ? AppColors.rpg
                : AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          onPressed: () {
            if (task.isDone) {
              vm.uncompleteTask(task);
            } else {
              vm.completeTask(task);
            }
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: task.isDone
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _diffColors[diffIdx].withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _diffLabels[diffIdx],
                style: TextStyle(
                  color: _diffColors[diffIdx],
                  fontSize: 11,
                ),
              ),
            ),
            Text(
              '+${task.xpValue} XP',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            if (task.dueDate != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: task.isOverdue
                        ? AppColors.danger
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${task.dueDate!.day}/${task.dueDate!.month}',
                    style: TextStyle(
                      color: task.isOverdue
                          ? AppColors.danger
                          : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
          ],
        ),
        onLongPress: task.isDone ? null : () => _showEditSheet(context),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final titleCtrl = TextEditingController(text: task.title);
    int difficulty = task.difficulty;
    DateTime? dueDate = task.dueDate;

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
                'Editar Misión',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Nombre de la misión',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Dificultad',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: List.generate(3, (i) {
                  final d = i + 1;
                  final labels = ['Fácil', 'Media', 'Difícil'];
                  final isActive = difficulty == d;
                  return ChoiceChip(
                    label: Text(
                      '${labels[i]} (+${d * 10} XP)',
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    selected: isActive,
                    selectedColor: AppColors.rpg,
                    backgroundColor: AppColors.scaffold,
                    onSelected: (_) => setSheetState(() => difficulty = d),
                  );
                }),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  dueDate != null
                      ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                      : 'Fecha límite (opcional)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate:
                        dueDate ??
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setSheetState(() => dueDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.rpg,
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    vm.updateTask(
                      task.copyWith(
                        title: title,
                        difficulty: difficulty,
                        dueDate: dueDate,
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
