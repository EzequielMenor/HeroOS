/// Domain entity for habits.
/// Minimal fields: id, userId, title, frequencyMask, currentStreak.
/// XP/RPG mechanics removed for Zen OS pivot.
class HabitEntity {
  final String id;
  final String userId;
  final String title;
  final String frequencyMask; // "Mon,Tue,Wed,Thu,Fri,Sat,Sun"
  final int currentStreak;
  final bool isArchived;

  const HabitEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.frequencyMask,
    this.currentStreak = 0,
    this.isArchived = false,
  });

  /// Day map matching [DateTime.weekday] (1=Mon..7=Sun).
  static const _dayMap = {
    'Mon': 1,
    'Tue': 2,
    'Wed': 3,
    'Thu': 4,
    'Fri': 5,
    'Sat': 6,
    'Sun': 7,
  };

  /// Is this habit scheduled for [date]?
  bool isActiveOn(DateTime date) {
    if (frequencyMask.isEmpty) {
      return true; // no mask = always active
    }
    final activeDays = frequencyMask
        .split(',')
        .map((d) => _dayMap[d.trim()])
        .whereType<int>();
    return activeDays.contains(date.weekday);
  }

  HabitEntity copyWith({
    String? title,
    String? frequencyMask,
    int? currentStreak,
    bool? isArchived,
  }) {
    return HabitEntity(
      id: id,
      userId: userId,
      title: title ?? this.title,
      frequencyMask: frequencyMask ?? this.frequencyMask,
      currentStreak: currentStreak ?? this.currentStreak,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
