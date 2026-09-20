# Plan de cierre — Sprint 3 (sesión del 28 ago, parte 2)

> **Archivado el 2026-08-31.** Documento histórico — no es fuente vigente de ningún concepto (ver tabla concepto→fuente en `README.md`).
>
> **Corrección post-mortem (verificada por dos revisiones independientes, Soberbia e Ira, el 2026-08-31):** la sección "Ruta en vez de unidad" más abajo afirma que `DriverAssignedRoutesPage` "ya existía completa y funcional" al conectarla desde `perfil_page.dart`. **Eso era falso incluso en el momento de escribirlo.** Esa pantalla lee `driver_profile.assigned_route_id`, un campo que el flujo real de asignación del presidente (`asignar_ruta_chofer_page.dart` → `assigned_route_ref`) nunca escribe — la pantalla sale vacía para cualquier chofer real. Detalle completo en `docs/DEUDA_TECNICA.md`.

**Fuentes:** verificación directa contra Figma (fileKey `VEgf3Hb8pe4CVkT07DG7Xi`, nodos Chofer `3238:7814/8018/8060`), `docs/COMPARACION_FIGMA_CODIGO_DOCS.md`, código real, y `flutter analyze` (0 errores tras los cambios de esta sesión).

---

## 1. Resuelto en esta sesión

### Bugs reportados
| # | Síntoma | Causa real | Fix |
|---|---|---|---|
| 0 | Perfil falla con `type 'AuthSuccess' is not a subtype of type 'AuthLoaded'` tras registrarse; se arregla solo cerrando/reabriendo la app | `AuthBloc._onRegisterEvent` nunca emitía `AuthLoaded`, solo `AuthSuccess` (sin el usuario). `perfil_page.dart:403` hacía un cast rígido `as AuthLoaded` | `auth_bloc.dart` ahora emite `AuthLoaded(user)` además de `AuthSuccess` al registrar; el cast rígido en `perfil_page.dart` se volvió seguro |
| 2 | Panel de Presidente: `type 'String' is not a subtype of type 'Timestamp?'` | Distintas rutas de escritura del proyecto guardan fechas como `Timestamp` nativo (`FieldValue.serverTimestamp()`) o como string ISO8601, y varios datasources asumían un solo formato con cast rígido (`as Timestamp?`) | Nuevo helper `lib/core/utils/firestore_date.dart` (`parseFirestoreDate`) que tolera ambos formatos, aplicado en `route_datasource.dart`, `driver_datasource.dart`, `wallet_datasource.dart`, `recharge_datasource.dart`, `benefit_request_datasource.dart`, `station_log_entity.dart` |

### Pedido: chofer se registra con unidad y documentos (no el dirigente)
Verificado contra Figma (`3.1 Tipo de vehiculo`, `3.1 Formulario`, `3.2 Verificar Documentos`) antes de construir, para no inventar campos:

- **Nueva pantalla `SolicitudChoferPage`** (`lib/features/driver/presentation/pages/solicitud_chofer_page.dart`): tipo de unidad (Bus/Micro/Taxitrufi/Otro), formulario (placa, línea, número de unidad, marca, color, capacidad — exactamente los campos de Figma), y los 5 documentos exactos de Figma (Licencia de conducir, Inspección técnica vehicular, SOAT, RUAT, Tarjeta de operación municipal), subidos a Storage y guardados en las claves **ya existentes** de `VehicleEntity.legalDocumentation` (`driver_license_url`, `vehicle_inspection_url`, `soat_url`, `ruat_url`, `municipal_operation_card_url` — no se inventó ninguna clave nueva).
- `perfil_page.dart` → "Registrarme como chofer" ahora abre esta pantalla en vez del diálogo de confirmación anterior. La unidad queda `pending_review` y `driver_request.status = 'pending'`, vinculadas por `owner_uid`.
- **`DriverApprovalPage`** ahora tiene "Ver unidad y documentos" por cada solicitud pendiente — abre una hoja con los datos de la unidad y cada documento (toca para verlo en grande) antes de aprobar/rechazar.
- **Chofer ya aprobado sin unidad** (`_NoVehicleCard` en `driver_home_page.dart`): botón "Registrar unidad" que reabre la misma pantalla en modo `isAdditionalUnit` (registra la unidad sin volver a mandar la solicitud de chofer, que ya está aprobada).

### Pedido: "al chofer se le asigna una ruta, no una unidad"
`DriverAssignedRoutesPage` (RQ-63) ya existía completa y funcional — mostraba todas las rutas GTFS reales para que el chofer eligiera la suya — pero **no se navegaba a ella desde ningún lado** (código huérfano). Se conectó: nuevo ítem "Ruta asignada" en `perfil_page.dart`, visible solo para `userType == 'driver'`.

### Confirmado ya funcional (no hacía falta reconstruirlo)
- **"Asignar tickeador"** (`AsignarTickeadorPage`, ya wireado a `PresidentePanelPage` desde la sesión anterior): candidatos reales, líneas GTFS reales, escribe `role: 'tickeador'` + `tickeador_info`. Solo faltaba probarlo.
- Se quitó **"Gestión de usuarios (todos los roles)"** de `driver_home_page.dart` — era de pruebas, ya no se muestra al dirigente.

**Verificación:** `flutter analyze` → 0 errores en todos los archivos tocados (156 issues restantes son *info*/*warning* de estilo preexistentes, no relacionados).

---

## 2. Gaps de Figma que siguen sin construir (de `COMPARACION_FIGMA_CODIGO_DOCS.md` §7)

| Gap | Estado del dominio | Esfuerzo estimado |
|---|---|---|
| Sistema de calificación (Usuario→Chofer y Chofer→Usuario) | Cero código en ningún lado | Alto — pantalla + colección `ratings` (ya documentada en Firestore, sin código) |
| Estadísticas del pasajero ("Mis gastos", "Rutas frecuentes") | Cero código | Medio |
| Rendimiento del chofer (Figma 6.2) | Cero código | Medio |
| Gestión de personal/tickeadores desde Presidente (Figma "Personal", "Agregar tickeadores") | Ninguna de las 2 implementaciones de Tickeador la tiene | Medio |
| Consolidar Tickeador (`features/tickeador` vs `driver/*tickeador_operations*`) | Bloqueante ya señalado en `RQ4-TIC-01`, sigue sin resolver | Alto (decisión + migración) |
| Dos frames "vista presidente" en el propio Figma sin resolver a uno | Es un problema de diseño, no de código | Bajo (decisión de diseño) |

---

## 3. Qué entra en Sprint 3 (recomendado) vs. qué pasa a Sprint 4

**Criterio:** Sprint 3 es "Admin, Presidente, Chofer, Usuario completos" — Tickeador queda para el final según tu instrucción original. Con eso:

### Sprint 3 — completar ahora
1. ✅ Ya hecho en esta sesión: bugs 0/2, registro de unidad+documentos, ruta asignada, tickeador habilitado, limpieza de UI de pruebas.
2. **Pendiente, recomendado antes de cerrar Sprint 3:**
   - Probar de punta a punta el flujo nuevo (registrar cuenta → registrarme como chofer con documentos → aprobar desde Presidente → iniciar servicio) en dispositivo real, no solo Chrome (ver `docs/INFORME_AVANCE_SPRINT.md` §7).
   - Cerrar las 3 observaciones ALTA/CRÍTICA que ya estaban abiertas en el tracker (RQ-32, RQ-58, RQ-71 — ver `docs/INFORME_AVANCE_SPRINT.md` §8).
   - Decidir y resolver cuál "vista presidente" es la definitiva en el propio Figma (bloqueante de baja complejidad, evita que se vuelva a duplicar algo).

### Sprint 4 — se difiere (Tickeador y lo que no es de los 4 perfiles base)
1. Consolidar Tickeador en una sola implementación (`RQ4-TIC-01`, crítico, bloqueante de lo demás de Tickeador).
2. Pantalla "Gestión de personal/tickeadores" + "Agregar tickeadores" (Figma, ninguna implementación la tiene).
3. Sistema de calificación (Usuario↔Chofer).
4. Estadísticas del pasajero y rendimiento del chofer.
5. Cola de revisión manual de recargas (`recharges` hoy se auto-aprueba sin revisión — ver `COMPARACION_FIGMA_CODIGO_DOCS.md` §10.4) y de `benefit_requests`.

---

## 4. Archivos nuevos/tocados en esta sesión

- `lib/core/utils/firestore_date.dart` (nuevo)
- `lib/features/auth/presentation/bloc/auth_bloc.dart`
- `lib/features/user/presentation/pages/perfil_page.dart`
- `lib/features/routes/data/datasources/route_datasource.dart`
- `lib/features/driver/data/datasources/driver_datasource.dart`
- `lib/features/driver/domain/services/driver_service.dart`
- `lib/features/driver/presentation/pages/solicitud_chofer_page.dart` (nuevo)
- `lib/features/driver/presentation/pages/driver_approval_page.dart`
- `lib/features/driver/presentation/pages/driver_home_page.dart`
- `lib/features/user/domain/services/storage_service.dart`
- `lib/features/user/data/datasources/wallet_datasource.dart`
- `lib/features/user/data/datasources/recharge_datasource.dart`
- `lib/features/user/data/datasources/benefit_request_datasource.dart`
- `lib/features/tickeador/domain/entities/station_log_entity.dart`
