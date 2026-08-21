import 'package:flutter/material.dart';
import 'package:mi_ruta/features/auth/data/models/auth_model.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_income_entry.dart';
import 'package:mi_ruta/features/user/data/models/user_model.dart';

/// MODO PRUEBA TEMPORAL.
/// Cuentas y datos estaticos para validar la UI de Presidente y Chofer sin
/// depender de que Firestore tenga los documentos/roles bien configurados.
/// No tocan Firebase Auth ni Firestore para nada.
///
/// Quitar este archivo y sus puntos de uso cuando se conecte el flujo real
/// de roles/permisos con datos externos:
/// - auth_remote_datasource_impl.dart (login)
/// - user_remote_datasource_impl.dart (getUserById)
/// - driver_income_datasource.dart (getIncomeHistory)
/// - presidente_home_page.dart (tabs Unidades y Reportes)

const testPresidenteUid = 'test-presidente-uid';
const testChoferUid = 'test-chofer-uid';

class StaticTestAccount {
  final String uid;
  final String password;
  final AuthModel authModel;
  final UserModel userModel;

  const StaticTestAccount({
    required this.uid,
    required this.password,
    required this.authModel,
    required this.userModel,
  });
}

final Map<String, StaticTestAccount> staticTestAccounts = {
  'presidente@test.com': StaticTestAccount(
    uid: testPresidenteUid,
    password: 'test1234',
    authModel: AuthModel(
      uid: testPresidenteUid,
      fullName: 'Presidente Prueba',
      email: 'presidente@test.com',
      governmentId: '0000000',
      phoneNumber: '70000000',
      role: 'presidente',
      createdAt: DateTime.now(),
    ),
    userModel: UserModel(
      uid: testPresidenteUid,
      fullName: 'Presidente Prueba',
      email: 'presidente@test.com',
      phoneNumber: '70000000',
      userType: 'presidente',
      profileImageUrl: '',
      rating: 0,
      reviewsCount: 0,
      walletBalance: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ),
  'chofer@test.com': StaticTestAccount(
    uid: testChoferUid,
    password: 'test1234',
    authModel: AuthModel(
      uid: testChoferUid,
      fullName: 'Chofer Prueba',
      email: 'chofer@test.com',
      governmentId: '0000001',
      phoneNumber: '70000001',
      role: 'driver',
      createdAt: DateTime.now(),
    ),
    userModel: UserModel(
      uid: testChoferUid,
      fullName: 'Chofer Prueba',
      email: 'chofer@test.com',
      phoneNumber: '70000001',
      userType: 'driver',
      profileImageUrl: '',
      rating: 4.8,
      reviewsCount: 12,
      walletBalance: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ),
};

final List<DriverIncomeEntry> staticTestDriverIncome = [
  DriverIncomeEntry(
    id: 'mock-1',
    driverId: testChoferUid,
    passengerId: 'pasajero-demo-1',
    tripId: 'trip-demo-1',
    amount: 5.5,
    description: 'Pago de viaje del pasajero pasajero-demo-1',
    date: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  DriverIncomeEntry(
    id: 'mock-2',
    driverId: testChoferUid,
    passengerId: 'pasajero-demo-2',
    tripId: 'trip-demo-2',
    amount: 3.0,
    description: 'Pago de viaje del pasajero pasajero-demo-2',
    date: DateTime.now().subtract(const Duration(days: 1)),
  ),
  DriverIncomeEntry(
    id: 'mock-3',
    driverId: testChoferUid,
    passengerId: 'pasajero-demo-3',
    tripId: 'trip-demo-3',
    amount: 8.0,
    description: 'Pago de viaje del pasajero pasajero-demo-3',
    date: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

/// Preview de "Unidades" para el panel Presidente en modo prueba.
class MockVehicleUnit {
  final String plate;
  final String routeRef;
  final String driverName;
  final String status; // Activa / Mantenimiento / Inactiva

  const MockVehicleUnit({
    required this.plate,
    required this.routeRef,
    required this.driverName,
    required this.status,
  });
}

const List<MockVehicleUnit> staticTestVehicles = [
  MockVehicleUnit(
    plate: 'CBA-1234',
    routeRef: 'Línea 4',
    driverName: 'Carlos Mamani',
    status: 'Activa',
  ),
  MockVehicleUnit(
    plate: 'CBA-5678',
    routeRef: 'Línea 7',
    driverName: 'Rosa Quispe',
    status: 'Activa',
  ),
  MockVehicleUnit(
    plate: 'CBA-9012',
    routeRef: 'Línea 2',
    driverName: 'Juan Pérez',
    status: 'Mantenimiento',
  ),
  MockVehicleUnit(
    plate: 'CBA-3456',
    routeRef: 'Línea 10',
    driverName: 'María López',
    status: 'Inactiva',
  ),
];

/// Preview de "Reportes" para el panel Presidente en modo prueba.
class MockReportStat {
  final String title;
  final String value;
  final IconData icon;

  const MockReportStat({
    required this.title,
    required this.value,
    required this.icon,
  });
}

const List<MockReportStat> staticTestReports = [
  MockReportStat(
    title: 'Viajes hoy',
    value: '128',
    icon: Icons.directions_bus,
  ),
  MockReportStat(
    title: 'Ingresos totales',
    value: 'Bs. 850.00',
    icon: Icons.payments,
  ),
  MockReportStat(
    title: 'Choferes activos',
    value: '12',
    icon: Icons.badge,
  ),
  MockReportStat(
    title: 'Rutas activas',
    value: '8',
    icon: Icons.route,
  ),
];
