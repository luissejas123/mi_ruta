import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class RouteDatasource {
  final FirebaseFirestore _firestore;

  RouteDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Crea una nueva ruta en Firestore
  Future<String> createRoute({
    required String name,
    required String ref,
    String? color,
    List<Map<String, double>>? stops,
    List<Map<String, double>>? polyline,
    String? description,
  }) async {
    try {
      final docRef = await _firestore.collection('routes').add({
        'name': name,
        'ref': ref,
        'color': color,
        'stops': stops ?? [],
        'polyline': polyline ?? [],
        'description': description,
        'active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear ruta: $e');
    }
  }

  /// Obtiene todas las rutas activas
  Future<List<RouteEntity>> getAllActiveRoutes() async {
    try {
      final snapshot = await _firestore
          .collection('routes')
          .where('active', isEqualTo: true)
          .get();

      // Ordenar en la app para evitar índice compuesto
      final routes = snapshot.docs
          .map((doc) => _mapToRouteEntity(doc))
          .toList();
      routes.sort((a, b) => a.name.compareTo(b.name));

      return routes;
    } catch (e) {
      throw Exception('Error al obtener rutas: $e');
    }
  }

  /// Obtiene N rutas activas (para búsqueda con paginación)
  Future<List<RouteEntity>> getActiveRoutesLimit(int limit) async {
    try {
      final snapshot = await _firestore
          .collection('routes')
          .where('active', isEqualTo: true)
          .limit(limit)
          .get();

      // Ordenar en la app
      final routes = snapshot.docs
          .map((doc) => _mapToRouteEntity(doc))
          .toList();
      routes.sort((a, b) => a.name.compareTo(b.name));

      return routes;
    } catch (e) {
      throw Exception('Error al obtener rutas: $e');
    }
  }

  /// Obtiene rutas activas CON OFFSET Y LIMIT (paginación real)
  /// Retorna un map con 'routes' (List<RouteEntity>) y 'lastDoc' (DocumentSnapshot?)
  /// Esto evita que Firestore devuelva todo de una vez
  Future<Map<String, dynamic>> getActiveRoutesPaginated(
    int limit, {
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // Sin filtro 'active' porque muchos documentos no tienen ese campo
      // y Firestore no incluye documentos con campo ausente en equality queries
      Query query = _firestore.collection('routes').limit(limit);

      // Si hay un cursor anterior, continuar desde ahí
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      // Mapear documentos sin ordenar para evitar crashes
      final routes = <RouteEntity>[];
      for (final doc in snapshot.docs) {
        try {
          routes.add(_mapToRouteEntity(doc));
        } catch (e) {
          print('⚠️ Error mapeando ruta ${doc.id}: $e');
        }
      }

      return {
        'routes': routes,
        'lastDoc': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      };
    } catch (e) {
      print('❌ Error en getActiveRoutesPaginated: $e');
      throw Exception('Error al obtener rutas paginadas: $e');
    }
  }

  /// Obtiene todas las rutas (incluyendo inactivas)
  Future<List<RouteEntity>> getAllRoutes() async {
    try {
      final snapshot = await _firestore
          .collection('routes')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => _mapToRouteEntity(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener rutas: $e');
    }
  }

  /// Obtiene una ruta por ID
  Future<RouteEntity?> getRouteById(String routeId) async {
    try {
      final doc = await _firestore.collection('routes').doc(routeId).get();

      if (!doc.exists) return null;

      return _mapToRouteEntity(doc);
    } catch (e) {
      throw Exception('Error al obtener ruta: $e');
    }
  }

  /// Actualiza una ruta
  Future<void> updateRoute({
    required String routeId,
    String? name,
    String? ref,
    String? color,
    List<Map<String, double>>? stops,
    List<Map<String, double>>? polyline,
    String? description,
    bool? active,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (ref != null) updateData['ref'] = ref;
      if (color != null) updateData['color'] = color;
      if (stops != null) updateData['stops'] = stops;
      if (polyline != null) updateData['polyline'] = polyline;
      if (description != null) updateData['description'] = description;
      if (active != null) updateData['active'] = active;

      await _firestore.collection('routes').doc(routeId).update(updateData);
    } catch (e) {
      throw Exception('Error al actualizar ruta: $e');
    }
  }

  /// Elimina (desactiva) una ruta
  Future<void> deleteRoute(String routeId) async {
    try {
      await _firestore.collection('routes').doc(routeId).update({
        'active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al eliminar ruta: $e');
    }
  }

  /// Obtiene una ruta por número de referencia
  Future<RouteEntity?> getRouteByRef(String ref) async {
    try {
      final snapshot = await _firestore
          .collection('routes')
          .where('ref', isEqualTo: ref)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return _mapToRouteEntity(snapshot.docs.first);
    } catch (e) {
      throw Exception('Error al obtener ruta por referencia: $e');
    }
  }

  RouteEntity _mapToRouteEntity(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convertir stops
    List<Map<String, double>> stops = [];
    if (data['stops'] != null && data['stops'] is List) {
      stops = (data['stops'] as List)
          .whereType<Map<String, dynamic>>()
          .map(
            (stop) => Map<String, double>.from({
              'lat': (stop['lat'] ?? 0.0).toDouble(),
              'lng': (stop['lng'] ?? 0.0).toDouble(),
            }),
          )
          .toList();
    }

    // Convertir polyline
    List<Map<String, double>> polyline = [];
    if (data['polyline'] != null && data['polyline'] is List) {
      polyline = (data['polyline'] as List)
          .whereType<Map<String, dynamic>>()
          .map(
            (coord) => Map<String, double>.from({
              'lat': (coord['lat'] ?? 0.0).toDouble(),
              'lng': (coord['lng'] ?? 0.0).toDouble(),
            }),
          )
          .toList();
    }

    return RouteEntity(
      id: doc.id,
      name: data['name'] ?? '',
      ref: data['ref'] ?? '',
      color: data['color'],
      stops: stops,
      polyline: polyline,
      description: data['description'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      active: data['active'] ?? true,
    );
  }
}
