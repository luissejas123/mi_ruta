import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/services/benefit_request_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_state.dart';

class BenefitRequestBLoC
    extends Bloc<BenefitRequestEvent, BenefitRequestState> {
  final BenefitRequestService _benefitRequestService;

  BenefitRequestBLoC({required BenefitRequestService benefitRequestService})
    : _benefitRequestService = benefitRequestService,
      super(const BenefitRequestInitial()) {
    on<SubmitBenefitRequestEvent>(_onSubmitBenefitRequest);
    on<LoadBenefitHistoryEvent>(_onLoadHistory);
    on<ClearBenefitRequestEvent>(_onClear);
  }

  Future<void> _onSubmitBenefitRequest(
    SubmitBenefitRequestEvent event,
    Emitter<BenefitRequestState> emit,
  ) async {
    emit(const BenefitRequestLoading());

    try {
      final requestId = await _benefitRequestService.submitBenefitRequest(
        userId: event.userId,
        benefitType: event.benefitType,
        description: event.description,
        documentFiles: event.documentFiles,
      );

      emit(
        BenefitRequestSubmitted(
          requestId: requestId,
          benefitType: event.benefitType,
          message:
              'Solicitud de beneficio enviada exitosamente. Esperando aprobación.',
        ),
      );
    } catch (e) {
      emit(BenefitRequestError(message: 'Error al enviar solicitud: $e'));
    }
  }

  Future<void> _onLoadHistory(
    LoadBenefitHistoryEvent event,
    Emitter<BenefitRequestState> emit,
  ) async {
    emit(const BenefitRequestLoading());

    try {
      final requests = await _benefitRequestService.getBenefitRequestHistory(
        event.userId,
      );
      emit(BenefitHistoryLoaded(requests));
    } catch (e) {
      emit(BenefitRequestError(message: 'Error al obtener historial: $e'));
    }
  }

  Future<void> _onClear(
    ClearBenefitRequestEvent event,
    Emitter<BenefitRequestState> emit,
  ) async {
    emit(const BenefitRequestInitial());
  }
}
