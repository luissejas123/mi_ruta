import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

// ── Eventos ──

abstract class TickeadorAssignmentEvent extends Equatable {
  const TickeadorAssignmentEvent();

  @override
  List<Object?> get props => [];
}

/// Carga los candidatos y las líneas reales sobre las que se puede asignar.
class LoadTickeadorAssignment extends TickeadorAssignmentEvent {
  const LoadTickeadorAssignment();
}

class AssignTickeador extends TickeadorAssignmentEvent {
  final String uid;
  final String assignedStation;
  final List<String> assignedLines;

  const AssignTickeador({
    required this.uid,
    required this.assignedStation,
    required this.assignedLines,
  });

  @override
  List<Object?> get props => [uid, assignedStation, assignedLines];
}

// ── Estados ──

abstract class TickeadorAssignmentState extends Equatable {
  const TickeadorAssignmentState();

  @override
  List<Object?> get props => [];
}

class TickeadorAssignmentInitial extends TickeadorAssignmentState {
  const TickeadorAssignmentInitial();
}

class TickeadorAssignmentLoading extends TickeadorAssignmentState {
  const TickeadorAssignmentLoading();
}

class TickeadorAssignmentLoaded extends TickeadorAssignmentState {
  /// Cuentas que aún no son tickeador y pueden serlo.
  final List<UserEntity> candidates;

  /// Tickeadores ya asignados.
  final List<UserEntity> tickeadores;

  /// Refs de línea reales (GTFS, vía `RouteService`) para elegir.
  final List<String> availableLines;

  const TickeadorAssignmentLoaded({
    required this.candidates,
    required this.tickeadores,
    required this.availableLines,
  });

  @override
  List<Object?> get props => [candidates, tickeadores, availableLines];
}

class TickeadorAssignmentError extends TickeadorAssignmentState {
  final String message;

  const TickeadorAssignmentError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── BLoC ──

/// "Asignar tickeador": lista de cuentas + líneas reales, y la escritura del
/// rol `tickeador` con su `tickeador_info`. Lo dispara `presidente`/`admin`.
class TickeadorAssignmentBloc
    extends Bloc<TickeadorAssignmentEvent, TickeadorAssignmentState> {
  final UserManagementService _userService;
  final RouteService _routeService;

  TickeadorAssignmentBloc({
    required UserManagementService userService,
    required RouteService routeService,
  })  : _userService = userService,
        _routeService = routeService,
        super(const TickeadorAssignmentInitial()) {
    on<LoadTickeadorAssignment>(_onLoad);
    on<AssignTickeador>(_onAssign);
  }

  Future<void> _onLoad(
    LoadTickeadorAssignment event,
    Emitter<TickeadorAssignmentState> emit,
  ) async {
    emit(const TickeadorAssignmentLoading());
    await _load(emit);
  }

  Future<void> _load(Emitter<TickeadorAssignmentState> emit) async {
    try {
      final users = await _userService.getUsers();
      // Las líneas salen de las rutas GTFS sembradas, no de una lista fija.
      // Ligero: solo se usa route.ref para armar la lista de líneas.
      final routes = await _routeService.getAllActiveRoutesLight();
      final lines = routes
          .map((r) => r.ref)
          .where((ref) => ref.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      emit(TickeadorAssignmentLoaded(
        candidates:
            users.where((u) => u.userType != 'tickeador').toList(),
        tickeadores:
            users.where((u) => u.userType == 'tickeador').toList(),
        availableLines: lines,
      ));
    } catch (e) {
      emit(TickeadorAssignmentError('Error al cargar los datos: $e'));
    }
  }

  Future<void> _onAssign(
    AssignTickeador event,
    Emitter<TickeadorAssignmentState> emit,
  ) async {
    try {
      await _userService.assignTickeador(
        event.uid,
        assignedStation: event.assignedStation,
        assignedLines: event.assignedLines,
      );
    } catch (e) {
      emit(TickeadorAssignmentError('Error al asignar el tickeador: $e'));
      return;
    }
    await _load(emit);
  }
}
