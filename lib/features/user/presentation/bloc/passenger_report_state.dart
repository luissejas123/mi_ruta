import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/passenger_report.dart';

/// Estados del BLoC de reporte de pasajero.
abstract class PassengerReportState extends Equatable {
  const PassengerReportState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial.
class PassengerReportInitial extends PassengerReportState {
  const PassengerReportInitial();
}

/// Cargando datos del reporte.
class PassengerReportLoading extends PassengerReportState {
  const PassengerReportLoading();
}

/// Datos del reporte cargados exitosamente.
class PassengerReportLoaded extends PassengerReportState {
  final PassengerReport report;

  const PassengerReportLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

/// Error al cargar el reporte.
class PassengerReportError extends PassengerReportState {
  final String message;

  const PassengerReportError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado vacío: el usuario no tiene viajes en el período.
class PassengerReportEmpty extends PassengerReportState {
  final ReportPeriod period;

  const PassengerReportEmpty(this.period);

  @override
  List<Object?> get props => [period];
}