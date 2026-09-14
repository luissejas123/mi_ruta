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

## Estado del proyecto (2026-09-13)

Sprint 3 avanzado y parcialmente completado; varios módulos que originalmente estaban planificados para Sprint 4 (chofer/admin/tickeador/presidente) ya se adelantaron y están implementados — Sprint 3 y 4 corrieron en paralelo, no en secuencia estricta, con cambios de alcance pedidos sobre la marcha (típico en Scrum). El detalle día a día de quién implementó qué vive en `docs/specs/claude Documento 8 Bitácora de Implementación.docx`.

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
