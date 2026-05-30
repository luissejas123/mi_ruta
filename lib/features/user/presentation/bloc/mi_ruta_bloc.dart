import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/usecases/get_current_location_usecase.dart';
import 'package:mi_ruta/features/user/domain/usecases/reverse_geocode_usecase.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_state.dart';

/// Controlador de estado (BLoC) para gestionar la geolocalización,
/// la interacción con el mapa y la selección de destinos.
class MiRutaBloc extends Bloc<MiRutaEvent, MiRutaState> {
  final GetCurrentLocationUseCase getCurrentLocationUseCase;
  final ReverseGeocodeUseCase reverseGeocodeUseCase;

  MiRutaBloc({
    required this.getCurrentLocationUseCase,
    required this.reverseGeocodeUseCase,
  }) : super(const MiRutaState()) {
    on<MiRutaLocationRequested>(_onLocationRequested);
    on<MiRutaGoToMyLocationRequested>(_onGoToMyLocationRequested);
    on<MiRutaPinModeToggled>(_onPinModeToggled);
    on<MiRutaCameraMoved>(_onCameraMoved);
    on<MiRutaCameraIdle>(_onCameraIdle);
    on<MiRutaPinDestinationConfirmed>(_onPinDestinationConfirmed);
    on<MiRutaClearSearch>(_onClearSearch);
    on<MiRutaNavTabSelected>(_onNavTabSelected);
  }

  Future<void> _onLocationRequested(
    MiRutaLocationRequested event,
    Emitter<MiRutaState> emit,
  ) async {
    emit(state.copyWith(isLocationLoading: true));
    final result = await getCurrentLocationUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        statusText: () => failure.message,
        isLocationLoading: false,
      )),
      (location) => emit(state.copyWith(
        myLocationLatLng: () => location,
        cameraCenter: () => location,
        cameraUpdateLocation: () => location,
        cameraTriggerCount: state.cameraTriggerCount + 1,
        isLocationLoading: false,
        statusText: () => null,
      )),
    );
  }

  Future<void> _onGoToMyLocationRequested(
    MiRutaGoToMyLocationRequested event,
    Emitter<MiRutaState> emit,
  ) async {
    if (state.myLocationLatLng != null) {
      emit(state.copyWith(
        cameraUpdateLocation: () => state.myLocationLatLng,
        cameraTriggerCount: state.cameraTriggerCount + 1,
      ));
    } else {
      add(const MiRutaLocationRequested());
    }
  }

  void _onPinModeToggled(
    MiRutaPinModeToggled event,
    Emitter<MiRutaState> emit,
  ) {
    final newPinMode = !state.isPinMode;
    emit(state.copyWith(
      isPinMode: newPinMode,
      cameraCenter: () => newPinMode ? (state.cameraCenter ?? state.myLocationLatLng) : null,
      pinAddress: () => null,
    ));

    if (newPinMode && state.cameraCenter != null) {
      add(const MiRutaCameraIdle());
    }
  }

  void _onCameraMoved(
    MiRutaCameraMoved event,
    Emitter<MiRutaState> emit,
  ) {
    emit(state.copyWith(
      cameraCenter: () => event.position,
      isCameraMoving: state.isPinMode ? true : state.isCameraMoving,
    ));
  }

  Future<void> _onCameraIdle(
    MiRutaCameraIdle event,
    Emitter<MiRutaState> emit,
  ) async {
    if (!state.isPinMode || state.cameraCenter == null) return;
    emit(state.copyWith(isCameraMoving: false, isGeocodingLoading: true));
    final result = await reverseGeocodeUseCase(state.cameraCenter!);
    result.fold(
      (failure) => emit(state.copyWith(
        pinAddress: () => 'Dirección no disponible',
        isGeocodingLoading: false,
      )),
      (address) => emit(state.copyWith(
        pinAddress: () => address,
        isGeocodingLoading: false,
      )),
    );
  }

  void _onPinDestinationConfirmed(
    MiRutaPinDestinationConfirmed event,
    Emitter<MiRutaState> emit,
  ) {
    if (state.cameraCenter == null) return;
    emit(state.copyWith(
      destinationLatLng: () => state.cameraCenter,
      searchText: () => state.pinAddress ?? 'Destino',
      isPinMode: false,
      pinAddress: () => null,
    ));
  }

  void _onClearSearch(
    MiRutaClearSearch event,
    Emitter<MiRutaState> emit,
  ) {
    emit(state.copyWith(
      destinationLatLng: () => null,
      searchText: () => null,
      cameraUpdateLocation: () => state.myLocationLatLng,
      cameraTriggerCount: state.cameraTriggerCount + 1,
    ));
  }

  void _onNavTabSelected(
    MiRutaNavTabSelected event,
    Emitter<MiRutaState> emit,
  ) {
    emit(state.copyWith(selectedIndex: event.index));
  }
}
