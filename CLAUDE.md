# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Mi Ruta** is a Flutter/Dart mobile application for public transportation route planning and booking in Cochabamba, Bolivia. The app features user authentication, route search with Google Maps integration, wallet/payment functionality, driver capabilities, and an admin panel.

- **Dart/Flutter SDK:** 3.10.1+
- **Platform:** Android, iOS, Web, Windows, macOS, Linux

## Key Dependencies

### State Management & Architecture
- **flutter_bloc (9.1.1):** BLoC pattern state management
- **dartz (0.10.1):** Functional programming — `Either<Failure, T>` for error handling
- **get_it (9.2.1):** Service locator for dependency injection
- **equatable (2.0.8):** Value equality for entities and states

### Firebase & Backend
- **firebase_core, firebase_auth, cloud_firestore, firebase_storage**

### Maps & Location
- **google_maps_flutter (2.17.0)**, **geolocator (14.0.2)**, **geocoding (3.0.0)**

### Data & Storage
- **sqflite (2.4.2):** Local SQLite (GTFS transit data), **flutter_dotenv (6.0.1):** `.env` config
- **mobile_scanner (5.0.0):** QR codes, **image_picker (1.0.4)**, **http (1.4.0)**

## Common Commands

```bash
flutter pub get               # Install dependencies
flutter run                   # Debug on connected device/emulator
flutter run --release         # Release build
flutter run -d chrome         # Web build
flutter analyze               # Static analysis
flutter format lib/           # Format Dart code
dart fix --apply              # Apply automated fixes
flutter test                  # Run all tests (see test/widget_test.dart)
flutter clean && flutter pub get && flutter run  # Clean rebuild
```

## Architecture

This project follows **Clean Architecture** with feature-based organization:

```
lib/features/{feature}/
├── data/
│   ├── datasources/     # Firestore, local DB, APIs (interface + impl)
│   ├── models/          # Data classes with JSON serialization
│   └── repositories/    # Implementations coordinating datasources
├── domain/
│   ├── entities/        # Pure Dart models (no Firebase)
│   ├── repositories/    # Abstract interfaces
│   ├── usecases/        # Business logic functions
│   └── services/        # Domain-level services (optional)
└── presentation/
    ├── bloc/            # Events, States, BLoC handlers
    ├── pages/           # Full-screen widgets
    └── widgets/         # Reusable UI components
```

**Key rules:**
1. Domain layer has zero dependencies on Flutter or Firebase — pure Dart only.
2. Repository/usecase return types are `Either<Failure, T>` from dartz. Domain-level planning services (e.g. `MultiRoutePlanner`, `PlannedTripService`) are an exception — they return `Future<List<...>>` directly since there's no recoverable failure case to model.
3. All dependencies registered centrally in [lib/core/di/dependency_injection.dart](lib/core/di/dependency_injection.dart) via `get_it`. Call `setupDependencies()` before `runApp()`.
4. Presentation communicates only through BLoC events — never calls Firestore directly.

### BLoC Pattern

```dart
// Dispatch from UI
context.read<UserBloc>().add(GetUserByIdEvent(uid: 'user_123'));

// Handle in BLoC
Future<void> _onGetUserById(GetUserByIdEvent event, Emitter emit) async {
  final result = await getUserByIdUseCase(event.uid);
  result.fold(
    (failure) => emit(UserError(failure.message)),
    (user) => emit(UserLoaded(user)),
  );
}
```

## Core Layer

```
lib/core/
├── di/dependency_injection.dart        # get_it setup, call setupDependencies() before runApp()
├── error/failures.dart                 # Failure base class for Either<Failure, T>
├── local_db/route_local_database.dart  # SQLite wrapper: routes_meta + app_config tables
├── theme/                              # theme_cubit.dart (dark/light mode), map_styles.dart (Google Maps JSON styles)
└── utils/                              # distance, polyline, map, location-icon helpers
```

## Core Features

- **auth/** — Login, registration, logout, password reset via Firebase Auth
- **user/** — User CRUD, location services, maps (`MiRutaBloc`). 25 presentation pages covering wallet/recharge (`RechargeService`), trip payments (`TripPaymentService`), QR (`pago_qr_utils_service.dart`, `qr_scanner_page.dart`), benefit requests (`BenefitRequestService`), notifications (`NotificationService`), trip history (`TripHistoryService`), navigation rendering (`NavigationPolylineBuilderService`, `NavigationMarkerBuilderService`, `TripRouteMapBuilderService`), and route/segment lookup (`RouteFinderService`, `TripSegmentService`, `TripPhaseService`).
- **routes/** — Full Clean Architecture feature, not just GTFS parsing:
  - GTFS asset parsing (routes.txt, trips.txt, shapes.txt) → SQLite seeding via `RouteDataSyncService` on startup ([lib/core/local_db/route_local_database.dart](lib/core/local_db/route_local_database.dart)); bbox queries return only routes with a cached `polyline_json`
  - Trip planning: `PlannedTripService` + `MultiRoutePlanner.planAsync()` search up to 3 bus legs plus explicit walking segments between origin/destination, scoring candidates by walk distance × penalty + transit distance, deduplicated by `ref|directionId` (not list index — `OsmRoute.id` is just an array position)
  - Entities: `RouteEntity`, `PlannedTrip`, `PlannedTripLeg` (`LegType.bus` / `LegType.walking`)
  - Presentation: `TripPlannerBloc` drives the "Planificar Viaje" flow
- **driver/** — Placeholder only (`.gitkeep` files in domain/presentation), not implemented
- **payment/** — Structural stub; real payment/recharge logic lives in `user/domain/services/` (`TripPaymentService`, `RechargeService`)
- **admin/** — Placeholder only, not implemented

## Setup

1. `flutter pub get`
2. Copy `.env.example` → `.env`, fill in Firebase credentials (`FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, etc.)
3. Place `google-services.json` → `android/app/` and `GoogleService-Info.plist` → `ios/Runner/` (both git-ignored)

## Adding a New Feature

Follow the data → domain → presentation layering above. Register datasources, repositories, usecases, and blocs as singletons in `dependency_injection.dart`. Add the BLoC to `MultiBlocProvider` in `main.dart` only if global state is needed.

## Common Gotchas

- **Never import Firebase in the domain layer** — domain code must be framework-agnostic.
- **Never call datasources from presentation** — always go through BLoC events.
- **Dispose resources** — `GoogleMapController`, `StreamSubscription`s in `BLoC.close()` or widget `dispose()`.
- **Location permissions** — geolocator requires runtime permissions on Android 6.0+.
- **Language** — User-facing strings are in **Spanish (es-BO)**.

## Reference Docs

- [ARCHITECTURE.md](ARCHITECTURE.md) — Architecture explanation with data flow
- [CLEAN_ARCHITECTURE_IMPLEMENTATION.md](CLEAN_ARCHITECTURE_IMPLEMENTATION.md) — Concrete implementation patterns
- [FIRESTORE_COLLECTIONS_GUIDE.md](FIRESTORE_COLLECTIONS_GUIDE.md) — Database schema
- [PAGES_GUIDE.md](PAGES_GUIDE.md) — UI pages and navigation flow
- [SECURITY.md](SECURITY.md) — Sensitive file handling (.env, credentials, keystore)
