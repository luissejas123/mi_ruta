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
    on<RenewBenefitRequestEvent>(_onRenewBenefitRequest);
    on<CancelBenefitRequestEvent>(_onCancelBenefitRequest);
    on<DownloadBenefitDocumentEvent>(_onDownloadDocument);
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

  Future<void> _onRenewBenefitRequest(
    RenewBenefitRequestEvent event,
    Emitter<BenefitRequestState> emit,
  ) async {
    emit(const BenefitRequestLoading());

    try {
      await _benefitRequestService.renewBenefitRequest(event.requestId);
      final requests = await _benefitRequestService.getBenefitRequestHistory(
        event.userId,
      );
      emit(
        BenefitRequestUpdated(
          message: 'Beneficio renovado y enviado nuevamente a revisión.',
        ),
      );
      emit(BenefitHistoryLoaded(requests));
    } catch (e) {
      emit(BenefitRequestError(message: 'Error al renovar beneficio: $e'));
    }
  }

  Future<void> _onCancelBenefitRequest(
    CancelBenefitRequestEvent event,
    Emitter<BenefitRequestState> emit,
  ) async {
    emit(const BenefitRequestLoading());

    try {
      await _benefitRequestService.cancelBenefitRequest(event.requestId);
      final requests = await _benefitRequestService.getBenefitRequestHistory(
        event.userId,
      );
      emit(
        BenefitRequestUpdated(
          message: 'Solicitud de beneficio cancelada correctamente.',
        ),
      );
      emit(BenefitHistoryLoaded(requests));
    } catch (e) {
      emit(BenefitRequestError(message: 'Error al cancelar beneficio: $e'));
    }
  }

  Future<void> _onDownloadDocument(
    DownloadBenefitDocumentEvent event,
    Emitter<BenefitRequestState> emit,
  ) async {
    emit(const BenefitRequestLoading());

    try {
      final request = await _benefitRequestService.getBenefitRequest(
        event.requestId,
      );
      if (request == null) {
        throw Exception('No se encontró la solicitud de beneficio');
      }

      final file = await _benefitRequestService.downloadBenefitCertificatePdf(
        request,
      );
      emit(
        BenefitDocumentDownloaded(
          filePath: file.path,
          message: 'Comprobante PDF descargado correctamente en ${file.path}',
        ),
      );

      final requests = await _benefitRequestService.getBenefitRequestHistory(
        event.userId,
      );
      emit(BenefitHistoryLoaded(requests));
    } catch (e) {
      emit(BenefitRequestError(message: 'Error al descargar comprobante: $e'));
    }
  }

  Future<void> _onClear(
    ClearBenefitRequestEvent event,
    Emitter<BenefitRequestState> emit,
  ) async {
    emit(const BenefitRequestInitial());
  }
}
