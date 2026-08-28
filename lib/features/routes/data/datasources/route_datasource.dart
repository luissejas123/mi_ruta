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

  /// Obtiene rutas activas para migración (en lotes para evitar OOM)
  /// Carga datos de FIRESTORE en LOTES de 20 rutas a la vez
  Future<List<RouteEntity>> getAllActiveRoutesForMigration() async {
    try {
      const batchSize = 20;
      final allRoutes = <RouteEntity>[];
      DocumentSnapshot? lastDoc;
      bool hasMore = true;

      print(
        '📦 Iniciando carga de rutas para migración (lotes de $batchSize)...',
      );

      while (hasMore) {
        Query query = _firestore
            .collection('routes')
            .where('active', isEqualTo: true)
            .limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          hasMore = false;
          continue;
        }

        // Mapear rutas del lote CON polyline/stops para calcular bbox
        for (final doc in snapshot.docs) {
          final entity = _mapToRouteEntity(doc);
          allRoutes.add(entity);
        }

        print(
          '⏳ Cargadas ${allRoutes.length} rutas... (último lote: ${snapshot.docs.length})',
        );

        lastDoc = snapshot.docs.last;
      }

      print('✅ Carga completada: ${allRoutes.length} rutas en total');
      return allRoutes;
    } catch (e, st) {
      print('❌ Error cargando rutas para migración: $e\n$st');
      throw Exception('Error al obtener rutas para migración: $e');
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

  /// Obtiene rutas cuyo bounding box contiene el punto dado.
  /// ESTRATEGIA ANTI-OOM: usa colección ligera `routes_bbox` para filtrar
  /// (sin polylines), luego carga solo los documentos coincidentes completos.
  Future<List<RouteEntity>> getRoutesNearPoint({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('📍 Buscando rutas cerca de ($latitude, $longitude)...');

      // PASO 1: Consultar colección LIGERA routes_bbox (solo metadatos, sin polylines)
      print('📥 Consultando routes_bbox (colección ligera)...');
      final bboxSnapshot = await _firestore
          .collection('routes_bbox')
          .where('active', isEqualTo: true)
          .get();

      print('📦 Documentos en routes_bbox: ${bboxSnapshot.docs.length}');

      if (bboxSnapshot.docs.isEmpty) {
        print(
          '⚠️ routes_bbox vacía. La migración aún no generó esta colección.',
        );
        return [];
      }

      // PASO 2: Filtrar por bbox en memoria (documentos son solo ~100 bytes c/u)
      final matchingIds = <String>[];

      for (final doc in bboxSnapshot.docs) {
        final data = doc.data();
        final latMin = data['lat_min'] as double?;
        final latMax = data['lat_max'] as double?;
        final lngMin = data['lng_min'] as double?;
        final lngMax = data['lng_max'] as double?;

        if (latMin != null &&
            latMax != null &&
            lngMin != null &&
            lngMax != null &&
            latitude >= latMin &&
            latitude <= latMax &&
            longitude >= lngMin &&
            longitude <= lngMax) {
          matchingIds.add(doc.id);
          print('  ✓ ${data['name'] ?? doc.id}');
        }
      }

      print('📊 Rutas que coinciden con bbox: ${matchingIds.length}');

      if (matchingIds.isEmpty) {
        print('❌ Ninguna ruta pasa por esa zona');
        return [];
      }

      // PASO 3: Cargar datos COMPLETOS solo de rutas coincidentes (pocos documentos)
      print('📥 Cargando polylines de ${matchingIds.length} rutas...');
      final routes = <RouteEntity>[];

      for (final id in matchingIds) {
        try {
          final doc = await _firestore.collection('routes').doc(id).get();
          if (doc.exists) {
            routes.add(_mapToRouteEntity(doc));
          }
        } catch (e) {
          print('  ⚠️ Error cargando $id: $e');
        }
      }

      print('✅ ${routes.length} rutas cargadas con éxito');
      return routes;
    } catch (e, st) {
      print('❌ Error en getRoutesNearPoint: $e\n$st');
      rethrow;
    }
  }

  /// Actualiza los bounding boxes de todas las rutas.
  /// Se usa una sola vez para migrar datos existentes.
  /// Recibe un map de routeId -> {lat_min, lat_max, lng_min, lng_max}
  Future<void> updateBoundingBoxes(
    Map<String, Map<String, double>> boundingBoxes,
  ) async {
    try {
      final batch = _firestore.batch();
      int updated = 0;

      boundingBoxes.forEach((routeId, bbox) {
        final docRef = _firestore.collection('routes').doc(routeId);
        batch.update(docRef, {
          'lat_min': bbox['lat_min'],
          'lat_max': bbox['lat_max'],
          'lng_min': bbox['lng_min'],
          'lng_max': bbox['lng_max'],
          'updated_at': FieldValue.serverTimestamp(),
        });
        updated++;
      });

      await batch.commit();
      print('✅ Actualizados $updated bounding boxes en Firestore');
    } catch (e) {
      throw Exception('Error actualizando bounding boxes: $e');
    }
  }

  /// Crea/actualiza la colección ligera `routes_bbox` que solo contiene metadatos.
  /// Esta colección NO incluye polylines ni stops, por lo que es muy liviana.
  /// Se usa para filtrar rutas por bounding box sin OOM.
  Future<void> populateRoutesBboxCollection(
    Map<String, Map<String, dynamic>> bboxMeta,
  ) async {
    try {
      print(
        '📤 Creando colección routes_bbox con ${bboxMeta.length} entradas...',
      );
      // Firestore batch: max 500 operaciones por batch
      const maxBatch = 400;
      final entries = bboxMeta.entries.toList();

      for (int i = 0; i < entries.length; i += maxBatch) {
        final batch = _firestore.batch();
        final chunk = entries.skip(i).take(maxBatch);

        for (final entry in chunk) {
          final docRef = _firestore.collection('routes_bbox').doc(entry.key);
          batch.set(docRef, entry.value);
        }

        await batch.commit();
        print(
          '  ⏳ Subidas ${(i + maxBatch).clamp(0, entries.length)}/${entries.length}...',
        );
      }

      print('✅ Colección routes_bbox creada correctamente');
    } catch (e, st) {
      print('❌ Error creando routes_bbox: $e\n$st');
      throw Exception('Error creando routes_bbox: $e');
    }
  }

  /// Verifica si la colección routes_bbox ya existe y tiene datos.
  Future<bool> isRoutesBboxCollectionPopulated() async {
    try {
      final snap = await _firestore.collection('routes_bbox').limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Tolera Timestamp nativo (`FieldValue.serverTimestamp()`) o string
  /// ISO8601 — distintas rutas de escritura de este proyecto usaron cada
  /// formato, y un cast rígido (`as Timestamp?`) rompía con "type 'String'
  /// is not a subtype of type 'Timestamp?'" en el que escribió string.
  DateTime? _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is Timestamp) return value.toDate();
    return null;
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
      createdAt: _parseDate(data['created_at']),
      updatedAt: _parseDate(data['updated_at']),
      active: data['active'] ?? true,
      latMin: (data['lat_min'] as num?)?.toDouble(),
      latMax: (data['lat_max'] as num?)?.toDouble(),
      lngMin: (data['lng_min'] as num?)?.toDouble(),
      lngMax: (data['lng_max'] as num?)?.toDouble(),
    );
  }
}
