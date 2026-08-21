#!/usr/bin/env python3
"""
Script para inicializar colecciones en Firestore con datos de ejemplo.
Crea las nuevas colecciones: claims, station_logs
Y actualiza usuarios y transporte_lines con nueva información.

Uso:
    python firestore_init_collections.py --project-id=mi-ruta-proyecto --json-key=path/to/serviceAccountKey.json
"""

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import argparse
from datetime import datetime, timedelta
import uuid

# Datos de ejemplo
EXAMPLE_USERS = [
    {
        "uid": "user_001",
        "full_name": "Juan Pérez García",
        "email": "juan.perez@example.com",
        "government_id": "12345678LP",
        "phone_number": "+591 70123456",
        "profile_picture_url": "https://example.com/profiles/user_001.jpg",
        "role": "user",
        "created_at": datetime.now().isoformat(),
        "wallet": {
            "current_balance": 67.50,
            "currency": "Bs"
        },
        "settings": {
            "dark_mode_enabled": False,
            "is_driver_mode": False
        }
    },
    {
        "uid": "driver_001",
        "full_name": "Carlos Eduardo Mamani",
        "email": "carlos.mamani@example.com",
        "government_id": "87654321SC",
        "phone_number": "+591 76543210",
        "profile_picture_url": "https://example.com/profiles/driver_001.jpg",
        "role": "driver",
        "created_at": datetime.now().isoformat(),
        "wallet": {
            "current_balance": 150.00,
            "currency": "Bs"
        },
        "settings": {
            "dark_mode_enabled": False,
            "is_driver_mode": True
        },
        "driver_info": {
            "assigned_line_id": "line_138",
            "vehicle_plate": "2341-ABC",
            "vehicle_capacity": 24,
            "status": "approved",
            "performance_status": "good",
            "strikes_count": 0
        }
    },
    {
        "uid": "tick_001",
        "full_name": "María López Rojas",
        "email": "maria.lopez@example.com",
        "government_id": "11223344LP",
        "phone_number": "+591 72234567",
        "profile_picture_url": "https://example.com/profiles/tick_001.jpg",
        "role": "tickeador",
        "created_at": datetime.now().isoformat(),
        "wallet": {
            "current_balance": 200.00,
            "currency": "Bs"
        },
        "settings": {
            "dark_mode_enabled": False,
            "is_driver_mode": False
        },
        "tickeador_info": {
            "assigned_station": "Terminal Sur",
            "assigned_lines": ["line_138", "line_200"],
            "status": "active"
        }
    },
    {
        "uid": "admin_001",
        "full_name": "Roberto Sánchez Flores",
        "email": "admin@example.com",
        "government_id": "55667788LP",
        "phone_number": "+591 79876543",
        "profile_picture_url": "https://example.com/profiles/admin_001.jpg",
        "role": "admin",
        "created_at": datetime.now().isoformat(),
        "wallet": {
            "current_balance": 500.00,
            "currency": "Bs"
        },
        "settings": {
            "dark_mode_enabled": True,
            "is_driver_mode": False
        },
        "admin_info": {
            "assigned_line_id": "line_138",
            "privileges": {
                "manage_routes": {"create": True, "edit": True, "delete": False},
                "manage_users": {"accept": True, "suspend": True, "delete": False},
                "manage_admins": {"create": False, "edit": False, "delete": False}
            }
        }
    },
    {
        "uid": "presidente_001",
        "full_name": "Fernando Guzmán Quispe",
        "email": "presidente@example.com",
        "government_id": "99887766LP",
        "phone_number": "+591 75555555",
        "profile_picture_url": "https://example.com/profiles/presidente_001.jpg",
        "role": "presidente",
        "created_at": datetime.now().isoformat(),
        "wallet": {
            "current_balance": 1000.00,
            "currency": "Bs"
        },
        "settings": {
            "dark_mode_enabled": True,
            "is_driver_mode": False
        },
        "admin_info": {
            "assigned_line_id": "line_138",
            "privileges": {
                "manage_routes": {"create": True, "edit": True, "delete": True},
                "manage_users": {"accept": True, "suspend": True, "delete": True},
                "manage_admins": {"create": True, "edit": True, "delete": True}
            }
        }
    }
]

EXAMPLE_TRANSPORT_LINES = [
    {
        "line_id": "line_138",
        "line_name": "Línea 138",
        "transport_type": "micro",
        "status": "active",
        "is_diverted_realtime": False,
        "origin": "Zona Central (Calle Comercio)",
        "destination": "Zona Sur (Avenida Blanco)",
        "base_fare": 2.00,
        "created_at": datetime.now().isoformat()
    },
    {
        "line_id": "line_200",
        "line_name": "Línea 200",
        "transport_type": "minibus",
        "status": "active",
        "is_diverted_realtime": False,
        "origin": "Terminal Norte",
        "destination": "Zona Periférica",
        "base_fare": 2.50,
        "created_at": datetime.now().isoformat()
    }
]

EXAMPLE_TRANSACTIONS = [
    {
        "user_id": "user_001",
        "transaction_type": "trip_payment",
        "amount": 2.00,
        "description": "Pago Transporte Línea 138",
        "timestamp": (datetime.now() - timedelta(days=1)).isoformat(),
        "payment_method": "wallet",
        "status": "completed"
    },
    {
        "user_id": "user_001",
        "transaction_type": "wallet_recharge",
        "amount": 50.00,
        "description": "Recarga Cartera",
        "timestamp": (datetime.now() - timedelta(days=2)).isoformat(),
        "payment_method": "credit_card",
        "status": "completed"
    }
]

EXAMPLE_CLAIMS = [
    {
        "claim_id": "claim_001",
        "reporter_id": "user_001",
        "target_id": "driver_001",
        "line_id": "line_138",
        "claim_type": "driver",
        "title": "Tarifa incorrecta",
        "description": "El chofer me cobró Bs 3.00 en lugar de Bs 2.00",
        "status": "open",
        "created_at": datetime.now().isoformat(),
        "resolved_at": None,
        "resolved_by": None
    },
    {
        "claim_id": "claim_002",
        "reporter_id": "driver_001",
        "target_id": "user_001",
        "line_id": "line_138",
        "claim_type": "user",
        "title": "Pasajero agresivo",
        "description": "El pasajero fue irrespetuoso con el personal de transporte",
        "status": "resolved",
        "created_at": (datetime.now() - timedelta(days=3)).isoformat(),
        "resolved_at": (datetime.now() - timedelta(days=2)).isoformat(),
        "resolved_by": "admin_001"
    },
    {
        "claim_id": "claim_003",
        "reporter_id": "tick_001",
        "target_id": None,
        "line_id": "line_138",
        "claim_type": "service",
        "title": "Sistema de reservas lento",
        "description": "El sistema tarda más de 5 segundos en confirmar la compra",
        "status": "open",
        "created_at": datetime.now().isoformat(),
        "resolved_at": None,
        "resolved_by": None
    }
]

EXAMPLE_STATION_LOGS = [
    {
        "log_id": "log_001",
        "tickeador_id": "tick_001",
        "station_name": "Terminal Sur",
        "line_id": "line_138",
        "vehicle_plate": "2341-ABC",
        "driver_id": "driver_001",
        "passenger_count": 24,
        "max_capacity": 24,
        "log_type": "departure",
        "timestamp": (datetime.now() - timedelta(hours=2)).isoformat(),
        "time_since_last_departure": "1h 20min"
    },
    {
        "log_id": "log_002",
        "tickeador_id": "tick_001",
        "station_name": "Terminal Sur",
        "line_id": "line_138",
        "vehicle_plate": "2341-ABC",
        "driver_id": "driver_001",
        "passenger_count": 22,
        "max_capacity": 24,
        "log_type": "departure",
        "timestamp": (datetime.now() - timedelta(hours=4)).isoformat(),
        "time_since_last_departure": "1h 15min"
    },
    {
        "log_id": "log_003",
        "tickeador_id": "tick_001",
        "station_name": "Terminal Sur",
        "line_id": "line_200",
        "vehicle_plate": "5678-XYZ",
        "driver_id": "driver_002" if "driver_002" else "driver_001",
        "passenger_count": 18,
        "max_capacity": 20,
        "log_type": "arrival",
        "timestamp": (datetime.now() - timedelta(hours=3)).isoformat(),
        "time_since_last_departure": None
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
            # Usa credenciales por defecto (variables de entorno)
            firebase_admin.initialize_app()
        print(f"✓ Firebase inicializado correctamente (Proyecto: {project_id})")
        return firestore.client()
    except Exception as e:
        print(f"✗ Error al inicializar Firebase: {e}")
        raise


def create_users(db):
    """Crea usuarios de ejemplo."""
    print("\n📝 Creando colección 'users'...")
    for user in EXAMPLE_USERS:
        try:
            db.collection('users').document(user['uid']).set(user)
            print(f"  ✓ Usuario creado: {user['full_name']} ({user['role']})")
        except Exception as e:
            print(f"  ✗ Error creando usuario {user['uid']}: {e}")


def create_transport_lines(db):
    """Crea líneas de transporte de ejemplo."""
    print("\n🚌 Creando colección 'transport_lines'...")
    for line in EXAMPLE_TRANSPORT_LINES:
        try:
            db.collection('transport_lines').document(line['line_id']).set(line)
            print(f"  ✓ Línea creada: {line['line_name']}")
        except Exception as e:
            print(f"  ✗ Error creando línea {line['line_id']}: {e}")


def create_transactions(db):
    """Crea transacciones de ejemplo."""
    print("\n💰 Creando colección 'transactions'...")
    for tx in EXAMPLE_TRANSACTIONS:
        try:
            doc_id = str(uuid.uuid4())
            db.collection('transactions').document(doc_id).set(tx)
            print(f"  ✓ Transacción creada: {tx['description']} ({tx['status']})")
        except Exception as e:
            print(f"  ✗ Error creando transacción: {e}")


def create_claims(db):
    """Crea reclamos de ejemplo (NUEVA COLECCIÓN)."""
    print("\n⚠️  Creando colección 'claims' (NUEVA)...")
    for claim in EXAMPLE_CLAIMS:
        try:
            db.collection('claims').document(claim['claim_id']).set(claim)
            print(f"  ✓ Reclamo creado: {claim['title']} ({claim['status']})")
        except Exception as e:
            print(f"  ✗ Error creando reclamo {claim['claim_id']}: {e}")


def create_station_logs(db):
    """Crea registros de terminal de ejemplo (NUEVA COLECCIÓN)."""
    print("\n📊 Creando colección 'station_logs' (NUEVA)...")
    for log in EXAMPLE_STATION_LOGS:
        try:
            db.collection('station_logs').document(log['log_id']).set(log)
            log_type = "Salida" if log['log_type'] == "departure" else "Llegada"
            print(f"  ✓ Registro creado: {log_type} Línea {log['line_id']}")
        except Exception as e:
            print(f"  ✗ Error creando registro {log['log_id']}: {e}")


def create_notifications(db):
    """Crea notificaciones de ejemplo."""
    print("\n🔔 Creando colección 'notifications'...")
    notifications = [
        {
            "user_id": "user_001",
            "category": "wallet",
            "title": "Saldo bajo",
            "content": "Tu saldo está por debajo de Bs 20. Recarga tu cartera.",
            "is_read": False,
            "created_at": datetime.now().isoformat(),
            "deep_link_module": "module_wallet"
        },
        {
            "user_id": "user_001",
            "category": "system",
            "title": "Nueva ruta disponible",
            "content": "Hay una nueva ruta a tu destino frecuente",
            "is_read": False,
            "created_at": datetime.now().isoformat(),
            "deep_link_module": "module_routes"
        }
    ]
    
    for notif in notifications:
        try:
            doc_id = str(uuid.uuid4())
            db.collection('notifications').document(doc_id).set(notif)
            print(f"  ✓ Notificación creada: {notif['title']}")
        except Exception as e:
            print(f"  ✗ Error creando notificación: {e}")


def create_routes_bbox(db):
    """Crea bounding boxes de rutas de ejemplo."""
    print("\n🗺️  Creando colección 'routes_bbox'...")
    routes_bbox = [
        {
            "route_id": "route_138_001",
            "line_id": "line_138",
            "bbox": {
                "north": -16.4980,
                "south": -16.5500,
                "east": -68.0900,
                "west": -68.1600
            },
            "metadata": {
                "line_name": "Línea 138",
                "transport_type": "micro",
                "base_fare": 2.00
            },
            "created_at": datetime.now().isoformat()
        }
    ]
    
    for route in routes_bbox:
        try:
            db.collection('routes_bbox').document(route['route_id']).set(route)
            print(f"  ✓ Ruta BBox creada: {route['metadata']['line_name']}")
        except Exception as e:
            print(f"  ✗ Error creando ruta bbox: {e}")


def main():
    parser = argparse.ArgumentParser(
        description='Inicializa colecciones en Firestore con datos de ejemplo'
    )
    parser.add_argument(
        '--project-id',
        required=True,
        help='ID del proyecto Firebase'
    )
    parser.add_argument(
        '--json-key',
        help='Ruta al archivo serviceAccountKey.json (opcional si usas credenciales por defecto)'
    )
    parser.add_argument(
        '--skip-users',
        action='store_true',
        help='Salta la creación de usuarios'
    )
    parser.add_argument(
        '--only-new',
        action='store_true',
        help='Solo crea las nuevas colecciones (claims, station_logs)'
    )
    
    args = parser.parse_args()
    
    # Inicializar Firebase
    db = init_firebase(args.project_id, args.json_key)
    
    print("\n" + "="*60)
    print("🔥 INICIALIZANDO FIRESTORE CON DATOS DE EJEMPLO")
    print("="*60)
    
    try:
        if not args.only_new:
            if not args.skip_users:
                create_users(db)
            create_transport_lines(db)
            create_transactions(db)
            create_notifications(db)
            create_routes_bbox(db)
        
        # Nuevas colecciones
        create_claims(db)
        create_station_logs(db)
        
        print("\n" + "="*60)
        print("✅ INICIALIZACIÓN COMPLETADA EXITOSAMENTE")
        print("="*60)
        print("\n📊 Resumen:")
        print(f"  - Usuarios: {len(EXAMPLE_USERS)}")
        print(f"  - Líneas de transporte: {len(EXAMPLE_TRANSPORT_LINES)}")
        print(f"  - Transacciones: {len(EXAMPLE_TRANSACTIONS)}")
        print(f"  - Reclamos (NUEVA): {len(EXAMPLE_CLAIMS)}")
        print(f"  - Registros de terminal (NUEVA): {len(EXAMPLE_STATION_LOGS)}")
        print(f"  - Notificaciones: 2")
        print(f"  - Rutas BBox: 1")
        print("\n💡 Próximos pasos:")
        print("  1. Verifica los datos en Firebase Console")
        print("  2. Crea sub-colecciones 'schedules' bajo transport_lines si es necesario")
        print("  3. Ajusta los datos según tus necesidades específicas")
        
    except Exception as e:
        print(f"\n❌ Error durante la inicialización: {e}")
        raise


if __name__ == '__main__':
    main()
