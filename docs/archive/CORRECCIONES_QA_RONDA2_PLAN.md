# Plan: 18 correcciones menores post-QA (todos los perfiles)

## Estado: ✅ Implementado (29 ago 2026)

Los 18 puntos del plan original están implementados y verificados con `flutter analyze` (0 errores en cada bloque A–E y en el proyecto completo — 153 issues, todos warnings/info preexistentes, mismo conteo que antes de empezar). Instalado y corriendo en el dispositivo real (`flutter clean && flutter pub get && flutter run -d 18201ae9ff5f --release`).

Durante el smoke test en el celular apareció **un crash preexistente no relacionado con estos 18 puntos**: `DriverTripHistoryPage` (perfil del chofer → "Historial del conductor") usaba `context.read()` (Provider) para obtener `DriverService`, pero esta app inyecta servicios con `get_it`, no con `Provider<T>` ancestros — nunca hubo un `Provider<DriverService>` en el árbol, así que la página fallaba (`Provider<DriverService> not found`) cada vez que se abría. Corregido a `getIt<DriverService>()` (`lib/features/driver/presentation/pages/driver_trip_history_page.dart:19`). Se revisó el resto del repo por el mismo patrón (`context.read()` sin tipo explícito) — es el único caso.

Ver la sección "Desviaciones del plan original" al final para lo que cambió durante la implementación respecto a lo planeado inicialmente.

## Contexto

Tras compilar e instalar la build con las 11 observaciones + el fix de revoke-admin, se hizo una segunda ronda de QA manual sobre el dispositivo real. El usuario reportó 18 puntos nuevos, explícitamente clasificados como "correcciones menores que no irán a observaciones" (Excel) — es decir, se implementan directo en código, no se documentan como pendiente.

Se investigó el código real (3 agentes Explore en paralelo) y las 10 pantallas de Figma referenciadas antes de planear, porque varios puntos escondían bugs de arquitectura más profundos de lo que el reporte sugería (nav que desaparece solo en Admin, logout sin confirmación en 2 perfiles, un campo de Firestore duplicado y roto para "ruta asignada del chofer", y un modelo de datos de 1-vehículo-por-chofer que no soporta lo que Figma muestra). El objetivo de este plan es resolver los 18 puntos de forma segura, reusando servicios/blocs ya existentes en vez de inventar mecanismos paralelos (regla del CLAUDE.md del repo), y dejar por escrito qué se simplificó a propósito.

**Decisiones ya confirmadas con el usuario:**
- "Gestionar Unidades" → versión simple (reutiliza el modelo actual de 1 unidad por chofer, solo se reubica/renombra correctamente el menú). Multi-unidad real queda fuera de alcance.
- Notificaciones de chofer → solo la página de alertas operativas (filtro por `NotificationType.operational`). Los toasts/badge flotantes de Figma (nodes 3238-8294/8426) requieren un disparador backend nuevo ("solicitud de parada" del pasajero) que no existe hoy — quedan anotados como pendiente de Sprint 4, no se implementan ahora.

## Hallazgos clave que cambian el enfoque

1. **Campo duplicado (viola regla #1 del CLAUDE.md):** el flujo real de asignación de rutas del presidente (`asignar_ruta_chofer_page.dart` → `user_management_datasource.dart:20`) escribe `users/{uid}.assigned_route_ref` (ya protegido en `firestore.rules`, ya leído por `driver_datasource.getAssignedRouteRef` / `DriverService.getAssignedRoute`, ya usado en el Home del chofer). Pero `DriverAssignedRoutesPage` (solo alcanzable hoy desde un ítem huérfano en Perfil, "Ruta asignada") lee/escribe un campo **distinto**: `driver_profile.assigned_route_id`, que el presidente nunca toca. Resultado: para cualquier chofer con ruta asignada por el flujo real, esa pantalla siempre muestra vacío. **No se toca ese código roto en este lote** (no fue pedido) — para el nuevo tab "Rutas" del chofer (punto 6) se usa el campo correcto (`assigned_route_ref`), no el roto.
2. **El bug de "navegación que desaparece" es real y está aislado en Admin.** `AdminHomePage` tiene su propio `BottomNavigationBar` (no el `CustomBottomNav` compartido); su tab "Rutas" empuja `AdminRouteManagementPage`, que no tiene barra de navegación propia → ahí es donde el usuario la pierde. El resto de perfiles (presidente/chofer/tickeador/pasajero) usan `CustomBottomNav` de forma consistente y nunca la pierden.
3. **El botón "atrás" forzado y decorativo de `AdminHomePage`** (`leading: IconButton(...)`, siempre visible aunque no haya nada que retroceder) es la única inconsistencia real encontrada — el resto de la app ya sigue el patrón correcto (`automaticallyImplyLeading` por defecto, o `false` en pantallas raíz).
4. **Logout:** existe un widget compartido `LogoutButton` que nadie usa en producción. Hay 4 copias casi idénticas del diálogo de confirmación (chofer, tickeador, perfil, super-admin switcher). `AdminHomePage` cierra sesión **sin ningún diálogo** (el bug reportado). `PresidentePanelPage` **no tiene ningún control de logout**.
5. **"¿A dónde vamos?"** no existe en el Home real del chofer (`driver_home_page.dart` no la tiene) — aparece porque el tab "Rutas" del chofer hoy es literalmente `RutasInicioPage`, la pantalla del pasajero. El punto 6 (nuevo tab Rutas del chofer) la elimina como efecto colateral.
6. **`stops_meta` (paradas GTFS) nunca se puebla** — el seed existe (`_seedStopsFromGtfs`) pero nadie lo llama. Confirma lo que dijo el usuario: no hay paradas reales. En cambio `routes_meta.polyline_json` (los trazados de las ~280 rutas) sí está poblado y disponible localmente — es la base correcta para "qué trufis pasan cerca de mí".

## Alcance por ítem

### A. Presidente

**A1. ✅ Reordenar panel + buscador/scroll en "Control de rutas en vivo"**
`lib/features/presidente/presentation/pages/presidente_panel_page.dart`: mover el bloque "Gestión de personal" antes de "Control de rutas en vivo" en el `ListView` de `_PresidentePanelView.build`. Convertir `_RouteControlSection` en `StatefulWidget` con un `TextField` que filtra `state.activeRoutes` por nombre/ref (client-side, case-insensitive), envuelto en un `ConstrainedBox(maxHeight: ~320)` + `ListView.builder` propio (en vez del `Column` plano actual) para que la lista scrollee de forma independiente.

**A2. ✅ Home del dirigente: ocultar "Registrar unidad" y arreglar el título "Modo Chofer"**
`lib/features/driver/presentation/pages/driver_home_page.dart` (esta es la pantalla real detrás del "Inicio" del dirigente, vía `roleOverride: 'presidente'`): título pasa de fijo `'Modo Chofer'` a `isSupervisor ? 'Panel del Dirigente' : 'Modo Chofer'`; `_VehicleServiceSection` (que renderiza `_NoVehicleCard`/"Registrar unidad") se oculta por completo cuando `isSupervisor == true`.

### B. Paradas cercanas → "qué trufis pasan cerca de mí"

**B1. ✅ Nueva búsqueda por intersección ruta↔radio (reemplaza la búsqueda por paradas, que está muerta)**

Nota de implementación: se aprovechó que `RouteDataSyncService` ya tenía un `getRoutesNearPoint({latitude, longitude})` (bbox nada más) — se agregó el método preciso como `getRoutesWithinRadius(...)` en ese mismo servicio (no uno nuevo separado), y las tarjetas de resultado quedaron sin `onTap`: la única pantalla de "detalle" existente (`StopDetailPage`) usa `RouteStopInfo` con campos fijos como `'A 1.2 km'`/`'Tráfico moderado'` — justo el patrón que prohíbe la regla #2 del CLAUDE.md — así que no se enlazó ahí.

- `lib/core/utils/distance_utils.dart`: nueva función `distanceToPolylineMeters(LatLng point, List<LatLng> polyline)` — distancia mínima punto-a-segmento (proyección + clamp), consistente con la aproximación ya usada en el archivo.
- `lib/core/local_db/route_local_database.dart`: nuevo método `getRoutesNearPoint(lat, lng, radiusMeters)` — usa las columnas `lat_min/lat_max/lng_min/lng_max` ya existentes en `routes_meta` como pre-filtro de bbox (expandido por `radiusMeters`), decodifica `polyline_json` de los sobrevivientes y filtra por la distancia real ≤ radiusMeters.
- `lib/features/routes/domain/services/route_service.dart`: wrapper `getRoutesNearPoint(...)`.
- Nuevo `lib/features/stops/presentation/bloc/nearby_routes_bloc.dart` (+ event/state), mismo patrón que `NearbyStopsBloc` pero devolviendo `List<RouteEntity>`.
- `lib/features/stops/presentation/pages/paradas_cercanas_page.dart`: cambia de `NearbyStopsBloc`/`BusStopService` a `NearbyRoutesBloc`/`RouteService`; las tarjetas muestran línea/ref + nombre + distancia en vez de nombre de parada. Se mantiene el entry point/label "Paradas cercanas" tal cual (sin renombrar el menú), solo cambia el copy interno.
- El código viejo (`BusStopService`, `NearbyStopsBloc`, `BusStopEntity`, tabla `stops_meta`) se deja intacto sin usar — no se borra en este lote (no fue pedido, cero riesgo de dejarlo).

**B2. ✅ Botón más intuitivo para elegir ubicación en el mapa**
Mismo archivo: se quita el pequeño ícono de mapa en el `AppBar` y se agrega un botón ancho y explícito ("📍 Elegir ubicación en el mapa") justo debajo de los chips de radio, siempre visible, que abre el mismo `MapLocationPickerPage` ya usado.

### C. Perfil — "Acerca de Mi Ruta" + versión + beneficios

**C1. ✅ Página "Acerca de Mi Ruta" real**
Nueva `lib/features/user/presentation/pages/acerca_de_page.dart`: breve guía de uso por perfil (Usuario, Chofer, Tickeador, Presidente, Administrador), botón que abre `LegalBottomSheet.show(context, isDriver: ...)` (widget ya existente, hoy solo usado en registro) para ver los Términos/EULA, y la versión de la app leída dinámicamente.
`perfil_page.dart`: el ítem "Acerca de MiRuta" (hoy `onTap: () {}`) pasa a navegar a esta página.

**C2. ✅ Versión dinámica (respuesta a tu pregunta)**

Nota: se agregó `package_info_plus: ^10.2.1` (no `^8.1.2` como se pensó al planear — esa versión choca con `share_plus` ya instalado; `flutter pub get` lo señaló y se subió a la mínima compatible).

No, no pasa nada si cambian el número en `pubspec.yaml` (`version: 1.0.0+1`) — hoy ese número no se lee en ningún lado del código, solo hay un string `'Versión 1.0.0'` copiado a mano en `perfil_page.dart`. Se agrega la dependencia `package_info_plus` y se reemplaza ese string fijo por `PackageInfo.fromPlatform().version` (+ build number), tanto en Perfil como en la nueva página "Acerca de" — así queda sincronizado automáticamente con `pubspec.yaml` para siempre, sin mantenimiento manual. Para saber "en qué versión estamos" el equipo mira directamente `pubspec.yaml` o la propia app.

**C3. ✅ "Acceder a beneficios" — visibilidad y comportamiento**
`perfil_page.dart`: el ítem se envuelve en `if (_isPassenger(user.userType))` (helper que ya existe en el archivo). Su `onTap` deja de llamar `navigateBottomNav(context, 1)` (que hoy abre la Billetera) y pasa a `Navigator.push(... SolicitudBeneficioPage())` directo (misma clase que ya usa `wallet_page.dart`).

### D. Chofer

**D1. ✅ Tab "Rutas" del chofer → página propia (ya no es la del pasajero)**
- `lib/features/user/presentation/widgets/bottom_nav_router.dart`: se agrega un parámetro opcional `routesBuilder: WidgetBuilder?` a `navigateBottomNav` (mismo patrón que el ya existente `homeBuilder`) — si se pasa, reemplaza el destino del índice 2; todos los demás llamadores (pasajero, presidente, tickeador) no lo pasan y siguen yendo a `RutasInicioPage` sin cambios.
- Nueva `lib/features/driver/presentation/pages/driver_rutas_page.dart`: reutiliza `DriverService.getAssignedRoute(vehicle)` (el campo correcto, `assigned_route_ref`) + el widget ya existente `DriverServiceMap` para dibujar la ruta asignada en un mapa grande. Debajo, una tarjeta con nombre/línea de la ruta y un switch "Ruta habilitada" atado a `vehicle.isOnDuty`, disparando los mismos eventos `StartService`/`StopService` de `DriverServiceBloc` que ya usa el botón de Inicio — un solo estado real, sin campos nuevos. Provee su propio `DriverServiceBloc` (mismo patrón que `DriverHomePage`), ya que se llega aquí reemplazando el stack (`pushAndRemoveUntil`).
- `driver_home_page.dart`: su `CustomBottomNav.onTap` pasa `routesBuilder: (_) => const DriverRutasPage()`.

**D2. ✅ Billetera del chofer → propia (no la copia del pasajero)**
Nueva `lib/features/driver/presentation/pages/driver_wallet_page.dart`, con el mismo patrón de `routesBuilder` extendido a `walletBuilder` en `navigateBottomNav` (índice 1) para no tocar al resto de perfiles:
- Card "INGRESOS" con el total vía `DriverIncomeService.getTotalIncome` (reusa `DriverIncomeBloc`/`LoadDriverIncome`, ya existente).
- **MOVIMIENTOS** → navega a `HistorialIngresosPage` (ya existe, encaja exacto).
- **RENDIMIENTO** → nueva pantalla pequeña que reusa `DriverService.getAssignedVehicle` + `getTripHistory` + `buildPerformanceSummary` (funciones puras ya existentes) para mostrar viajes/pagados/promedio.
- **MOSTRAR QR / ACTUALIZAR QR** → se extrae el flujo de cobro ya implementado y probado en Home (`_ChargeSection`: `GenerateTripCharge`/`ClearTripCharge` de `DriverOperationsBloc`) a un widget reutilizable, y se monta aquí también. **Aclaración importante:** esto reutiliza el QR de cobro por transacción que ya funciona — no es un QR fijo/personal permanente distinto (eso sí sería una función nueva de pagos, fuera de alcance de una corrección menor). Se documenta la simplificación.
- `driver_home_page.dart`: pasa `walletBuilder: (_) => const DriverWalletPage()`.
- Nota: `_ChargeSection` de `driver_home_page.dart` se extrajo a `lib/features/driver/presentation/widgets/charge_section.dart` (clase pública `ChargeSection`) para reusarla en ambos lugares, tal como decía el plan.

**D3. ✅ Ocultar buscador "¿A dónde vamos?" en chofer**
Confirmado: no existe en el Home real del chofer. Queda resuelto como efecto colateral de D1 (el tab Rutas del chofer ya no es `RutasInicioPage`, que es donde vive esa barra).

**D4. ✅ Notificaciones del chofer → solo alertas operativas**
`lib/features/user/presentation/pages/notificaciones_page.dart`: lee el rol actual (mismo patrón que otras páginas vía `AuthBloc`); cuando el rol es `driver` (o `presidente` en vista de chofer), filtra el feed a `NotificationType.operational` únicamente y oculta los toggles de Viajes/Recargas/Regalos, mostrando un encabezado simple "Alertas operativas". No requiere campos nuevos — reusa el tipo `operational` ya usado por `DriverService.notifyStop`.

**D5. ✅ Perfil del chofer: ocultar "Planificar viaje", agregar "Gestionar Unidades" (versión simple)**
`perfil_page.dart`: el ítem "Planificar viaje" (hoy incondicional) se envuelve en `if (user.userType != 'driver')`. Nuevo ítem "Gestionar Unidades" (visible solo si `userType == 'driver'`) que navega a una página que muestra la unidad actual del chofer con edición de marca/modelo/color y el switch de servicio — reutiliza `DriverService.updateVehicleInfo` y `startService`/`stopService`, ya implementados (es esencialmente lo que hoy vive suelto dentro de Home, bajo el nombre correcto y como su propia pantalla).

### E. Consistencia global (nav, atrás, logout)

**E1. ✅ `CustomBottomNav` soporta subconjuntos de tabs**
`lib/features/user/presentation/widgets/custom_bottom_nav.dart`: nuevo parámetro opcional `tabs: List<int>` (default `[0,1,2,3]`, los índices semánticos Inicio/Billetera/Rutas/Perfil de siempre). Construye los `items` visibles a partir de esa lista y traduce el `onTap` de vuelta al índice semántico real — así **ningún** call site existente (pasajero, presidente, chofer) cambia su comportamiento; solo Tickeador y Admin pasarán un subconjunto.

**E2. ✅ Admin: la navegación nunca debe desaparecer + quitar el botón "atrás" decorativo**
`admin_home_page.dart`: se quita el `leading: IconButton` forzado (se deja `automaticallyImplyLeading` por defecto, igual que el resto de la app — el arco solo aparece cuando de verdad hay algo que retroceder). Ambas pantallas (`AdminHomePage` y `AdminRouteManagementPage`) usan `CustomBottomNav(tabs: const [0,2,3], ...)` de E1 con su propia lógica de `onTap` (permisos + navegación) definida en cada archivo — no se extrajo un widget `_AdminBottomNav` compartido como se bocetó al planear, porque cada pantalla necesita un comportamiento algo distinto en "Inicio" (Home no hace nada al tocarlo, Gestión de rutas hace `Navigator.pop`) y forzar una sola función para ambas casos habría sido más frágil que reusar el widget visual (`CustomBottomNav`) y repetir ~15 líneas de wiring. Ningún cambio de permisos ni de rutas de navegación, solo que la barra ahora persiste.

**E3. ✅ Tickeador: sin Rutas ni Billetera**
`tickeador_home_page.dart`: su `CustomBottomNav` pasa a `tabs: const [0, 3]` (Inicio/Perfil), igual que el mockup de Figma (node 3896-5285). Elimina de paso la posibilidad de llegar por error a la Billetera/Rutas del pasajero desde Tickeador.

Bug adicional encontrado y corregido de paso (mismo archivo/línea): el tab "Inicio" del Tickeador nunca pasaba `homeBuilder`, así que tocar "Inicio" llevaba a `MiRutaScreen` (pantalla del pasajero) en vez de volver a `TickeadorHomePage` — se agregó `homeBuilder: (_) => const TickeadorHomePage()`.

**E4. ✅ Logout: una sola confirmación, en todos lados**
Nuevo helper compartido (junto al `LogoutButton` ya existente en `lib/features/user/presentation/widgets/logout_button.dart`): `Future<void> confirmLogout(BuildContext context)` con el mismo diálogo ya usado 4 veces. Se reemplazan las 4 copias (`driver_home_page.dart`, `tickeador_home_page.dart`, `perfil_page.dart`, `super_admin_switcher_page.dart`) por una llamada a este helper. Se agrega a `admin_home_page.dart` (hoy cierra sesión sin preguntar — el bug reportado) y a `presidente_panel_page.dart` (hoy no tiene ningún control de logout — se agrega un `IconButton` en el `AppBar`).

**E5. ✅ Botón "atrás" — ya cubierto por E2**
La única inconsistencia real que se encontró era el arco forzado de `AdminHomePage`; el resto del código ya sigue el patrón correcto (pantallas raíz sin arco, pantallas empujadas con arco por defecto). No se requiere trabajo adicional fuera de E2.

## Verificación

- `flutter analyze` después de cada bloque (A/B/C/D/E) — 0 errores en cada uno.
- `flutter analyze` del proyecto completo al terminar — **0 errores**, 153 issues (todos warnings/info preexistentes, mismo conteo que antes de tocar nada).
- `flutter clean && flutter pub get && flutter run -d 18201ae9ff5f --release` — instalado y corriendo en el Mi A3 real. Durante el smoke test apareció el crash de `DriverTripHistoryPage` descrito arriba (no es uno de los 18 puntos) — corregido y reinstalado.
- Pendiente de esta sesión: pasada de humo manual completa punto por punto (entrar como presidente, chofer, tickeador, admin, pasajero) — la app está corriendo en el celular, lista para que el usuario la revise.

## Archivos nuevos creados

- `lib/features/stops/presentation/bloc/nearby_routes_{bloc,event,state}.dart`
- `lib/features/user/presentation/pages/acerca_de_page.dart`
- `lib/features/driver/presentation/pages/driver_rutas_page.dart`
- `lib/features/driver/presentation/pages/driver_wallet_page.dart`
- `lib/features/driver/presentation/pages/rendimiento_page.dart`
- `lib/features/driver/presentation/pages/gestionar_unidades_page.dart`
- `lib/features/driver/presentation/widgets/charge_section.dart`

## Desviaciones del plan original (descubiertas/decididas durante la implementación)

1. **B1**: se reusó `RouteDataSyncService.getRoutesNearPoint` existente (se le agregó `getRoutesWithinRadius`) en vez de crear un servicio nuevo separado — mismo resultado, menos código nuevo.
2. **B1**: las tarjetas de "Paradas cercanas" quedaron sin `onTap` a un detalle — la única pantalla de detalle existente usa datos inventados (regla #2 del CLAUDE.md), así que no se enlazó ahí en vez de fingir datos.
3. **C2**: `package_info_plus` quedó en `^10.2.1`, no `^8.1.2` (conflicto de versión con `share_plus` ya instalado).
4. **D2**: se extrajo `ChargeSection` a un widget compartido (tal como decía el plan) — confirmado, sin cambios de fondo.
5. **E2**: no se extrajo un widget `_AdminBottomNav` único — cada pantalla admin tiene su propio `onTap` (comportamiento distinto en "Inicio" según desde dónde se mire), reusando el widget visual `CustomBottomNav` en vez de una función 100% compartida.
6. **E3**: se encontró y corrigió un bug adicional no listado originalmente — el tab "Inicio" del Tickeador llevaba a la pantalla del pasajero por un `homeBuilder` faltante.
7. **Fuera del plan, encontrado en vivo**: `DriverTripHistoryPage` crasheaba siempre (bug preexistente, `Provider<DriverService>` inexistente) — corregido.

## Simplificaciones a propósito (documentar para la próxima revisión de equipo)

- **QR de chofer** (MOSTRAR QR/ACTUALIZAR QR en la nueva Billetera): reusa el flujo de cobro por transacción que ya funciona (`GenerateTripCharge`/`ClearTripCharge`) — no es un QR fijo/personal permanente. Eso sería una función de pagos nueva, fuera de alcance.
- **Gestionar Unidades**: muestra y edita la única unidad del chofer (modelo actual de datos). Soporte real de varias unidades por chofer fue explícitamente descartado por el usuario para este lote — sería su propio ticket.
- **Notificaciones de chofer**: solo la página de alertas operativas. Los toasts/badge flotantes de Figma (nodes 3238-8294/8426) quedan pendientes para Sprint 4 — necesitan un disparador backend ("solicitud de parada" del pasajero) que no existe hoy.
- **Campo `driver_profile.assigned_route_id` roto** (hallazgo #1 de este documento): no se tocó, sigue ahí, sin usarlo desde el nuevo tab "Rutas" del chofer. Si en algún momento se retoma `DriverAssignedRoutesPage`/el ítem "Ruta asignada" de Perfil, hay que migrarlo a `assigned_route_ref` primero.
