import 'package:equatable/equatable.dart';

class RouteChargeSummary extends Equatable {
  final String route;
  final double amount;
  final int paymentCount;

  const RouteChargeSummary({
    required this.route,
    required this.amount,
    required this.paymentCount,
  });

  @override
  List<Object?> get props => [route, amount, paymentCount];
}

class PassengerWalletReport extends Equatable {
  static const reconciliationTolerance = 0.01;

  final double income;
  final double payments;
  final double refunds;
  final double currentBalance;
  final int paymentCount;
  final int cancellationCount;
  final List<RouteChargeSummary> routeCharges;

  const PassengerWalletReport({
    required this.income,
    required this.payments,
    required this.refunds,
    required this.currentBalance,
    required this.paymentCount,
    required this.cancellationCount,
    required this.routeCharges,
  });

  double get calculatedBalance => income - payments + refunds;

  double get reconciliationDifference => currentBalance - calculatedBalance;

  bool get isReconciled =>
      reconciliationDifference.abs() <= reconciliationTolerance;

  /// [from] / [to] (opcionales) limitan el reporte a un período usando el
  /// campo `_date` (DateTime) que agrega el datasource. Sin período se
  /// consideran todos los movimientos y la conciliación con el saldo aplica.
  factory PassengerWalletReport.fromLedger({
    required double currentBalance,
    required Iterable<Map<String, dynamic>> transactions,
    required Iterable<Map<String, dynamic>> trips,
    DateTime? from,
    DateTime? to,
  }) {
    bool inPeriod(Map<String, dynamic> item) {
      if (from == null && to == null) return true;
      final date = item['_date'];
      if (date is! DateTime) return false;
      if (from != null && date.isBefore(from)) return false;
      if (to != null && date.isAfter(to)) return false;
      return true;
    }

    final tripsById = <String, Map<String, dynamic>>{};
    var cancellationCount = 0;

    for (final trip in trips) {
      final id = trip['id'];
      // El mapa por id incluye todos los viajes: un pago del período puede
      // apuntar a un viaje creado antes.
      if (id is String) tripsById[id] = trip;
      if (!inPeriod(trip)) continue;
      if (trip['status'] == 'cancelled' ||
          trip['payment_status'] == 'refunded') {
        cancellationCount++;
      }
    }

    var income = 0.0;
    var payments = 0.0;
    var refunds = 0.0;
    var paymentCount = 0;
    final routeAmounts = <String, double>{};
    final routeCounts = <String, int>{};
    final routeLabels = <String, String>{};

    for (final transaction in transactions) {
      if (!_isCompleted(transaction['status'])) continue;
      if (!inPeriod(transaction)) continue;

      final amountValue = transaction['amount'];
      if (amountValue is! num || !amountValue.isFinite) continue;
      final amount = amountValue.abs().toDouble();
      if (amount == 0) continue;

      switch (transaction['transaction_type']) {
        case 'top_up':
        case 'recharge':
          income += amount;
          break;
        case 'trip_payment':
          payments += amount;
          paymentCount++;
          final tripId = transaction['trip_id'];
          final trip = tripId is String ? tripsById[tripId] : null;
          final routeRef = trip?['route_ref'] as String?;
          final routeName = trip?['route_name'] as String?;
          final transactionRouteRef = transaction['route_number'] as String?;
          final transactionRouteName = transaction['route_name'] as String?;
          final routeKey =
              _firstNonEmpty([
                routeRef,
                transactionRouteRef,
                routeName,
                transactionRouteName,
              ]) ??
              'Sin ruta';
          final routeLabel =
              _firstNonEmpty([
                routeName,
                transactionRouteName,
                routeRef,
                transactionRouteRef,
              ]) ??
              'Sin ruta';
          routeAmounts.update(
            routeKey,
            (total) => total + amount,
            ifAbsent: () => amount,
          );
          routeCounts.update(routeKey, (count) => count + 1, ifAbsent: () => 1);
          routeLabels[routeKey] = routeLabel;
          break;
        case 'refund':
          refunds += amount;
          break;
      }
    }

    final routeCharges =
        routeAmounts.entries
            .map(
              (entry) => RouteChargeSummary(
                route: routeLabels[entry.key] ?? entry.key,
                amount: entry.value,
                paymentCount: routeCounts[entry.key] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return PassengerWalletReport(
      income: income,
      payments: payments,
      refunds: refunds,
      currentBalance: currentBalance,
      paymentCount: paymentCount,
      cancellationCount: cancellationCount,
      routeCharges: routeCharges,
    );
  }

  static bool _isCompleted(dynamic status) =>
      status == null || status == 'approved' || status == 'completed';

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  @override
  List<Object?> get props => [
    income,
    payments,
    refunds,
    currentBalance,
    paymentCount,
    cancellationCount,
    routeCharges,
  ];
}
