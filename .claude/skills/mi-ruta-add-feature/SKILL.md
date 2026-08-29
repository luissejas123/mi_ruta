---
name: mi-ruta-add-feature
description: Adds a new feature to Mi Ruta following its existing Clean Architecture + BLoC + get_it conventions (data/domain/presentation layers). Use when asked to add a new feature, page, or piece of functionality to lib/features/.
---
# Adding a Feature to Mi Ruta

## Contents
- [Layering Rules](#layering-rules)
- [Folder Structure](#folder-structure)
- [Workflow](#workflow)
- [Examples](#examples)

## Layering Rules

This repo already has a fixed architecture — don't introduce a different pattern (no MVVM/`ChangeNotifier`/`Provider`, no ad-hoc `setState` for business state).

1. **Domain layer has zero Flutter/Firebase imports.** Pure Dart only — entities, abstract repositories, usecases.
2. **Repository/usecase return types are `Either<Failure, T>`** from `dartz`. Exception: domain-level planning services (`MultiRoutePlanner`, `PlannedTripService`) return `Future<List<...>>` directly — only follow that exception if there's genuinely no recoverable failure case to model, not as a shortcut.
3. **All dependencies are registered centrally** in [lib/core/di/dependency_injection.dart](../../../lib/core/di/dependency_injection.dart) via `get_it`, using `getIt.registerSingleton<T>(...)` in the existing style — datasource → repository → usecase → bloc, in that order, each built from the previously registered one.
4. **Presentation never calls datasources or Firestore directly** — only dispatches BLoC events and reads BLoC state.
5. User-facing strings are in **Spanish (es-BO)**.

## Folder Structure

```
lib/features/{feature}/
├── data/
│   ├── datasources/     # Firestore/SQLite/API — interface + impl (e.g. FooDatasource, FooDatasourceImpl)
│   ├── models/          # JSON-serializable data classes
│   └── repositories/    # Implements the domain repository interface, coordinates datasources
├── domain/
│   ├── entities/         # Pure Dart, no Firebase
│   ├── repositories/      # Abstract interface only
│   ├── usecases/          # One class per operation, callable via `call()`
│   └── services/          # Optional domain-level orchestration (see Layering Rules #2)
└── presentation/
    ├── bloc/             # {Feature}Event, {Feature}State, {Feature}Bloc
    ├── pages/            # Full-screen widgets
    └── widgets/          # Reusable UI components
```

## Workflow

- [ ] **Step 1: Domain first.** Define the entity (extends `Equatable`), the abstract repository interface, and the usecase(s).
- [ ] **Step 2: Data layer.** Implement the datasource (talking to Firestore/SQLite/etc — check [FIRESTORE_COLLECTIONS_GUIDE.md](../../../FIRESTORE_COLLECTIONS_GUIDE.md) if it touches Firestore, see `mi-ruta-firestore-schema-check` skill), the model, and the repository implementation returning `Either<Failure, T>`.
- [ ] **Step 3: BLoC.** Create `{Feature}Event`, `{Feature}State`, and `{Feature}Bloc` that calls the usecase and folds the `Either` into states.
- [ ] **Step 4: Register in DI.** Add datasource → repository → usecase → bloc registrations to `dependency_injection.dart`, following the existing ordering/style in that file.
- [ ] **Step 5: Wire into `main.dart`** — add the BLoC to `MultiBlocProvider` **only if the state needs to be global**; otherwise provide it locally where the feature's pages are pushed.
- [ ] **Step 6: Presentation.** Build pages/widgets that dispatch events via `context.read<FooBloc>().add(...)` and render via `BlocBuilder`/`BlocConsumer`. Never call the datasource or repository directly from a widget.
- [ ] **Step 7: Verify.** Run `flutter analyze` and, if the feature has meaningful logic, add/extend a test. Manually confirm the new page is actually reachable via navigation from an existing screen — don't leave it orphaned (see `mi-ruta-qa-review` skill for what "orphaned" looked like in a past task).

## Examples

### Registering in `dependency_injection.dart` (existing style)

```dart
getIt.registerSingleton<FooDatasource>(FooDatasourceImpl(getIt<FirebaseFirestore>()));
getIt.registerSingleton<FooRepository>(FooRepositoryImpl(getIt<FooDatasource>()));
getIt.registerSingleton<GetFooUseCase>(GetFooUseCase(getIt<FooRepository>()));
getIt.registerSingleton<FooBloc>(FooBloc(getIt<GetFooUseCase>()));
```

### BLoC handler folding `Either`

```dart
Future<void> _onGetFoo(GetFooEvent event, Emitter<FooState> emit) async {
  emit(FooLoading());
  final result = await getFooUseCase(event.id);
  result.fold(
    (failure) => emit(FooError(failure.message)),
    (foo) => emit(FooLoaded(foo)),
  );
}
```
