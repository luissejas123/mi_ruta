# Script para Inicializar Firestore - Mi Ruta

> ⚠️ **NO EJECUTAR contra un proyecto Firebase real sin revisar primero — desactualizado desde 2026-06-01, verificado contra el esquema y el código reales el 2026-08-31 (ver `docs/DEUDA_TECNICA.md` para el detalle completo):**
> - Crea la colección `transport_lines`, que `FIRESTORE_COLLECTIONS_GUIDE.md` declara explícitamente **eliminada/inexistente** en el proyecto real.
> - El documento de `routes_bbox` que siembra usa un esquema anidado (`bbox: {north, south, east, west}`) y **no escribe el campo `active`** que el código filtra al leer (`.where('active', isEqualTo: true)`) — cualquier ruta sembrada por este script queda invisible para la app. Las coordenadas de ejemplo además son de La Paz, no de Cochabamba.
> - El documento de `notifications` que siembra es un documento plano; el código real espera la subcolección `notifications/{uid}/items` — son incompatibles.
> - Los `users` que siembra no incluyen `roles`/`is_super_admin`/`admin_permissions`. Si el uid de un documento sembrado coincidiera con una cuenta real, la sobrescribiría **degradando sus permisos en silencio** (el script sí sobrescribe: ver la sección de flags más abajo).
> - Existe un **segundo script**, `tools/firestore_init_driver_collections.py` (crea `vehicles`, `trips`, `ratings`), que este README no menciona en ningún lado.
>
> Antes de correrlo: comparar campo por campo contra `FIRESTORE_COLLECTIONS_GUIDE.md` (fuente de verdad del esquema) y decidir si conviene reescribirlo o retirarlo.

## Descripción

Script Python para inicializar Firestore con datos de ejemplo para el proyecto Mi Ruta. Crea todas las colecciones necesarias incluyendo las nuevas colecciones `claims` y `station_logs` con datos realistas.

## Requisitos

1. **Python 3.7+**
2. **Firebase Admin SDK para Python**
3. **Credenciales de Firebase (serviceAccountKey.json)**

## Instalación de Dependencias

```bash
pip install firebase-admin
```

## Configuración de Credenciales

### Opción 1: Usando archivo serviceAccountKey.json (Recomendado)

1. Abre [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto
3. Ve a **Configuración del proyecto** → **Cuentas de servicio**
4. Haz clic en **Generar nueva clave privada**
5. Guarda el archivo JSON descargado (ej: `mi-ruta-firebase-key.json`)

### Opción 2: Usando variables de entorno

```bash
# En Windows (PowerShell)
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\ruta\al\serviceAccountKey.json"

# En Linux/Mac
export GOOGLE_APPLICATION_CREDENTIALS="/ruta/al/serviceAccountKey.json"
```

## Uso

### Comando Básico

```bash
python firestore_init_collections.py --project-id=mi-ruta-prod --json-key=path/to/serviceAccountKey.json
```

### Ejemplos

**Inicializar todas las colecciones:**
```bash
python firestore_init_collections.py \
  --project-id=mi-ruta-prod \
  --json-key=../firebase-key.json
```

**Solo crear las nuevas colecciones (claims y station_logs):**
```bash
python firestore_init_collections.py \
  --project-id=mi-ruta-prod \
  --json-key=../firebase-key.json \
  --only-new
```

**Saltarse la creación de usuarios:**
```bash
python firestore_init_collections.py \
  --project-id=mi-ruta-prod \
  --json-key=../firebase-key.json \
  --skip-users
```

**Usando variables de entorno (sin --json-key):**
```bash
python firestore_init_collections.py --project-id=mi-ruta-prod
```

## Colecciones Creadas

### Datos de Ejemplo Creados

#### 1. **users** (5 usuarios)
- `user_001`: Pasajero regular (role: user)
- `driver_001`: Conductor (role: driver)
- `tick_001`: Operador de terminal (role: tickeador)
- `admin_001`: Administrador (role: admin)
- `presidente_001`: Presidente de línea (role: presidente)

**Campos incluidos:** Sub-objetos para `driver_info`, `tickeador_info`, `admin_info`

#### 2. **transport_lines** (2 líneas)
- `line_138`: Línea 138 (micro)
- `line_200`: Línea 200 (minibus)

**Campos nuevos:** `is_diverted_realtime`, `origin`, `destination`

#### 3. **transactions** (2 transacciones)
- Pago de viaje
- Recarga de cartera

#### 4. **claims** (3 reclamos) ⭐ NUEVA
- Reclamo sobre chofer
- Reclamo sobre usuario (resuelto)
- Reclamo sobre servicio

#### 5. **station_logs** (3 registros) ⭐ NUEVA
- Salidas de vehículos
- Llegadas de vehículos

#### 6. **notifications** (2 notificaciones)
- Alerta de saldo bajo
- Notificación de nueva ruta

#### 7. **routes_bbox** (1 ruta)
- BBox para Línea 138

## Campos de Ejemplo

### users - Sub-objeto driver_info
```json
{
  "driver_info": {
    "assigned_line_id": "line_138",
    "vehicle_plate": "2341-ABC",
    "vehicle_capacity": 24,
    "status": "approved",
    "performance_status": "good",
    "strikes_count": 0
  }
}
```

### claims - Estructura Completa
```json
{
  "claim_id": "claim_001",
  "reporter_id": "user_001",
  "target_id": "driver_001",
  "line_id": "line_138",
  "claim_type": "driver",
  "title": "Tarifa incorrecta",
  "description": "El chofer me cobró Bs 3.00 en lugar de Bs 2.00",
  "status": "open",
  "created_at": "2026-05-30T...",
  "resolved_at": null,
  "resolved_by": null
}
```

### station_logs - Estructura Completa
```json
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
  "timestamp": "2026-05-30T...",
  "time_since_last_departure": "1h 20min"
}
```

## Opciones de Línea de Comandos

| Opción | Descripción | Ejemplo |
|--------|-------------|---------|
| `--project-id` | **Requerido.** ID del proyecto Firebase | `mi-ruta-prod` |
| `--json-key` | Ruta al archivo serviceAccountKey.json | `../firebase-key.json` |
| `--skip-users` | Salta la creación de usuarios | Flag (sin valor) |
| `--only-new` | Solo crea claims y station_logs | Flag (sin valor) |

## Notas Importantes

⚠️ **Antes de ejecutar en producción:**

1. **Respalda tus datos existentes** - El script sobrescribe documentos con los mismos IDs
2. **Ejecuta en desarrollo primero** - Prueba con el proyecto de desarrollo
3. **Verifica los datos** - Abre Firebase Console para revisar los datos creados
4. **Ajusta los datos** - Modifica `EXAMPLE_*` en el script según tus necesidades

## Solución de Problemas

### Error: "The user does not have permission to access the specified project"

```bash
# Verifica que el project-id sea correcto
# Revisa que las credenciales tengan permisos en Firestore
```

### Error: "Module firebase_admin not found"

```bash
pip install firebase-admin
```

### Error: "Invalid JSON key file"

- Verifica que el archivo existe
- Verifica la ruta (usa rutas absolutas o relativas claras)
- Asegúrate de que es un archivo válido de serviceAccountKey.json

### Los datos no aparecen en Firebase Console

1. Espera unos segundos y recarga la consola
2. Verifica que estés en el proyecto correcto
3. Comprueba que el script terminó sin errores

## Personalización

Para agregar más datos de ejemplo:

1. Abre `firestore_init_collections.py`
2. Modifica las listas `EXAMPLE_*`:
   ```python
   EXAMPLE_CLAIMS.append({
       "claim_id": "claim_004",
       "reporter_id": "user_002",
       # ... más campos
   })
   ```
3. Ejecuta el script nuevamente

## Próximos Pasos

Después de ejecutar el script:

1. ✅ Verifica los datos en [Firebase Console](https://console.firebase.google.com)
2. ✅ Crea sub-colecciones `schedules` bajo `transport_lines` si lo necesitas
3. ✅ Actualiza `FIRESTORE_COLLECTIONS_GUIDE.md` con tus datos específicos
4. ✅ Prueba las consultas en tu aplicación Flutter

## Contacto

Para problemas o sugerencias, consulta la documentación en `FIRESTORE_COLLECTIONS_GUIDE.md`.
