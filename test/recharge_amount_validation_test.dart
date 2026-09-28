import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/user/domain/services/recharge_service.dart';

void main() {
  group('Validación del monto de recarga QR', () {
    test('acepta montos positivos hasta Bs. 5.000', () {
      expect(RechargeService.validateAmount(0.01), isNull);
      expect(RechargeService.validateAmount(5000), isNull);
    });

    test('rechaza valores vacíos, no finitos y no positivos', () {
      expect(RechargeService.validateAmount(null), isNotNull);
      expect(RechargeService.validateAmount(0), isNotNull);
      expect(RechargeService.validateAmount(-1), isNotNull);
      expect(RechargeService.validateAmount(double.nan), isNotNull);
      expect(RechargeService.validateAmount(double.infinity), isNotNull);
    });

    test('rechaza montos mayores a Bs. 5.000', () {
      expect(RechargeService.validateAmount(5000.01), isNotNull);
      expect(RechargeService.validateAmount(1e39), isNotNull);
    });
  });
}
