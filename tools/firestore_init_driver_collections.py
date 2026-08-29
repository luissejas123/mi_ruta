#!/usr/bin/env python3
"""
Script para inicializar colecciones específicas de CONDUCTORES en Firestore.
Crea: users (con driver_profile), vehicles, trips, transactions, notifications, ratings

Uso:
    python firestore_init_driver_collections.py --project-id=mi-ruta-4004d --json-key=firebase-key.json
"""

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import argparse
from datetime import datetime, timedelta, time
import uuid
import random

# ============================================================================
# DATOS DE EJEMPLO - CONDUCTORES
# ============================================================================

EXAMPLE_DRIVERS = [
    {
        "uid": "driver_001",
        "full_name": "Juan Pérez",
        "phone_number": "+591 70123456",
        "email": "juan.perez@gmail.com",
        "profile_picture_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/profiles%2Fdriver_001.jpg",
        "role": "driver",
        "created_at": datetime.now().isoformat(),
        "is_driver_mode": True,
        "dark_mode": False,
        "driver_profile": {
            "current_vehicle_id": "ABC-1234",
            "assigned_route_id": "line_233",
            "is_service_active": False,
            "average_rating": 4.9,
            "total_trips_completed": 42
        }
    },
    {
        "uid": "driver_002",
        "full_name": "Carlos Eduardo Mamani",
        "phone_number": "+591 76543210",
        "email": "carlos.mamani@gmail.com",
        "profile_picture_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/profiles%2Fdriver_002.jpg",
        "role": "driver",
        "created_at": datetime.now().isoformat(),
        "is_driver_mode": True,
        "dark_mode": False,
        "driver_profile": {
            "current_vehicle_id": "XYZ-5678",
            "assigned_route_id": "line_138",
            "is_service_active": True,
            "average_rating": 4.7,
            "total_trips_completed": 28
        }
    }
]

EXAMPLE_VEHICLES = [
    {
        "vehicle_id": "ABC-1234",
        "owner_uid": "driver_001",
        "vehicle_type": "taxitrufi",
        "line_number": "233",
        "internal_number": "103",
        "brand": "Toyota",
        "model": "Corolla 2023",
        "color": "Blanco",
        "passenger_capacity": 15,
        "status": "approved",
        "legal_documentation": {
            "driver_license_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/documents%2Fdriver_001_license.pdf",
            "vehicle_inspection_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/documents%2FABC1234_inspection.pdf",
            "soat_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/documents%2FABC1234_soat.pdf",
            "ruat_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/documents%2FABC1234_ruat.pdf",
            "municipal_operation_card_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/documents%2FABC1234_municipal.pdf"
        },
        "updated_at": datetime.now().isoformat()
    },
    {
        "vehicle_id": "XYZ-5678",
        "owner_uid": "driver_002",
        "vehicle_type": "micro",
        "line_number": "138",
        "internal_number": "045",
        "brand": "Mercedes-Benz",
        "model": "Sprinter 2022",
        "color": "Azul",
        "passenger_capacity": 24,
        "status": "approved",
        "legal_documentation": {
            "driver_license_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/documents%2Fdriver_002_license.pdf",
            "vehicle_inspection_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/documents%2FXYZ5678_inspection.pdf",
            "soat_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/documents%2FXYZ5678_soat.pdf",
            "ruat_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/documents%2FXYZ5678_ruat.pdf",
            "municipal_operation_card_url": "https://firebasestorage.googleapis.com/v0/b/mi-ruta-4004d.appspot.com/o/documents%2FXYZ5678_municipal.pdf"
        },
        "updated_at": datetime.now().isoformat()
    }
]

EXAMPLE_TRIPS = [
    {
        "trip_id": "TRP_001",
        "driver_uid": "driver_001",
        "vehicle_id": "ABC-1234",
        "internal_number": "103",
        "route_line": "233",
        "route_name": "Quillacollo - Cochabamba",
        "start_point": "Terminal Quillacollo",
        "end_point": "Plaza 14 de Septiembre",
        "start_time": (datetime.now() - timedelta(days=1, hours=8)).isoformat(),
        "end_time": (datetime.now() - timedelta(days=1, hours=7, minutes=45)).isoformat(),
        "duration_minutes": 15,
        "distance_km": 5.2,
        "base_fare": 4.00,
        "passengers_count": 8,
        "points_earned": 120,
        "total_amount_accumulated": 32.00,
        "geo_path_snapshot_url": "https://maps.googleapis.com/maps/api/staticmap?path=auto&markers=color:red|51.5,0&key=YOUR_KEY"
    },
    {
        "trip_id": "TRP_002",
        "driver_uid": "driver_001",
        "vehicle_id": "ABC-1234",
        "internal_number": "103",
        "route_line": "233",
        "route_name": "Quillacollo - Cochabamba",
        "start_point": "Plaza 14 de Septiembre",
        "end_point": "Terminal Quillacollo",
        "start_time": (datetime.now() - timedelta(days=1, hours=7, minutes=30)).isoformat(),
        "end_time": (datetime.now() - timedelta(days=1, hours=7, minutes=15)).isoformat(),
        "duration_minutes": 15,
        "distance_km": 5.1,
        "base_fare": 4.00,
        "passengers_count": 12,
        "points_earned": 150,
        "total_amount_accumulated": 48.00,
        "geo_path_snapshot_url": "https://maps.googleapis.com/maps/api/staticmap?path=auto&markers=color:red|51.5,0&key=YOUR_KEY"
    },
    {
        "trip_id": "TRP_003",
        "driver_uid": "driver_002",
        "vehicle_id": "XYZ-5678",
        "internal_number": "045",
        "route_line": "138",
        "route_name": "Zona Central - Zona Sur",
        "start_point": "Calle Comercio",
        "end_point": "Avenida Blanco",
        "start_time": (datetime.now() - timedelta(hours=3)).isoformat(),
        "end_time": (datetime.now() - timedelta(hours=2, minutes=45)).isoformat(),
        "duration_minutes": 15,
        "distance_km": 6.8,
        "base_fare": 2.50,
        "passengers_count": 18,
        "points_earned": 200,
        "total_amount_accumulated": 45.00,
        "geo_path_snapshot_url": "https://maps.googleapis.com/maps/api/staticmap?path=auto&markers=color:red|51.5,0&key=YOUR_KEY"
    }
]

EXAMPLE_TRANSACTIONS_DRIVERS = [
    {
        "transaction_id": "TX_001",
        "user_uid": "driver_001",
        "type": "trip_income",
        "amount": 32.00,
        "currency": "Bs",
        "description": "Ingreso por viajes - Día 1",
        "payment_method": "QR_code",
        "timestamp": (datetime.now() - timedelta(days=1, hours=8)).isoformat(),
        "analytics": {
            "day_of_week": "V",
            "week_number": 22,
            "year": 2026
        }
    },
    {
        "transaction_id": "TX_002",
        "user_uid": "driver_001",
        "type": "withdrawal",
        "amount": -150.00,
        "currency": "Bs",
        "description": "Retiro de ganancias",
        "payment_method": "bank_transfer",
        "timestamp": (datetime.now() - timedelta(days=2)).isoformat(),
        "analytics": {
            "day_of_week": "J",
            "week_number": 22,
            "year": 2026
        }
    },
    {
        "transaction_id": "TX_003",
        "user_uid": "driver_002",
        "type": "trip_income",
        "amount": 45.00,
        "currency": "Bs",
        "description": "Ingreso por viajes - Hoy",
        "payment_method": "QR_code",
        "timestamp": (datetime.now() - timedelta(hours=3)).isoformat(),
        "analytics": {
            "day_of_week": "S",
            "week_number": 22,
            "year": 2026
        }
    }
]

EXAMPLE_NOTIFICATIONS = [
    {
        "notification_id": "NTF_001",
        "recipient_uid": "driver_001",
        "type": "maintenance",
        "title": "Recordatorio de Mantenimiento",
        "body": "Tu vehículo ABC-1234 necesita mantenimiento preventivo",
        "is_read": False,
        "timestamp": (datetime.now() - timedelta(hours=2)).isoformat()
    },
    {
        "notification_id": "NTF_002",
        "recipient_uid": "driver_002",
        "type": "stop_request",
        "title": "Solicitud de Parada",
        "body": "Un pasajero solicita detenerse",
        "is_read": False,
        "timestamp": datetime.now().isoformat(),
        "stop_details": {
            "location_name": "Av. Beijing",
            "estimated_time_minutes": 5
        }
    },
    {
        "notification_id": "NTF_003",
        "recipient_uid": "driver_001",
        "type": "road_block",
        "title": "Bloqueo (Protestas)",
        "body": "La calle 231 está bloqueada debido a una movilización",
        "is_read": True,
        "timestamp": (datetime.now() - timedelta(hours=12)).isoformat()
    },
    {
        "notification_id": "NTF_004",
        "recipient_uid": "driver_002",
        "type": "payment_alert",
        "title": "Alerta de Pago",
        "body": "Se detectó un pago anómalo en tu cuenta",
        "is_read": False,
        "timestamp": (datetime.now() - timedelta(hours=1)).isoformat()
    }
]

EXAMPLE_RATINGS = [
    {
        "rating_id": "RAT_001",
        "trip_id": "TRP_001",
        "reviewer_uid": "user_001",
        "target_uid": "driver_001",
        "stars": 5,
        "selected_tags": [
            "Conductor amable",
            "Viaje seguro",
            "Llegó a tiempo"
        ],
        "created_at": (datetime.now() - timedelta(days=1, hours=7)).isoformat()
    },
    {
        "rating_id": "RAT_002",
        "trip_id": "TRP_002",
        "reviewer_uid": "user_002",
        "target_uid": "driver_001",
        "stars": 4,
        "selected_tags": [
            "Excelente conducción",
            "Vehículo limpio"
        ],
        "created_at": (datetime.now() - timedelta(days=1, hours=7, minutes=10)).isoformat()
    },
    {
        "rating_id": "RAT_003",
        "trip_id": "TRP_003",
        "reviewer_uid": "user_003",
        "target_uid": "driver_002",
        "stars": 4,
        "selected_tags": [
            "Conductor experimentado",
            "Ruta optimizada"
        ],
        "created_at": (datetime.now() - timedelta(hours=2, minutes=45)).isoformat()
    }
]


def init_firebase(project_id, json_key_path):
    """Inicializa Firebase con credenciales."""
    try:
        if json_key_path:
            cred = credentials.Certificate(json_key_path)
            firebase_admin.initialize_app(cred, {
                'projectId': project_id
            })
        else:
            firebase_admin.initialize_app()
        print(f"✓ Firebase inicializado correctamente (Proyecto: {project_id})")
        return firestore.client()
    except Exception as e:
        print(f"✗ Error al inicializar Firebase: {e}")
        raise


def create_drivers(db):
    """Actualiza/crea usuarios conductores con driver_profile."""
    print("\n👨‍✈️  Creando/Actualizando conductores con driver_profile...")
    for driver in EXAMPLE_DRIVERS:
        try:
            db.collection('users').document(driver['uid']).set(driver)
            print(f"  ✓ Conductor creado: {driver['full_name']} (Ruta: {driver['driver_profile']['assigned_route_id']})")
        except Exception as e:
            print(f"  ✗ Error creando conductor {driver['uid']}: {e}")


def create_vehicles(db):
    """Crea vehículos con documentación legal."""
    print("\n🚗 Creando colección 'vehicles' con documentación legal...")
    for vehicle in EXAMPLE_VEHICLES:
        try:
            db.collection('vehicles').document(vehicle['vehicle_id']).set(vehicle)
            print(f"  ✓ Vehículo creado: {vehicle['brand']} {vehicle['model']} ({vehicle['vehicle_id']})")
            print(f"    - Placa: {vehicle['vehicle_id']}")
            print(f"    - Capacidad: {vehicle['passenger_capacity']} pasajeros")
            print(f"    - Documentos: {len(vehicle['legal_documentation'])} archivos")
        except Exception as e:
            print(f"  ✗ Error creando vehículo {vehicle['vehicle_id']}: {e}")


def create_trips(db):
    """Crea historial de viajes realizados."""
    print("\n🗺️  Creando colección 'trips' (Historial de viajes)...")
    for trip in EXAMPLE_TRIPS:
        try:
            db.collection('trips').document(trip['trip_id']).set(trip)
            print(f"  ✓ Viaje creado: {trip['route_name']} ({trip['trip_id']})")
            print(f"    - Conductor: {trip['driver_uid']}")
            print(f"    - Pasajeros: {trip['passengers_count']}")
            print(f"    - Ingresos: Bs {trip['total_amount_accumulated']}")
        except Exception as e:
            print(f"  ✗ Error creando viaje {trip['trip_id']}: {e}")


def create_transactions_drivers(db):
    """Crea transacciones de ingresos de conductores."""
    print("\n💰 Creando colección 'transactions' (Ingresos de conductores)...")
    for tx in EXAMPLE_TRANSACTIONS_DRIVERS:
        try:
            db.collection('transactions').document(tx['transaction_id']).set(tx)
            tx_type = "Ingreso" if tx['type'] == "trip_income" else "Retiro"
            print(f"  ✓ Transacción: {tx_type} - Bs {abs(tx['amount'])} ({tx['transaction_id']})")
        except Exception as e:
            print(f"  ✗ Error creando transacción {tx['transaction_id']}: {e}")


def create_notifications_drivers(db):
    """Crea notificaciones específicas para conductores."""
    print("\n🔔 Creando colección 'notifications' (Alertas y solicitudes)...")
    for notif in EXAMPLE_NOTIFICATIONS:
        try:
            db.collection('notifications').document(notif['notification_id']).set(notif)
            status = "✓ leído" if notif['is_read'] else "⭕ no leído"
            print(f"  ✓ Notificación: {notif['title']} {status}")
            if 'stop_details' in notif:
                print(f"    - Ubicación: {notif['stop_details']['location_name']}")
        except Exception as e:
            print(f"  ✗ Error creando notificación {notif['notification_id']}: {e}")


def create_ratings(db):
    """Crea calificaciones y reseñas de viajes."""
    print("\n⭐ Creando colección 'ratings' (Calificaciones de conductores)...")
    for rating in EXAMPLE_RATINGS:
        try:
            db.collection('ratings').document(rating['rating_id']).set(rating)
            stars = "⭐" * rating['stars']
            print(f"  ✓ Calificación: {stars} ({rating['rating_id']})")
            print(f"    - Conductor: {rating['target_uid']}")
            print(f"    - Tags: {', '.join(rating['selected_tags'][:2])}")
        except Exception as e:
            print(f"  ✗ Error creando calificación {rating['rating_id']}: {e}")


def main():
    parser = argparse.ArgumentParser(
        description='Inicializa colecciones de conductores en Firestore'
    )
    parser.add_argument(
        '--project-id',
        required=True,
        help='ID del proyecto Firebase'
    )
    parser.add_argument(
        '--json-key',
        help='Ruta al archivo serviceAccountKey.json'
    )
    parser.add_argument(
        '--collection',
        help='Crear solo una colección específica (drivers, vehicles, trips, transactions, notifications, ratings)'
    )
    
    args = parser.parse_args()
    
    db = init_firebase(args.project_id, args.json_key)
    
    print("\n" + "="*70)
    print("🔥 INICIALIZANDO FIRESTORE - COLECCIONES DE CONDUCTORES")
    print("="*70)
    
    try:
        if not args.collection or args.collection == 'drivers':
            create_drivers(db)
        
        if not args.collection or args.collection == 'vehicles':
            create_vehicles(db)
        
        if not args.collection or args.collection == 'trips':
            create_trips(db)
        
        if not args.collection or args.collection == 'transactions':
            create_transactions_drivers(db)
        
        if not args.collection or args.collection == 'notifications':
            create_notifications_drivers(db)
        
        if not args.collection or args.collection == 'ratings':
            create_ratings(db)
        
        print("\n" + "="*70)
        print("✅ INICIALIZACIÓN COMPLETADA")
        print("="*70)
        print("\n📊 Resumen de datos creados:")
        print(f"  👨‍✈️  Conductores: {len(EXAMPLE_DRIVERS)}")
        print(f"  🚗 Vehículos: {len(EXAMPLE_VEHICLES)}")
        print(f"  🗺️  Viajes completados: {len(EXAMPLE_TRIPS)}")
        print(f"  💰 Transacciones: {len(EXAMPLE_TRANSACTIONS_DRIVERS)}")
        print(f"  🔔 Notificaciones: {len(EXAMPLE_NOTIFICATIONS)}")
        print(f"  ⭐ Calificaciones: {len(EXAMPLE_RATINGS)}")
        
        print("\n📚 Estructura de colecciones:")
        print("  1. users (expandida): uid → driver_profile")
        print("  2. vehicles: vehicle_id (placa) → legal_documentation")
        print("  3. trips: trip_id → datos del viaje y ganancias")
        print("  4. transactions: transaction_id → ingresos y retiros")
        print("  5. notifications: notification_id → alertas y solicitudes")
        print("  6. ratings: rating_id → evaluaciones de usuarios sobre conductores")
        
        print("\n💡 Acciones recomendadas:")
        print("  1. Verifica los datos en Firebase Console")
        print("  2. Implementa las vistas en la app Flutter")
        print("  3. Integra el BLoC para manejo de estado")
        print("  4. Carga las imágenes y documentos reales a Storage")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        raise


if __name__ == '__main__':
    main()
