import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/usecases/admin_route_usecases.dart';
import 'package:mi_ruta/features/admin/domain/usecases/get_transported_passengers_usecase.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/transported_passengers_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/transported_passengers_state.dart';

class TransportedPassengersBloc
    extends Bloc<TransportedPassengersEvent, TransportedPassengersState> {
  final GetAdminRoutesUseCase getAdminRoutesUseCase;
  final GetTransportedPassengersUseCase getTransportedPassengersUseCase;

  TransportedPassengersBloc({
    required this.getAdminRoutesUseCase,
    required this.getTransportedPassengersUseCase,
  }) : super(const TransportedPassengersState()) {
    on<LoadRoutesForQueryEvent>(_onLoadRoutes);
    on<SearchTransportedPassengersEvent>(_onSearch);
  }

  Future<void> _onLoadRoutes(
    LoadRoutesForQueryEvent event,
    Emitter<TransportedPassengersState> emit,
  ) async {
    emit(state.copyWith(isLoadingRoutes: true, routesError: () => null));
    final result = await getAdminRoutesUseCase();
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingRoutes: false,
          routesError: () => failure.message,
        ),
      ),
      (routes) => emit(
        state.copyWith(isLoadingRoutes: false, routes: routes),
      ),
    );
  }

  Future<void> _onSearch(
    SearchTransportedPassengersEvent event,
    Emitter<TransportedPassengersState> emit,
  ) async {
    emit(state.copyWith(isSearching: true, searchError: () => null));
    final result = await getTransportedPassengersUseCase(
      routeRef: event.routeRef,
      from: event.from,
      to: event.to,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(isSearching: false, searchError: () => failure.message),
      ),
      (report) => emit(
        state.copyWith(isSearching: false, report: () => report),
      ),
    );
  }
}
