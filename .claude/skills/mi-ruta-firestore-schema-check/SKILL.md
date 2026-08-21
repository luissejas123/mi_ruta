---
name: mi-ruta-firestore-schema-check
description: Checks and reuses existing Firestore field names before writing new data in Mi Ruta, avoiding duplicate/invented fields. Use before adding any field to a Firestore write, or before creating a new datasource method that writes to Firestore.
---
# Checking Firestore Schema Before Writing

## Contents
- [Why This Exists](#why-this-exists)
- [Workflow](#workflow)
- [Known Traps](#known-traps)
- [Examples](#examples)

## Why This Exists

This project's Firestore schema already has real inconsistencies (the `users` collection has both `snake_case` and `camelCase` documents coexisting — see [FIRESTORE_COLLECTIONS_GUIDE.md](../../../FIRESTORE_COLLECTIONS_GUIDE.md)). Adding yet another naming variant for a field that already exists (e.g. `nombre` next to `name`/`fullName`, or a new `estimatedDistance` next to an existing `distance`) makes reads unreliable — some code will read the old field, some the new one, and data silently diverges.

Route/stop data is GTFS-seeded (`routes` / `routes_bbox` collections, synced to SQLite by `RouteDataSyncService`) — it must not be re-invented as hardcoded UI strings.

## Workflow

- [ ] **Step 1: Identify the collection** you're about to write to or read from.
- [ ] **Step 2: Open [FIRESTORE_COLLECTIONS_GUIDE.md](../../../FIRESTORE_COLLECTIONS_GUIDE.md)** and find that collection's documented schema and example document.
- [ ] **Step 3: Grep the actual datasource file** for that collection (e.g. `route_datasource.dart`, `user_remote_datasource_impl.dart`) to confirm the guide is still accurate — it can drift from real code.
- [ ] **Step 4: Reuse the existing field name and casing convention** used by the datasource you're editing. If the collection has a documented casing inconsistency (like `users`), match whichever convention that specific datasource already writes, and make sure any new read handles both variants.
- [ ] **Step 5: If a genuinely new field is needed**, confirm it isn't a rename/duplicate of something already there, then add it to [FIRESTORE_COLLECTIONS_GUIDE.md](../../../FIRESTORE_COLLECTIONS_GUIDE.md) in the same commit so the guide doesn't drift again.
- [ ] **Step 6: For route/stop/traffic/distance data specifically** — pull it from `RouteEntity`/`routes_bbox`/SQLite (`RouteDataSyncService`, `RouteService`), not a hardcoded literal string. If real-time distance/traffic isn't wired up yet, leave it visibly unimplemented (e.g. a TODO or explicit "no disponible") rather than a fake static value like `'A 1.2 km'`.

## Known Traps

- **Duplicate field under new name**: adding `stop_name` when `stopName` already exists elsewhere for the same concept.
- **Hardcoded route/stop data**: a service method that always returns the same distance/traffic string regardless of input — looks correct in the UI but is fake for every stop. This exact bug happened in `RouteService.getStopInfo()` (RQ-38): `stopName` parameter was accepted but never used to filter/compute the returned data.
- **Timestamp type mismatch**: some collections use native Firestore `Timestamp`, others ISO 8601 strings — check the existing field before assuming a type.

## Examples

### Wrong — invents a new field and fakes the value

```dart
Future<RouteStopInfo> getStopInfo(String stopName) async {
  return RouteStopInfo(
    stopName: stopName,
    distance: 'A 1.2 km',       // hardcoded regardless of stopName
    trafficStatus: 'Tráfico moderado', // never computed
  );
}
```

### Right — reuses existing GTFS-backed data and computes from the real input

```dart
Future<RouteStopInfo> getStopInfo(String stopName) async {
  final routes = await getAllActiveRoutes();
  final servingLines = routes
      .where((r) => (r.stops ?? const []).any((s) => s.matchesStopName(stopName)))
      .map((r) => r.name)
      .toList();
  // distance/traffic: compute from GeolocatorPlatform/route geometry,
  // or surface as "no disponible" until a real data source exists —
  // never a fixed literal.
  ...
}
```
