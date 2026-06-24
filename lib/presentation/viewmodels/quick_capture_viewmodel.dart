import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/services/ai_service.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/finance_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dev_repository.dart';

/// ViewModel for Quick Capture.
/// Calls AIService.classify, routes to correct repository by type.
class QuickCaptureViewModel extends ChangeNotifier {
  final AiService _aiService = AiService();
  late final dynamic _taskRepo;
  late final dynamic _habitRepo;
  late final dynamic _noteRepo;
  late final dynamic _financeRepo;

  bool _isLoading = false;
  String? _error;
  String? _lastResult;

  QuickCaptureViewModel() : 
    _taskRepo = AuthRepository.devQuickAccess ? DevRepository() : TaskRepository(),
    _habitRepo = AuthRepository.devQuickAccess ? DevRepository() : HabitRepository(),
    _noteRepo = AuthRepository.devQuickAccess ? DevRepository() : NoteRepository(),
    _financeRepo = AuthRepository.devQuickAccess ? DevRepository() : FinanceRepository();

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastResult => _lastResult;

  /// Captures text: classifies via AI, routes to correct repo.
  Future<void> capture(String text) async {
    _isLoading = true;
    _error = null;
    _lastResult = null;
    notifyListeners();

    try {
      final (type, _) = await _aiService.classify(text);
      final userId = AuthRepository.devQuickAccess ? 'dev-user' : Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        _error = 'Usuario no disponible';
        _isLoading = false;
        notifyListeners();
        return;
      }

      switch (type) {
        case AiClassification.tarea:
          await _taskRepo.createTask(TaskEntity(
            id: '',
            userId: userId,
            title: text,
          ));
          _lastResult = 'Tarea creada';
          break;

        case AiClassification.habito:
          await _habitRepo.createHabit(HabitEntity(
            id: '',
            userId: userId,
            title: text,
            frequencyMask: '1111111',
          ));
          _lastResult = 'Hábito creado';
          break;

        case AiClassification.gasto:
          // Quick capture gasto: amount=0 until user specifies
          await _financeRepo.createTransaction(TransactionEntity(
            id: '',
            userId: userId,
            accountId: '', // placeholder — user categorizes later
            amount: 0,
            note: text,
            date: DateTime.now(),
          ));
          _lastResult = 'Gasto registrado';
          break;

        case AiClassification.nota:
          await _noteRepo.createNote(NoteEntity(
            id: '',
            userId: userId,
            title: text.length > 50 ? text.substring(0, 50) : text,
            content: text,
            date: DateTime.now(),
          ));
          _lastResult = 'Nota guardada';
          break;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
