import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/services/trip_payment_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_state.dart';

class TripPaymentBLoC extends Bloc<TripPaymentEvent, TripPaymentState> {
  final TripPaymentService _tripPaymentService;

  TripPaymentBLoC({required TripPaymentService tripPaymentService})
    : _tripPaymentService = tripPaymentService,
      super(const TripPaymentInitial()) {
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<RefundTripEvent>(_onRefundTrip);
    on<ClearPaymentEvent>(_onClear);
  }

  Future<void> _onRefundTrip(
    RefundTripEvent event,
    Emitter<TripPaymentState> emit,
  ) async {
    emit(const TripPaymentLoading());

    try {
      final result = await _tripPaymentService.refundTrip(
        userId: event.userId,
        tripId: event.tripId,
      );

      if (result['success'] == true) {
        emit(
          TripRefundSuccess(
            message: result['message'],
            amount: result['amount'],
            newBalance: result['newBalance'],
            tripId: result['tripId'],
          ),
        );
      } else {
        emit(TripPaymentError(message: result['message']));
      }
    } catch (e) {
      emit(TripPaymentError(message: 'Error al procesar el reembolso: $e'));
    }
  }

  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<TripPaymentState> emit,
  ) async {
    emit(const TripPaymentLoading());

    try {
      final result = await _tripPaymentService.processPayment(
        userId: event.userId,
        qrData: event.qrData,
      );

      if (result['success'] == true) {
        emit(
          TripPaymentSuccess(
            message: result['message'],
            amount: result['amount'],
            newBalance: result['newBalance'],
            tripId: result['tripId'],
          ),
        );
      } else {
        emit(TripPaymentError(message: result['message']));
      }
    } catch (e) {
      emit(TripPaymentError(message: 'Error al procesar el pago: $e'));
    }
  }

  Future<void> _onClear(
    ClearPaymentEvent event,
    Emitter<TripPaymentState> emit,
  ) async {
    emit(const TripPaymentInitial());
  }
}
