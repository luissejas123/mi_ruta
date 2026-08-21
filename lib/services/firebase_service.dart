import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inicializar colecciones con datos de prueba
  static Future<void> initializeCollections() async {
    try {
      await _createUsersCollection();
      await _createBusesCollection();
      await _createWalletsCollection();
      print('✅ Todas las colecciones inicializadas correctamente');
    } catch (e) {
      print('❌ Error al inicializar colecciones: $e');
    }
  }

  /// Crear colección de usuarios
  static Future<void> _createUsersCollection() async {
    try {
      final usersRef = _firestore.collection('users');

      // Verificar si ya existe
      final snapshot = await usersRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('ℹ️  Colección usuarios ya existe');
        return;
      }

      // Crear datos de prueba
      await usersRef.doc('user001').set({
        'name': 'Juan Pérez',
        'email': 'juan@example.com',
        'phone': '+34 612 345 678',
        'city': 'Madrid',
        'registrationDate': DateTime.now(),
        'active': true,
        'photo': 'https://via.placeholder.com/150',
        'rating': 4.5,
      });

      await usersRef.doc('user002').set({
        'name': 'María García',
        'email': 'maria@example.com',
        'phone': '+34 698 765 432',
        'city': 'Barcelona',
        'registrationDate': DateTime.now(),
        'active': true,
        'photo': 'https://via.placeholder.com/150',
        'rating': 4.8,
      });

      await usersRef.doc('user003').set({
        'name': 'Carlos López',
        'email': 'carlos@example.com',
        'phone': '+34 654 321 987',
        'city': 'Valencia',
        'registrationDate': DateTime.now(),
        'active': false,
        'photo': 'https://via.placeholder.com/150',
        'rating': 3.9,
      });

      print('✅ Colección usuarios creada');
    } catch (e) {
      print('❌ Error creando usuarios: $e');
    }
  }

  /// Crear colección de buses
  static Future<void> _createBusesCollection() async {
    try {
      final busesRef = _firestore.collection('buses');

      // Verificar si ya existe
      final snapshot = await busesRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('ℹ️  Colección buses ya existe');
        return;
      }

      // Crear datos de prueba
      await busesRef.doc('bus001').set({
        'plate': 'MAD-1234-AA',
        'model': 'Mercedes Sprinter',
        'year': 2022,
        'capacity': 50,
        'driver': 'Juan Pérez',
        'driverId': 'user001',
        'status': 'available',
        'location': {'latitude': 40.4168, 'longitude': -3.7038},
        'route': 'Madrid - Barcelona',
        'nextDeparture': DateTime.now().add(Duration(hours: 2)),
        'basePrice': 45.50,
      });

      await busesRef.doc('bus002').set({
        'plate': 'BCN-5678-BB',
        'model': 'Volvo B13R',
        'year': 2021,
        'capacity': 55,
        'driver': 'María García',
        'driverId': 'user002',
        'status': 'in-route',
        'location': {'latitude': 41.3851, 'longitude': 2.1734},
        'route': 'Barcelona - Valencia',
        'nextDeparture': DateTime.now().add(Duration(hours: 5)),
        'basePrice': 38.75,
      });

      await busesRef.doc('bus003').set({
        'plate': 'VAL-9012-CC',
        'model': 'Irizar i6',
        'year': 2020,
        'capacity': 48,
        'driver': 'Carlos López',
        'driverId': 'user003',
        'status': 'maintenance',
        'location': {'latitude': 39.4699, 'longitude': -0.3763},
        'route': 'Valencia - Madrid',
        'nextDeparture': DateTime.now().add(Duration(hours: 24)),
        'basePrice': 42.00,
      });

      print('✅ Colección buses creada');
    } catch (e) {
      print('❌ Error creando buses: $e');
    }
  }

  /// Crear colección de monederos
  static Future<void> _createWalletsCollection() async {
    try {
      final walletsRef = _firestore.collection('wallets');

      // Verificar si ya existe
      final snapshot = await walletsRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('ℹ️  Colección wallets ya existe');
        return;
      }

      // Crear datos de prueba
      await walletsRef.doc('wallet001').set({
        'userId': 'user001',
        'holderName': 'Juan Pérez',
        'balance': 250.50,
        'currency': 'EUR',
        'paymentMethod': 'credit_card',
        'card': {
          'last4Digits': '1234',
          'bank': 'BBVA',
          'expirationDate': '12/25',
        },
        'transactions': 15,
        'lastUpdate': DateTime.now(),
        'status': 'active',
      });

      await walletsRef.doc('wallet002').set({
        'userId': 'user002',
        'holderName': 'María García',
        'balance': 580.75,
        'currency': 'EUR',
        'paymentMethod': 'paypal',
        'paypalEmail': 'maria@paypal.com',
        'transactions': 32,
        'lastUpdate': DateTime.now(),
        'status': 'active',
      });

      await walletsRef.doc('wallet003').set({
        'userId': 'user003',
        'holderName': 'Carlos López',
        'balance': 125.00,
        'currency': 'EUR',
        'paymentMethod': 'bank_transfer',
        'bank': 'CaixaBank',
        'iban': 'ES91****',
        'transactions': 8,
        'lastUpdate': DateTime.now(),
        'status': 'inactive',
      });

      print('✅ Colección wallets creada');
    } catch (e) {
      print('❌ Error creando wallets: $e');
    }
  }

  /// Obtener todos los usuarios
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error obteniendo usuarios: $e');
      return [];
    }
  }

  /// Obtener todos los buses
  static Future<List<Map<String, dynamic>>> getBuses() async {
    try {
      final snapshot = await _firestore.collection('buses').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error obteniendo buses: $e');
      return [];
    }
  }

  /// Obtener todos los wallets
  static Future<List<Map<String, dynamic>>> getWallets() async {
    try {
      final snapshot = await _firestore.collection('wallets').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error obteniendo wallets: $e');
      return [];
    }
  }
}
