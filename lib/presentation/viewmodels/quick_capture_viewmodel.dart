import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/services/ai_service.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/finance_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dev_repository.dart';

/// Capture mode for the two-phase quick capture UI.
enum CaptureMode { mission, expense, note }

/// ViewModel for Quick Capture with async local save + AI processing.
/// Implements race condition handling and API key validation.
class QuickCaptureViewModel extends ChangeNotifier {
  final AiService _aiService = AiService();
  late final dynamic _taskRepo;
  late final dynamic _noteRepo;
  late final dynamic _financeRepo;

  bool _isLoading = false;
  String? _error;
  String? _lastResult;

  /// Map of pending AI requests: entityId -> Completer for race condition handling.
  final Map<String, Completer<void>> _pendingAiRequests = {};

  QuickCaptureViewModel()
      : _taskRepo = AuthRepository.devQuickAccess ? DevRepository() : TaskRepository(),
        _noteRepo = AuthRepository.devQuickAccess ? DevRepository() : NoteRepository(),
        _financeRepo = AuthRepository.devQuickAccess ? DevRepository() : FinanceRepository();

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastResult => _lastResult;

  /// Checks if AI API key is configured.
  Future<bool> _isAiApiKeyConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('ai_api_key');
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Finds a matching category from transaction history based on note/concept similarity.
  /// Deterministic fallback when AI is unavailable.
  Future<String> _findCategoryFromHistory(String note, List<TransactionEntity> history) async {
    if (note.isEmpty || history.isEmpty) return 'General';

    final normalizedNote = note.toLowerCase().trim();

    // Exact match first
    for (final txn in history) {
      if (txn.note?.toLowerCase().trim() == normalizedNote) {
        return txn.category;
      }
    }

    // Keyword-based matching
    final keywords = normalizedNote.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    for (final txn in history.reversed) {
      if (txn.note == null) continue;
      final txnKeywords = txn.note!.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
      final intersection = keywords.intersection(txnKeywords);
      if (intersection.length >= 2) {
        return txn.category;
      }
    }

    return 'General';
  }

  /// Captures by mode with immediate local save and async AI processing.
  /// Returns immediately after local save; AI runs in background.
  Future<void> captureByMode(
    CaptureMode mode,
    String text, {
    String? accountId,
    DateTime? dueDate,
    bool isIncome = false,
    double? amount,
  }) async {
    _isLoading = true;
    _error = null;
    _lastResult = null;
    notifyListeners();

    try {
      final userId = AuthRepository.devQuickAccess
          ? 'dev-user'
          : Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        _error = 'Usuario no disponible';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Immediate local save with pendingAi status
      switch (mode) {
        case CaptureMode.mission:
          await _createTaskImmediate(userId, text, dueDate: dueDate);
          break;
        case CaptureMode.expense:
          await _createExpenseImmediate(
            userId,
            text,
            amount: amount,
            accountId: accountId,
            isIncome: isIncome,
          );
          break;
        case CaptureMode.note:
          await _createNoteImmediate(userId, text);
          break;
      }

      _isLoading = false;
      notifyListeners();

      // AI processing in background (after local save completes)
      _processAiInBackground(mode, text, userId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a task immediately with pendingAi status.
  Future<void> _createTaskImmediate(
    String userId,
    String title, {
    DateTime? dueDate,
  }) async {
    final task = TaskEntity(
      id: '',
      userId: userId,
      title: title,
      energy: Energy.medium,
      dueDate: dueDate,
      syncStatus: SyncStatus.pendingAi,
    );
    await _taskRepo.createTask(task);
    _lastResult = 'Tarea creada';
  }

  /// Creates an expense immediately with pendingAi status.
  Future<void> _createExpenseImmediate(
    String userId,
    String note, {
    double? amount,
    String? accountId,
    bool isIncome = false,
  }) async {
    String targetAccountId = accountId ?? '';

    if (targetAccountId.isEmpty) {
      final accounts = await _financeRepo.getAccounts();
      if (accounts.isNotEmpty) {
        targetAccountId = accounts.first.id;
      } else {
        // Create default account if none exists
        await _financeRepo.createAccount(AccountEntity(
          id: '',
          userId: userId,
          name: 'Principal',
          balance: 0,
          type: 'Cash',
        ));
        final newAccounts = await _financeRepo.getAccounts();
        if (newAccounts.isNotEmpty) {
          targetAccountId = newAccounts.first.id;
        }
      }
    }

    if (targetAccountId.isEmpty) {
      throw Exception('No se pudo obtener ni crear una cuenta bancaria.');
    }

    // Use the explicit amount if provided; otherwise try to extract from text.
    // Default to 0.0 (not -0.0) when no amount is available.
    double rawAmount = amount ?? _extractAmount(note);
    if (rawAmount == 0) {
      rawAmount = 0.0; // ensure no -0.0
    }

    final signedAmount = isIncome ? rawAmount.abs() : -rawAmount.abs();

    final txn = TransactionEntity(
      id: '',
      userId: userId,
      accountId: targetAccountId,
      amount: signedAmount,
      category: 'General',
      note: note,
      date: DateTime.now(),
      syncStatus: SyncStatus.pendingAi,
    );
    await _financeRepo.createTransaction(txn);
    _lastResult = 'Gasto registrado';
  }

  /// Creates a note immediately with pendingAi status.
  Future<void> _createNoteImmediate(String userId, String content) async {
    final note = NoteEntity(
      id: '',
      userId: userId,
      title: content.split('\n').first,
      content: content,
      tags: [],
      date: DateTime.now(),
    );
    await _noteRepo.createNote(note);
    _lastResult = 'Nota guardada';
  }

  /// Extracts amount from text.
  double _extractAmount(String text) {
    // Look for number patterns: €12.50, 12.50€, 12,50€, €12,50
    final patterns = [
      RegExp(r'(\d+[.,]\d{2})\s*€'),
      RegExp(r'€\s*(\d+[.,]\d{2})'),
      RegExp(r'(\d+[.,]\d{2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1) ?? match.group(0) ?? '';
        final normalized = amountStr.replaceAll(',', '.');
        final amount = double.tryParse(normalized);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }
    return 0.0;
  }

  /// Processes AI classification in background after local save.
  /// Handles race conditions: if userModified, discards AI response.
  Future<void> _processAiInBackground(
    CaptureMode mode,
    String text,
    String userId,
  ) async {
    final aiConfigured = await _isAiApiKeyConfigured();

    if (!aiConfigured) {
      // No API key - use deterministic fallback and mark as completed
      await _applyDeterministicFallback(mode, text, userId);
      return;
    }

    // Create completer for race condition handling
    final requestKey = '${mode.name}_${DateTime.now().millisecondsSinceEpoch}';
    final completer = Completer<void>();
    _pendingAiRequests[requestKey] = completer;

    try {
      final result = await _aiService.classify(text);

      // Check if request was invalidated by user edit
      if (completer.isCompleted) {
        // Request was cancelled due to user edit
        _pendingAiRequests.remove(requestKey);
        return;
      }

      // Apply AI result if still valid
      await _applyAiResult(mode, text, userId, result);

      _pendingAiRequests.remove(requestKey);
    } catch (e) {
      _pendingAiRequests.remove(requestKey);
      // On error, apply deterministic fallback
      await _applyDeterministicFallback(mode, text, userId);
    }
  }

  /// Applies AI classification result to the created entity.
  Future<void> _applyAiResult(
    CaptureMode mode,
    String text,
    String userId,
    AiExtractionResult result,
  ) async {
    // For now, we need to find the most recently created entity
    // and update it with AI classification. In a full implementation,
    // we would track the entity ID created in the immediate save.
    // This is a simplified version that would need refinement for production.
  }

  /// Applies deterministic fallback when AI is unavailable.
  /// Looks up category from transaction history.
  Future<void> _applyDeterministicFallback(
    CaptureMode mode,
    String text,
    String userId,
  ) async {
    if (mode == CaptureMode.expense) {
      // Find the most recent pendingAi transaction and update it.
      // In a full implementation, we would track the created transaction ID.
      final dynamic rawTransactions = await _financeRepo.getTransactions();
      if (rawTransactions is! List) return;
      final List<TransactionEntity> transactions =
          rawTransactions.cast<TransactionEntity>();
      if (transactions.isEmpty) return;

      // Use `where` + `firstOrNull` to avoid firstWhere/orElse typing issues
      // with dynamic repos.
      final pendingTxn = transactions
          .where((t) => t.syncStatus == SyncStatus.pendingAi)
          .firstOrNull;
      if (pendingTxn == null) return;

      final history = transactions
          .where((t) => t.syncStatus == SyncStatus.completed)
          .toList();
      final category = await _findCategoryFromHistory(text, history);

      final updated = pendingTxn.copyWith(
        category: category,
        syncStatus: SyncStatus.completed,
      );
      await _financeRepo.updateTransaction(updated);
    }
  }

  /// Invalidates pending AI request when user manually edits an entity.
  /// Call this when user edits a pendingAi entity.
  void invalidatePendingAi(String entityId) {
    _pendingAiRequests.forEach((key, completer) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    _pendingAiRequests.clear();
  }

  /// Legacy capture method - routes to mode-specific capture.
  Future<void> capture(String text) async {
    final category = InputParserService.determineCategory(text);
    final mode = switch (category) {
      InputCategory.task => CaptureMode.mission,
      InputCategory.finance => CaptureMode.expense,
      InputCategory.note => CaptureMode.note,
    };
    await captureByMode(mode, text);
  }
}

/// Input category for legacy parser.
enum InputCategory { task, finance, note }

/// Simple input parser service for backward compatibility.
class InputParserService {
  static InputCategory determineCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('gasto') ||
        lower.contains('pago') ||
        lower.contains('compra') ||
        lower.contains('€') ||
        lower.contains('ingreso')) {
      return InputCategory.finance;
    }
    if (lower.contains('tarea') ||
        lower.contains('misión') ||
        lower.contains('hacer') ||
        lower.contains('comprar')) {
      return InputCategory.task;
    }
    return InputCategory.note;
  }
}
