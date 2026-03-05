import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Heatmap tipo GitHub — grid de 7 filas (Lun-Dom) × 13 columnas (semanas).
///
/// Recibe un `Map<DateTime, bool>` donde:
/// - key presente + true  → completado (azul)
/// - key presente + false → programado pero NO completado (gris oscuro)
/// - key ausente           → día no programado (invisible / scaffold)
class HabitHeatmap extends StatelessWidget {
  final Map<DateTime, bool> data;

  const HabitHeatmap({super.key, required this.data});

  /// Normaliza fecha a medianoche.
  static DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    // Construimos la grid de 13 semanas × 7 días (91 celdas)
    // Empezamos desde el lunes de hace 12 semanas para alinear filas
    final today = _norm(DateTime.now());
    // Retroceder al lunes de esta semana (1 = Monday en Dart)
    final todayWeekday = today.weekday; // 1=Mon, 7=Sun
    final thisMonday = today.subtract(Duration(days: todayWeekday - 1));
    // Retroceder 12 semanas más para tener 13 columnas
    final startMonday = thisMonday.subtract(const Duration(days: 12 * 7));

    const int weeks = 13;
    const int daysPerWeek = 7;
    const double cellSize = 12;
    const double cellSpacing = 3;

    // Etiquetas de días (columna izquierda)
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leyenda
        Row(
          children: [
            const Spacer(),
            _legendDot(AppColors.habits, 'Hecho'),
            const SizedBox(width: 12),
            _legendDot(AppColors.divider, 'Fallo'),
            const SizedBox(width: 12),
            _legendDot(AppColors.scaffold, 'N/A'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Labels de días
            Column(
              children: List.generate(daysPerWeek, (row) {
                return SizedBox(
                  height: cellSize + cellSpacing,
                  child: Center(
                    child: Text(
                      dayLabels[row],
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: 4),
            // Grid
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // scroll al final (hoy) por defecto
                child: Row(
                  children: List.generate(weeks, (col) {
                    return Column(
                      children: List.generate(daysPerWeek, (row) {
                        final day = startMonday.add(
                          Duration(days: col * 7 + row),
                        );
                        final isFuture = day.isAfter(today);

                        Color color;
                        if (isFuture) {
                          color = Colors.transparent;
                        } else if (data.containsKey(day)) {
                          color = data[day]!
                              ? AppColors.habits
                              : AppColors.divider;
                        } else {
                          color = AppColors.scaffold;
                        }

                        return Container(
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(cellSpacing / 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
