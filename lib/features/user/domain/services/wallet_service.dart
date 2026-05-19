import 'package:mi_ruta/features/user/data/datasources/wallet_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/wallet.dart';

/// Servicio de dominio para operaciones de billetera
class WalletService {
  final WalletDatasource _datasource;

  WalletService({required WalletDatasource datasource})
    : _datasource = datasource;

  /// Crea una billetera inicial para un usuario nuevo
  /// Se recomienda llamar durante el registro de usuario
  Future<void> createNewUserWallet(
    String userId, {
    double initialBalance = 0.0,
  }) async {
    await _datasource.createWallet(userId, initialBalance: initialBalance);
  }

  /// Inicializa billetera si no existe (para usuarios sin billetera)
  Future<Wallet?> ensureWalletExists(String userId) async {
    return _datasource.initializeWalletIfNotExists(userId);
  }

  /// Obtiene la billetera del usuario
  Future<Wallet?> getWallet(String userId) async {
    return _datasource.getWalletByUserId(userId);
  }

  /// Recarga saldo a la billetera
  /// Lanza excepción si el amount es negativo o cero
  Future<void> topUpBalance(String userId, double amount) async {
    if (amount <= 0) {
      throw ArgumentError('El monto debe ser mayor a 0');
    }
    await _datasource.topUpBalance(userId, amount);
  }

  /// Realiza pago de viaje
  /// Valida que haya saldo suficiente
  Future<void> payTrip(
    String userId,
    double amount, {
    required String routeNumber,
    required String routeName,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('El monto debe ser mayor a 0');
    }

    final wallet = await _datasource.getWalletByUserId(userId);
    if (wallet == null) {
      throw Exception('Billetera no encontrada');
    }

    if (wallet.currentBalance < amount) {
      throw Exception(
        'Saldo insuficiente. Disponible: ${wallet.currentBalance}',
      );
    }

    await _datasource.deductTripPayment(
      userId,
      amount,
      routeNumber: routeNumber,
      routeName: routeName,
    );
  }

  /// Obtiene el historial de transacciones formateado
  Future<List<Map<String, dynamic>>> getTransactionHistory(
    String userId, {
    int limit = 50,
  }) async {
    final transactions = await _datasource.getTransactionHistory(
      userId,
      limit: limit,
    );

    // Ordenar por más recientes primero
    transactions.sort((a, b) {
      final dateA = a['timestamp'] as dynamic;
      final dateB = b['timestamp'] as dynamic;
      return dateB.compareTo(dateA);
    });

    return transactions;
  }

  /// Valida si el usuario tiene saldo suficiente para un viaje
  Future<bool> hasEnoughBalance(String userId, double amount) async {
    final wallet = await _datasource.getWalletByUserId(userId);
    return wallet != null && wallet.currentBalance >= amount;
  }

  /// Obtiene el saldo formateado para mostrar
  Future<String> getFormattedBalance(String userId) async {
    final wallet = await _datasource.getWalletByUserId(userId);
    if (wallet == null) return 'BS. 0.00';
    return '${wallet.currency}. ${wallet.currentBalance.toStringAsFixed(2)}';
  }

  /// Obtiene estadísticas de transacciones del usuario
  /// Retorna: {total_ingreso, total_gasto, transacciones_count, saldo_actual}
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    final wallet = await _datasource.getWalletByUserId(userId);
    if (wallet == null) {
      return {
        'total_ingreso': 0.0,
        'total_gasto': 0.0,
        'transacciones_count': 0,
        'saldo_actual': 0.0,
      };
    }

    final transactions = await _datasource.getTransactionHistory(
      userId,
      limit: 1000,
    );

    double totalIngreso = 0.0;
    double totalGasto = 0.0;

    for (var tx in transactions) {
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      final type = tx['transaction_type'] as String?;

      if (type == 'top_up') {
        totalIngreso += amount;
      } else if (type == 'trip_payment') {
        totalGasto += amount;
      }
    }

    return {
      'total_ingreso': totalIngreso,
      'total_gasto': totalGasto,
      'transacciones_count': transactions.length,
      'saldo_actual': wallet.currentBalance,
      'currency': wallet.currency,
    };
  }

  /// Filtra transacciones por tipo
  Future<List<Map<String, dynamic>>> getTransactionsByType(
    String userId,
    String transactionType,
  ) async {
    final allTransactions = await getTransactionHistory(userId, limit: 1000);
    return allTransactions
        .where((tx) => (tx['transaction_type'] as String?) == transactionType)
        .toList();
  }

  /// Valida si la billetera del usuario es válida y existe
  Future<bool> hasValidWallet(String userId) async {
    try {
      final wallet = await _datasource.getWalletByUserId(userId);
      return wallet != null && wallet.currency.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
