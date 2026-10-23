import 'package:mi_ruta/features/user/data/datasources/wallet_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/movement_entity.dart';
import 'package:mi_ruta/features/user/domain/entities/passenger_wallet_report.dart';
import 'package:mi_ruta/features/user/domain/entities/wallet.dart';

/// Servicio de dominio para operaciones de billetera y movimientos (Obs 4)
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
    String? tripId,
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
      tripId: tripId,
    );
  }

  /// Obtiene el historial de movimientos tipados ordenados por fecha descendente
  Future<List<MovementEntity>> getTransactionHistory(
    String userId, {
    int limit = 50,
  }) async {
    final movements = await _datasource.getTransactionHistory(
      userId,
      limit: limit,
    );

    // Ordenar por fecha más reciente primero
    movements.sort((a, b) => b.fecha.compareTo(a.fecha));

    return movements;
  }

  /// Calcula el saldo neto a partir de los movimientos completados (Obs 4):
  /// Saldo = Σ(Ingresos Completados) - Σ(Pagos Completados)
  double calculateBalanceFromMovements(List<MovementEntity> movements) {
    return movements
        .where((m) => m.estado == MovementStatus.completed)
        .fold(0.0, (acc, m) => acc + m.signedAmount);
  }

  /// Verifica si el saldo guardado en la billetera cuadra con el historial de movimientos
  bool verifyBalanceMatchesHistory({
    required double currentBalance,
    required List<MovementEntity> movements,
    double tolerance = 0.01,
  }) {
    final calculated = calculateBalanceFromMovements(movements);
    return (currentBalance - calculated).abs() <= tolerance;
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

  /// Obtiene estadísticas de movimientos y verifica si el saldo cuadra (Obs 4)
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    final wallet = await _datasource.getWalletByUserId(userId);
    if (wallet == null) {
      return {
        'total_ingreso': 0.0,
        'total_gasto': 0.0,
        'transacciones_count': 0,
        'saldo_actual': 0.0,
        'saldo_calculado': 0.0,
        'saldo_cuadra': true,
      };
    }

    final movements = await getTransactionHistory(userId, limit: 1000);

    double totalIngreso = 0.0;
    double totalGasto = 0.0;

    for (final m in movements) {
      if (m.estado == MovementStatus.completed) {
        if (m.isIncome) {
          totalIngreso += m.monto;
        } else {
          totalGasto += m.monto;
        }
      }
    }

    final saldoCalculado = totalIngreso - totalGasto;
    final saldoCuadra =
        (wallet.currentBalance - saldoCalculado).abs() <= 0.01;

    return {
      'total_ingreso': totalIngreso,
      'total_gasto': totalGasto,
      'transacciones_count': movements.length,
      'saldo_actual': wallet.currentBalance,
      'saldo_calculado': saldoCalculado,
      'saldo_cuadra': saldoCuadra,
      'currency': wallet.currency,
    };
  }

  /// Resume ingresos, pagos, reembolsos y cancelaciones del pasajero,
  /// conciliando el ledger completo contra el saldo guardado en su billetera.
  Future<({PassengerWalletReport report, Wallet wallet})> getPassengerReport(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final wallet = await _datasource.getWalletByUserId(userId);
    if (wallet == null) {
      throw Exception('Billetera no encontrada');
    }

    final data = await _datasource.getPassengerReportData(userId);
    return (
      report: PassengerWalletReport.fromLedger(
        currentBalance: wallet.currentBalance,
        transactions: data.transactions,
        trips: data.trips,
        from: from,
        to: to,
      ),
      wallet: wallet,
    );
  }

  /// Filtra movimientos por tipo
  Future<List<MovementEntity>> getTransactionsByType(
    String userId,
    MovementType tipo,
  ) async {
    final allMovements = await getTransactionHistory(userId, limit: 1000);
    return allMovements.where((m) => m.tipo == tipo).toList();
  }

  /// Obtiene las ganancias del chofer a partir de las transacciones
  /// `trip_payment_received` registradas por TripPaymentService.
  /// Retorna: {total_ganancia, transacciones_count, transactions}
  Future<Map<String, dynamic>> getDriverEarnings(String userId) async {
    final transactions = await _datasource.getDriverEarningsTransactions(
      userId,
    );

    double total = 0.0;
    for (final tx in transactions) {
      total += (tx['amount'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'total_ganancia': total,
      'transacciones_count': transactions.length,
      'transactions': transactions,
    };
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
