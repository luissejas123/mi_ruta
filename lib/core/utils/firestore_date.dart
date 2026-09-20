import 'package:cloud_firestore/cloud_firestore.dart';

/// Parsea un valor de fecha leído de Firestore que puede venir como
/// `Timestamp` nativo (`FieldValue.serverTimestamp()`) o como string
/// ISO8601, según qué parte del código haya escrito el documento.
///
/// Varios datasources de este proyecto asumían un solo formato con un cast
/// rígido (`data['campo'] as Timestamp?`), lo que rompía con
/// "type 'String' is not a subtype of type 'Timestamp?'" en cualquier
/// documento escrito por una ruta de código distinta (p. ej. el panel de
/// Presidente, que agrega datos de `routes`/`vehicles`/`users` escritos por
/// datasources diferentes). Usar este helper en vez de un cast directo.
DateTime? parseFirestoreDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  if (value is Timestamp) return value.toDate();
  return null;
}
