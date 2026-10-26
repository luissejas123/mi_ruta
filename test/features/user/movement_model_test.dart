import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/user/domain/entities/movement_entity.dart';
import 'package:mi_ruta/features/user/domain/entities/wallet.dart';
import 'package:mi_ruta/features/user/data/models/movement_model.dart';
import 'package:mi_ruta/features/user/domain/services/wallet_service.dart';
import 'package:mi_ruta/features/user/data/datasources/wallet_datasource.dart';

class MockWalletDatasource implements WalletDatasource {
  @override
  Future<void> createWallet(String userId, {double initialBalance = 0.0}) async {}
  @override
  Future<void> deductTripPayment(String userId, double amount, {required String routeNumber, required String routeName, String? tripId}) async {}
  @override
  Future<List<MovementModel>> getTransactionHistory(String userId, {int limit = 50}) async => [];
  @override
  Future<Wallet?> getWalletByUserId(String userId) async => null;
  @override
  Future<Wallet?> initializeWalletIfNotExists(String userId) async => null;
  @override
  Future<void> topUpBalance(String userId, double amount) async {}
  @override
  Future<void> updateBalance(String userId, double newBalance) async {}
  @override
  Future<List<Map<String, dynamic>>> getDriverEarningsTransactions(String userId) async => [];
}

void main() {
  group('MovementEntity & MovementModel - Obs 4', () {
    test('MovementModel deserializa formato canónico nuevo con los 6 campos', () {
      final now = DateTime(2026, 10, 23, 12, 0, 0);
      final json = {
        'id': 'tx_001',
        'user_id': 'user_123',
        'tipo': 'pago_viaje',
        'monto': 2.50,
        'linea': '106',
        'ruta': 'Quillacollo - Cochabamba',
        'viaje_id': 'TRP_001',
        'fecha': Timestamp.fromDate(now),
        'estado': 'completed',
        'descripcion': 'Pago Línea 106 - Quillacollo - Cochabamba',
      };

      final model = MovementModel.fromJson(json, docId: 'tx_001');

      expect(model.id, 'tx_001');
      expect(model.userId, 'user_123');
      expect(model.tipo, MovementType.pagoViaje);
      expect(model.monto, 2.50);
      expect(model.linea, '106');
      expect(model.ruta, 'Quillacollo - Cochabamba');
      expect(model.viajeId, 'TRP_001');
      expect(model.fecha, now);
      expect(model.estado, MovementStatus.completed);
      expect(model.isIncome, false);
      expect(model.signedAmount, -2.50);
      expect(model.formattedSignedAmount, '- Bs. 2.50');
    });

    test('MovementModel es retrocompatible con esquemas legacy antiguos', () {
      final now = DateTime(2026, 10, 20, 15, 30);
      final legacyJson = {
        'user_id': 'user_456',
        'transaction_type': 'recharge',
        'amount': 50.0,
        'timestamp': Timestamp.fromDate(now),
        'status': 'approved',
        'description': 'Recarga con QR',
      };

      final model = MovementModel.fromJson(legacyJson, docId: 'leg_01');

      expect(model.id, 'leg_01');
      expect(model.userId, 'user_456');
      expect(model.tipo, MovementType.recarga);
      expect(model.monto, 50.0);
      expect(model.linea, isNull);
      expect(model.ruta, isNull);
      expect(model.viajeId, isNull);
      expect(model.estado, MovementStatus.completed);
      expect(model.isIncome, true);
      expect(model.signedAmount, 50.0);
      expect(model.formattedSignedAmount, '+ Bs. 50.00');
    });

    test('MovementModel normaliza montos negativos provenientes de legacy trip_payment', () {
      final legacyTripPayment = {
        'user_id': 'user_789',
        'transaction_type': 'trip_payment',
        'amount': -3.0,
        'trip_id': 'TRP_999',
        'status': 'completed',
      };

      final model = MovementModel.fromJson(legacyTripPayment, docId: 'leg_02');

      expect(model.monto, 3.0);
      expect(model.tipo, MovementType.pagoViaje);
      expect(model.viajeId, 'TRP_999');
      expect(model.signedAmount, -3.0);
    });

    test('toJson serializa con los nombres de campo existentes (Obs 4)', () {
      final now = DateTime(2026, 10, 23, 10, 0);
      final model = MovementModel(
        id: 'tx_new',
        userId: 'usr_1',
        tipo: MovementType.recarga,
        monto: 20.0,
        linea: null,
        ruta: null,
        viajeId: null,
        fecha: now,
        estado: MovementStatus.completed,
        descripcion: 'Recarga de saldo',
      );

      final json = model.toJson();

      // Se escriben solo los campos existentes de `transactions`.
      expect(json.containsKey('tipo'), isFalse);
      expect(json['user_id'], 'usr_1');
      expect(json['status'], 'completed');
      expect(json['transaction_type'], 'top_up');
      expect(json['amount'], 20.0);
    });
  });

  group('Conciliación y Cuadre de Saldo con Historial - Obs 4', () {
    final service = WalletService(datasource: MockWalletDatasource());

    test('calculateBalanceFromMovements calcula correctamente ingresos y egresos completados', () {
      final movements = [
        MovementEntity(
          id: '1',
          userId: 'u1',
          tipo: MovementType.recarga,
          monto: 50.0,
          fecha: DateTime.now(),
          estado: MovementStatus.completed,
          descripcion: 'Recarga inicial',
        ),
        MovementEntity(
          id: '2',
          userId: 'u1',
          tipo: MovementType.pagoViaje,
          monto: 2.50,
          linea: '106',
          ruta: 'Quillacollo - Cochabamba',
          viajeId: 't1',
          fecha: DateTime.now(),
          estado: MovementStatus.completed,
          descripcion: 'Pago pasaje',
        ),
        MovementEntity(
          id: '3',
          userId: 'u1',
          tipo: MovementType.pagoViaje,
          monto: 3.00,
          linea: '233',
          ruta: 'Terminal',
          viajeId: 't2',
          fecha: DateTime.now(),
          estado: MovementStatus.completed,
          descripcion: 'Pago pasaje 2',
        ),
        // Movimiento pendiente no debe afectar el saldo
        MovementEntity(
          id: '4',
          userId: 'u1',
          tipo: MovementType.recarga,
          monto: 100.0,
          fecha: DateTime.now(),
          estado: MovementStatus.pending,
          descripcion: 'Recarga pendiente',
        ),
        // Reembolso completado (Obs 1) suma al saldo
        MovementEntity(
          id: '5',
          userId: 'u1',
          tipo: MovementType.reembolso,
          monto: 3.00,
          linea: '233',
          viajeId: 't2',
          fecha: DateTime.now(),
          estado: MovementStatus.completed,
          descripcion: 'Reembolso por viaje cancelado',
        ),
      ];

      // Esperado: +50 - 2.50 - 3.00 + 3.00 = 47.50
      final calculated = service.calculateBalanceFromMovements(movements);
      expect(calculated, 47.50);

      // Verificación de cuadre con el saldo real
      expect(
        service.verifyBalanceMatchesHistory(
          currentBalance: 47.50,
          movements: movements,
        ),
        isTrue,
      );

      // Descuadre simulado
      expect(
        service.verifyBalanceMatchesHistory(
          currentBalance: 50.00,
          movements: movements,
        ),
        isFalse,
      );
    });
  });
}
