/// Períodos de reporte para la observación 7.
enum ReportPeriod { hoy, semanal, mensual, todos }

extension ReportPeriodExtension on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.hoy:
        return 'Hoy';
      case ReportPeriod.semanal:
        return 'Semanal';
      case ReportPeriod.mensual:
        return 'Mensual';
      case ReportPeriod.todos:
        return 'Todos';
    }
  }
}

/// Cargo por ruta (línea).
class RouteCharge {
  final String routeName;
  final int tripCount;
  final double totalAmount;

  const RouteCharge({
    required this.routeName,
    required this.tripCount,
    required this.totalAmount,
  });

  factory RouteCharge.fromMap(Map<String, dynamic> map) {
    return RouteCharge(
      routeName: map['routeName'] ?? '',
      tripCount: map['tripCount'] ?? 0,
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeName': routeName,
      'tripCount': tripCount,
      'totalAmount': totalAmount,
    };
  }

  @override
  String toString() => 'RouteCharge($routeName, $tripCount trips, Bs. $totalAmount)';
}

/// Datos completos del reporte de pasajero.
class PassengerReport {
  final ReportPeriod period;
  final double totalIncome;
  final double totalPayments;
  final double totalRefunds;
  final List<RouteCharge> routeCharges;
  final int cancellationCount;

  /// Saldo actual de la billetera (para mostrar junto al resumen).
  final double? currentBalance;

  /// Solo en "Todos": si ingresos − pagos + reembolsos cuadra con el saldo.
  /// `null` en los demás períodos (un período parcial no tiene por qué
  /// cuadrar con el saldo total).
  final bool? isReconciled;

  const PassengerReport({
    required this.period,
    required this.totalIncome,
    required this.totalPayments,
    required this.totalRefunds,
    required this.routeCharges,
    required this.cancellationCount,
    this.currentBalance,
    this.isReconciled,
  });

  factory PassengerReport.fromMap(Map<String, dynamic> map) {
    var routeChargesList = <RouteCharge>[];
    if (map['routeCharges'] != null) {
      final list = map['routeCharges'] as List;
      routeChargesList =
          list.map((e) => RouteCharge.fromMap(e as Map<String, dynamic>)).toList();
    }

    return PassengerReport(
      period: ReportPeriod.values.firstWhere(
        (period) => period.label == (map['period'] ?? 'Todos'),
        orElse: () => ReportPeriod.todos,
      ),
      totalIncome: (map['totalIncome'] ?? 0.0).toDouble(),
      totalPayments: (map['totalPayments'] ?? 0.0).toDouble(),
      totalRefunds: (map['totalRefunds'] ?? 0.0).toDouble(),
      routeCharges: routeChargesList,
      cancellationCount: map['cancellationCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'period': period.label,
      'totalIncome': totalIncome,
      'totalPayments': totalPayments,
      'totalRefunds': totalRefunds,
      'routeCharges': routeCharges.map((rc) => rc.toMap()).toList(),
      'cancellationCount': cancellationCount,
    };
  }

  @override
  String toString() =>
      'PassengerReport(period: ${period.label}, income: Bs. $totalIncome, '
      'payments: Bs. $totalPayments, refunds: Bs. $totalRefunds, '
      'routes: ${routeCharges.length}, cancellations: $cancellationCount)';
}