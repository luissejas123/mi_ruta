import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/demo/demo_constants.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_active_vehicles_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_active_vehicles_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/usecases/vehicle_usecases.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';
import 'package:mi_ruta/features/user/domain/usecases/user_usecases.dart';

/// Resultado intermedio: unidades activas ya cruzadas con sus choferes.
class _Combined {
  final List<VehicleEntity>? vehicles;
  final Map<String, UserEntity>? driversByUid;
  final String? errorMessage;

  const _Combined.loaded(this.vehicles, this.driversByUid)
      : errorMessage = null;
  const _Combined.error(this.errorMessage)
      : vehicles = null,
        driversByUid = null;
}

/// BLoC para la vista admin de unidades actualmente activas.
class AdminActiveVehiclesBloc
    extends Bloc<AdminActiveVehiclesEvent, AdminActiveVehiclesState> {
  final GetActiveVehiclesStreamUseCase getActiveVehiclesStreamUseCase;
  final GetUsersByIdsUseCase getUsersByIdsUseCase;

  AdminActiveVehiclesBloc({
    required this.getActiveVehiclesStreamUseCase,
    required this.getUsersByIdsUseCase,
  }) : super(const AdminVehiclesInitial()) {
    on<WatchActiveVehicles>(_onWatchActiveVehicles);
    on<WatchStaticDemoVehicles>(_onWatchStaticDemoVehicles);
  }

  /// TEMPORAL — modo prueba: lista fija en memoria, sin Firestore.
  void _onWatchStaticDemoVehicles(
    WatchStaticDemoVehicles event,
    Emitter<AdminActiveVehiclesState> emit,
  ) {
    final now = DateTime.now();
    final demoVehicle = VehicleEntity(
      vehicleId: kStaticDemoVehicleId,
      ownerUid: kStaticDemoDriverUid,
      vehicleType: 'micro',
      lineNumber: '101',
      internalNumber: '01',
      brand: 'Volkswagen',
      model: 'Crafter',
      color: 'Blanco',
      passengerCapacity: 20,
      status: 'approved',
      legalDocumentation: const {},
      isOnDuty: true,
      isOnDutyUpdatedAt: now,
      updatedAt: now,
    );
    final demoDriver = UserEntity(
      uid: kStaticDemoDriverUid,
      fullName: 'Demo (Chofer)',
      email: '',
      phoneNumber: '',
      userType: 'driver',
      profileImageUrl: '',
      rating: 0,
      reviewsCount: 0,
      walletBalance: 0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    emit(AdminVehiclesLoaded(
      vehicles: [demoVehicle],
      driversByUid: {kStaticDemoDriverUid: demoDriver},
    ));
  }

  Future<void> _onWatchActiveVehicles(
    WatchActiveVehicles event,
    Emitter<AdminActiveVehiclesState> emit,
  ) async {
    emit(const AdminVehiclesLoading());

    final combinedStream = getActiveVehiclesStreamUseCase().asyncMap((either) {
      return either.fold(
        (failure) async => _Combined.error(failure.message),
        (vehicles) async {
          final ownerUids = vehicles
              .map((v) => v.ownerUid)
              .where((uid) => uid.isNotEmpty)
              .toSet()
              .toList();

          final driversByUid = <String, UserEntity>{};
          if (ownerUids.isNotEmpty) {
            final usersResult = await getUsersByIdsUseCase(ownerUids);
            usersResult.fold(
              (_) {},
              (users) {
                for (final user in users) {
                  driversByUid[user.uid] = user;
                }
              },
            );
          }
          return _Combined.loaded(vehicles, driversByUid);
        },
      );
    });

    await emit.forEach<_Combined>(
      combinedStream,
      onData: (combined) {
        if (combined.errorMessage != null) {
          return AdminVehiclesError(message: combined.errorMessage!);
        }
        return AdminVehiclesLoaded(
          vehicles: combined.vehicles!,
          driversByUid: combined.driversByUid!,
        );
      },
      onError: (error, stackTrace) {
        return AdminVehiclesError(
            message: 'Error en stream de unidades activas: $error');
      },
    );
  }
}
