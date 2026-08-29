import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Eventos del BLoC MiRuta.
abstract class MiRutaEvent extends Equatable {
  const MiRutaEvent();

  @override
  List<Object?> get props => [];
}

/// Solicita obtener la ubicación del GPS actual del dispositivo.
class MiRutaLocationRequested extends MiRutaEvent {
  const MiRutaLocationRequested();
}

/// Centra la cámara en la posición actual obtenida por GPS.
class MiRutaGoToMyLocationRequested extends MiRutaEvent {
  const MiRutaGoToMyLocationRequested();
}

/// Alterna entre el modo pin/arrastre interactivo en el mapa.
class MiRutaPinModeToggled extends MiRutaEvent {
  const MiRutaPinModeToggled();
}

/// Registra el movimiento de la cámara del mapa actualizando el centro.
class MiRutaCameraMoved extends MiRutaEvent {
  final LatLng position;

  const MiRutaCameraMoved(this.position);

  @override
  List<Object?> get props => [position];
}

/// Ejecuta geocodificación inversa cuando la cámara se detiene en modo PIN.
class MiRutaCameraIdle extends MiRutaEvent {
  const MiRutaCameraIdle();
}

/// Confirma la coordenada bajo el PIN como destino seleccionado.
class MiRutaPinDestinationConfirmed extends MiRutaEvent {
  const MiRutaPinDestinationConfirmed();
}

/// Limpia el destino seleccionado y el cuadro de búsqueda.
class MiRutaClearSearch extends MiRutaEvent {
  const MiRutaClearSearch();
}

/// Cambia la pestaña seleccionada del bottom navigation bar.
class MiRutaNavTabSelected extends MiRutaEvent {
  final int index;

  const MiRutaNavTabSelected(this.index);

  @override
  List<Object?> get props => [index];
}
