---
name: mi-ruta-qa-review
description: Reviews a teammate's task/branch in Mi Ruta before approving it in the QA board — checks it's actually wired into app navigation, checks for hardcoded/fake data, and previews the screen safely. Use when asked to revisar/review a task, PR, or branch before marking it approved.
---
# Reviewing a Task Before QA Approval

## Contents
- [What to Check](#what-to-check)
- [Workflow](#workflow)
- [Safely Previewing a Screen](#safely-previewing-a-screen)
- [Examples of Real Findings](#examples-of-real-findings)

## What to Check

A task/branch is not done just because it compiles. Check, in order:

1. **Is it actually reachable from the app?** A new page/widget that nothing navigates to is not a finished feature — it's an orphaned file.
2. **Is the data real or faked?** Look for hardcoded literals standing in for computed/fetched values (a fixed distance string, a fixed status, a fixed ETA regardless of input).
3. **Does it follow the layering rules?** (see `mi-ruta-add-feature` skill) — no direct Firestore calls from presentation, `Either<Failure, T>` from repositories/usecases, domain layer free of Flutter imports.
4. **Does it reuse existing Firestore fields/GTFS data?** (see `mi-ruta-firestore-schema-check` skill) — no duplicated/invented fields.
5. **Is the UI/copy consistent with the screen's actual state?** e.g. a "before boarding" screen showing boarding-only status text is a copy-paste bug, not just cosmetics.
6. **Does it actually run?** Missing local-only files (`firebase_options.dart`, `google-services.json`, `.env`) are expected per-machine setup, not a code defect — regenerate locally, don't flag them as bugs in the review.

## Workflow

- [ ] **Step 1: Get the diff.** `git show <commit>` or `git diff <base>..<branch>` for the files the task claims to touch.
- [ ] **Step 2: Trace navigation.** `grep` for `NewPageName(` across `lib/` — if the only matches are the file's own definition and self-references, it's not wired into the real flow. Say so explicitly rather than assuming it's fine.
- [ ] **Step 3: Read the service/repository layer the UI depends on.** Look for parameters that are accepted but never used to compute the returned value — a strong signal of hardcoded/fake data.
- [ ] **Step 4: Preview the screen if needed** — see [Safely Previewing a Screen](#safely-previewing-a-screen) below. Never leave a debug preview change committed.
- [ ] **Step 5: Report findings** with concrete file:line references, then ask the user whether to log them as an observation for the task's author or fix them directly.

## Safely Previewing a Screen

Some screens under review aren't reachable from the normal login flow yet. To preview one without breaking `main.dart` permanently:

1. Temporarily add the import and swap `home: const _AuthGate()` in `lib/main.dart` for `home: const TargetPage()`.
2. Mark both edits with a `// TEMP debug preview` comment so they're easy to find.
3. After the user confirms they've seen it, **revert both edits immediately** — `git diff lib/main.dart` should come back clean before ending the task.

Do this instead of leaving a permanent debug route/button — this repo has no debug-menu convention yet, and adding one is a separate decision the user should make explicitly, not something to slip in during a review.

## Examples of Real Findings

From reviewing RQ-38 (parada/ruta detail card) on `dev-mario-branez`:

- `RouteService.getStopInfo(stopName)` accepted `stopName` but returned hardcoded `distance: 'A 1.2 km'`, `trafficStatus: 'Tráfico moderado'` regardless of the actual stop.
- `RutaTiempoPage` (pre-boarding screen, button says "Ver abordaje") showed `status: 'A bordo'` — copy-pasted from the boarding screen, wrong for its own state.
- Neither `RutaTiempoPage` nor `RutaAbordajePage` was reachable from any real navigation path (`grep` showed the constructors were only referenced by themselves and each other) — the feature wasn't actually integrated into the trip-planning flow.
