import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/user/domain/entities/passenger_report.dart';
import 'package:mi_ruta/features/user/domain/repositories/passenger_report_repository.dart';
import 'package:mi_ruta/features/user/domain/services/wallet_service.dart';

/// Reporte del pasajero (Obs. 7) con datos reales.
///
/// Usa las consultas de `WalletService.getPassengerReport` (movimientos de
/// `transactions` y viajes de `trips` del pasajero) y las adapta al modelo
/// que muestra `MiReportePage`. El período se traduce a un rango de fechas.
class PassengerReportRepositoryImpl implements PassengerReportRepository {
  final WalletService _walletService;

  PassengerReportRepositoryImpl({required WalletService walletService})
    : _walletService = walletService;

  @override
  Future<Either<Failure, PassengerReport>> getReport(
    String userId,
    ReportPeriod period,
  ) async {
    if (userId.isEmpty) {
      return Left(
        ServerFailure(message: 'No se pudo identificar al pasajero'),
      );
    }
    try {
      final range = rangeFor(period, DateTime.now());
      final result = await _walletService.getPassengerReport(
        userId,
        from: range.from,
        to: range.to,
      );
      final data = result.report;
      return Right(
        PassengerReport(
          period: period,
          totalIncome: data.income,
          totalPayments: data.payments,
          totalRefunds: data.refunds,
          cancellationCount: data.cancellationCount,
          routeCharges: data.routeCharges
              .map(
                (r) => RouteCharge(
                  routeName: r.route,
                  tripCount: r.paymentCount,
                  totalAmount: r.amount,
                ),
              )
              .toList(),
          currentBalance: data.currentBalance,
          isReconciled: period == ReportPeriod.todos ? data.isReconciled : null,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'No se pudo cargar tu reporte: $e'));
    }
  }

  /// Rango de fechas de cada período. "Semanal" empieza el lunes y
  /// "Mensual" el día 1.
  static ({DateTime? from, DateTime? to}) rangeFor(
    ReportPeriod period,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case ReportPeriod.hoy:
        return (from: today, to: now);
      case ReportPeriod.semanal:
        return (
          from: today.subtract(Duration(days: today.weekday - 1)),
          to: now,
        );
      case ReportPeriod.mensual:
        return (from: DateTime(now.year, now.month), to: now);
      case ReportPeriod.todos:
        return (from: null, to: null);
    }
  }
}
