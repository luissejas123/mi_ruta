import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/tickeador/data/datasources/tickeador_datasource.dart';

void main() {
  group('TickeadorDatasource index fallback', () {
    test('detecta el error de índice compuesto faltante en Firestore', () {
      const error = 'FAILED_PRECONDITION: The query requires an index. Create it here: https://console.firebase.google.com/...';

      expect(TickeadorDatasource.isMissingCompositeIndexError(error), isTrue);
    });

    test('no marca como error de índice un error normal', () {
      const error = 'Permission denied';

      expect(TickeadorDatasource.isMissingCompositeIndexError(error), isFalse);
    });
  });
}
