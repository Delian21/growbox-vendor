# GROWBOX Vendor

**GROWBOX Vendor** is the vendor-facing portal for the GROWBOX agricultural marketplace. It lets produce vendors manage their store, products, orders and sales from one app — on mobile, web and desktop.

> **Status:** UI prototype / design implementation. All data is mocked in-memory (see [`ARCHITECTURE.md`](ARCHITECTURE.md)) — there is no backend integration yet.

## Start here

`lib/main.dart` is the way in: `growboxProviders()` creates one `ChangeNotifier` per
domain (auth, products, orders, sales, store, notifications, theme), `GrowboxApp` passes
them to `MaterialApp.router` along with `appRouter`, and the first route is `/` — the
splash. The splash plays its logo animation for at least one second and waits for
`SharedPreferences` to open (giving up after 5 s either way), then hands over to `/login`.
Every signed-in screen lives under one `ShellRoute` wrapped in `MainLayout`, which draws
the sidebar, header and bottom dock around it. Nothing is fetched: screens read from the
providers, which are seeded from `lib/data/mock/`. Only the theme mode, the store profile
and the two store photos survive a restart.

If you only need to change one thing:

| To change… | Open |
| --- | --- |
| What a screen looks like | `lib/features/<feature>/<feature>_screen.dart` |
| Which pages exist, their URLs and transitions | `lib/app/router.dart` |
| What the back button does | `RootPopScope` in `lib/main.dart` (app-wide), `MainLayout` (inside the shell) |
| Sidebar, header, bottom dock, responsive chrome | `lib/shared/layouts/main_layout.dart` |
| Colours, spacing, UI copy | `lib/core/constants/app_colors.dart`, `app_dimensions.dart`, `app_strings.dart` |
| Light/dark themes, and the theme mode that persists | `lib/app/theme.dart`, `lib/app/theme_provider.dart` |
| Splash timing, logo animation, startup work | `lib/features/splash/splash_screen.dart` |
| Products, stock, the "low stock" threshold (10) | `lib/features/products/product_catalog.dart` |
| Orders, statuses, which transitions are allowed | `lib/app/providers/orders_provider.dart`, `lib/data/models/order.dart` |
| Sales totals, commission (10%), chart buckets | `lib/app/providers/sales_provider.dart` |
| Store profile, open/closed, hours, saved prefs keys | `lib/app/providers/store_provider.dart` |
| Store photo size caps and compression | `lib/shared/utils/store_photo_compression.dart` |
| Seed data and product images | `lib/data/mock/`, `assets/images/produce/` |
| A shared widget (`Growbox*`) | `lib/shared/widgets/` |
| Add an app-wide provider | `growboxProviders()` in `lib/main.dart` |
| Tests | `test/` — `widget_test.dart` pins startup, `overflow_matrix_test.dart` pins layout |

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
├── data/       # models and in-memory mock data (no backend yet)
├── features/   # one folder per feature (auth, products, orders, ...)
└── shared/     # reusable layouts, widgets, helpers
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for a deep dive into layering, state management, routing and data flow.
