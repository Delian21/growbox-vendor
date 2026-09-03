# GROWBOX Vendor

**GROWBOX Vendor** is the vendor-facing portal for the GROWBOX agricultural marketplace. It lets produce vendors manage their store, products, orders and sales from one app — on mobile, web and desktop.

> **Status:** UI prototype / design implementation. All data is mocked in-memory (see [`ARCHITECTURE.md`](ARCHITECTURE.md)) — there is no backend integration yet.

## Features

- **Authentication flow** — login, registration, email verification, forgot/reset password, plus pending-approval and suspended-store states.
- **Store onboarding** — a 4-step wizard (business info → contact details → verification → success).
- **Dashboard** — key metrics and a weekly sales trend chart.
- **Products** — browse, search, add, edit and delete produce with bundled stock photos and low-stock indicators.
- **Orders** — filterable list across the full lifecycle (pending → accepted → preparing → ready → completed / cancelled) with an order-details screen.
- **Sales** — summary cards, per-transaction history, and a weekly bar chart with today / week / month / all filters.
- **Store management** — open/close toggle, profile editing, and operating hours (persisted locally).
- **Notifications** — unread badges, mark-as-read, delete and clear all.
- **Settings & help** — light/dark/system theme (persisted) and a help & support screen.
- **Responsive layout** — collapsible sidebar on desktop, floating bottom dock / drawer on mobile.

## Tech stack

| Layer | Choice |
| --- | --- |
| Framework | Flutter (Material 3), Dart SDK `^3.13.0` |
| Navigation | [go_router](https://pub.dev/packages/go_router) |
| State management | [provider](https://pub.dev/packages/provider) + `ChangeNotifier` |
| Charts | [fl_chart](https://pub.dev/packages/fl_chart) |
| Local persistence | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| Imagery | [image_picker](https://pub.dev/packages/image_picker) + bundled assets |
| Animations | [flutter_staggered_animations](https://pub.dev/packages/flutter_staggered_animations) |

## Getting started

Prerequisites: Flutter SDK with Dart `^3.13.0`.

```bash
cd growbox_vendor
flutter pub get
flutter run      # pick a device / platform
```

Run the tests:

```bash
flutter test
```

Build for production web:

```bash
flutter build web
```

`serve_verify.js` at the project root is a throwaway static server for spot-checking the release web build:

```bash
node serve_verify.js   # serves build/web at http://127.0.0.1:18080
```

It can be deleted once no longer needed.

## Project structure

```
lib/
├── app/        # app-wide wiring: providers, router, theme
├── core/       # cross-cutting constants and utilities
├── data/       # models, mock data, repositories
├── features/   # one folder per feature (auth, products, orders, ...)
└── shared/     # reusable layouts, widgets, helpers
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for a deep dive into layering, state management, routing and data flow.