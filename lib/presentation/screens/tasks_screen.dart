import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/task_entity.dart';
import '../viewmodels/tasks_viewmodel.dart';

// ── Paleta Zen OS (local refs) ───────────────────────────────────────────────
Color get _kBg => AppColors.scaffold;
             // #060606
Color get _kTextPrimary => AppColors.textPrimary;
 // #F0EDE8
Color get _kTextSecondary => AppColors.textSecondary;
 // rgba bone 45%
Color get _kDivider => AppColors.divider;
         // rgba white 5%
Color get _kAccent => AppColors.accent;
        // #8FBC8F
Color get _kDanger => AppColors.danger;
           // #F44336

/// Pantalla de Tareas — diseño Zen OS consistente con el resto de pantallas.
/// Web: split-panel. Mobile: toggle lista/calendario con SafeArea.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _showCalendar = false;

  // Filtros: 0=Abiertas, 1=Hechas, 2=Todas
  int _filterIndex = 0;

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

  List<TaskEntity> _filteredTasks(TasksViewModel vm) {
    switch (_filterIndex) {
      case 0:
        return vm.pendingTasks;
      case 1:
        return vm.doneTasks;
      default:
        return vm.tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TasksViewModel>();

    if (vm.isLoading) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: _kAccent,
              strokeWidth: 1.5,
            ),
          ),
        ),
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
    final unscheduled =
        vm.tasks.where((t) => t.dueDate == null && !t.isDone).toList();

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: calendario
              SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE d MMMM', 'es')
                                  .format(DateTime.now())
                                  .toUpperCase(),
                              style: TextStyle(
                                color: _kTextSecondary,
                                fontSize: 9,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Misiones',
                                  style: GoogleFonts.inter(
                                    color: _kTextPrimary,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                                ),
                                Spacer(),
                                GestureDetector(
                                  onTap: () => showTaskCreateSheet(context, vm, initialDate: _selectedDay),
                                  child: Icon(Icons.add, size: 18, color: _kTextSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildCalendarWidget(vm, grouped),
                    ],
                  ),
                ),
              ),
              // Divisor vertical
              Container(width: 1, color: _kDivider),
              // Right: lista del día seleccionado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Text(
                        DateFormat('EEEE d MMMM', 'es')
                            .format(_selectedDay)
                            .toUpperCase(),
                        style: TextStyle(
                          color: _kTextSecondary,
                          fontSize: 9,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(bottom: 100),
                        children: [
                          if (selectedTasks.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Text(
                                'Sin misiones para este día.',
                                style: TextStyle(
                                  color: _kTextSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          else
                            ...selectedTasks
                                .map((t) => _TaskTile(task: t, vm: vm)),
                          if (unscheduled.isNotEmpty) ...[
                            SizedBox(height: 8),
                            _ZenSectionLabel('SIN FECHA'),
                            ...unscheduled
                                .map((t) => _TaskTile(task: t, vm: vm)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── MOBILE ──────────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(TasksViewModel vm) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE d MMMM', 'es')
                            .format(DateTime.now())
                            .toUpperCase(),
                        style: TextStyle(
                          color: _kTextSecondary,
                          fontSize: 9,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Misiones',
                            style: GoogleFonts.inter(
                              color: _kTextPrimary,
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () => showTaskCreateSheet(context, vm, initialDate: _selectedDay),
                            child: Icon(Icons.add, size: 18, color: _kTextSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // ── Toggles Vista ────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _ZenViewToggle(
                        label: 'LISTA',
                        isActive: !_showCalendar,
                        onTap: () => setState(() => _showCalendar = false),
                      ),
                      SizedBox(width: 20),
                      _ZenViewToggle(
                        label: 'CALENDARIO',
                        isActive: _showCalendar,
                        onTap: () => setState(() => _showCalendar = true),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // ── Filtros (solo en lista) ───────────────────────────────────
                if (!_showCalendar) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _ZenFilter(
                          label: 'ABIERTAS',
                          isActive: _filterIndex == 0,
                          onTap: () => setState(() => _filterIndex = 0),
                        ),
                        SizedBox(width: 20),
                        _ZenFilter(
                          label: 'HECHAS',
                          isActive: _filterIndex == 1,
                          onTap: () => setState(() => _filterIndex = 1),
                        ),
                        SizedBox(width: 20),
                        _ZenFilter(
                          label: 'TODAS',
                          isActive: _filterIndex == 2,
                          onTap: () => setState(() => _filterIndex = 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                // Línea divisora
                Container(height: 1, color: _kDivider),
                // ── Contenido ────────────────────────────────────────────────
                Expanded(
                  child: _showCalendar
                      ? _buildCalendarViewMobile(vm)
                      : _buildListView(vm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Vista lista (mobile) ────────────────────────────────────────────────────

  Widget _buildListView(TasksViewModel vm) {
    final tasks = _filteredTasks(vm);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 32, color: _kTextSecondary),
            SizedBox(height: 16),
            Text(
              _filterIndex == 1
                  ? 'Aún no has completado\nninguna misión.'
                  : 'Sin misiones activas.\nCrea tu primera quest.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 100),
      itemCount: tasks.length,
      itemBuilder: (context, i) => _TaskTile(task: tasks[i], vm: vm),
    );
  }

  // ── Vista calendario (mobile) ───────────────────────────────────────────────

  Widget _buildCalendarViewMobile(TasksViewModel vm) {
    final grouped = _groupByDay(vm.tasks);
    final selectedTasks = _tasksForDay(_selectedDay, grouped);
    final unscheduled =
        vm.tasks.where((t) => t.dueDate == null && !t.isDone).toList();

    return ListView(
      padding: EdgeInsets.only(bottom: 100),
      children: [
        _buildCalendarWidget(vm, grouped),
        Container(height: 1, color: _kDivider),
        SizedBox(height: 16),
        _ZenSectionLabel(
          DateFormat('EEEE d MMMM', 'es')
              .format(_selectedDay)
              .toUpperCase(),
        ),
        if (selectedTasks.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Sin misiones para este día.',
              style: TextStyle(color: _kTextSecondary, fontSize: 14),
            ),
          )
        else
          ...selectedTasks.map((t) => _TaskTile(task: t, vm: vm)),
        if (unscheduled.isNotEmpty) ...[
          SizedBox(height: 8),
          Container(height: 1, color: _kDivider),
          _ZenSectionLabel('SIN FECHA'),
          ...unscheduled.map((t) => _TaskTile(task: t, vm: vm)),
        ],
      ],
    );
  }

  // ── Calendario ──────────────────────────────────────────────────────────────

  Widget _buildCalendarWidget(
    TasksViewModel vm,
    Map<DateTime, List<TaskEntity>> grouped,
  ) {
    return TableCalendar<TaskEntity>(
      firstDay: DateTime.now().subtract(Duration(days: 365)),
      lastDay: DateTime.now().add(Duration(days: 365)),
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
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: GoogleFonts.inter(
          color: _kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: _kTextSecondary,
          size: 18,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: _kTextSecondary,
          size: 18,
        ),
        headerPadding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.transparent),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: _kTextSecondary,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
        weekendStyle: TextStyle(
          color: _kTextSecondary,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
      calendarStyle: CalendarStyle(
        tablePadding: EdgeInsets.symmetric(horizontal: 8),
        defaultTextStyle:
            TextStyle(color: _kTextPrimary, fontSize: 13),
        weekendTextStyle:
            TextStyle(color: _kTextPrimary, fontSize: 13),
        outsideTextStyle: TextStyle(
          color: _kTextSecondary.withValues(alpha: 0.35),
          fontSize: 13,
        ),
        disabledTextStyle: TextStyle(
          color: _kTextSecondary.withValues(alpha: 0.2),
          fontSize: 13,
        ),
        todayDecoration: BoxDecoration(
          border: Border.all(color: _kAccent, width: 1),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: _kAccent,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        selectedDecoration: BoxDecoration(
          color: _kAccent,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        markersMaxCount: 3,
        markerSize: 4,
        markerMargin: EdgeInsets.symmetric(horizontal: 1),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return null;
          final hasPending = events.any((t) => !t.isDone);
          final hasOverdue = events.any((t) => t.isOverdue);
          final dotColor = hasOverdue
              ? _kDanger
              : hasPending
                  ? _kAccent
                  : _kAccent.withValues(alpha: 0.5);
          return Positioned(
            bottom: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                events.length.clamp(0, 3),
                (_) => Container(
                  width: 4,
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: 1),
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

}

// ── Widgets privados ─────────────────────────────────────────────────────────

/// Sheet Zen OS: fondo #0B0B0B, borde superior 1px, padding consistente.
class _ZenSheet extends StatelessWidget {
  final String title;
  final String label;
  final Widget child;

  const _ZenSheet({
    required this.title,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        26,
        22,
        MediaQuery.of(context).viewInsets.bottom + 44,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _kTextSecondary,
              fontSize: 9,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.inter(
              color: _kTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}


/// Toggle de vista (Lista / Calendario): texto uppercase con línea blanca.
class _ZenViewToggle extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ZenViewToggle({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? _kTextPrimary : _kTextSecondary,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          SizedBox(height: 4),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: 1.5,
            width: isActive ? 36 : 0,
            color: _kTextPrimary,
          ),
        ],
      ),
    );
  }
}

/// Filtro de texto (Abiertas/Hechas/Todas): uppercase con línea textPrimary.
class _ZenFilter extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ZenFilter({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? _kTextPrimary : _kTextSecondary,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          SizedBox(height: 3),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: 1.5,
            width: isActive ? 28 : 0,
            color: _kTextPrimary,
          ),
        ],
      ),
    );
  }
}

/// Cabecera de sección Zen OS: UPPERCASE 9px letterSpacing 2.0.
class _ZenSectionLabel extends StatelessWidget {
  final String text;
  const _ZenSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          color: _kTextSecondary,
          fontSize: 9,
          letterSpacing: 2.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Tile de tarea: plano, borde inferior ultra fino, sin cards.
class _TaskTile extends StatelessWidget {
  final TaskEntity task;
  final TasksViewModel vm;

  const _TaskTile({required this.task, required this.vm});

  static final _energyLabels = ['Baja', 'Media', 'Alta'];

  @override
  Widget build(BuildContext context) {
    final energyIdx = task.energy?.index ?? 1;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        color: _kDanger,
        child: Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 20,
        ),
      ),
      onDismissed: (_) => vm.deleteTask(task.id),
      child: GestureDetector(
        onLongPress: task.isDone ? null : () => _showEditSheet(context),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _kDivider, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox circular
              GestureDetector(
                onTap: () {
                  if (task.isDone) {
                    vm.uncompleteTask(task);
                  } else {
                    vm.completeTask(task);
                  }
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isDone ? _kAccent : _kTextSecondary,
                      width: 1.5,
                    ),
                    color: task.isDone
                        ? _kAccent.withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  child: task.isDone
                      ? Icon(Icons.check, size: 12, color: _kAccent)
                      : null,
                ),
              ),
              SizedBox(width: 16),
              // Título + metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: task.isDone ? _kTextSecondary : _kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: _kTextSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        // Tappable energy indicator (three bars style)
                        GestureDetector(
                          onTap: task.isDone
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  vm.cycleTaskEnergy(task);
                                },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Three bars energy indicator
                                  _energyBars(energy: task.energy ?? Energy.medium),
                                SizedBox(width: 6),
                                Text(
                                  _energyLabels[energyIdx],
                                  style: TextStyle(
                                    color: _kTextSecondary,
                                    fontSize: 11,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (task.dueDate != null) ...[
                          SizedBox(width: 12),
                          Icon(
                            Icons.schedule_outlined,
                            size: 11,
                            color: task.isOverdue ? _kDanger : _kTextSecondary,
                          ),
                          SizedBox(width: 3),
                          Text(
                            DateFormat('d MMM', 'es').format(task.dueDate!),
                            style: TextStyle(
                              color: task.isOverdue
                                  ? _kDanger
                                  : _kTextSecondary,
                              fontSize: 11,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Three-bar energy indicator widget.
  static final _energyColors = [
    Color(0xFF6DBF6D), // low - green
    Color(0xFFE8A84A), // medium - amber
    Color(0xFFF44336), // high - red
  ];

  /// Energy bars indicator - displays 1, 2, or 3 bars based on energy level.
  static Widget _energyBars({required Energy energy}) {
    final level = energy.index; // 0=low, 1=medium, 2=high
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i <= level;
        return Container(
          width: 3,
          height: 10 + (i * 2), // Increasing height: 10, 12, 14
          margin: EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isActive
                ? _energyColors[level]
                : _kTextSecondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  void _showEditSheet(BuildContext context) {
    final titleCtrl = TextEditingController(text: task.title);
    Energy energy = task.energy ?? Energy.medium;
    DateTime? dueDate = task.dueDate;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _ZenSheet(
          title: 'Editar tarea',
          label: 'EDITAR MISIÓN',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: TextStyle(color: _kTextPrimary, fontSize: 16),
                cursorColor: _kAccent,
                decoration: InputDecoration(
                  hintText: 'Nombre de la misión',
                  hintStyle: TextStyle(color: _kTextSecondary, fontSize: 16),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kDivider, width: 1),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kAccent, width: 1),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'ENERGÍA',
                style: TextStyle(
                  color: _kTextSecondary,
                  fontSize: 9,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: Energy.values.map((e) {
                  final labels = ['Baja', 'Media', 'Alta'];
                  final isActive = energy == e;
                  return Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: _ZenFilter(
                      label: labels[e.index].toUpperCase(),
                      isActive: isActive,
                      onTap: () => setSheetState(() => energy = e),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate:
                        dueDate ?? DateTime.now().add(Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: _kAccent,
                          onPrimary: Colors.black,
                          surface: AppColors.surface,
                          onSurface: _kTextPrimary,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setSheetState(() => dueDate = picked);
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: _kTextSecondary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      dueDate != null
                          ? DateFormat('d MMM yyyy', 'es').format(dueDate!)
                          : 'Fecha límite (opcional)',
                      style: TextStyle(
                        color: dueDate != null ? _kTextPrimary : _kTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              // Botones
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Text(
                      'CANCELAR',
                      style: TextStyle(
                        color: _kTextSecondary,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      vm.updateTask(
                        task.copyWith(
                          title: title,
                          energy: energy,
                          dueDate: dueDate,
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      color: AppColors.textPrimary,
                      child: Text(
                        'GUARDAR',
                        style: TextStyle(
                          color: AppColors.scaffold,
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


  void showTaskCreateSheet(BuildContext context, TasksViewModel vm, {DateTime? initialDate}) {
    final titleCtrl = TextEditingController();
    Energy energy = Energy.medium;
    DateTime? dueDate = initialDate;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _ZenSheet(
          title: 'Crear tarea',
          label: 'NUEVA MISIÓN',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: TextStyle(color: _kTextPrimary, fontSize: 16),
                cursorColor: _kAccent,
                decoration: InputDecoration(
                  hintText: 'Nombre de la misión',
                  hintStyle: TextStyle(color: _kTextSecondary, fontSize: 16),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kDivider, width: 1),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kAccent, width: 1),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              SizedBox(height: 24),
              // Energía
              Text(
                'ENERGÍA',
                style: TextStyle(
                  color: _kTextSecondary,
                  fontSize: 9,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: Energy.values.map((e) {
                  final labels = ['Baja', 'Media', 'Alta'];
                  final isActive = energy == e;
                  return Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: _ZenFilter(
                      label: labels[e.index].toUpperCase(),
                      isActive: isActive,
                      onTap: () => setSheetState(() => energy = e),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24),
              // Fecha límite
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate:
                        dueDate ?? DateTime.now().add(Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: _kAccent,
                          onPrimary: Colors.black,
                          surface: AppColors.surface,
                          onSurface: _kTextPrimary,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setSheetState(() => dueDate = picked);
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: _kTextSecondary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      dueDate != null
                          ? DateFormat('d MMM yyyy', 'es').format(dueDate!)
                          : 'Fecha límite (opcional)',
                      style: TextStyle(
                        color: dueDate != null ? _kTextPrimary : _kTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              // Botones
              Row(
                children: [
                  // Cancel
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Text(
                      'CANCELAR',
                      style: TextStyle(
                        color: _kTextSecondary,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Spacer(),
                  // Add
                  GestureDetector(
                    onTap: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      vm.createTask(
                        title: title,
                        energy: energy,
                        dueDate: dueDate,
                      );
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      color: AppColors.textPrimary,
                      child: Text(
                        'CREAR',
                        style: TextStyle(
                          color: AppColors.scaffold,
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
