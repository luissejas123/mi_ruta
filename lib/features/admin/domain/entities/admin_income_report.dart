/// Ingresos del sistema en un período (Obs. 8, reporte del administrador).
///
/// Se calcula con los viajes realmente cobrados (`trips` con
/// `payment_status: paid`/`refunded`) y las recargas aprobadas
/// (`recharges` con `status: approved`). Entidad pura: recibe los documentos
/// ya leídos con una fecha `_date` (DateTime) agregada por el datasource.
class LineIncome {
  final String line;
  final int paidTrips;
  final double collected;

  const LineIncome({
    required this.line,
    required this.paidTrips,
    required this.collected,
  });
}

class AdminIncomeReport {
  /// Total cobrado en pasajes (incluye los viajes reembolsados después).
  final double collected;

  /// Total devuelto a pasajeros por cancelaciones.
  final double refunded;

  /// Recargas de saldo aprobadas en el período.
  final double recharges;

  final int paidTrips;
  final int refundedTrips;
  final int approvedRecharges;
  final List<LineIncome> byLine;

  const AdminIncomeReport({
    required this.collected,
    required this.refunded,
    required this.recharges,
    required this.paidTrips,
    required this.refundedTrips,
    required this.approvedRecharges,
    required this.byLine,
  });

  /// Ingreso neto por pasajes: cobrado − reembolsado.
  double get netIncome => collected - refunded;

  factory AdminIncomeReport.compute({
    required Iterable<Map<String, dynamic>> trips,
    required Iterable<Map<String, dynamic>> recharges,
    required DateTime from,
    required DateTime to,
  }) {
    bool inRange(Object? date) =>
        date is DateTime && !date.isBefore(from) && !date.isAfter(to);
    double amountOf(Object? value) =>
        value is num && value.isFinite ? value.toDouble().abs() : 0.0;

    var collected = 0.0;
    var refunded = 0.0;
    var paidTrips = 0;
    var refundedTrips = 0;
    final lineAmounts = <String, double>{};
    final lineCounts = <String, int>{};

    for (final trip in trips) {
      final status = trip['payment_status'];
      if (status != 'paid' && status != 'refunded') continue;
      final amount = amountOf(trip['payment_amount']);
      if (amount == 0) continue;

      // Cobro: cuenta por la fecha de pago.
      if (inRange(trip['_paid_date'])) {
        collected += amount;
        paidTrips++;
        final line = _lineLabel(trip);
        lineAmounts.update(line, (v) => v + amount, ifAbsent: () => amount);
        lineCounts.update(line, (v) => v + 1, ifAbsent: () => 1);
      }
      // Reembolso: cuenta por la fecha en que se devolvió.
      if (status == 'refunded' && inRange(trip['_refund_date'])) {
        refunded += amountOf(trip['refund_amount'] ?? trip['payment_amount']);
        refundedTrips++;
      }
    }

    var recharged = 0.0;
    var approvedRecharges = 0;
    for (final recharge in recharges) {
      if (recharge['status'] != 'approved') continue;
      if (!inRange(recharge['_date'])) continue;
      recharged += amountOf(recharge['amount']);
      approvedRecharges++;
    }

    final byLine = lineAmounts.entries
        .map(
          (e) => LineIncome(
            line: e.key,
            paidTrips: lineCounts[e.key] ?? 0,
            collected: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.collected.compareTo(a.collected));

    return AdminIncomeReport(
      collected: collected,
      refunded: refunded,
      recharges: recharged,
      paidTrips: paidTrips,
      refundedTrips: refundedTrips,
      approvedRecharges: approvedRecharges,
      byLine: byLine,
    );
  }

  static String _lineLabel(Map<String, dynamic> trip) {
    final ref = trip['route_ref']?.toString().trim() ?? '';
    final name = trip['route_name']?.toString().trim() ?? '';
    if (ref.isNotEmpty && name.isNotEmpty && !name.contains(ref)) {
      return 'Línea $ref · $name';
    }
    if (name.isNotEmpty) return name;
    if (ref.isNotEmpty) return 'Línea $ref';
    return 'Sin línea';
  }
}
