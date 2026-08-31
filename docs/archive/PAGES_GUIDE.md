# Guía de Páginas - Mi Ruta

Documentación completa de todas las páginas (screens) del proyecto Mi Ruta, incluyendo su propósito, funcionalidad y lo que se muestra en pantalla.

---

## 📋 Índice

1. [Páginas de Autenticación](#autenticación)
2. [Páginas de Usuario](#usuario)
3. [Páginas de Conductor](#conductor)
4. [Páginas de Administrador](#administrador)

---

## 🔐 Autenticación

### 1. **IniciarSesionPage** (`iniciar_sesion_page.dart`)
- **Propósito**: Pantalla inicial de login y opciones de autenticación
- **Ubicación**: `lib/features/auth/presentation/pages/`
- **¿Qué muestra?**:
  - Logo y nombre de la aplicación "MiRuta"
  - Eslogan: "Tu ruta, tu viaje, tu pago"
  - Botones para iniciar sesión
  - Opciones para registrarse
  - Botones amarillos personalizados
- **Funcionalidad**:
  - Punto de entrada a la aplicación
  - Acceso para usuarios nuevos y existentes
  - Manejo de autenticación mediante AuthBloc

---

### 2. **InsertarCorreoPage** (`insertar_correo_page.dart`)
- **Propósito**: Formulario para ingresar correo electrónico durante el login
- **Ubicación**: `lib/features/auth/presentation/pages/`
- **¿Qué muestra?**:
  - Campo de entrada para correo electrónico
  - Validación en tiempo real
  - Botón de continuar

---

### 3. **RegisterPage** (`register_page.dart`)
- **Propósito**: Formulario completo de registro de nuevo usuario
- **Ubicación**: `lib/features/auth/presentation/pages/`
- **¿Qué muestra?**:
  - Campos para datos personales (nombre, email, contraseña, etc.)
  - Validaciones de campos
  - Opción para aceptar términos y condiciones

---

### 4. **RecuperarAccesoPage** (`recuperar_acceso_page.dart`)
- **Propósito**: Recuperación de acceso mediante correo electrónico
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Campo para ingresar correo electrónico
  - Enlace para recuperar contraseña
  - Mensajes de estado de recuperación
- **Funcionalidad**:
  - Envía correo de recuperación
  - Maneja estados de carga y error

---

### 5. **RegistrationSuccessPage** (`registration_success_page.dart`)
- **Propósito**: Pantalla de confirmación tras registrarse exitosamente
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Mensaje de éxito de registro
  - Botón para proceder a la aplicación principal

---

## 👤 Usuario

### 6. **MiRutaScreen** (`mi_ruta_screen.dart`)
- **Propósito**: Pantalla principal de inicio de la aplicación
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Mapa interactivo de Google Maps centrado en la ubicación del usuario
  - Barra de búsqueda en la parte superior
  - Botones flotantes de acciones (Mi ubicación, modo pin, limpiar búsqueda)
  - Barra de navegación inferior con 4 tabs
  - Panel de información de rutas cuando se selecciona una
  - Marcadores de origen, destino y paradas
- **Funcionalidad**:
  - Ubicación en tiempo real del usuario
  - Búsqueda de lugares
  - Modo de selección de punto (pin mode)
  - Navegación entre diferentes secciones de la app mediante bottom nav
  - Integración con MiRutaBloc para gestionar estado

---

### 7. **RutasInicioPage** (`rutas_inicio_page.dart`)
- **Propósito**: Pantalla para iniciar la búsqueda y planificación de rutas
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Mapa con marcadores de origen y destino
  - Barra de búsqueda en la parte superior
  - Modo de pin para seleccionar ubicaciones (origen/destino)
  - Panel de confirmación de ubicación seleccionada
  - Hoja deslizable inferior con opciones de rutas
  - Barra de navegación inferior
- **Funcionalidad**:
  - Permite seleccionar origen y destino
  - Calcula rutas disponibles automáticamente
  - Muestra loading mientras prepara rutas
  - Integración con servicios GTFS y datos de rutas

---

### 8. **RutasSeleccionPage** (`rutas_seleccion_page.dart`)
- **Propósito**: Muestra lista de rutas disponibles para un destino
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Mapa con la ubicación de destino
  - AppBar con nombre del destino
  - Lista de rutas disponibles
  - Información de cada ruta (número, tiempo, precio)
  - Barra de navegación inferior
- **Funcionalidad**:
  - Selección de ruta específica
  - Navegación a detalles de ruta (RutaLineaPage)
  - Muestra datos del destino seleccionado

---

### 9. **RutaLineaPage** (`ruta_linea_page.dart`)
- **Propósito**: Muestra detalles específicos de una línea/ruta seleccionada
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Mapa con la ruta trazada en la línea
  - Información detallada de la línea (número, trayectoria)
  - Paradas de la línea
  - Información del destino
  - Opciones para ver tiempo estimado o información de abordaje
- **Funcionalidad**:
  - Visualización de trayecto completo
  - Integración con TripLineBloc para estados
  - Cálculo de distancias
  - Navegación a otras pantallas relacionadas

---

### 10. **RutaTiempoPage** (`ruta_tiempo_page.dart`)
- **Propósito**: Muestra tiempo estimado de llegada y detalles de la ruta
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Mapa de la ruta
  - Tiempo estimado de viaje
  - Información de parada de abordaje
  - Destino seleccionado
  - Botón para confirmar y proceder
- **Funcionalidad**:
  - Cálculo y muestra de tiempos
  - Información de paradas de abordaje
  - Transición a página de abordaje

---

### 11. **RutaAbordajePage** (`ruta_abordaje_page.dart`)
- **Propósito**: Información de dónde abordar el transporte
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Mapa con la ubicación de parada de abordaje
  - Información de la parada (dirección, referencias)
  - Información de la línea a tomar
  - Destino final
  - Instrucciones de abordaje
- **Funcionalidad**:
  - Muestra ubicación exacta de parada
  - Información para el usuario sobre dónde esperar

---

### 12. **RutaNavegacionPage** (`ruta_navegacion_page.dart`)
- **Propósito**: Navegación paso a paso durante el viaje
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Mapa en tiempo real durante el viaje
  - Posición actual en la ruta
  - Siguiente parada de descenso (alighting)
  - Información de navegación en tiempo real
  - Panel inferior con resumen de ruta
  - Botones para comunicarse con conductor
- **Funcionalidad**:
  - Navegación GPS en tiempo real
  - Alertas cuando se aproxima la parada de descenso
  - Integración con servicios de ubicación
  - Preparación para pago del viaje

---

### 13. **RutasSugerenciasPage** (`rutas_sugerencias_page.dart`)
- **Propósito**: Muestra sugerencias de rutas frecuentes y lugares guardados
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Mapa en la parte superior
  - Tarjetas con sugerencias de destinos:
    - Destinos recientes (ej: Plaza 14 de septiembre)
    - Lugares guardados
    - Puntos frecuentes
- **Funcionalidad**:
  - Acceso rápido a rutas frecuentes
  - Mejora la experiencia del usuario
  - Navegación directa a RutasSeleccionPage al seleccionar

---

### 14. **MapSearchPage** (`map_search_page.dart`)
- **Propósito**: Búsqueda y autocomplete de lugares en el mapa
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Barra de búsqueda con autocomplete
  - Lista de resultados mientras escribe
  - Predicciones de Google Places
  - Manejo de errores en búsqueda
- **Funcionalidad**:
  - Búsqueda con debounce (espera mientras escribe)
  - Integración con PlacesDatasource
  - Retorna ubicación seleccionada
  - Manejo de estados de carga y error

---

### 15. **WalletPage** (`wallet_page.dart`)
- **Propósito**: Gestor de saldo/billetera del usuario
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Saldo actual del usuario (tarjeta destacada)
  - Botones de acciones:
    - Recargar saldo
    - Ver movimientos
    - Pagar con QR
    - Solicitar beneficio
  - Barra de navegación inferior
  - Información del usuario
- **Funcionalidad**:
  - Muestra saldo en tiempo real
  - Acceso a recarga de saldo
  - Acceso a historial de transacciones
  - Pago mediante QR (código QR del conductor)
  - Solicitud de beneficios

---

### 16. **RecargaSaldoPage** (`recarga_saldo_page.dart`)
- **Propósito**: Opciones de recarga de saldo
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Opciones de recarga disponibles
  - Métodos de pago
  - Enlace a RecargaQRPage para recarga por transferencia
  - Información de saldo actual
- **Funcionalidad**:
  - Acceso a diferentes métodos de recarga
  - Gestión del saldo mediante WalletBloc

---

### 17. **RecargaQRPage** (`recarga_qr_page.dart`)
- **Propósito**: Recarga de saldo mediante transferencia bancaria con QR
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Código QR personalizado para transferencia
  - Pasos para realizar la recarga:
    1. Escanear QR con app bancaria
    2. Transferir monto
    3. Ingresar monto y subir comprobante
    4. Confirmación
  - Campo para ingresar monto
  - Opción para subir imagen del comprobante
  - Estado de procesamiento
- **Funcionalidad**:
  - Generación de QR único por usuario
  - Carga de imagen del comprobante de transferencia
  - Procesamiento automático de recarga
  - Integración con RechargeBloc

---

### 18. **ConfirmacionRecargaPage** (`confirmacion_recarga_page.dart`)
- **Propósito**: Confirmación de recarga exitosa
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Ícono de éxito (checkmark verde)
  - Mensaje de confirmación
  - Monto recargado
  - Botón para volver a wallet o continuar
- **Funcionalidad**:
  - Confirmación visual de transacción completada
  - Navegación de regreso a wallet

---

### 19. **MovimientosPage** (`movimientos_page.dart`)
- **Propósito**: Historial de transacciones y movimientos del saldo
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Filtro por período de tiempo
  - Lista de transacciones (cronológicamente ordenadas)
  - Cada transacción muestra:
    - Tipo (viaje, recarga, etc.)
    - Monto
    - Fecha y hora
    - Descripción/detalles
  - Barra de navegación inferior
- **Funcionalidad**:
  - Visualización de historial de movimientos
  - Filtrado por fechas
  - Integración con WalletBloc para obtener datos

---

### 20. **PagoQRPage** (`pago_qr_page.dart`)
- **Propósito**: Pago de viaje mediante lectura de QR del conductor
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Área para escanear código QR
  - Instrucción: "Escanee el código QR del chofer"
  - Botón/área para activar scanner
  - Estado de procesamiento del pago
  - Confirmación después del pago
- **Funcionalidad**:
  - Escaneo del QR del conductor
  - Procesamiento del pago automático
  - Deducción del saldo
  - Confirmación de pago exitoso
  - Integración con TripPaymentBloc

---

### 21. **QRScannerPage** (`qr_scanner_page.dart`)
- **Propósito**: Página de escaneo de código QR
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Cámara en tiempo real
  - Área de escaneo indicada
  - Instrucciones para usuario
- **Funcionalidad**:
  - Integración con librería de escaneo QR
  - Captura y decodificación de QR
  - Retorna datos del QR escaneado

---

### 22. **SolicitudBeneficioPage** (`solicitud_beneficio_page.dart`)
- **Propósito**: Formulario para solicitar beneficios/descuentos especiales
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Selector de tipo de beneficio (dropdown)
  - Campo de descripción
  - Área para adjuntar documentos
  - Botón para seleccionar documentos de galería
  - Lista de documentos adjuntos
  - Botón de envío
  - Barra de navegación inferior
- **Funcionalidad**:
  - Selección de tipo de beneficio
  - Carga de múltiples documentos (fotos)
  - Validación de información
  - Envío de solicitud
  - Integración con ImagePicker

---

### 23. **ConfirmacionBeneficioPage** (`confirmacion_beneficio_page.dart`)
- **Propósito**: Confirmación de solicitud de beneficio enviada
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Ícono de éxito
  - Mensaje de confirmación
  - Referencia de solicitud
  - Información sobre próximos pasos
- **Funcionalidad**:
  - Confirmación visual de envío
  - Información sobre revisión de solicitud

---

### 24. **SubirFotografiePage** (`subir_fotografia_page.dart`)
- **Propósito**: Carga de foto de perfil del usuario
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Área para mostrar foto seleccionada
  - Botón para seleccionar foto de galería o cámara
  - Opción de recortar/editar foto
  - Botón de guardar
- **Funcionalidad**:
  - Captura o selección de foto
  - Previsualización de foto
  - Carga y guardado en perfil

---

### 25. **TestWidgetsScreen** (`test_widgets_screen.dart`)
- **Propósito**: Pantalla de perfil/menú del usuario (también actúa como "settings/profile")
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Encabezado de perfil (foto, nombre, email)
  - Menú de opciones:
    - Rutas frecuentes
    - Historial de viajes
    - Notificaciones
    - Planificar ruta
    - Otros elementos del menú
  - Switches para:
    - Modo oscuro
    - Modo conductor
  - Botón de cerrar sesión
  - Barra de navegación inferior
- **Funcionalidad**:
  - Visualización de datos del perfil
  - Acceso a configuración
  - Cambio de tema
  - Modo conductor (posible para usuarios conductores)
  - Logout de la aplicación

---

### 26. **MapsPage** (`maps_page.dart`)
- **Propósito**: Página de demostración/alternativa de mapa
- **Ubicación**: `lib/features/user/presentation/pages/`
- **¿Qué muestra?**:
  - Mapa de Google Maps
  - Marcadores de ubicaciones (ej: Cochabamba)
  - InfoWindow al seleccionar marcador
  - Barra de navegación inferior
- **Funcionalidad**:
  - Muestra ubicaciones de ejemplo
  - Integración básica de Google Maps

---

## 🚗 Conductor

> **Estado**: Las páginas del módulo conductor están en desarrollo (carpeta vacía)

Las páginas del conductor se encontrarán en:
- `lib/features/driver/presentation/pages/`

Serán similares a las del usuario pero adaptadas para conductores:
- Dashboard de conductor
- Solicitud de viajes
- Rutas asignadas
- Generación de QR para pagos
- Historial de viajes como conductor
- Ganancias y estadísticas

---

## 👨‍💼 Administrador

> **Estado**: Las páginas del administrador están en desarrollo (carpeta vacía)

Las páginas del administrador se encontrarán en:
- `lib/features/admin/presentation/pages/`

Incluirán:
- Dashboard administrativo
- Gestión de rutas (GTFS)
- Gestión de usuarios
- Gestión de conductores
- Reportes y estadísticas
- Monitoreo de transacciones

---

## 🗺️ Flujo de Navegación Principal

```
IniciarSesionPage
    ↓
[InsertarCorreoPage OR RegisterPage]
    ↓
MiRutaScreen (Pantalla Principal)
    ├── Bottom Nav Tab 0: MiRutaScreen
    ├── Bottom Nav Tab 1: WalletPage
    │   ├── RecargaSaldoPage
    │   │   └── RecargaQRPage
    │   │       └── ConfirmacionRecargaPage
    │   ├── MovimientosPage
    │   ├── PagoQRPage
    │   │   └── QRScannerPage
    │   └── SolicitudBeneficioPage
    │       └── ConfirmacionBeneficioPage
    ├── Bottom Nav Tab 2: RutasInicioPage
    │   ├── RutasSeleccionPage
    │   │   └── RutaLineaPage
    │   │       ├── RutaTiempoPage
    │   │       └── RutaAbordajePage
    │   │           └── RutaNavegacionPage
    │   └── RutasSugerenciasPage
    └── Bottom Nav Tab 3: TestWidgetsScreen
        └── SubirFotografiePage
```

---

## 📱 Componentes Visuales Comunes

- **CustomBottomNav**: Barra de navegación inferior con 4 tabs en la mayoría de páginas
- **AppBar**: Barras de encabezado personalizadas con color blanco
- **Google Maps**: Integrada en múltiples pantallas para visualización de rutas
- **Botones Amarillos**: Estilo visual consistente de botones primarios (Color 0xFFFBC02D)
- **Tarjetas de Información**: Componentes reutilizables para mostrar información

---

## 🔄 Blocs Utilizados

| Bloc | Páginas | Propósito |
|------|---------|----------|
| **AuthBloc** | Todas las de auth y user | Gestión de autenticación |
| **MiRutaBloc** | MiRutaScreen | Gestión de mapa y ubicación |
| **RouteSearchBloc** | RutasInicioPage | Búsqueda de rutas |
| **TripLineBloc** | RutaLineaPage | Detalles de línea |
| **WalletBloc** | WalletPage, movimientos, recarga | Gestión de saldo |
| **RechargeBloc** | RecargaQRPage | Recarga de saldo |
| **TripPaymentBloc** | PagoQRPage | Pagos de viajes |

---

## 📝 Notas Importantes

- La mayoría de páginas usan **BLoC pattern** para gestión de estado
- Las páginas utilizan **Firebase** para autenticación y datos
- La aplicación es **responsive** y se adapta a diferentes tamaños de pantalla
- La barra de navegación inferior es persistente en la mayoría de páginas
- Se utiliza **Google Maps** y servicios de geolocalización
- Los datos de rutas provienen de **GTFS (General Transit Feed Specification)**

