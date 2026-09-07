import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/claims_event.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/claims_state.dart';
import 'package:mi_ruta/features/user/domain/services/claim_service.dart';

class ClaimsBloc extends Bloc<ClaimsEvent, ClaimsState> {
  final ClaimService _service;

  ClaimsBloc({required ClaimService service}) : _service = service, super(ClaimsInitial()) {
    on<LoadClaims>(_onLoad);
    on<ResolveClaim>(_onResolve);
  }

  Future<void> _onLoad(LoadClaims event, Emitter<ClaimsState> emit) async {
    emit(ClaimsLoading());
    try {
      final claims = await _service.getClaims(lineIds: event.lineIds);
      emit(ClaimsLoaded(claims, event.lineIds));
    } catch (e) {
      emit(ClaimsError('Error al cargar reclamos: $e'));
    }
  }

  Future<void> _onResolve(ResolveClaim event, Emitter<ClaimsState> emit) async {
    final current = state;
    try {
      await _service.resolveClaim(
        event.claimId,
        resolvedBy: event.resolvedBy,
        resolutionNote: event.resolutionNote,
      );
      if (current is ClaimsLoaded) {
        add(LoadClaims(lineIds: current.lineIds));
      }
    } catch (e) {
      emit(ClaimsError('No se pudo resolver el reclamo: $e'));
    }
  }
}
