---
name: flutter-add-integration-test
description: Adds integration/widget tests to Mi Ruta following its BLoC + get_it architecture. Use when asked to add tests for a feature, BLoC, or user flow.
---
# Adding Tests to Mi Ruta

## Contents
- [Test Types in This Repo](#test-types-in-this-repo)
- [Project Setup](#project-setup)
- [Workflow](#workflow)
- [Examples](#examples)

## Test Types in This Repo

Only `flutter_test` is currently a dev dependency (see `pubspec.yaml`) and `test/widget_test.dart` is the only existing test. Prefer, in order of cost/value for this codebase:

1. **Unit tests for usecases/repositories/services** — pure Dart, no widgets, fastest and highest value given the domain layer is already Flutter-free.
2. **BLoC tests** — verify a sequence of emitted states for a given event, mocking the usecase(s) the BLoC depends on.
3. **Widget tests** — pump a single page wrapped in the BLoC providers it needs (mirroring the relevant slice of `MultiBlocProvider` from `main.dart`), verify rendering/interaction.
4. **Full integration tests** (`integration_test` package, real app boot) — only add this dependency if the user explicitly asks for end-to-end device testing; it's not set up in this repo yet and pulls in `flutter drive`/device requirements.

## Project Setup

If adding BLoC or widget tests that need mocks:

```bash
flutter pub add --dev mocktail
```

(Prefer `mocktail` over `mockito` — no code generation step, works cleanly with `dartz`'s `Either` return types used throughout this repo's repositories/usecases.)

If the user explicitly wants full integration tests:

```bash
flutter pub add 'dev:integration_test:{"sdk":"flutter"}'
```
Then create `integration_test/` at the repo root, following the standard `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` + `testWidgets` pattern.

## Workflow

- [ ] **Step 1: Pick the layer to test** per [Test Types in This Repo](#test-types-in-this-repo) — default to the cheapest layer that actually exercises the change.
- [ ] **Step 2: Mock only what's injected via constructor.** Every usecase/repository/datasource in this repo takes its dependency through the constructor (see `dependency_injection.dart`), so mocking is just passing a `Mock` in place of the real dependency — never reach into `getIt` from a test.
- [ ] **Step 3: For BLoC tests**, cover: initial state, loading state emitted before the async call, success state with the right data, and failure state when the usecase returns `Left(failure)`.
- [ ] **Step 4: For widget tests**, wrap the page under test in exactly the `BlocProvider`s it reads from — check the page's `context.read<X>()`/`BlocBuilder<X, _>` calls to know which ones are required.
- [ ] **Step 5: Run `flutter test`** and fix failures before considering the task done.

## Examples

### Usecase unit test

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFooRepository extends Mock implements FooRepository {}

void main() {
  late MockFooRepository repository;
  late GetFooUseCase useCase;

  setUp(() {
    repository = MockFooRepository();
    useCase = GetFooUseCase(repository);
  });

  test('returns Right(Foo) when repository succeeds', () async {
    final foo = Foo(id: '1');
    when(() => repository.getFoo('1')).thenAnswer((_) async => Right(foo));

    final result = await useCase('1');

    expect(result, Right(foo));
  });
}
```

### BLoC test (manual, no `bloc_test` package required)

```dart
blocTestManually() async {
  final bloc = FooBloc(mockUseCase);
  final states = <FooState>[];
  final sub = bloc.stream.listen(states.add);

  bloc.add(const GetFooEvent(id: '1'));
  await Future<void>.delayed(Duration.zero); // let async handler run

  expect(states, [isA<FooLoading>(), isA<FooLoaded>()]);
  await sub.cancel();
}
```

(If tests grow beyond a handful of BLoCs, propose adding the `bloc_test` package for `blocTest()` syntax rather than hand-rolling this pattern everywhere.)

### Widget test with scoped BlocProviders

```dart
testWidgets('shows loaded foo', (tester) async {
  final bloc = MockFooBloc();
  whenListen(bloc, Stream.value(FooLoaded(Foo(id: '1'))), initialState: FooInitial());

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<FooBloc>.value(
        value: bloc,
        child: const FooPage(),
      ),
    ),
  );

  expect(find.text('Foo 1'), findsOneWidget);
});
```
