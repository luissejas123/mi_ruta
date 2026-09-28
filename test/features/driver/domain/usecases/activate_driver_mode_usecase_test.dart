import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_legal_documents.dart';
import 'package:mi_ruta/features/driver/domain/repositories/driver_repository.dart';
import 'package:mi_ruta/features/driver/domain/usecases/activate_driver_mode_usecase.dart';

class MockDriverRepository extends Mock implements DriverRepository {}

void main() {
  late MockDriverRepository repository;
  late ActivateDriverModeUseCase useCase;

  const userId = 'user_123';

  Vehicle buildVehicle(String status) => Vehicle(
        id: 'ABC-1234',
        ownerUid: userId,
        vehicleType: 'taxitrufi',
        lineNumber: '233',
        internalNumber: '12',
        brand: 'Toyota',
        model: 'Hiace',
        color: 'Blanco',
        passengerCapacity: 15,
        status: status,
        legalDocuments: const VehicleLegalDocuments(
          soatUrl: 'https://example.com/soat.jpg',
          vehicleInspectionUrl: 'https://example.com/inspection.jpg',
          driverLicenseUrl: 'https://example.com/license.jpg',
          municipalOperationCardUrl: 'https://example.com/municipal.jpg',
          ruatUrl: 'https://example.com/ruat.jpg',
        ),
        updatedAt: DateTime(2026, 1, 1),
      );

  setUp(() {
    repository = MockDriverRepository();
    useCase = ActivateDriverModeUseCase(repository: repository);
  });

  test(
    'retorna Left ("aún no fue aprobada") cuando el usuario nunca solicitó '
    'convertirse en chofer (NoVehicleApplication → null)',
    () async {
      when(() => repository.getMyVehicleApplication(userId))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(userId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('aún no fue aprobada')),
        (_) => fail('se esperaba Left, se obtuvo Right'),
      );
      verifyNever(() => repository.activateDriverMode(any()));
    },
  );

  test(
    'retorna Left ("aún no fue aprobada") cuando la solicitud está '
    "status='pending_review'",
    () async {
      when(() => repository.getMyVehicleApplication(userId))
          .thenAnswer((_) async => Right(buildVehicle('pending_review')));

      final result = await useCase(userId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('aún no fue aprobada')),
        (_) => fail('se esperaba Left, se obtuvo Right'),
      );
      verifyNever(() => repository.activateDriverMode(any()));
    },
  );

  test(
    "llama a repository.activateDriverMode y retorna Right cuando la "
    "solicitud está status='approved'",
    () async {
      when(() => repository.getMyVehicleApplication(userId))
          .thenAnswer((_) async => Right(buildVehicle('approved')));
      when(() => repository.activateDriverMode(userId))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(userId);

      expect(result, const Right<Failure, void>(null));
      verify(() => repository.activateDriverMode(userId)).called(1);
    },
  );
}
