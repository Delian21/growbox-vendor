# Architecture

## Overview

GROWBOX Vendor is a Flutter application organized **feature-first**, with thin cross-cutting layers for app wiring, data and shared UI. State is managed with `provider` + `ChangeNotifier`, navigation with `go_router`, and all data is currently **mocked in-memory** — repositories are the seam where a real backend will later plug in.

```
lib/
├── app/                  # Composition root: providers, router, themes
│   ├── providers/        # One ChangeNotifier per domain
│   ├── router.dart       # All routes + page transitions
│   └── theme.dart        # Light/dark Material 3 themes
├── core/                 # No widget logic; constants & utils
│   ├── constants/        # AppColors, AppDimensions, AppStrings
│   └── utils/            # formatters
├── data/                 # Data layer, no UI
│   ├── models/           # Plain Dart models (Order, Store, ...)
│   ├── mock/             # In-memory mock data & image maps
│   └── repositories/     # Data access (SalesRepository today)
├── features/             # Screens grouped by feature
│   ├── auth/  onboarding/  dashboard/  products/  orders/
│   ├── sales/  store/  notifications/  settings/  help/
│   └── splash/
└── shared/               # Reusable, feature-agnostic UI
    ├── layouts/          # MainLayout (sidebar, header, bottom dock)
    ├── widgets/          # Growbox* buttons, cards, states, dialogs
    └── utils/            # snackbar helper
```

### Dependency rule

Code points **downward**: `features → shared → core`, and `features → app/providers`; `app → data`. `data` never imports widgets. Mock data is isolated in `data/mock` so it can be swapped for network calls without touching screens.

## State management

- All app state lives in `ChangeNotifier` classes under `app/providers/`, registered app-wide in `growboxProviders()` in `lib/main.dart` via `MultiProvider`. Screens use `context.watch<T>()` / `context.read<T>()`.
- `growboxProviders()` is exported so the widget tests build the exact same dependency graph as production.
- The product catalog is a special case: `ProductCatalog` (in `features/products/product_catalog.dart`) is a `ChangeNotifier` **singleton** that owns the product list. `ProductsProvider` subscribes to it and forwards notifications, so the list screen, the detail screen and CRUD operations always read and write the same source of truth.

| Provider | Owns |
| --- | --- |
| `AuthProvider` | login / register / logout mock session |
| `ProductsProvider` | product catalog (wraps the `ProductCatalog` singleton) |
| `OrdersProvider` | order list, status filters, status updates |
| `SalesProvider` | transactions, summary, period filters (via `SalesRepository`) |
| `StoreProvider` | store profile, open/close, opening hours (`SharedPreferences`) |
| `NotificationsProvider` | notifications (read / delete / clear) |
| `ThemeProvider` | light / dark / system theme mode (`SharedPreferences`) |

## Routing

`app/router.dart` defines a single `GoRouter` (`appRouter`):

- **`/`** — splash (5s, then navigates to `/login`)
- **Auth** — `/login`, `/register`, `/verify-email`, `/forgot-password`, `/reset-password`
- **Auth status** — `/pending-approval`, `/suspended`
- **Onboarding** — `/onboarding/business-info`, `/onboarding/contact-details`, `/onboarding/verification`, `/onboarding/success`
- **Shell (app)** — a `ShellRoute` wrapping `MainLayout`, with `/dashboard`, `/products` (+ `:id` details), `/orders` (+ `:id` details), `/sales`, `/store`, `/notifications`, `/settings`, `/help`

Each route group uses a custom `CustomTransitionPage`: fade + slide-up for auth, cross-fade for shell tabs, slide-from-right for detail screens, slide + scale for onboarding.

Back-press behavior is handled centrally:

- `RootPopScope` (in `main.dart`) intercepts the system back gesture at the root and routes it per location — shell tabs go back to `/dashboard`, detail screens back to their list, onboarding back one step, etc. A second back press on `/dashboard` (within 2s) shows the exit dialog.
- `MainLayout` adds its own `PopScope` for in-app shell behavior.

## Theming

- `app/theme.dart` exposes `GrowboxTheme.lightTheme` / `darkTheme`, both Material 3 `ColorScheme.fromSeed` builds seeded from `AppColors.primary` (dark variant seeds from `AppColors.darkPrimary`).
- `ThemeProvider` cycles System → Light → Dark and persists the mode to `SharedPreferences` under `theme_mode`.
- All design tokens live in `core/constants` (`AppColors`, `AppDimensions`, `AppStrings`). Screens reference tokens, never hard-coded values.

## Data layer

- **Models** (`data/models/`) are plain immutable Dart classes — `Order` / `OrderItem`, `Store`, `TransactionRecord`, `SalesSummary`, `SalesByPeriod`, `NotificationItem` — with `copyWith` helpers where mutation is needed.
- **Mock data** (`data/mock/`) seeds orders, notifications, transactions and the store profile; `MockImages` maps product/category names to bundled assets under `assets/images/produce/`.
- **Repositories** (`data/repositories/`) are the boundary to a future backend. Today only `SalesRepository` exists as a real class; providers that need data consume it, so swapping mock data for HTTP calls means changing repository implementations, not screens.
- **Persistence**: `SharedPreferences` is used today only for the theme mode and store opening hours (`store_operating_days`, `store_open_time`, `store_close_time`).

## Feature screens

- **Auth / onboarding** — full-screen flows with mock validation (e.g. password-length check) and a simulated network delay.
- **Dashboard** — summary cards plus an `fl_chart` line chart fed by mock sales.
- **Products** — searchable catalog grid with staggered animations, add/edit sheet, delete confirmation, and image picking via `image_picker`.
- **Orders** — filterable list with status chips and an order-details screen; status transitions call `OrdersProvider.updateOrderStatus`.
- **Sales** — summary, transaction history, `fl_chart` bar chart, and today / week / month / all filters via `SalesProvider.setPeriod`.
- **Store** — profile editing, logo/banner picking, open/close toggle, and an operating-hours editor persisted to `SharedPreferences`.
- **Notifications / Settings / Help** — list + management UI, theme settings, static support screen.

## Shared UI

- `MainLayout` (`shared/layouts/`) implements the responsive chrome: collapsible glassmorphism sidebar (desktop), glass header with theme toggle and notification bell, mobile drawer, and a floating bottom dock with a sliding pill indicator. It owns back-navigation within the shell.
- `shared/widgets/` holds the reusable `Growbox*` components (buttons, cards, text fields, empty/error/loading states, dialogs, success modal, badges).
- `shared/utils/snackbar_helper.dart` centralizes snackbar feedback.

## Testing

- `test/widget_test.dart` boots the full app with the same `growboxProviders()` wiring as production (with mocked `SharedPreferences`) and asserts the splash → login flow.
- `test/mock_images_assets_test.dart` guards asset integrity: every product, category and store image referenced by mock data must resolve to a bundled file.

## Future backend integration

The intended seams, in order of work:

1. Give each provider a repository (extend the `SalesRepository` pattern).
2. Replace `data/mock/*` seeds with repository calls backed by HTTP.
3. Add `fromJson` / `toJson` to models (or add API-payload models).
4. Move `AuthProvider` onto a real auth service and gate shell routes with go_router redirects once auth is real.

## Conventions

- Feature-first folders: put a screen in `features/<feature>/`, not in a flat screens folder.
- Register any new app-wide provider in `growboxProviders()` in `main.dart`.
- Design tokens belong in `core/constants`, not inline in widgets.
- Reuse `shared/widgets` before writing a new one-off widget.