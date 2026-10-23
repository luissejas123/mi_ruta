import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/user/domain/entities/passenger_report.dart';
import 'package:mi_ruta/features/user/domain/repositories/passenger_report_repository.dart';

/// Mock repository para la Observación 7 (Reporte del Pasajero).
/// Proporciona datos de prueba que varían según el período seleccionado.
/// "Hoy" queda vacío intencionalmente para probar estados de vacío y cargando.
class PassengerReportRepositoryMock implements PassengerReportRepository {
  @override
  Future<Either<Failure, PassengerReport>> getReport(
    String userId,
    ReportPeriod period,
  ) async {
    // Simdelay de red
    await Future.delayed(const Duration(milliseconds: 500));

    // Datos de prueba que cambian según el período
    switch (period) {
      case ReportPeriod.hoy:
        // "Hoy" vacío para probar estado vacío ("Aún no tienes viajes en este período")
        return Right(
          const PassengerReport(
            period: ReportPeriod.hoy,
            totalIncome: 0.0,
            totalPayments: 0.0,
            totalRefunds: 0.0,
            routeCharges: [],
            cancellationCount: 0,
          ),
        );

      case ReportPeriod.semanal:
        return Right(
          PassengerReport(
            period: ReportPeriod.semanal,
            totalIncome: 45.50,
            totalPayments: 32.00,
            totalRefunds: 5.20,
            routeCharges: [
              RouteCharge(routeName: 'Línea 101', tripCount: 12, totalAmount: 36.00),
              RouteCharge(routeName: 'Línea 102', tripCount: 8, totalAmount: 24.00),
            ],
            cancellationCount: 2,
          ),
        );

      case ReportPeriod.mensual:
        return Right(
          PassengerReport(
            period: ReportPeriod.mensual,
            totalIncome: 180.00,
            totalPayments: 120.00,
            totalRefunds: 15.50,
            routeCharges: [
              RouteCharge(routeName: 'Línea 101', tripCount: 45, totalAmount: 135.00),
              RouteCharge(routeName: 'Línea 102', tripCount: 30, totalAmount: 90.00),
              RouteCharge(routeName: 'Línea 103', tripCount: 10, totalAmount: 30.00),
            ],
            cancellationCount: 3,
          ),
        );

      case ReportPeriod.todos:
        return Right(
          PassengerReport(
            period: ReportPeriod.todos,
            totalIncome: 250.00,
            totalPayments: 180.00,
            totalRefunds: 25.00,
            routeCharges: [
              RouteCharge(routeName: 'Línea 101', tripCount: 57, totalAmount: 171.00),
              RouteCharge(routeName: 'Línea 102', tripCount: 38, totalAmount: 114.00),
              RouteCharge(routeName: 'Línea 103', tripCount: 15, totalAmount: 45.00),
            ],
            cancellationCount: 5,
          ),
        );
    }
  }
}