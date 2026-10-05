# ChubiPocket — App

The Flutter client for ChubiPocket, a personal finance and shared-expense app.
Track everyday spending, split costs with a partner or friends, handle
subscriptions, and keep an eye on budgets and saving goals — in one place.

Part of a multi-repo project:

- **chubi-pocket-app** — this repo, the Flutter client (iOS & Android)
- [chubi-pocket-be](https://github.com/ppChub722/chubi-pocket-be) — Go REST API
- [chubi-pocket-web](https://github.com/ppChub722/chubi-pocket-web) — web client (in progress)
- [chubi-pocket-docs](https://github.com/ppChub722/chubi-pocket-docs) — specs and design docs

> Solo project, built to learn Flutter and Go by shipping something real rather
> than following tutorials. It runs against a live API on a VPS.

---

## What's in the app

Sixteen feature areas, each shaped by a real situation rather than a feature list:

| Area | |
|---|---|
| Accounts | Cash, bank and e-wallet balances |
| Transactions | Income, expense and transfers, with a quick-create flow |
| Categories & tags | Organise every entry |
| Budgets | Caps per category, with an overview |
| Saving goals | Track progress toward a target |
| Scheduled transactions | Recurring entries and subscriptions |
| Shared expenses & projects | Split costs by trip or plan and settle up |
| Personal debts | Track who owes whom |
| Contacts | People you share costs with |
| Notifications | Invites, link requests and reminders |

---

## Tech

- **Flutter** (Dart SDK 3.11+), Material 3
- **flutter_bloc / Cubit** for state
- **go_router** for navigation
- **dio** for HTTP, with a logging interceptor and typed API exceptions
- **flutter_secure_storage** for auth tokens (device keystore), **shared_preferences** for non-sensitive prefs
- **connectivity_plus** for offline awareness
- **google_fonts**, custom theming, and **intl** localization (English & Thai)

---

## Architecture

Structured by feature, not by layer. Each feature under `lib/features/<name>/`
follows the same shape:

```
features/transactions/
  data/            # repository + API calls
  domain/          # models, value objects
  presentation/
    cubit/         # state
    pages/         # screens
    widgets/       # feature-specific UI
```

Shared plumbing lives in `lib/core/` — networking, routing, theming, storage,
logging — and `lib/shared/` holds cross-feature widgets. The app mirrors the
backend module for module, so a change to, say, budgets stays in one folder on
each side.

```
lib/
  app/            # app shell, navigation scaffold
  core/           # network, router, theme, storage, logger, constants
  features/       # one folder per feature (see above)
  shared/         # widgets and helpers used across features
  l10n/           # English & Thai translations
  main.dart
```

---

## Running it locally

Needs the [backend](https://github.com/ppChub722/chubi-pocket-be) running first
(one `docker compose up`).

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` is the host machine as seen from the Android emulator; use your
machine's LAN IP for a physical device, or the deployed API URL to run against
production.

```bash
flutter test        # unit tests (auth layer)
flutter analyze     # linter
```

---

## Status

Actively built. Core flows — accounts, transactions, budgets, saving goals,
scheduled transactions, categories, tags, contacts, personal debts — are in
place and run against the live API. Transaction-level splits are the main
piece still on the way (tracked in the specs).
