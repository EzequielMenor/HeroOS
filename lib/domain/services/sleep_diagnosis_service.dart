import '../entities/sleep_log_entity.dart';

/// Resultado del diagnóstico de sueño.
class SleepDiagnosis {
  final String title;
  final String physicalAnalysis;
  final String mentalAnalysis;
  final String reason;
  final String advice;

  const SleepDiagnosis({
    required this.title,
    required this.physicalAnalysis,
    required this.mentalAnalysis,
    required this.reason,
    required this.advice,
  });
}

/// Motor de diagnóstico de sueño basado en reglas.
/// No requiere API externa — funciona offline.
class SleepDiagnosisService {
  SleepDiagnosisService._();

  static SleepDiagnosis? diagnose(SleepLogEntity log) {
    // Mínimo de datos: necesitamos al menos las horas
    if (log.totalHours <= 0) return null;

    final hours = log.totalHours;
    final deep = log.deepSleepPct;
    final rem = log.remSleepPct;
    final lpm = log.avgHeartRate;

    final physicalScore = _physicalScore(deep, lpm);
    final mentalScore = _mentalScore(rem, hours);

    return SleepDiagnosis(
      title: _buildTitle(physicalScore, mentalScore, hours, deep, rem),
      physicalAnalysis: _buildPhysical(deep, lpm, hours),
      mentalAnalysis: _buildMental(rem, hours),
      reason: _buildReason(hours, deep, rem, lpm),
      advice: _buildAdvice(physicalScore, mentalScore, hours, deep, rem),
    );
  }

  // ─── Scores internos (0=bajo, 1=medio, 2=alto) ───────────────────────────

  static int _physicalScore(int? deep, int? lpm) {
    int score = 1; // medio por defecto si no hay datos

    if (deep != null) {
      if (deep >= 20) {
        score = 2;
      } else if (deep >= 15) {
        score = 1;
      } else {
        score = 0;
      }
    }

    if (lpm != null) {
      if (lpm <= 55) {
        score = score < 2 ? score + 1 : 2;
      } else if (lpm > 70) {
        score = score > 0 ? score - 1 : 0;
      }
      score = score.clamp(0, 2);
    }

    return score;
  }

  static int _mentalScore(int? rem, double hours) {
    int score = 1;

    if (hours >= 8) {
      score = 2;
    } else if (hours >= 7) {
      score = 1;
    } else if (hours < 6) {
      score = 0;
    }

    if (rem != null) {
      if (rem >= 20) {
        score = score < 2 ? score + 1 : 2;
      } else if (rem < 15) {
        score = score > 0 ? score - 1 : 0;
      }
      score = score.clamp(0, 2);
    }

    return score;
  }

  // ─── Titular ─────────────────────────────────────────────────────────────

  static String _buildTitle(
    int physScore,
    int mentalScore,
    double hours,
    int? deep,
    int? rem,
  ) {
    if (deep == null && rem == null) {
      if (hours >= 8) return 'Descanso sólido — sigue así';
      if (hours >= 7) return 'Buena noche, aunque podría mejorar';
      if (hours >= 6) return 'Poco tiempo, cuerpo y mente lo notan';
      return 'Noche corta — tu cuerpo necesita más';
    }

    if (physScore == 2 && mentalScore == 2) {
      return 'Noche de élite: cuerpo y mente al 100%';
    }
    if (physScore == 2 && mentalScore == 1) {
      return 'Recuperación física de élite, mente a medias';
    }
    if (physScore == 2 && mentalScore == 0) {
      return 'Cuerpo reparado, pero la mente lo necesita';
    }
    if (physScore == 1 && mentalScore == 2) {
      return 'Mente fresca, cuerpo con margen de mejora';
    }
    if (physScore == 1 && mentalScore == 1) {
      return 'Noche correcta — sin alarmas, sin récords';
    }
    if (physScore == 1 && mentalScore == 0) {
      return 'Descanso justo — la mente puede flaquear hoy';
    }
    if (physScore == 0 && mentalScore == 2) {
      return 'Mente ágil, pero el cuerpo pide recuperación';
    }
    if (physScore == 0 && mentalScore == 1) {
      return 'Noche difícil — dale al cuerpo lo que necesita';
    }
    return 'Noche de deuda: cuerpo y mente necesitan recuperarse';
  }

  // ─── Análisis físico ─────────────────────────────────────────────────────

  static String _buildPhysical(int? deep, int? lpm, double hours) {
    final deepStr = deep != null
        ? 'Tu sueño profundo fue del $deep% '
              '(ideal 15–25%).'
        : 'No registraste fases de sueño.';

    final lpmStr = lpm != null
        ? lpm <= 55
              ? ' Ritmo cardíaco de $lpm LPM: tu corazón trabajó a tope para reparar.'
              : lpm <= 70
              ? ' Ritmo cardíaco de $lpm LPM: dentro del rango normal.'
              : ' Ritmo cardíaco de $lpm LPM: algo elevado — puede indicar estrés o calor.'
        : '';

    if (deep == null) {
      if (hours >= 7) return '$deepStr Registro suficiente para recuperación básica.$lpmStr';
      return '$deepStr Pocas horas limitan la reparación muscular.$lpmStr';
    }

    if (deep >= 20) return '$deepStr Tejidos y músculos bien reparados.$lpmStr';
    if (deep >= 15) return '$deepStr Recuperación física aceptable.$lpmStr';
    if (deep >= 10) return '$deepStr Recuperación física por debajo de lo óptimo.$lpmStr';
    return '$deepStr Muy poco sueño profundo — el cuerpo quedó con deuda.$lpmStr';
  }

  // ─── Análisis mental ─────────────────────────────────────────────────────

  static String _buildMental(int? rem, double hours) {
    final hoursStr = hours >= 7 ? 'Dormiste ${hours.toStringAsFixed(1)}h' : 'Solo ${hours.toStringAsFixed(1)}h de sueño';
    final remStr = rem != null
        ? ' con un $rem% de REM (ideal 20–25%).'
        : '.';

    if (rem == null) {
      if (hours >= 8) return '$hoursStr$remStr Memoria y creatividad tienen base sólida.';
      if (hours >= 7) return '$hoursStr$remStr Función cognitiva probable en buen estado.';
      if (hours >= 6) return '$hoursStr$remStr Puede haber algo de niebla mental durante el día.';
      return '$hoursStr$remStr Alta probabilidad de irritabilidad y dificultad de concentración.';
    }

    if (rem >= 20 && hours >= 7) return '$hoursStr$remStr Memoria, creatividad y estado de ánimo en forma.';
    if (rem >= 20) return '$hoursStr$remStr Buen porcentaje REM, aunque las horas totales limitan el beneficio.';
    if (rem >= 15 && hours >= 7) return '$hoursStr$remStr Función cognitiva correcta, aunque con margen de mejora en REM.';
    if (rem >= 15) return '$hoursStr$remStr REM justo y horas cortas — posible neblina mental leve.';
    return '$hoursStr$remStr REM insuficiente — espera algo de niebla mental o irritabilidad hoy.';
  }

  // ─── El por qué ──────────────────────────────────────────────────────────

  static String _buildReason(double hours, int? deep, int? rem, int? lpm) {
    final reasons = <String>[];

    if (hours < 6) {
      reasons.add('Dormir menos de 6h recorta drásticamente el sueño REM, que ocurre en las últimas horas de la noche.');
    } else if (hours < 7) {
      reasons.add('Con menos de 7h el cuerpo prioriza el sueño profundo sobre el REM, sacrificando recuperación mental.');
    }

    if (rem != null && rem < 15) {
      if (hours >= 7) {
        reasons.add('El sueño REM bajo puede deberse a estrés, alcohol, o haber interrumpido el ciclo justo antes del amanecer.');
      }
    }

    if (deep != null && deep < 10) {
      reasons.add('Poco sueño profundo suele estar relacionado con ambiente ruidoso, temperatura alta o mucho estrés antes de dormir.');
    }

    if (lpm != null && lpm > 70) {
      reasons.add('El ritmo cardíaco elevado durante el sueño puede indicar estrés acumulado, hidratación insuficiente o temperatura ambiente alta.');
    }

    if (reasons.isEmpty) {
      if (deep != null && deep >= 20 && rem != null && rem >= 20) {
        return 'Tus ciclos de sueño siguieron un patrón saludable: el cuerpo dedicó tiempo suficiente a cada fase en el orden correcto.';
      }
      return 'Los datos muestran un patrón de sueño estable sin señales de alarma destacadas.';
    }

    return reasons.join(' ');
  }

  // ─── Consejo del día ─────────────────────────────────────────────────────

  static String _buildAdvice(
    int physScore,
    int mentalScore,
    double hours,
    int? deep,
    int? rem,
  ) {
    // Casos críticos primero
    if (hours < 5.5) return 'Prioriza una siesta de 20 min esta tarde si puedes. Evita decisiones importantes.';

    if (mentalScore == 0) {
      return 'Evita decisiones complejas o creativas hoy. Trabaja en tareas rutinarias y bebe agua al despertar.';
    }

    if (physScore == 0) {
      return 'No es el día ideal para entrenar intenso. Opta por movilidad o una caminata suave para facilitar la recuperación.';
    }

    if (physScore == 2 && mentalScore == 2) {
      return '¡Día perfecto para entrenar fuerte y afrontar retos mentales! Aprovecha esta ventana de rendimiento.';
    }

    if (physScore == 2 && mentalScore <= 1) {
      return 'Buen momento para entrenar fuerza o cardio, pero delega decisiones creativas importantes para mañana.';
    }

    if (physScore <= 1 && mentalScore == 2) {
      return 'Tu mente está lista para el trabajo creativo o de estudio. Evita el entrenamiento de alta intensidad hoy.';
    }

    if (rem != null && rem >= 20) {
      return 'Tu fase REM fue excelente: aprovecha esta mañana para aprender o crear algo nuevo.';
    }

    if (deep != null && deep >= 20) {
      return 'Recuperación muscular completada. Puedes entrenar con normalidad hoy.';
    }

    return 'Día de rendimiento moderado. Mantén rutinas conocidas y asegura una buena noche esta noche.';
  }
}
