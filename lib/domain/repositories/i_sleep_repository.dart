import '../entities/sleep_log_entity.dart';

abstract class ISleepRepository {
  Future<List<SleepLogEntity>> getSleepLogs();
  Future<SleepLogEntity?> getTodayLog();
  Future<void> createSleepLog(SleepLogEntity log);
  Future<void> updateSleepLog(SleepLogEntity log);
  Future<void> deleteSleepLog(String logId);
}
