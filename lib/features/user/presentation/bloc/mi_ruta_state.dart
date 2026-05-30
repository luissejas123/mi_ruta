import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Estado de la pantalla MiRuta.
class MiRutaState extends Equatable {
  /// Ubicación GPS actual del dispositivo.
  final LatLng? myLocationLatLng;

  /// Ubicación de destino seleccionada y confirmada.
  final LatLng? destinationLatLng;

  /// Texto a mostrar en el cuadro de búsqueda (nombre de dirección o "Destino").
  final String? searchText;

  /// Mensaje de estado (ej. errores de GPS).
  final String? statusText;

  /// Pestaña seleccionada en el menú de navegación inferior.
  final int selectedIndex;

  /// Indica si está activo el modo interactivo para seleccionar con un pin en el mapa.
  final bool isPinMode;

  /// Dirección obtenida mediante geocodificación inversa para el pin actual.
  final String? pinAddress;

  /// Indica si la cámara se encuentra en movimiento (arrastrándose).
  final bool isCameraMoving;

  /// Coordenada central del mapa (bajo el PIN si isPinMode es true).
  final LatLng? cameraCenter;

  /// Indica si se está obteniendo la ubicación actual por GPS.
  final bool isLocationLoading;

  /// Indica si se está realizando geocodificación.
  final bool isGeocodingLoading;

  /// Coordenada a la cual la vista debe animar la cámara del mapa.
  final LatLng? cameraUpdateLocation;

  /// Contador utilizado para disparar la animación de cámara en el BlocListener.
  final int cameraTriggerCount;

  const MiRutaState({
    this.myLocationLatLng,
    this.destinationLatLng,
    this.searchText,
    this.statusText,
    this.selectedIndex = 0,
    this.isPinMode = false,
    this.pinAddress,
    this.isCameraMoving = false,
    this.cameraCenter,
    this.isLocationLoading = false,
    this.isGeocodingLoading = false,
    this.cameraUpdateLocation,
    this.cameraTriggerCount = 0,
  });

  MiRutaState copyWith({
    LatLng? Function()? myLocationLatLng,
    LatLng? Function()? destinationLatLng,
    String? Function()? searchText,
    String? Function()? statusText,
    int? selectedIndex,
    bool? isPinMode,
    String? Function()? pinAddress,
    bool? isCameraMoving,
    LatLng? Function()? cameraCenter,
    bool? isLocationLoading,
    bool? isGeocodingLoading,
    LatLng? Function()? cameraUpdateLocation,
    int? cameraTriggerCount,
  }) {
    return MiRutaState(
      myLocationLatLng: myLocationLatLng != null ? myLocationLatLng() : this.myLocationLatLng,
      destinationLatLng: destinationLatLng != null ? destinationLatLng() : this.destinationLatLng,
      searchText: searchText != null ? searchText() : this.searchText,
      statusText: statusText != null ? statusText() : this.statusText,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isPinMode: isPinMode ?? this.isPinMode,
      pinAddress: pinAddress != null ? pinAddress() : this.pinAddress,
      isCameraMoving: isCameraMoving ?? this.isCameraMoving,
      cameraCenter: cameraCenter != null ? cameraCenter() : this.cameraCenter,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      isGeocodingLoading: isGeocodingLoading ?? this.isGeocodingLoading,
      cameraUpdateLocation: cameraUpdateLocation != null ? cameraUpdateLocation() : this.cameraUpdateLocation,
      cameraTriggerCount: cameraTriggerCount ?? this.cameraTriggerCount,
    );
  }

  @override
  List<Object?> get props => [
        myLocationLatLng,
        destinationLatLng,
        searchText,
        statusText,
        selectedIndex,
        isPinMode,
        pinAddress,
        isCameraMoving,
        cameraCenter,
        isLocationLoading,
        isGeocodingLoading,
        cameraUpdateLocation,
        cameraTriggerCount,
      ];
}
