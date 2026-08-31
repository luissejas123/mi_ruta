/// Clase abstracta para fallos/errores
abstract class Failure {
  final String message;
  Failure({required this.message});
}

/// Fallo genérico de servidor/Firestore
class ServerFailure extends Failure {
  ServerFailure({required super.message});
}

/// Fallo de conexión
class NetworkFailure extends Failure {
  NetworkFailure({required super.message});
}

/// Fallo genérico
class GeneralFailure extends Failure {
  GeneralFailure({required super.message});
}
