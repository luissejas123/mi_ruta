/// Utilidades para formateo de fechas.
class DateFormatter {
  /// Formatea una fecha como "Hoy", "Ayer" o "dd/mm/yyyy"
  static String formatShortDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hoy';
    } else if (dateOnly == yesterday) {
      return 'Ayer';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Formatea una fecha con hora: "Hoy - HH:MM"
  static String formatWithTime(DateTime date) {
    final dateStr = formatShortDate(date);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$dateStr - $hour:$minute';
  }

  /// Formatea una duración en minutos a string legible: "5 min", "1 h 30 min"
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours h';
    }
    return '$hours h $mins min';
  }

  /// Formatea distancia: "1.2 km", "500 m"
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
