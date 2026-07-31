# AGENTS.md

Guidance for AI assistants and contributors working on this codebase.

## Project overview

Flutter app for a vegetable mandi (marketplace) business: staff manage products,
orders (bills), customers, stock, charges, expenses, and print Bluetooth receipts.
Offline-first with local SQLite storage and server sync over a Phoenix websocket.

- **Stack**: Flutter (Material 3), Provider + flutter_bloc, go_router, sqflite,
  dio, phoenix_socket, print_bluetooth_thermal.
- **SDK**: Dart >= 3.3.1, tested on Flutter 3.27.x.
- **App package name**: `mandiapp` (imports use `package:mandiapp/...`).

## Repository layout

```
lib/
  main.dart              App bootstrap: DB init, providers, router
  routes/app_routes.dart All go_router routes
  screens/               One file per screen (thin UI + state wiring)
  widgets/               Reusable UI, grouped by feature area (checkout, reports, ...)
  blocs/                 flutter_bloc, one folder per domain (order, stock, ...)
  controllers/           Plain logic controllers for forms (login/signup/user)
  models/                Plain Dart models with fromMap/toMap + copyWith
  dao/                   Data-access layer (sqflite), one class per entity
  services/              Singleton services: api, auth, printer, pdf, socket, sync
  utils/                 Stateless helpers (db_helper, app_helper, constants)
  helpers/               Theme system, string extensions
```

### Layer rules

- **models** never import from `dao`, `services`, or Flutter UI.
- **dao** classes take/return models and use `DBHelper.instance.database` /
  `SyncedDatabase` for all reads/writes.
- **blocs** orchestrate DAOs; screens consume bloc state. Screens should not
  query DAOs directly — route through a bloc.
- **services** are singletons (`X.instance`) and hold cross-cutting concerns
  (socket, sync, printing, PDF reports).
- **screens** import `helpers/theme/app_theme.dart` for theming (there is a
  `helpers/theme/app_theme.dart`; do not add new ad-hoc theme files).

## Data layer

- Single SQLite DB at `lib/utils/db_helper.dart` (currently **version 11**).
  - **Important**: `onUpgrade` is currently empty. When schema changes are
    needed, add a real migration there instead of bumping the version blindly.
  - Table and preference-key names are centralized in `lib/utils/constants.dart`
    (`DbTables`, `PrefsKeys`) — always reference those instead of raw strings.
    Column names are still raw SQL strings; centralize them (`DbColumns`) as you
    add new code.
- `SyncedDatabase` (`lib/utils/synced_database.dart`) wraps `Database` and
  fires `SyncService.instance.syncRecord(...)` on inserts/updates to synced
  tables. Deletes are intentionally **not** synced.
- Sync is "dirty-record" based: every synced table has
  `sync_status` + `updated_at` columns. `SyncService` (`lib/services/sync_service.dart`)
  pushes pending records over the websocket and merges server pushes back into
  the local DB (see `report_dao.dart` for the upsert merge patterns).

## Conventions

- **Formatting**: run `dart format lib/ test/` before finishing any change.
- **Lints**: `analysis_options.yaml` includes `flutter_lints` plus extras
  (e.g. `prefer_const_constructors`, `directives_ordering`, `avoid_dynamic_calls`).
  The goal is `flutter analyze` with **zero issues** — keep it that way.
- **Deprecated APIs**: don't use `withOpacity` (use `withValues(alpha: ...)`),
  `onBackground` (use `onSurface`), or `surfaceVariant` (use
  `surfaceContainerHighest`).
- **State classes**: keep private states named `_XState`; expose them via
  `State<Widget> createState()`.
- **Debug output**: use `debugPrint`, never `print` (lint-enforced).

## Commands

```sh
flutter pub get          # install deps
flutter analyze          # must report: No issues found!
dart format lib/ test/   # normalize formatting
flutter test             # run tests (currently minimal)
```

## Gotchas

- `DBHelper.generateUuidInt()` produces a random 8-digit int used as a local PK
  that is later reconciled with server IDs — don't rely on it being unique
  forever.
- `checkout` pauses `SyncService` during the critical write sequence — don't
  reorder that without reading `checkout_screen.dart` and `sync_service.dart`.
- Permission prompts (`flutter_contacts`, bluetooth) are platform-gated in
  `main.dart`; desktop builds skip them.
