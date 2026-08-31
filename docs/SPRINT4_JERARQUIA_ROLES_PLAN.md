# Plan de implementación — Jerarquía de roles funcional (Sprint 4)

**Fecha:** 27 de agosto de 2026
**Objetivo:** dejar funcional el flujo Administrador → Presidente → Chofer/Tickeador, eliminando en el camino los 3 mecanismos de superadmin duplicados, todo dato hardcodeado de presentaciones previas, y el hueco de seguridad en Firestore.
**Fuentes:** `docs/REQUERIMIENTOS_POR_PERFIL_SPRINT3_SPRINT4.md` §4 (backlog RQ4-*), auditoría de código de esta sesión, y las decisiones de producto tomadas abajo en §0.
**Estado:** **Fases 0-9 (§4), las reglas de Firestore (§5) y el fix de mensajes de login (§9) implementados** (27 ago 2026). Pendiente: compilar y correr la app — la máquina donde se implementó no tiene el SDK de Flutter, así que nada se compiló ni se ejecutó (lo hace el equipo). Ver §8 para los hallazgos nuevos y lo que queda abierto, y §9 para el fix de login. **28 ago 2026: corrección de roles simultáneos implementada y verificada con `dart analyze` (0 errores) — ver §10.**

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

Como las reglas de Firestore (§5) van a impedir que un cliente se escriba `role`/`is_super_admin` a sí mismo, el primer superadmin **no se puede crear desde la app**. Procedimiento manual, una sola vez por entorno (dev/staging/prod). La versión canónica de este runbook vive en [SECURITY.md](../SECURITY.md) ("SuperAdmin: cómo se siembra el primero"); acá queda el detalle operativo paso a paso.

1. **Crear la cuenta normal desde la app.** Un desarrollador se registra con un correo que **solo el equipo de desarrollo conoce** (no se commitea en ningún archivo — vive en un gestor de secretos del equipo o se comunica de forma privada, igual que cualquier credencial). Hacerlo por el registro normal, **no** creando el usuario a mano en la consola: así el documento `users/{uid}` queda con el ID correcto (el UID de Auth) y todos los campos que espera `UserModel`/`AuthModel`.
2. El registro crea `users/{uid}` con `role: 'user'` (comportamiento normal).
3. **Obtener el UID.** Firebase Console → proyecto → *Build → Authentication → pestaña Users* → buscar el correo → copiar el **User UID**.
4. **Abrir el documento.** *Build → Firestore Database* → colección `users` → abrir el documento cuyo ID es ese UID (se puede identificar también por el campo `email`).
5. **Editar dos campos** y guardar:

   | Campo | Tipo | Valor | Notas |
   |---|---|---|---|
   | `role` | string | `admin` | En minúsculas, exacto. Si el doc además tiene `userType`, ponerlo también en `admin`. |
   | `is_super_admin` | **boolean** | **`true`** | Nombre exacto (minúsculas + guion bajo). Debe ser booleano `true`, **no** el string `"true"` — `AuthModel.fromJson` hace `json['is_super_admin'] as bool? ?? false`, así que un string se ignora y queda en `false`. Como el campo no existe todavía, usar *Add field*. |

   La consola escribe con credenciales de administrador, así que pasa por encima de las reglas de §5 que bloquean estos campos desde el cliente. Es el único camino para el primero.
6. **Recargar la sesión** en la app: cerrar sesión y volver a entrar (o reiniciar la app). El perfil se lee de Firestore al iniciar sesión; hasta entonces sigue con los valores viejos.
7. **Verificar.** La cuenta debe aterrizar en `AdminHomePage` ("Perfil Administrativo"), mostrar el distintivo de superadmin en la cabecera (`admin_home_page.dart`, `if (user.isSuperAdmin)`) y mostrar el botón "Cambiar de perfil" (`SwitchProfileButton`, visible con `is_super_admin` o `qa_access`).
8. Desde ahí esa cuenta ya promueve a otros admins/presidentes desde la propia app (Fase 4/5). El paso manual solo se repite para sembrar un entorno nuevo.

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

---

## 8. Resultado de la implementación (27 ago 2026)

### Errores de compilación encontrados que el plan no registraba

El repo **no compilaba ni arrancaba** antes de este trabajo. Además de los dos puntos de §1:

1. `dependency_injection.dart` registraba `ChangePasswordBloc` dos veces además del bloque `ADMIN FEATURE`. `getIt.registerSingleton` lanza excepción en registro duplicado (nunca se activa `allowReassignment`), así que `setupDependencies()` reventaba al arrancar.
2. `main.dart` tenía un `import` **después** de declaraciones de función (Dart lo rechaza), `admin_home_page.dart` importado 3 veces y `driver_home_page.dart` 2 veces.
3. `main.dart` pasaba `builder:` **dos veces** al mismo `MaterialApp` (argumento nombrado duplicado). Se resolvió componiendo `RouteUpdateBanner` y `_ConnectivityBanner` en un solo `builder`.
4. `perfil_page.dart`: el `_buildMenuItem` de "Notificaciones" nunca se cerraba y el de "Planificar viaje" quedaba anidado dentro como argumento posicional.
5. El conflicto de `driver_home_page.dart` era de **tres** ramas, no dos: había un conflicto anidado de `origin/pedro-integracion-jesus` dentro del lado HEAD. Se resolvió con HEAD para `adolfo-dev` y con el lado `pedro` en el anidado, porque su import (`CustomBottomNav`) sí se usa en el cuerpo que sobrevive.
6. `DriverApprovalPage` referenciaba un `UserManagementBloc` con una API totalmente distinta (`service:`, `LoadManagedUsers`, `SetManagedUserActiveState`, `updatingUid`) a la que existe en esa ruta — esa versión se perdió en el mismo merge. Se reescribió la página sobre un `DriverApprovalBloc` nuevo y dedicado.
7. `UserManagementService`/`UserManagementDatasource` **no estaban registrados** en DI, pese a que `DriverApprovalPage` hacía `getIt<UserManagementService>()`. Ya se registran.
8. `PresidenteDashboardService` estaba importado en el DI pero nunca registrado, mientras `presidente_home_page.dart` hacía `getIt<PresidenteDashboardService>()` — habría explotado en runtime. Se resolvió solo al borrar esa página (Fase 7).

### Decisiones tomadas durante la implementación

- **Fase 4, home de `admin`:** `homeScreenForRole()` mandaba a `AdminPrivilegesPage`, pero `main.dart` e `iniciar_sesion_page.dart` mandaban a `AdminHomePage`. Se unificó sobre **`AdminHomePage`**, que es el hub "Perfil Administrativo" y ya enlaza a `AdminPrivilegesPage` — el equivocado era `home_router`.
- **Fase 4, rol `tickeador`:** el plan no decía a dónde mandarlo. Va a `TickeadorHomePage`, que ya existe y es a donde lo manda el switcher de super-admin.
- **Fase 6, aprobación atómica:** el plan proponía `UpdateUserRoleUseCase(role:'driver')` **más** marcar `driver_request.status`. Se hace en **una sola escritura** (`resolveDriverRequest`) para que no pueda quedar rol de chofer con solicitud pendiente. Se escribe solo `role`, nunca `userType` (regla 1 de CLAUDE.md).
- **Fase 8, datos reales:** las líneas asignables salen de `RouteService.getAllActiveRoutes()` (GTFS sembrado), no de una lista fija. **No existe catálogo de estaciones** en el backend (`BusStopService` solo resuelve paradas por coordenadas), así que la estación se escribe a mano — no se inventó un listado falso.
- **`AuthModel.toJson`/`UserModel.toJson` no escriben** `is_super_admin` ni `driver_request`: son campos privilegiados que solo tocan métodos dedicados o la consola.

### Pendiente / abierto

- **Nada se compiló en esta sesión.** No hay SDK de Flutter en la máquina donde se implementó; la compilación y el `flutter analyze`/`flutter test` quedan a cargo del equipo. Cubre también el fix del §9.
- **`DevAdminBootstrap` queda inoperante en entornos nuevos:** escribe `role: 'admin'` desde el cliente y las reglas nuevas lo deniegan (falla en silencio). Ya está documentado en su propio doc-comment. Decidir si se borra o se reemplaza por el runbook manual de SECURITY.md.
- **Segundo mecanismo de hardcodeo no previsto en §0.2:** `lib/core/demo/demo_constants.dart` + `LoginAsDemoUseCase` + vehículos demo en `driver_vehicle_bloc.dart` y `admin_active_vehicles_bloc.dart`. **No se tocó** — parece un "modo demo" deliberado y con UI propia, no residuo de presentación. Decidir si entra en la regla de §0.2.
- **`qa_access` se mantuvo** como mecanismo secundario (vive en la base de datos, cumple §0.1). Sigue pendiente la decisión de §2 sobre retirarlo o documentarlo como QA-only.
- **Reglas de Firestore:** solo se endureció `users` (el hueco real). El resto de colecciones sigue permisivo para sesión autenticada. Ojo al editar: **no** agregar un `match /{document=**}` permisivo al final — el comodín recursivo también cubre `users/` y anularía toda la protección.

---

## 9. Fix de mensajes de error en el login (27 ago 2026)

Reporte de QA: al equivocarse de correo o contraseña, la app solo mostraba un pop-up genérico tipo "server fail", en vez de decir si falló el correo o la contraseña.

### Causa

El mensaje legible **sí se generaba** (`_mensajeError` en `auth_remote_datasource_impl.dart`), pero nunca llegaba a la UI:

1. **`auth_bloc.dart` emitía `AuthError(message: failure.toString())`** en vez de `failure.message`. `Failure` (`core/error/failures.dart`) no sobreescribe `toString()`, así que el pop-up mostraba literalmente `Instance of 'ServerFailure'`. El bug estaba en los 5 handlers del bloc (login, registro, logout, loginAsDemo, resetPassword).
2. `auth_repository_impl.dart` envolvía todo como `ServerFailure(message: e.toString())`, dejando el prefijo `Exception: ` en el texto.

### Cambios

| Archivo | Cambio |
|---|---|
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | `failure.toString()` → `failure.message` en todos los handlers. |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | Helper `_mensajeLimpio()` que quita el prefijo `Exception: `; usado en los 7 catch. |
| `lib/features/auth/data/datasources/auth_remote_datasource_impl.dart` | `_mensajeError` normaliza el código a minúsculas y agrega el alias `invalid-login-credentials` (variante de firebase_auth 6.x). Ya distinguía `user-not-found` de `wrong-password`. Mensajes reescritos a español claro. |

Resultado: correo inexistente → **"No existe una cuenta registrada con ese correo."**; contraseña mala → **"La contraseña es incorrecta."**

### Límite conocido (no es bug)

Si el proyecto de Firebase tiene activada **Email enumeration protection** (por defecto en proyectos nuevos), Firebase Auth devuelve `invalid-credential` **a propósito** tanto para correo inexistente como para contraseña incorrecta, para no revelar qué correos están registrados. En ese caso la app solo puede mostrar **"El correo o la contraseña son incorrectos."**. Distinguirlos desde el cliente exigiría consultar `users` sin autenticar, lo que filtraría nombres/teléfonos/saldos y contradice las reglas de §5. Para recuperar el detalle: *Firebase Console → Authentication → Settings → User account protection*, desactivar esa protección — los mensajes granulares vuelven a funcionar solos, sin cambios de código.

---

## 10. Corrección: roles simultáneos (28 ago 2026)

El modelo de §0-§9 asumía que `role` era un valor único — otorgar un rol nuevo **sobrescribía** el anterior (promover a admin/presidente o aprobar como chofer borraba silenciosamente el `user` base, y no había forma de que un dirigente conservara su rol de chofer). Esto quedó corregido con la decisión de producto real, tomada en esta sesión:

Toda cuenta es `user` por definición. Sobre esa base, las únicas combinaciones válidas son:

| Combinación | Ejemplo |
|---|---|
| `[user]` | pasajero |
| `[user, admin]` | admin que también es pasajero |
| `[user, driver]` | chofer aprobado |
| `[user, driver, presidente]` | dirigente que también es chofer |
| `[user, presidente]` | dirigente sin necesidad de ser chofer |
| `[user, tickeador]` | tickeador |

`admin`, `driver` y `tickeador` son mutuamente excluyentes entre sí. `presidente` es la única excepción: combina con `driver` o va sola. **Sin límite** en cuántas cuentas pueden tener `admin`/`presidente` a la vez — decisión explícita para las pruebas de Sprint 4, se le pone límite recién al cierre.

### Qué se implementó

1. **`lib/features/admin/domain/entities/role_hierarchy.dart`** (nuevo) — única fuente de verdad de la matriz de compatibilidad: `isValidRoleSet`, `canGrant`, `primaryRole`. Todo el código de grant pasa por acá antes de escribir a Firestore.
2. **Firestore `users/{uid}.roles`** (nuevo, `array<string>`) — todos los roles simultáneos de la cuenta. `role` (singular) se mantiene, recalculado en cada escritura como `RoleHierarchy.primaryRole(roles)` (admin > presidente > driver > tickeador > user) — decide la pantalla de inicio, pero ya no es la fuente de verdad de permisos.
3. **Las 3 escrituras de rol pasaron de sobrescribir a ser aditivas y validadas**: `AdminRemoteDataSourceImpl.updateUserRole` (promover admin/presidente), `UserManagementDatasource.resolveDriverRequest` (aprobar chofer), `UserManagementDatasource.assignTickeador` (asignar tickeador). Las tres leen los roles actuales, calculan la unión, y **lanzan** si la combinación resultante no está en `RoleHierarchy` — el repositorio ya envuelve eso en `Left(Failure)`, así que el error llega a la UI sin código nuevo.
4. **`AdminAccessService`** y los checks de `perfil_page.dart`/`user_management_page.dart` pasaron de `user.role == 'x'` a `user.roles.contains('x')` — si no, una cuenta con varios roles perdía acceso a las funciones de los roles que no fueran el "activo".
5. **`lib/features/admin/presentation/pages/role_switcher_page.dart`** (nuevo) — reemplaza en `perfil_page.dart` al viejo switch binario "Modo conductor" (ver Figma `node-id=3238-11287`, insuficiente para una cuenta con hasta 3 roles). Solo navega (mismo patrón que `SuperAdminSwitcherPage`, sin escribir en Firestore); se muestra únicamente si `roles.length > 1`, y solo lista los roles que la cuenta realmente tiene — a diferencia de `SuperAdminSwitcherPage`, que es el acceso de prueba QA/superadmin a los 5 perfiles sin importar los roles reales (se dejó intacto, es una herramienta distinta).
6. **`firestore.rules`**: `roles` se agregó a `touchesPrivilegedField()` — el dueño de la cuenta nunca puede auto-escribírselo, igual que `role`.
7. Documentado en `FIRESTORE_COLLECTIONS_GUIDE.md` (sección "Roles simultáneos").

### Verificado

`dart analyze lib` — **0 errores** (solo warnings/infos preexistentes, ninguno en los archivos tocados). No se corrió la app (falta `google-services.json`/`.env` en esta máquina) ni se probó contra Firestore real — falta QA manual del flujo completo (promover, aprobar chofer, asignar tickeador, cambiar de perfil) antes de dar esto por cerrado.

### Pendiente / fuera de alcance de esta corrección

- ~~No hay flujo de **revocar** un rol (solo otorgar).~~ **✅ Resuelto (29 ago 2026, otra sesión/PC):** botón "Quitar privilegios de administrador" en `admin_permissions_edit_page.dart`. Implementado con dos primitivas en `AdminRemoteDataSource`: `revokeUserRole(uid, role)` (quita un rol puntual, valida contra `RoleHierarchy.isValidRoleSet`) y `resetToPlainUser(uid)` (resetea `roles`/`role` a `['user']`/`'user'` incondicionalmente, sin validar el estado previo). El botón usa **`resetToPlainUser`**, no `revokeUserRole(uid, 'admin')`: bajo las reglas propias de `RoleHierarchy`, `{admin, presidente}` nunca es una combinación otorgable, así que en uso normal ambos caminos dan el mismo resultado — pero como este equipo edita documentos de `users` a mano desde la consola de Firebase (fuera de `RoleHierarchy`), una cuenta puede terminar con una combinación que la app nunca validaría (ej. `roles: ['user','admin','presidente']`). En ese caso `revokeUserRole(uid,'admin')` dejaría `'presidente'` colgado; `resetToPlainUser` no, porque no depende de que la combinación de entrada sea válida. Cadena completa: `AdminRemoteDataSourceImpl.resetToPlainUser` → `AdminRepositoryImpl.resetToPlainUser` → `ResetToPlainUserUseCase` → `AdminPrivilegesBloc._onRevokeAdmin` (evento `RevokeAdminRoleEvent`) → registrado en `dependency_injection.dart`. Verificado con `flutter analyze` — 0 errores en los archivos tocados. `revokeUserRole` se deja intacta como primitiva genérica (quitar un rol puntual de una combinación ya válida) para uso futuro.
- `UserManagementPage` solo pre-valida (oculta el botón) para "promover a admin/presidente" — el flujo de "asignar tickeador"/"aprobar chofer" sigue sin ese guard visual en la UI (la validación server-side/datasource sí aplica siempre, solo falta la mejora de UX).
- No se migró ningún doc existente: una cuenta creada antes de esta corrección no tiene `roles` hasta que se le otorgue un rol nuevo — mientras tanto, todo el código la trata como `[role]` (fallback automático, ver `AuthModel.fromJson`/`AdminUserModel.fromJson`).

---

## 11. Observación suelta (no relacionada a roles, encontrada al probar en dispositivo real)

Al correr la app en un teléfono real (`flutter run -d 18201ae9ff5f`, 28 ago 2026) para verificar la corrección de §10, apareció este warning en el log — no lo generó la corrección de roles, ya existía:

```
W/Firestore: Listen for QueryWrapper(query=Query(target=Query(transactions where user_id==... order by -timestamp, -__name__);limitType=LIMIT_TO_FIRST)) failed:
Status{code=FAILED_PRECONDITION, description=The query requires an index. ...}
```

Falta un **índice compuesto** en Firestore para la colección `transactions` (`user_id` + `timestamp` desc). El código ya lo maneja con gracia (`! Índice compuesto requerido. Usando alternativa sin ordenar...` — cae a una consulta sin ordenar en vez de crashear), así que no es bloqueante, pero el historial de movimientos de la wallet no sale ordenado por fecha hasta que se cree.

Link directo para crearlo (generado por Firestore para este proyecto, `mi-ruta-4004d`):
https://console.firebase.google.com/v1/r/project/mi-ruta-4004d/firestore/indexes?create_composite=ClJwcm9qZWN0cy9taS1ydXRhLTQwMDRkL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy90cmFuc2FjdGlvbnMvaW5kZXhlcy9fEAEaCwoHdXNlcl9pZBABGg0KCXRpbWVzdGFtcBACGgwKCF9fbmFtZV9fEAI

Basta con abrirlo con una cuenta que tenga acceso al proyecto y confirmar "Crear índice" — Firestore lo construye solo, sin tocar código.
