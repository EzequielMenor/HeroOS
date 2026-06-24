import 'package:flutter/foundation.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/habit_log_entity.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/sleep_log_entity.dart';
import '../../domain/entities/user_goals_entity.dart';
import '../../domain/entities/rpg_event_entity.dart';
import '../../domain/entities/profile_entity.dart';

/// Repositorio en memoria para modo desarrollador.
/// Cuando [AuthRepository.devQuickAccess] está activo, los viewmodels
/// usan esta clase en vez de los repositorios de Supabase.
/// Los datos se pierden al reiniciar — es solo para desarrollo.
class DevRepository {
  static final DevRepository _instance = DevRepository._();
  factory DevRepository() => _instance;
  DevRepository._();

  bool get isActive => kDebugMode;

  int _nextId = 1;
  String _genId() => 'dev_${_nextId++}';

  // ── In-memory stores ──
  final List<HabitEntity> _habits = [];
  final List<HabitLogEntity> _habitLogs = [];
  final List<AccountEntity> _accounts = [];
  final List<TransactionEntity> _transactions = [];
  final List<CategoryEntity> _categories = [];
  final List<TaskEntity> _tasks = [];
  final List<SleepLogEntity> _sleepLogs = [];
  UserGoalsEntity? _goals;
  ProfileEntity? _profile;
  final List<RpgEventEntity> _rpgEvents = [];

  // ── Habits ──
  List<HabitEntity> getHabits() => List.from(_habits);

  Future<void> createHabit(HabitEntity h) async {
    _habits.add(HabitEntity(
      id: _genId(),
      userId: 'dev-user',
      title: h.title,
      frequencyMask: h.frequencyMask,
      xpReward: h.xpReward,
      dmgPenalty: h.dmgPenalty,
      currentStreak: 0,
      isArchived: false,
    ));
  }

  Future<void> updateHabit(HabitEntity h) async {
    final idx = _habits.indexWhere((e) => e.id == h.id);
    if (idx != -1) _habits[idx] = h;
  }

  Future<void> archiveHabit(String habitId) async {
    _habits.removeWhere((e) => e.id == habitId);
  }

  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((e) => e.id == habitId);
  }

  // ── Habit Logs ──
  List<String> getCompletedHabitIds(DateTime date) {
    return _habitLogs
        .where((l) =>
            l.date.year == date.year &&
            l.date.month == date.month &&
            l.date.day == date.day)
        .map((l) => l.habitId)
        .toList();
  }

  Future<void> logHabitCompletion(String habitId, DateTime date) async {
    _habitLogs.add(HabitLogEntity(
      id: _genId(),
      habitId: habitId,
      date: date,
      status: 'completed',
    ));
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx != -1) {
      final h = _habits[idx];
      _habits[idx] = h.copyWith(currentStreak: h.currentStreak + 1);
    }
  }

  Future<void> uncompleteHabitLog(String habitId, DateTime date) async {
    _habitLogs.removeWhere((l) =>
        l.habitId == habitId &&
        l.date.year == date.year &&
        l.date.month == date.month &&
        l.date.day == date.day);
  }

  List<HabitLogEntity> getHabitLogsInRange(DateTime from, DateTime to) {
    return _habitLogs
        .where((l) =>
            l.date.isAfter(from.subtract(const Duration(days: 1))) &&
            l.date.isBefore(to.add(const Duration(days: 1))))
        .toList();
  }

  // ── Tasks ──
  List<TaskEntity> getTasks() => List.from(_tasks);

  Future<void> createTask(TaskEntity t) async {
    _tasks.add(TaskEntity(
      id: _genId(),
      userId: 'dev-user',
      title: t.title,
      isDone: false,
      dueDate: t.dueDate,
      difficulty: t.difficulty,
    ));
  }

  Future<void> updateTask(TaskEntity t) async {
    final idx = _tasks.indexWhere((e) => e.id == t.id);
    if (idx != -1) _tasks[idx] = t;
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((e) => e.id == taskId);
  }

  Future<void> completeTask(String taskId) async {
    final idx = _tasks.indexWhere((e) => e.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(isDone: true);
    }
  }

  Future<void> uncompleteTask(String taskId) async {
    final idx = _tasks.indexWhere((e) => e.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(isDone: false);
    }
  }

  // ── Finance: Accounts ──
  List<AccountEntity> getAccounts() => List.from(_accounts);

  Future<void> createAccount(AccountEntity a) async {
    _accounts.add(AccountEntity(
      id: _genId(),
      userId: 'dev-user',
      name: a.name,
      type: a.type,
      currency: a.currency,
      balance: a.balance,
    ));
  }

  Future<void> updateAccount(AccountEntity a) async {
    final idx = _accounts.indexWhere((e) => e.id == a.id);
    if (idx != -1) _accounts[idx] = a;
  }

  Future<void> deleteAccount(String accountId) async {
    _accounts.removeWhere((e) => e.id == accountId);
  }

  // ── Finance: Transactions ──
  List<TransactionEntity> getTransactions({String? accountId}) {
    if (accountId != null) {
      return _transactions.where((t) => t.accountId == accountId).toList();
    }
    return List.from(_transactions);
  }

  Future<void> createTransaction(TransactionEntity t) async {
    _transactions.add(TransactionEntity(
      id: _genId(),
      accountId: t.accountId,
      amount: t.amount,
      category: t.category,
      note: t.note,
      date: t.date,
      userId: 'dev-user',
    ));
    // Update account balance
    final accIdx = _accounts.indexWhere((a) => a.id == t.accountId);
    if (accIdx != -1) {
      final acc = _accounts[accIdx];
      _accounts[accIdx] = AccountEntity(
        id: acc.id,
        userId: acc.userId,
        name: acc.name,
        type: acc.type,
        currency: acc.currency,
        balance: acc.balance + t.amount,
      );
    }
  }

  Future<void> deleteTransaction(String txId) async {
    final tx = _transactions.firstWhere((t) => t.id == txId);
    _transactions.removeWhere((e) => e.id == txId);
    // Revert account balance
    final accIdx = _accounts.indexWhere((a) => a.id == tx.accountId);
    if (accIdx != -1) {
      final acc = _accounts[accIdx];
      _accounts[accIdx] = AccountEntity(
        id: acc.id,
        userId: acc.userId,
        name: acc.name,
        type: acc.type,
        currency: acc.currency,
        balance: acc.balance - tx.amount,
      );
    }
  }

  // ── Transfers ──
  Future<void> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? note,
  }) async {
    // Remove from source
    final fromIdx = _accounts.indexWhere((a) => a.id == fromAccountId);
    if (fromIdx != -1) {
      final acc = _accounts[fromIdx];
      _accounts[fromIdx] = AccountEntity(
        id: acc.id, userId: acc.userId, name: acc.name,
        type: acc.type, currency: acc.currency,
        balance: acc.balance - amount,
      );
    }
    // Add to destination
    final toIdx = _accounts.indexWhere((a) => a.id == toAccountId);
    if (toIdx != -1) {
      final acc = _accounts[toIdx];
      _accounts[toIdx] = AccountEntity(
        id: acc.id, userId: acc.userId, name: acc.name,
        type: acc.type, currency: acc.currency,
        balance: acc.balance + amount,
      );
    }
    _transactions.add(TransactionEntity(
      id: _genId(), accountId: fromAccountId, amount: -amount,
      category: 'Transferencia', note: note ?? 'Transferencia',
      date: DateTime.now(), userId: 'dev-user',
    ));
    _transactions.add(TransactionEntity(
      id: _genId(), accountId: toAccountId, amount: amount,
      category: 'Transferencia', note: note ?? 'Transferencia',
      date: DateTime.now(), userId: 'dev-user',
    ));
  }

  // ── Finance: Categories ──
  List<CategoryEntity> getCategories() => List.from(_categories);

  Future<void> createCategory(CategoryEntity c) async {
    _categories.add(CategoryEntity(
      id: _genId(),
      userId: 'dev-user',
      name: c.name,
      icon: c.icon,
      isExpense: c.isExpense,
      accountType: c.accountType,
      isDefault: c.isDefault,
    ));
  }

  Future<void> updateCategory(CategoryEntity c) async {
    final idx = _categories.indexWhere((e) => e.id == c.id);
    if (idx != -1) _categories[idx] = c;
  }

  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((e) => e.id == categoryId);
  }

  // ── Sleep ──
  List<SleepLogEntity> getSleepLogs() => List.from(_sleepLogs);

  SleepLogEntity? getTodayLog() {
    final today = DateTime.now();
    try {
      return _sleepLogs.firstWhere((s) =>
          s.startTime.year == today.year &&
          s.startTime.month == today.month &&
          s.startTime.day == today.day);
    } catch (_) {
      return null;
    }
  }

  Future<void> createSleepLog(SleepLogEntity log) async {
    _sleepLogs.add(SleepLogEntity(
      id: _genId(),
      userId: 'dev-user',
      startTime: log.startTime,
      endTime: log.endTime,
      totalHours: log.totalHours,
      deepSleepPct: log.deepSleepPct,
      lightSleepPct: log.lightSleepPct,
      remSleepPct: log.remSleepPct,
      qualityRating: log.qualityRating,
      notes: log.notes,
      avgHeartRate: log.avgHeartRate,
    ));
  }

  Future<void> updateSleepLog(SleepLogEntity log) async {
    final idx = _sleepLogs.indexWhere((e) => e.id == log.id);
    if (idx != -1) _sleepLogs[idx] = log;
  }

  Future<void> deleteSleepLog(String logId) async {
    _sleepLogs.removeWhere((e) => e.id == logId);
  }

  // ── Goals ──
  UserGoalsEntity? getGoals() => _goals;

  Future<void> saveGoals(UserGoalsEntity g) async {
    _goals = g;
  }

  // ── Profile ──
  ProfileEntity getProfile() {
    _profile ??= ProfileEntity(
      id: 'dev-user',
      username: 'Héroe Dev',
      level: 1,
      currentXp: 0,
      xpNextLevel: 100,
      currentHp: 100,
      maxHp: 100,
      currentGold: 0,
    );
    return _profile!;
  }

  Future<void> updateProfile(ProfileEntity p) async {
    _profile = p;
  }

  Future<void> updateAvatarUrl(String url) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(avatarUrl: url);
    }
  }

  // ── RPG Events ──
  List<RpgEventEntity> getRpgEvents({int limit = 20}) =>
      _rpgEvents.take(limit).toList();

  List<RpgEventEntity> getRecentEvents({int limit = 20}) => getRpgEvents(limit: limit);

  Future<void> log(RpgEventType type, int amount, String description) async {
    _rpgEvents.add(RpgEventEntity(
      id: _genId(),
      userId: 'dev-user',
      type: type,
      amount: amount,
      description: description,
      createdAt: DateTime.now(),
    ));
  }

  /// Limpia todos los datos (útil para resetear entre sesiones dev).
  void clearAll() {
    _habits.clear();
    _habitLogs.clear();
    _accounts.clear();
    _transactions.clear();
    _categories.clear();
    _tasks.clear();
    _sleepLogs.clear();
    _goals = null;
    _rpgEvents.clear();
    _nextId = 1;
  }
}
