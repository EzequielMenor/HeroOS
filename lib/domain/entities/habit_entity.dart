/// Entidad de dominio pura para Hábitos.
/// La lógica de "¿está activo hoy?" vive aquí, sin saber nada de Supabase.
class HabitEntity {
  final String id;
  final String userId;
  final String title;
  final String frequencyMask; // "Mon,Tue,Wed,Thu,Fri,Sat,Sun"
  final int xpReward;
  final int dmgPenalty;
  final int currentStreak;
  final bool isArchived;

  const HabitEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.frequencyMask,
    this.xpReward = 10,
    this.dmgPenalty = 5,
    this.currentStreak = 0,
    this.isArchived = false,
  });

  /// Días de la semana mapeados al formato de [DateTime.weekday] (1=Mon..7=Sun).
  static const _dayMap = {
    'Mon': 1,
    'Tue': 2,
    'Wed': 3,
    'Thu': 4,
    'Fri': 5,
    'Sat': 6,
    'Sun': 7,
  };

  /// ¿Este hábito está programado para [date]?
  bool isActiveOn(DateTime date) {
    if (frequencyMask.isEmpty) {
      return true; // si no hay máscara → siempre activo
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
    int? xpReward,
    int? dmgPenalty,
    int? currentStreak,
    bool? isArchived,
  }) {
    return HabitEntity(
      id: id,
      userId: userId,
      title: title ?? this.title,
      frequencyMask: frequencyMask ?? this.frequencyMask,
      xpReward: xpReward ?? this.xpReward,
      dmgPenalty: dmgPenalty ?? this.dmgPenalty,
      currentStreak: currentStreak ?? this.currentStreak,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
