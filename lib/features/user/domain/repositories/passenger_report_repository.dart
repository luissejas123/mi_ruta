import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/user/domain/entities/passenger_report.dart';

/// Repositorio abstracto para el reporte de pasajero.
/// Define el contrato `getReport(userId, period)` que la pantalla y el BLoC
/// consumen. Implementación real se conecta a Firestore; la implementación
///Mock se usa durante el desarrollo.
abstract class PassengerReportRepository {
  /// Obtiene el reporte del pasajero para el período especificado.
  Future<Either<Failure, PassengerReport>> getReport(
    String userId,
    ReportPeriod period,
  );
}