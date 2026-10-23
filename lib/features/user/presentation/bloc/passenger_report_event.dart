import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/passenger_report.dart';

/// Eventos del BLoC de reporte de pasajero.
abstract class PassengerReportEvent extends Equatable {
  const PassengerReportEvent();

  @override
  List<Object?> get props => [];
}

/// Carga el reporte del pasajero para el período especificado.
class LoadPassengerReportEvent extends PassengerReportEvent {
  final String userId;
  final ReportPeriod period;

  const LoadPassengerReportEvent({required this.userId, required this.period});

  @override
  List<Object?> get props => [userId, period];
}

/// Evento de recarga manual (para recargar la pantalla).
class RefreshPassengerReportEvent extends PassengerReportEvent {
  const RefreshPassengerReportEvent();
}