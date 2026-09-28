# Mi Ruta

App móvil (Flutter/Firebase) de planificación y pago de transporte público en Cochabamba, Bolivia. Roles: Usuario, Chofer, Tickeador, Presidente (dirigente de línea), Administrador.

## Setup rápido

1. `flutter pub get`
2. Copiar `.env.example` → `.env` y completar credenciales de Firebase (`FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, etc.)
3. Colocar `google-services.json` → `android/app/` y `GoogleService-Info.plist` → `ios/Runner/` (ambos ignorados por git — nunca commitear ninguno de los tres, ver [SECURITY.md](SECURITY.md))

## Comandos comunes

```bash
flutter pub get               # Instalar dependencias
flutter run                   # Debug en dispositivo/emulador conectado
flutter analyze               # Análisis estático
flutter test                  # Correr tests
flutter clean && flutter pub get && flutter run  # Rebuild limpio
```

## Arquitectura

Clean Architecture por feature (`data` / `domain` / `presentation`), BLoC para estado, `get_it` para inyección de dependencias. El detalle completo — capas, reglas de dependencia, patrón de BLoC, cómo agregar una feature nueva — vive en [CLAUDE.md](CLAUDE.md), que se carga siempre como contexto de proyecto; no se repite aquí para no crear una segunda copia que se desincronice.

## Seguridad — nunca commitear

`.env`, `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`, certificados (`*.pem`/`*.key`/`*.p12`), `debug.keystore`. Guía completa, incluido el runbook para sembrar el primer SuperAdmin: [SECURITY.md](SECURITY.md).

## Estado del proyecto (2026-09-28)

Sprint 3 avanzado y parcialmente completado; varios módulos que originalmente estaban planificados para Sprint 4 (chofer/admin/tickeador/presidente) ya se adelantaron y están implementados — Sprint 3 y 4 corrieron en paralelo, no en secuencia estricta, con cambios de alcance pedidos sobre la marcha (típico en Scrum). El detalle día a día de quién implementó qué vive en `docs/specs/claude Documento 8 Bitácora de Implementación.docx`.

### Trabajo en curso sin commitear (rama `dev-jesus-villarroel`)

Hay cambios locales sin commitear al 2026-09-28 — **para seguir trabajando en otra máquina hay que commitear y pushear esta rama primero**, `git status`/`git diff` no viaja solo. Resumen de lo que incluyen:

- **Plan de 11 puntos QA (chofer/tickeador/beneficios/navegación) completo**, las 3 tandas: ícono de ubicación sin flecha, ocultar opciones de menú ya no vigentes, abordaje por placa con lista para duplicados, descuentos de beneficios configurables por el admin y aplicados al cobro, notificación al tickeador cuando un chofer inicia servicio + escaneo de QR de unidad para Salida/Llegada/Intermedio, y el viaje abordado persiste al cambiar de pestaña (`NavigationBloc` ahora es singleton).
- **Auditoría y fix de navegación por rol**: varias pantallas decidían qué mostrar/a dónde navegar leyendo `AuthBloc` (foto fija de al iniciar sesión) en vez de `UserBloc` (stream en vivo de Firestore) — un cambio de rol durante la sesión no se reflejaba hasta cerrar y volver a entrar. Corregido en `perfil_rol_page.dart`, `perfil_page.dart` y `notificaciones_page.dart`.
- **`PerfilConductorPage` eliminada**: el chofer tenía una pantalla de Perfil aparte, desactualizada (4 opciones fijas) y con un pie de navegación que no reenviaba a las pantallas del rol — ahora el chofer usa el mismo `PerfilPage` compartido que el resto de los roles, que ya lo soporta bien.
- **"Convertirme en chofer" (RQ-68) oculto** de Perfil por decisión del usuario — quedaba duplicado con "Registrarme como chofer" (el flujo real, con aprobación del dirigente); ver `docs/DEUDA_TECNICA.md` ítem correspondiente.
- Ver [docs/DEUDA_TECNICA.md](docs/DEUDA_TECNICA.md) para el detalle completo de bugs encontrados/corregidos y páginas que quedaron huérfanas a propósito.

## Documentación formal del proyecto (`docs/specs/`)

Los documentos académicos originales (`Documento 1` a `Documento 10`, formato `.docx`, uno por cada nivel de la `Guía de Documentación de Desarrollo.docx`) describen el sistema como se diseñó en el papel — no siempre coinciden con lo que quedó implementado. Cada uno tiene una versión espejo con el prefijo `claude ` (ej. `claude Documento 1 Modelo del Dominio.docx`) que corrige el contenido contra el código real, con cita de archivo:línea en cada corrección — los originales no se tocan. Los diagramas UML (`Documento 4` y sus sub-documentos `4.1`-`4.6`) tienen el texto/tablas corregidos pero las imágenes quedan como `[DIAGRAMA PENDIENTE]` hasta que se regeneren visualmente. `docs/figma/claude Figma explicado Mi Ruta.docx` hace lo mismo para el inventario de pantallas de Figma. `Documento 7.1 Product Backlog.xlsx` queda fuera de este proceso a propósito.

## Dónde está la fuente de verdad de cada cosa

Este proyecto tuvo, en algún momento, más de un documento reclamando ser la fuente de un mismo concepto — la causa raíz real detrás del bug de "ruta asignada" que describe `docs/DEUDA_TECNICA.md` §1. Esta tabla existe para que no se repita: antes de escribir un documento nuevo sobre algo de la lista, edita el que ya existe.

| Concepto | Fuente única |
|---|---|
| Reglas de trabajo para agentes de IA, capas, DI, BLoC | [CLAUDE.md](CLAUDE.md) |
| Esquema de colecciones de Firestore | [FIRESTORE_COLLECTIONS_GUIDE.md](FIRESTORE_COLLECTIONS_GUIDE.md) |
| Archivos sensibles, runbook de SuperAdmin | [SECURITY.md](SECURITY.md) |
| Ciclo de vida de navegación/tracking GPS | [NAVIGATION_FIX.md](NAVIGATION_FIX.md) |
| Documentación formal del proyecto (modelo, diseño funcional, reglas, UML, arquitectura, QA, bitácora, anexos) | [docs/specs/](docs/specs/) — ver sección de arriba |
| Bugs conocidos y decisiones técnicas pendientes | [docs/DEUDA_TECNICA.md](docs/DEUDA_TECNICA.md) |
| Plan activo: seguridad de dinero, tarifas por distancia, GPS en paradas | [docs/PLAN_SEGURIDAD_TARIFAS_GPS.md](docs/PLAN_SEGURIDAD_TARIFAS_GPS.md) |
| Script de siembra de Firestore (⚠️ desactualizado, leer antes de correr) | [tools/FIRESTORE_INIT_README.md](tools/FIRESTORE_INIT_README.md) |

## Documentación archivada

`docs/archive/` guarda documentos con valor histórico (auditorías de sprint, planes ya cerrados, diagnósticos ya resueltos) que dejaron de ser referencia activa pero no ameritan borrarse — explican por qué se tomó una decisión, aunque ya no describan el estado actual del proyecto.
