import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';

abstract class TickeadorState extends Equatable {
  const TickeadorState();

  @override
  List<Object?> get props => [];
}

class TickeadorLoading extends TickeadorState {
  const TickeadorLoading();
}

class TickeadorLoaded extends TickeadorState {
  final List<DriverTripEntity> history;
  final DriverTripEntity? lastValidatedTrip;
  final String? lastValidationError;
  final bool isValidating;

  const TickeadorLoaded({
    required this.history,
    this.lastValidatedTrip,
    this.lastValidationError,
    this.isValidating = false,
  });

  TickeadorLoaded copyWith({
    List<DriverTripEntity>? history,
    DriverTripEntity? lastValidatedTrip,
    String? lastValidationError,
    bool clearLastResult = false,
    bool? isValidating,
  }) {
    return TickeadorLoaded(
      history: history ?? this.history,
      lastValidatedTrip: clearLastResult ? null : (lastValidatedTrip ?? this.lastValidatedTrip),
      lastValidationError:
          clearLastResult ? null : (lastValidationError ?? this.lastValidationError),
      isValidating: isValidating ?? this.isValidating,
    );
  }

  @override
  List<Object?> get props => [history, lastValidatedTrip, lastValidationError, isValidating];
}

class TickeadorError extends TickeadorState {
  final String message;

  const TickeadorError(this.message);

  @override
  List<Object?> get props => [message];
}
