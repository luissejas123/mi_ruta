import 'package:cloud_firestore/cloud_firestore.dart';

class TripPaymentService {
  final FirebaseFirestore _firestore;

  TripPaymentService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Procesa el pago de un viaje escaneando el QR del chofer
  /// El QR contiene: driverId|tripId|amount
  Future<Map<String, dynamic>> processPayment({
    required String userId,
    required String qrData,
  }) async {
    try {
      // Decodificar QR: formato "driverId|tripId|amount"
      final parts = qrData.split('|');
      if (parts.length < 3) {
        throw Exception('Código QR inválido');
      }

      final String driverId = parts[0];
      final String tripId = parts[1];
      final double amount = double.parse(parts[2]);

      if (amount <= 0) {
        throw Exception('Monto inválido');
      }

      return await _chargeTrip(
        userId: userId,
        driverId: driverId,
        tripId: tripId,
        amount: amount,
        paymentMethod: 'qr',
      );
    } catch (e) {
      return {'success': false, 'message': 'Error al procesar pago: $e'};
    }
  }

  /// Cobra un viaje de abordaje (Bloque 2, paso 3) por [amount] ya resuelto
  /// según distancia recorrida (`TariffService`) — a diferencia de
  /// [processPayment], acá no hay QR de cobro que decodificar: el viaje ya
  /// existe desde que el pasajero abordó (`DriverService.createBoardingTrip`,
  /// `passenger_id` ya puesto) y el monto se calcula recién ahora, al avisar
  /// que baja. Comparte la misma transacción atómica que el flujo de QR —
  /// mismas garantías contra doble cobro.
  Future<Map<String, dynamic>> processDistanceFare({
    required String userId,
    required String driverId,
    required String tripId,
    required double amount,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Monto inválido');
      }
      return await _chargeTrip(
        userId: userId,
        driverId: driverId,
        tripId: tripId,
        amount: amount,
        paymentMethod: 'distance',
      );
    } catch (e) {
      return {'success': false, 'message': 'Error al procesar cobro: $e'};
    }
  }

  Future<Map<String, dynamic>> _chargeTrip({
    required String userId,
    required String driverId,
    required String tripId,
    required double amount,
    required String paymentMethod,
  }) async {
    // Verificar que el viaje exista
    final tripDoc = await _firestore.collection('trips').doc(tripId).get();
    if (!tripDoc.exists) {
      throw Exception('Viaje no encontrado');
    }

    final tripData = tripDoc.data() as Map<String, dynamic>;
    if (tripData['driver_id'] != driverId) {
      throw Exception('El chofer no coincide con el viaje');
    }

    // Obtener datos del usuario para verificar saldo
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('Usuario no encontrado');
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final passengerName =
        userData['fullName'] ??
        userData['full_name'] ??
        userData['name'] ??
        'Desconocido';
    final walletData = userData['wallet'] as Map<String, dynamic>?;

    final driverDoc = await _firestore.collection('users').doc(driverId).get();
    final driverData = driverDoc.data() as Map<String, dynamic>?;
    final driverName =
        driverData?['fullName'] ??
        driverData?['full_name'] ??
        driverData?['name'] ??
        'Desconocido';
    final currentBalance = (walletData?['current_balance'] ?? 0).toDouble();

    if (currentBalance < amount) {
      throw Exception(
        'Saldo insuficiente. Saldo: Bs. ${currentBalance.toStringAsFixed(2)}, Requerido: Bs. ${amount.toStringAsFixed(2)}',
      );
    }

    // Realizar transacción atómica. La relectura de `tripRef` DENTRO de la
    // transacción (antes de cualquier escritura, como exige Firestore) es
    // la guarda real contra el doble cobro: si dos pasajeros escanean el
    // mismo QR casi al mismo tiempo, la segunda transacción ve
    // `payment_status: 'paid'` ya escrito por la primera y aborta — la
    // lectura de `tripDoc` de más arriba solo sirvió para el chequeo
    // rápido de UI, no reemplaza esta (docs/PLAN_SEGURIDAD_TARIFAS_GPS.md,
    // Bloque 0).
    final tripRef = _firestore.collection('trips').doc(tripId);
    await _firestore.runTransaction((transaction) async {
      final freshTripSnap = await transaction.get(tripRef);
      if (!freshTripSnap.exists) {
        throw Exception('Viaje no encontrado');
      }
      final freshTripData = freshTripSnap.data() as Map<String, dynamic>;
      if (freshTripData['payment_status'] == 'paid') {
        throw Exception('Este viaje ya fue pagado');
      }
      // Un viaje de abordaje (`createBoardingTrip`) ya trae `passenger_id`
      // puesto desde que subió — si alguien escanea el QR equivocado (dos
      // pasajeros bajando de la misma unidad casi a la vez), esto evita
      // cobrarle a uno el viaje del otro. Un cobro manual del chofer
      // (`createTripCharge`) nace sin `passenger_id`, así que lo toma quien
      // lo escanee primero, sin cambios respecto al comportamiento actual.
      final existingPassengerId = freshTripData['passenger_id'] as String?;
      if (existingPassengerId != null && existingPassengerId != userId) {
        throw Exception('Este viaje ya está asociado a otro pasajero');
      }

      // Descontar de billetera del usuario
      transaction.update(_firestore.collection('users').doc(userId), {
        'wallet.current_balance': FieldValue.increment(-amount),
        'wallet.updated_at': FieldValue.serverTimestamp(),
      });

      // Acreditar al chofer
      transaction.update(_firestore.collection('users').doc(driverId), {
        'wallet.current_balance': FieldValue.increment(amount),
        'wallet.updated_at': FieldValue.serverTimestamp(),
      });

      // Actualizar estado del viaje
      transaction.update(tripRef, {
        'status': 'completed',
        'passenger_id': userId,
        'payment_status': 'paid',
        'payment_amount': amount,
        'paid_at': FieldValue.serverTimestamp(),
      });
    });

    // Registrar transacción para el usuario
    await _firestore.collection('transactions').add({
      'user_id': userId,
      'transaction_type': 'trip_payment',
      'amount': -amount,
      'description': 'Pago a chofer $driverName',
      'timestamp': FieldValue.serverTimestamp(),
      'payment_method': paymentMethod,
      'status': 'completed',
      'trip_id': tripId,
      'driver_id': driverId,
    });

    // Registrar transacción para el chofer
    await _firestore.collection('transactions').add({
      'user_id': driverId,
      'transaction_type': 'trip_payment_received',
      'amount': amount,
      'description': 'Cobro a pasajero $passengerName',
      'timestamp': FieldValue.serverTimestamp(),
      'payment_method': paymentMethod,
      'status': 'completed',
      'trip_id': tripId,
      'passenger_id': userId,
    });

    return {
      'success': true,
      'amount': amount,
      'driverId': driverId,
      'tripId': tripId,
      'newBalance': currentBalance - amount,
      'message':
          'Pago procesado exitosamente. Saldo: Bs. ${(currentBalance - amount).toStringAsFixed(2)}',
    };
  }

  /// Cancela un viaje ya pagado y devuelve el saldo al pasajero.
  ///
  /// **Todo ocurre dentro de una sola transacción de Firestore**: el abono al
  /// pasajero, el débito al chofer, el cambio de estado del viaje y los dos
  /// movimientos espejo en `transactions`. A diferencia de [_chargeTrip] —
  /// que escribe sus `transactions` *después* de cerrar la transacción, así
  /// que un corte de red entre ambos pasos deja el saldo movido sin
  /// movimiento en el ledger — acá no puede quedar nada a medias.
  ///
  /// Guardas: el viaje tiene que existir, estar pagado, pertenecer a este
  /// pasajero y no haber sido reembolsado antes (la relectura dentro de la
  /// transacción es la que protege de un doble reembolso por doble toque,
  /// igual que la de [_chargeTrip] protege del doble cobro).
  Future<Map<String, dynamic>> refundTrip({
    required String userId,
    required String tripId,
  }) async {
    try {
      final tripRef = _firestore.collection('trips').doc(tripId);
      final passengerRef = _firestore.collection('users').doc(userId);
      // Las refs de los movimientos se crean FUERA del callback: si Firestore
      // reintenta la transacción, se reusan los mismos IDs en vez de generar
      // documentos nuevos en cada intento.
      final passengerTxRef = _firestore.collection('transactions').doc();
      final driverTxRef = _firestore.collection('transactions').doc();

      return await _firestore.runTransaction<Map<String, dynamic>>((
        transaction,
      ) async {
        // ── 1. Lecturas (Firestore exige todas antes de cualquier escritura)
        final tripSnap = await transaction.get(tripRef);
        if (!tripSnap.exists) {
          throw Exception('Viaje no encontrado');
        }
        final tripData = tripSnap.data() as Map<String, dynamic>;

        if (tripData['payment_status'] == 'refunded') {
          throw Exception('Este viaje ya fue reembolsado');
        }
        if (tripData['payment_status'] != 'paid') {
          throw Exception('Este viaje no tiene un pago que devolver');
        }
        if (tripData['passenger_id'] != userId) {
          throw Exception('Este viaje no te pertenece');
        }

        final amount = ((tripData['payment_amount'] ?? 0) as num).toDouble();
        if (amount <= 0) {
          throw Exception('El viaje no registra un monto pagado');
        }

        final driverId = tripData['driver_id'] as String?;
        if (driverId == null || driverId.isEmpty) {
          throw Exception('El viaje no tiene un chofer asociado');
        }
        final driverRef = _firestore.collection('users').doc(driverId);

        final passengerSnap = await transaction.get(passengerRef);
        if (!passengerSnap.exists) {
          throw Exception('Usuario no encontrado');
        }
        final passengerData = passengerSnap.data() as Map<String, dynamic>;
        final driverSnap = await transaction.get(driverRef);
        if (!driverSnap.exists) {
          // Sin esto, el `transaction.update` de más abajo fallaría con un
          // NOT_FOUND crudo en vez de un mensaje que el pasajero entienda.
          throw Exception('El chofer del viaje ya no existe');
        }
        final driverData = driverSnap.data();

        final passengerBalance = _readBalance(passengerData);
        final driverBalance = _readBalance(driverData);
        final newPassengerBalance = passengerBalance + amount;
        // El saldo del chofer puede quedar negativo si ya gastó lo cobrado.
        // Se permite a propósito: recortarlo a 0 haría que el ledger y el
        // saldo dejen de cuadrar (aparecería dinero de la nada), y el
        // pasajero no puede quedarse sin su devolución por eso.
        final newDriverBalance = driverBalance - amount;

        final passengerName =
            passengerData['fullName'] ??
            passengerData['full_name'] ??
            passengerData['name'] ??
            'Desconocido';
        final driverName =
            driverData?['fullName'] ??
            driverData?['full_name'] ??
            driverData?['name'] ??
            'Desconocido';
        // El viaje no guarda `payment_method` (vive solo en la transacción
        // espejo de `transactions`, ver FIRESTORE_COLLECTIONS_GUIDE.md), y
        // además el reembolso siempre vuelve a la billetera sin importar si
        // el cobro original fue por QR o por distancia.
        const paymentMethod = 'wallet';

        // ── 2. Escrituras
        transaction.update(
          passengerRef,
          _balanceUpdates(passengerData, newPassengerBalance),
        );
        transaction.update(
          driverRef,
          _balanceUpdates(driverData, newDriverBalance),
        );

        transaction.update(tripRef, {
          'status': 'cancelled',
          'payment_status': 'refunded',
          'refund_amount': amount,
          'refunded_at': FieldValue.serverTimestamp(),
        });

        // Movimiento del pasajero: entra dinero → monto positivo, igual que
        // `top_up`/`recharge`.
        transaction.set(passengerTxRef, {
          'user_id': userId,
          'transaction_type': 'refund',
          'amount': amount,
          'description': 'Reembolso por viaje cancelado - $driverName',
          'timestamp': FieldValue.serverTimestamp(),
          'payment_method': paymentMethod,
          'status': 'completed',
          'trip_id': tripId,
          'driver_id': driverId,
        });

        // Movimiento del chofer: sale dinero → monto negativo, mismo criterio
        // que el `trip_payment` del pasajero en `_chargeTrip`.
        transaction.set(driverTxRef, {
          'user_id': driverId,
          'transaction_type': 'refund_issued',
          'amount': -amount,
          'description': 'Reembolso a pasajero $passengerName',
          'timestamp': FieldValue.serverTimestamp(),
          'payment_method': paymentMethod,
          'status': 'completed',
          'trip_id': tripId,
          'passenger_id': userId,
        });

        return {
          'success': true,
          'amount': amount,
          'tripId': tripId,
          'driverId': driverId,
          'newBalance': newPassengerBalance,
          'message':
              'Viaje cancelado. Se devolvieron Bs. ${amount.toStringAsFixed(2)} a tu billetera.',
        };
      });
    } catch (e) {
      return {
        'success': false,
        'message': e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'No se pudo procesar el reembolso: $e',
      };
    }
  }

  /// Indica si un viaje todavía se puede cancelar con devolución de saldo:
  /// está pagado, es de este pasajero y no se reembolsó antes.
  Future<bool> isTripRefundable({
    required String userId,
    required String tripId,
  }) async {
    try {
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) return false;

      final tripData = tripDoc.data() as Map<String, dynamic>;
      return tripData['payment_status'] == 'paid' &&
          tripData['passenger_id'] == userId &&
          ((tripData['payment_amount'] ?? 0) as num) > 0;
    } catch (_) {
      return false;
    }
  }

  /// Lee el saldo de un documento de `users` aceptando las dos claves que
  /// conviven en la colección (`current_balance` snake_case y `balance`
  /// camelCase) — mismo criterio que `WalletDatasource.getWalletByUserId`.
  static double _readBalance(Map<String, dynamic>? userData) {
    final walletData = userData?['wallet'] as Map<String, dynamic>?;
    return ((walletData?['current_balance'] ?? walletData?['balance'] ?? 0)
            as num)
        .toDouble();
  }

  /// Escribe el saldo nuevo en las claves que el documento YA tiene, sin
  /// inventar una tercera variante (regla #1 de CLAUDE.md). Si el documento
  /// solo tenía `wallet.balance`, incrementar `current_balance` a secas
  /// habría creado una clave que `getWalletByUserId` lee con prioridad,
  /// pisando el saldo anterior.
  static Map<String, dynamic> _balanceUpdates(
    Map<String, dynamic>? userData,
    double newBalance,
  ) {
    final walletData = userData?['wallet'] as Map<String, dynamic>?;
    final updates = <String, dynamic>{
      'wallet.current_balance': newBalance,
      'wallet.updated_at': FieldValue.serverTimestamp(),
    };
    if (walletData != null && walletData.containsKey('balance')) {
      updates['wallet.balance'] = newBalance;
    }
    return updates;
  }

  /// Obtiene el historial de pagos de viajes del usuario
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .where('transaction_type', isEqualTo: 'trip_payment')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error al obtener historial de pagos: $e');
    }
  }

  /// Verifica si un viaje ya fue pagado
  Future<bool> isTripPaid(String tripId) async {
    try {
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) return false;

      final tripData = tripDoc.data() as Map<String, dynamic>;
      return tripData['payment_status'] == 'paid';
    } catch (e) {
      throw Exception('Error al verificar estado del pago: $e');
    }
  }
}
