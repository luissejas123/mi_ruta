import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/user/domain/entities/wallet.dart';

class WalletDatasource {
  final FirebaseFirestore _firestore;

  WalletDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Crea una billetera inicial para un nuevo usuario
  /// Se llama automáticamente cuando el usuario se registra
  Future<void> createWallet(
    String userId, {
    double initialBalance = 0.0,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).set({
        'wallet': {
          'current_balance': initialBalance,
          'currency': 'Bs',
          'created_at': now,
          'updated_at': now,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error creando billetera: $e');
    }
  }

  /// Inicializa billetera si no existe
  /// Útil para usuarios existentes que aún no tienen billetera
  Future<Wallet?> initializeWalletIfNotExists(String userId) async {
    try {
      final existing = await getWalletByUserId(userId);
      if (existing != null) return existing;

      await createWallet(userId);
      return await getWalletByUserId(userId);
    } catch (e) {
      throw Exception('Error inicializando billetera: $e');
    }
  }

  /// Obtiene la billetera del usuario actual desde Firestore
  Future<Wallet?> getWalletByUserId(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      final walletData = data['wallet'] as Map<String, dynamic>?;
      if (walletData == null) return null;

      return Wallet(
        userId: userId,
        currentBalance:
            (walletData['current_balance'] as num?)?.toDouble() ?? 0.0,
        currency: walletData['currency'] as String? ?? 'Bs',
        createdAt:
            (walletData['created_at'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        updatedAt:
            (walletData['updated_at'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error obteniendo billetera: $e');
    }
  }

  /// Actualiza el saldo de la billetera
  Future<void> updateBalance(String userId, double newBalance) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'wallet.current_balance': newBalance,
        'wallet.updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error actualizando saldo: $e');
    }
  }

  /// Carga saldo a la billetera
  Future<void> topUpBalance(String userId, double amount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('users').doc(userId);
        final doc = await transaction.get(docRef);

        if (!doc.exists) throw Exception('Usuario no encontrado');

        final currentBalance =
            ((doc.data() as Map<String, dynamic>)['wallet']['current_balance']
                    as num?)
                ?.toDouble() ??
            0.0;
        final newBalance = currentBalance + amount;

        transaction.update(docRef, {
          'wallet.current_balance': newBalance,
          'wallet.updated_at': FieldValue.serverTimestamp(),
        });

        // Registrar transacción
        await _firestore.collection('transactions').add({
          'user_id': userId,
          'transaction_type': 'top_up',
          'amount': amount,
          'description': 'Recarga de saldo',
          'timestamp': FieldValue.serverTimestamp(),
          'payment_method': 'wallet',
          'status': 'completed',
        });
      });
    } catch (e) {
      throw Exception('Error recargando saldo: $e');
    }
  }

  /// Realiza un pago de viaje
  Future<void> deductTripPayment(
    String userId,
    double amount, {
    required String routeNumber,
    required String routeName,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('users').doc(userId);
        final doc = await transaction.get(docRef);

        if (!doc.exists) throw Exception('Usuario no encontrado');

        final currentBalance =
            ((doc.data() as Map<String, dynamic>)['wallet']['current_balance']
                    as num?)
                ?.toDouble() ??
            0.0;

        if (currentBalance < amount) {
          throw Exception(
            'Saldo insuficiente. Disponible: BS. ${currentBalance.toStringAsFixed(2)}, '
            'Necesario: BS. ${amount.toStringAsFixed(2)}, '
            'Faltante: BS. ${(amount - currentBalance).toStringAsFixed(2)}',
          );
        }

        final newBalance = currentBalance - amount;

        transaction.update(docRef, {
          'wallet.current_balance': newBalance,
          'wallet.updated_at': FieldValue.serverTimestamp(),
        });

        // Registrar transacción
        await _firestore.collection('transactions').add({
          'user_id': userId,
          'transaction_type': 'trip_payment',
          'amount': amount,
          'description': 'Pago Línea $routeNumber - $routeName',
          'timestamp': FieldValue.serverTimestamp(),
          'payment_method': 'wallet',
          'status': 'completed',
          'route_number': routeNumber,
          'route_name': routeName,
        });
      });
    } catch (e) {
      throw Exception('Error realizando pago: $e');
    }
  }

  /// Obtiene el historial de transacciones del usuario
  /// Nota: Requiere índice compuesto en Firestore (user_id + timestamp)
  Future<List<Map<String, dynamic>>> getTransactionHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      // Si el error es por índice faltante, intentar alternativa
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        print(
          '⚠️ Índice compuesto requerido. Usando alternativa sin ordenar...',
        );
        try {
          // Fallback: obtener sin order, ordenar en memoria
          final snapshot = await _firestore
              .collection('transactions')
              .where('user_id', isEqualTo: userId)
              .limit(limit * 2) // Obtener más documentos sin ordenar
              .get();

          final transactions = snapshot.docs.map((doc) => doc.data()).toList();

          // Ordenar en memoria por timestamp descendente
          transactions.sort((a, b) {
            final dateA = a['timestamp'] as dynamic;
            final dateB = b['timestamp'] as dynamic;
            return dateB.compareTo(dateA);
          });

          return transactions.take(limit).toList();
        } catch (fallbackError) {
          throw Exception(
            'Error obteniendo historial. '
            'Se requiere crear un índice compuesto en Firestore. '
            'Consulta la documentación en WALLET_FIRESTORE_INITIALIZATION.md\n'
            'Error: $fallbackError',
          );
        }
      }

      throw Exception('Error obteniendo historial: $e');
    }
  }
}
