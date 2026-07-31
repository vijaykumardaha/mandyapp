# mandiapp

Offline-first Flutter app for a vegetable mandi (marketplace) business. Staff
manage products, orders (bills), customers, stock, charges, expenses, and print
Bluetooth receipts. Local SQLite storage syncs to the server over a Phoenix
websocket.

## Stack

- Flutter (Material 3), Provider + flutter_bloc, go_router
- sqflite (local SQLite), dio (REST API), phoenix_socket (realtime sync)
- print_bluetooth_thermal (receipt printing)

## Getting started

```sh
flutter pub get
flutter run
```

Requires Dart >= 3.3.1 (tested on Flutter 3.27.x).

## Project structure

See `AGENTS.md` for the full architecture guide — layer rules (screens / blocs /
dao / models / services), the data & sync layer, and conventions.

The most relevant entry points:

- `lib/main.dart` — bootstrap, providers, theming
- `lib/routes/app_routes.dart` — all go_router routes
- `lib/utils/db_helper.dart` — SQLite schema + version (11)
- `lib/utils/synced_database.dart` — DB wrapper that triggers sync on writes
- `lib/services/sync_service.dart` — websocket push/merge logic

Feature-specific docs: `PAYMENT_SUMMARY_MIGRATION.md`,
`REPORTS_DAO_README.md`, `REPORTS_SYSTEM_README.md`.

## Development

```sh
flutter analyze   # must report: No issues found!
dart format lib/ test/
flutter test
```

## Server config

API + websocket endpoints are configured in `lib/services/app_config.dart`.
