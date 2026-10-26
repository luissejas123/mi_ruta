import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/user/domain/services/trip_line_validator.dart';
import 'package:mi_ruta/features/user/domain/services/trip_payment_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDocRef extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _MockDocSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _MockTripPaymentService extends Mock implements TripPaymentService {}

void main() {
  group('TripLineValidator', () {
    test('acepta la misma línea (ignora espacios y mayúsculas)', () {
      expect(
        () => TripLineValidator.ensureSameLine(
          boardedRouteRef: '108',
          qrRouteRef: ' 108 ',
        ),
        returnsNormally,
      );
      expect(
        () => TripLineValidator.ensureSameLine(
          boardedRouteRef: 'b',
          qrRouteRef: 'B',
        ),
        returnsNormally,
      );
    });

    test('rechaza una línea diferente', () {
      expect(
        () => TripLineValidator.ensureSameLine(
          boardedRouteRef: '108',
          qrRouteRef: '230',
        ),
        throwsA(
          isA<TripQrValidationException>().having(
            (e) => e.message,
            'message',
            TripLineValidator.mismatchMessage,
          ),
        ),
      );
    });

    test('rechaza cuando el viaje del QR no tiene línea', () {
      for (final missing in [null, '', '   ', 42]) {
        expect(
          () => TripLineValidator.ensureSameLine(
            boardedRouteRef: '108',
            qrRouteRef: missing,
          ),
          throwsA(
            isA<TripQrValidationException>().having(
              (e) => e.message,
              'message',
              TripLineValidator.unknownQrLineMessage,
            ),
          ),
        );
      }
    });

    test('rechaza cuando no se conoce la línea abordada', () {
      for (final missing in [null, '']) {
        expect(
          () => TripLineValidator.ensureSameLine(
            boardedRouteRef: missing,
            qrRouteRef: '108',
          ),
          throwsA(
            isA<TripQrValidationException>().having(
              (e) => e.message,
              'message',
              TripLineValidator.unknownBoardedLineMessage,
            ),
          ),
        );
      }
    });
  });

  group('TripPaymentService.processPayment — validación de línea', () {
    late _MockFirestore firestore;
    late _MockCollection trips;
    late _MockCollection users;
    late TripPaymentService service;

    void stubTrip(String tripId, Map<String, dynamic> data) {
      final ref = _MockDocRef();
      final snap = _MockDocSnapshot();
      when(() => trips.doc(tripId)).thenReturn(ref);
      when(() => ref.get()).thenAnswer((_) async => snap);
      when(() => snap.exists).thenReturn(true);
      when(() => snap.data()).thenReturn(data);
    }

    setUp(() {
      firestore = _MockFirestore();
      trips = _MockCollection();
      users = _MockCollection();
      when(() => firestore.collection('trips')).thenReturn(trips);
      when(() => firestore.collection('users')).thenReturn(users);
      service = TripPaymentService(firestore: firestore);
    });

    test('QR ilegible o con formato inválido: no toca Firestore', () async {
      for (final qr in ['texto-cualquiera', 'd|t', 'd|t|3|x', '|t|3', 'd|t|NaN']) {
        final result = await service.processPayment(
          userId: 'u1',
          qrData: qr,
          expectedRouteRef: '108',
        );
        expect(result['success'], isFalse, reason: qr);
      }
      verifyZeroInteractions(firestore);
    });

    test('QR de otro viaje que el abordaje en curso: no toca Firestore',
        () async {
      final result = await service.processPayment(
        userId: 'u1',
        qrData: 'driver-1|otro-viaje|3.0',
        expectedRouteRef: '108',
        expectedTripId: 'trip-1',
      );
      expect(result['success'], isFalse);
      expect(result['message'], TripLineValidator.tripMismatchMessage);
      verifyZeroInteractions(firestore);
    });

    test('QR válido de una línea diferente: se bloquea antes de cobrar',
        () async {
      stubTrip('trip-1', {
        'driver_id': 'driver-1',
        'route_ref': '230',
        'payment_status': 'pending',
      });

      final result = await service.processPayment(
        userId: 'u1',
        qrData: 'driver-1|trip-1|3.0',
        expectedRouteRef: '108',
        expectedTripId: 'trip-1',
      );

      expect(result['success'], isFalse);
      expect(result['message'], TripLineValidator.mismatchMessage);
      // Nunca llegó a leer saldo ni a abrir la transacción de cobro.
      verifyNever(() => firestore.collection('users'));
    });

    test('viaje del QR sin route_ref: no se cobra', () async {
      stubTrip('trip-1', {
        'driver_id': 'driver-1',
        'payment_status': 'pending',
      });

      final result = await service.processPayment(
        userId: 'u1',
        qrData: 'driver-1|trip-1|3.0',
        expectedRouteRef: '108',
      );

      expect(result['success'], isFalse);
      expect(result['message'], TripLineValidator.unknownQrLineMessage);
      verifyNever(() => firestore.collection('users'));
    });

    test('QR válido de la misma línea: continúa con el cobro existente',
        () async {
      stubTrip('trip-1', {
        'driver_id': 'driver-1',
        'route_ref': '108',
        'payment_status': 'pending',
      });
      // Corta el flujo existente justo después de la validación (usuario
      // inexistente) para comprobar que la validación lo dejó pasar.
      final userRef = _MockDocRef();
      final userSnap = _MockDocSnapshot();
      when(() => users.doc('u1')).thenReturn(userRef);
      when(() => userRef.get()).thenAnswer((_) async => userSnap);
      when(() => userSnap.exists).thenReturn(false);

      final result = await service.processPayment(
        userId: 'u1',
        qrData: 'driver-1|trip-1|3.0',
        expectedRouteRef: '108',
        expectedTripId: 'trip-1',
      );

      expect(result['success'], isFalse);
      expect(result['message'], contains('Usuario no encontrado'));
      verify(() => firestore.collection('users')).called(1);
    });
  });

  group('TripPaymentBLoC — reintentos y disparos repetidos', () {
    late _MockTripPaymentService service;

    setUp(() {
      service = _MockTripPaymentService();
    });

    void stubProcess(Future<Map<String, dynamic>> Function() answer) {
      when(
        () => service.processPayment(
          userId: any(named: 'userId'),
          qrData: any(named: 'qrData'),
          expectedRouteRef: any(named: 'expectedRouteRef'),
          expectedTripId: any(named: 'expectedTripId'),
        ),
      ).thenAnswer((_) => answer());
    }

    const event = ProcessPaymentEvent(
      userId: 'u1',
      qrData: 'driver-1|trip-1|3.0',
      expectedRouteRef: '108',
      expectedTripId: 'trip-1',
    );

    test('pasa la línea y el viaje esperados al servicio', () async {
      stubProcess(
        () async => {'success': false, 'message': 'x'},
      );
      final bloc = TripPaymentBLoC(tripPaymentService: service);
      bloc.add(event);
      await bloc.stream.firstWhere((s) => s is TripPaymentError);

      verify(
        () => service.processPayment(
          userId: 'u1',
          qrData: 'driver-1|trip-1|3.0',
          expectedRouteRef: '108',
          expectedTripId: 'trip-1',
        ),
      ).called(1);
      await bloc.close();
    });

    test('ignora un segundo cobro mientras el primero está en curso',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      stubProcess(() => completer.future);
      final bloc = TripPaymentBLoC(tripPaymentService: service);

      bloc.add(event);
      await bloc.stream.firstWhere((s) => s is TripPaymentLoading);
      bloc.add(event);
      bloc.add(event);
      await Future<void>.delayed(Duration.zero);

      completer.complete({
        'success': true,
        'message': 'ok',
        'amount': 3.0,
        'newBalance': 7.0,
        'tripId': 'trip-1',
      });
      await bloc.stream.firstWhere((s) => s is TripPaymentSuccess);

      verify(
        () => service.processPayment(
          userId: any(named: 'userId'),
          qrData: any(named: 'qrData'),
          expectedRouteRef: any(named: 'expectedRouteRef'),
          expectedTripId: any(named: 'expectedTripId'),
        ),
      ).called(1);
      await bloc.close();
    });

    test('tras un error (p. ej. otra línea) se puede reintentar', () async {
      var calls = 0;
      stubProcess(() async {
        calls++;
        return calls == 1
            ? {'success': false, 'message': TripLineValidator.mismatchMessage}
            : {
                'success': true,
                'message': 'ok',
                'amount': 3.0,
                'newBalance': 7.0,
                'tripId': 'trip-1',
              };
      });
      final bloc = TripPaymentBLoC(tripPaymentService: service);

      bloc.add(event);
      final error = await bloc.stream.firstWhere((s) => s is TripPaymentError);
      expect(
        (error as TripPaymentError).message,
        TripLineValidator.mismatchMessage,
      );

      bloc.add(event);
      await bloc.stream.firstWhere((s) => s is TripPaymentSuccess);
      expect(calls, 2);
      await bloc.close();
    });
  });
}
