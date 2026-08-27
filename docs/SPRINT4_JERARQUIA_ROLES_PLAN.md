# Plan de implementación — Jerarquía de roles funcional (Sprint 4)

**Fecha:** 27 de agosto de 2026
**Objetivo:** dejar funcional el flujo Administrador → Presidente → Chofer/Tickeador, eliminando en el camino los 3 mecanismos de superadmin duplicados, todo dato hardcodeado de presentaciones previas, y el hueco de seguridad en Firestore.
**Fuentes:** `docs/REQUERIMIENTOS_POR_PERFIL_SPRINT3_SPRINT4.md` §4 (backlog RQ4-*), auditoría de código de esta sesión, y las decisiones de producto tomadas abajo en §0.
**Estado:** plan aprobado, implementación **no iniciada**. Este documento es el punto de entrada para continuar el trabajo desde otra máquina.

---

## 0. Decisiones de producto (ya tomadas, no reabrir sin motivo)

1. **El superadmin vive en la base de datos, no en el código.** Nada de listas de emails hardcodeadas en Dart. Se usa un correo "inventado" que solo conocen los desarrolladores, únicamente como procedimiento operativo para saber qué cuenta promover manualmente la primera vez — ese correo **no se commitea en ningún archivo del repo**. Ver §3 para el runbook exacto.
2. **Todo lo hardcodeado que se usó para una presentación previa se elimina.** Ningún dato de negocio debe venir de constantes en el código — todo pasa por Firestore. Esto incluye `core/debug/static_test_accounts.dart` completo (no solo su uso en el panel de Presidente).
3. **Las reglas de Firestore se corrigen como parte obligatoria de este trabajo, no como nota aparte.** Hoy cualquier cliente puede escribirse `role: 'admin'` directo por SDK. Eso contradice lo que se afirma en el contrato sobre seguridad, así que se tiene que cerrar en este mismo sprint.

---

## 1. Hallazgos previos que no estaban en el backlog original

Estos dos bugs bloquean cualquier trabajo en los archivos que toca este plan — se encontraron auditando el código, no vienen de una tarea del tracker:

1. **`lib/features/driver/presentation/pages/driver_home_page.dart` tiene marcadores de conflicto de merge sin resolver** (`<<<<<<< HEAD ... >>>>>>> origin/adolfo-dev`), commit `a73d2b7 "Merge pedro corregido"`. El archivo no compila tal cual está. Ahí vive `_SupervisorSection`/`_PresidentePanelSection`, necesarios para "Asignar tickeador". Resolver quedándose con la versión más completa (HEAD/pedro, con `DriverOperationsBloc` y las secciones de aprobación) — la de `adolfo-dev` es una versión más simple que regresionaría funcionalidad.
2. **`lib/core/di/dependency_injection.dart` registra dos veces, íntegro, el bloque `// ADMIN FEATURE`** (líneas ~162-220 y ~222-277). Mismo origen (merge sin resolver), sin marcadores porque "resolvió" quedándose con ambas copias. Hay que des-duplicar antes de agregar cualquier registro nuevo de DI para Presidente/Tickeador.

---

## 2. Los 3 mecanismos de superadmin (a unificar según §0.1)

| # | Mecanismo | Archivo | Qué usa |
|---|---|---|---|
| 1 | `SuperAdminConfig.superAdminEmails` | `lib/core/config/super_admin_config.dart:17-19` | allowlist de emails hardcodeada, usada por `AdminAccessService.isSuperAdmin()` para saltarse `admin_permissions` |
| 2 | `kSuperAdminEmail` / `isSuperAdminEmail()` | `lib/core/config/super_admin_config.dart:4-7` | un único email hardcodeado, distinto al de arriba, usado solo por `SwitchProfileButton` para mostrar/ocultar el switcher de perfil |
| 3 | `qa_access` (campo Firestore) | escrito por `UserManagementDatasource.setQaAccess` (`lib/features/admin/data/datasources/user_management_datasource.dart:30-35`) | toggle por cuenta, también gatilla `SwitchProfileButton` |

Los mecanismos 1 y 2 usan **listas de emails diferentes** — un superadmin de permisos puede no ver el switcher de perfil y viceversa. Bug real, no solo duplicación.

**Reemplazo único (según §0.1):** campo booleano en Firestore `users/{uid}.is_super_admin` (nuevo, snake_case consistente con el resto del esquema). `AdminAccessService.isSuperAdmin(AuthEntity)` pasa a leer `user.isSuperAdmin` (nuevo getter en `AuthEntity`, poblado desde ese campo por `AuthModel.fromJson`), no un email. Se eliminan por completo `SuperAdminConfig.superAdminEmails` y `kSuperAdminEmail`/`isSuperAdminEmail()`. `qa_access` se mantiene como mecanismo secundario intencional (ya vive en la base de datos, cumple la regla de §0.1) — decisión pendiente de confirmar si también se retira o se documenta como QA-only.

---

## 3. Runbook: cómo se bootstrapea el primer superadmin

Como las reglas de Firestore (§5) van a impedir que un cliente se escriba `role`/`is_super_admin` a sí mismo, el primer superadmin **no se puede crear desde la app**. Procedimiento manual, una sola vez por entorno (dev/staging/prod):

1. Un desarrollador registra una cuenta normal en la app con un correo que **solo el equipo de desarrollo conoce** (no se commitea en ningún archivo — vive en un gestor de secretos del equipo o se comunica de forma privada, igual que cualquier credencial).
2. Esa cuenta queda creada en Firestore como `users/{uid}` con `role: 'user'` (comportamiento normal de registro).
3. Un desarrollador con acceso a la consola de Firebase (o vía Admin SDK con credenciales de servicio, que ignoran las reglas de seguridad de cliente) edita ese documento manualmente y setea `role: 'admin'`, `is_super_admin: true`.
4. Desde ahí, esa cuenta ya puede usar la propia app (Fase 4 del plan) para promover a otros admins/presidentes — no hace falta repetir el paso manual salvo para sembrar un entorno nuevo.

---

## 4. Plan de fases (orden de dependencias)

### Fase 0 — Limpieza previa (bloquea todo lo demás)
- Resolver el merge conflict en `driver_home_page.dart` (§1.1).
- Des-duplicar el bloque `ADMIN FEATURE` en `dependency_injection.dart` (§1.2).

### Fase 1 — Eliminar hardcodeo de presentación (según §0.2)
- Borrar `lib/core/debug/static_test_accounts.dart` completo (`staticTestVehicles`, `staticTestReports`, y cualquier cuenta demo que contenga).
- Quitar sus 3 usos fuera del panel de Presidente:
  - `lib/features/auth/data/datasources/auth_remote_datasource_impl.dart:88` ("MODO PRUEBA TEMPORAL")
  - `lib/features/user/data/datasources/user_remote_datasource_impl.dart:21` ("MODO PRUEBA TEMPORAL")
  - `lib/features/driver/data/datasources/driver_income_datasource.dart:15` ("MODO PRUEBA TEMPORAL")
  - Confirmar qué flujo real reemplaza a cada uno (debe ser 100% Firestore) antes de borrar — no dejar un camino sin datos.
- El cuarto uso (`presidente_home_page.dart`) se resuelve solo al borrar esa página completa en la Fase 6.

### Fase 2 — Superadmin vía base de datos (según §0.1)
- Agregar `isSuperAdmin` a `AuthEntity`/`AuthModel`, poblado desde `users/{uid}.is_super_admin` (bool, default `false`).
- `AdminAccessService.isSuperAdmin()` pasa a recibir `AuthEntity` y leer `user.isSuperAdmin` en vez de comparar email contra una lista.
- Eliminar `SuperAdminConfig.superAdminEmails`, `kSuperAdminEmail`, `isSuperAdminEmail()`.
- Actualizar `SwitchProfileButton` (`lib/features/admin/presentation/widgets/switch_profile_button.dart:19`) para usar el nuevo check.
- Documentar el runbook de §3 en `SECURITY.md` (no en código).

### Fase 3 — Reconocer el rol Presidente en permisos
- En `admin_access_service.dart`, agregar `canApproveChoferRequests`, `canAssignTickeador` como responsabilidades fijas de `presidente` (no mezclarlas con el esquema configurable de `admin_permissions`, que es solo para `admin`).

### Fase 4 — Unificar ruteo por rol
- Extender `homeScreenForRole()` en `lib/core/navigation/home_router.dart` para los 5 roles (`admin`, `presidente`, `driver`, `tickeador`, resto → `MiRutaScreen`).
- `lib/main.dart` (`_AuthGate`) e `lib/features/auth/presentation/pages/iniciar_sesion_page.dart` (`_onAuthLoaded`) dejan de tener su propio switch y llaman a `homeScreenForRole()`.

### Fase 5 — "Promover a Presidente"
- Evento hermano de `PromoteUserToAdminEvent` en `user_management_bloc.dart`, reutilizando `UpdateUserRoleUseCase` con `role: 'presidente'` (ya cableado de punta a punta, no requiere datasource nuevo).
- Botón junto a "Promover a administrador" en `UserManagementPage`.
- Gatillado solo por `admin` (Presidente no otorga Presidente).

### Fase 6 — "Registrarme como chofer" + cola de aprobación
- Campo nuevo `users/{uid}.driver_request: {status: 'pending'|'approved'|'rejected', requested_at}`. **No tocar `role` hasta la aprobación** — si no, el ruteo por rol mandaría al usuario a `DriverHomePage` antes de tiempo.
- Botón en `perfil_page.dart` visible cuando `role == 'user'` y no hay solicitud pendiente.
- Extender `DriverApprovalPage` para leer también `driver_request.status == 'pending'`, con acción "Aprobar" que llama `UpdateUserRoleUseCase(role: 'driver')` + marca `driver_request.status = 'approved'`.
- Gatillado solo por `presidente`/`admin`.

### Fase 7 — Eliminar panel de Presidente duplicado (y su hardcodeo, ver Fase 1)
- Borrar `PresidenteHomePage`, `PresidenteDashboardBloc/Event/State`, `PresidenteDashboardService` — es el panel con datos falsos.
- Quedarse con `PresidentePanelPage` (datos reales de Firestore vía `PresidentePanelBloc`/`AdminService`/`RouteService`) como home oficial de Presidente.
- Apuntar `home_router.dart` (Fase 4) a `PresidentePanelPage`.

### Fase 8 — "Asignar tickeador"
- Reutilizar `UpdateUserRoleUseCase` con `role: 'tickeador'` + escribir `tickeador_info: {assigned_station, assigned_lines, status}` con la forma exacta que ya espera `TickeadorEntity.fromJson`.
- UI dentro de `PresidentePanelPage`, mismo patrón de lista + confirmación que "Promover a administrador".

### Fase 9 — Documentar el esquema nuevo
- Agregar a `FIRESTORE_COLLECTIONS_GUIDE.md`: `is_super_admin`, `driver_request`, `tickeador_info` (recién esta fase empiezan a escribirse de verdad).

---

## 5. Reglas de seguridad de Firestore (obligatorio, según §0.3)

Estado actual de `firestore.rules` (repo root):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} { allow read, write: if true; }
  }
}
```

Completamente abierto. Reemplazar por reglas que, como mínimo:

- `users/{uid}`: el dueño puede leer/editar su propio documento **excepto** `role`, `is_super_admin`, `admin_permissions`, `tickeador_info`.
- Esos campos privilegiados solo los puede escribir una request cuyo propio `users/{auth.uid}` tenga `role in ['admin', 'presidente']` o `is_super_admin == true` (usar `get()` dentro de la regla para leer el doc del solicitante).
- `driver_request.status`: el dueño puede escribir `'pending'`; solo `admin`/`presidente` pueden escribir `'approved'`/`'rejected'`.
- El resto de colecciones puede seguir con reglas más permisivas si hoy no representan un riesgo de escalamiento de privilegios — priorizar `users` primero.

Esta fase puede avanzar en paralelo a partir de la Fase 2 (en cuanto exista `is_super_admin` como campo real).

---

## 6. Orden sugerido de sprint

```
Fase 0 (limpieza merge/DI)
  └─▶ Fase 1 (borrar hardcodeo de presentación)
  └─▶ Fase 2 (superadmin vía DB) ──▶ Reglas de Firestore (§5, en paralelo)
        └─▶ Fase 3 (permisos Presidente)
              ├─▶ Fase 5 (promover a Presidente)
              ├─▶ Fase 6 (solicitar ser chofer)
              └─▶ Fase 8 (asignar tickeador)
  └─▶ Fase 7 (borrar panel Presidente duplicado) ──▶ Fase 4 (unificar ruteo, ya sabe a dónde mandar Presidente)
Fase 9 (documentar esquema) — al final, cuando los campos ya se están escribiendo de verdad
```

## 7. Archivos clave para retomar

- `lib/features/admin/domain/services/admin_access_service.dart`
- `lib/core/config/super_admin_config.dart`
- `lib/core/debug/static_test_accounts.dart` (a eliminar)
- `lib/core/navigation/home_router.dart`
- `lib/features/admin/presentation/bloc/user_management_bloc.dart`
- `lib/features/presidente/presentation/pages/presidente_panel_page.dart`
- `lib/features/presidente/presentation/pages/presidente_home_page.dart` (a eliminar)
- `lib/features/driver/presentation/pages/driver_home_page.dart` (resolver conflicto primero)
- `lib/core/di/dependency_injection.dart` (des-duplicar primero)
- `lib/features/user/presentation/pages/perfil_page.dart`
- `firestore.rules`
- `FIRESTORE_COLLECTIONS_GUIDE.md` (actualizar en Fase 9)
