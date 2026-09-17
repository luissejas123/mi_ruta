import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/presidente/domain/usecases/tariff_usecases.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/tariff_event.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/tariff_state.dart';

class TariffBloc extends Bloc<TariffEvent, TariffState> {
  final GetTariffUseCase getTariffUseCase;
  final SaveTariffUseCase saveTariffUseCase;

  TariffBloc({
    required this.getTariffUseCase,
    required this.saveTariffUseCase,
  }) : super(const TariffInitial()) {
    on<LoadTariff>(_onLoadTariff);
    on<SaveTariffRequested>(_onSaveTariff);
  }

  Future<void> _onLoadTariff(
    LoadTariff event,
    Emitter<TariffState> emit,
  ) async {
    emit(const TariffLoading());
    final result = await getTariffUseCase(event.routeRef);
    result.fold(
      (failure) => emit(TariffError(message: failure.message)),
      (tariff) => emit(TariffLoaded(tariff: tariff)),
    );
  }

  Future<void> _onSaveTariff(
    SaveTariffRequested event,
    Emitter<TariffState> emit,
  ) async {
    final result = await saveTariffUseCase(
      routeRef: event.routeRef,
      pricePerKmBs: event.pricePerKmBs,
    );
    result.fold(
      (failure) => emit(TariffError(message: failure.message)),
      (tariff) => emit(TariffLoaded(tariff: tariff, justSaved: true)),
    );
  }
}
