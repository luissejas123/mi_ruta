import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/tickeador/domain/services/tickeador_service.dart';

void main() {
  group('QR de pago del tickeador', () {
    test('decodifica el formato usado por el conductor', () {
      final payload = TripQrPayload.parse('driver-1|trip-2|3.50');

      expect(payload.driverId, 'driver-1');
      expect(payload.tripId, 'trip-2');
      expect(payload.amount, 3.5);
    });

    test('rechaza códigos incompletos o con campos extra', () {
      expect(() => TripQrPayload.parse('trip-2'), throwsFormatException);
      expect(
        () => TripQrPayload.parse('driver|trip|3.5|extra'),
        throwsFormatException,
      );
    });

    test('rechaza montos inválidos o no finitos', () {
      expect(() => TripQrPayload.parse('driver|trip|0'), throwsFormatException);
      expect(
        () => TripQrPayload.parse('driver|trip|NaN'),
        throwsFormatException,
      );
      expect(
        () => TripQrPayload.parse('driver|trip|Infinity'),
        throwsFormatException,
      );
    });
  });
}
