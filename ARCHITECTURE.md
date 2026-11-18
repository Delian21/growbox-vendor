# Architecture

## Overview

GROWBOX Vendor is a Flutter application organized **feature-first**, with thin cross-cutting layers for app wiring, data and shared UI. State is managed with `provider` + `ChangeNotifier`, navigation with `go_router`, and all data is currently **mocked in-memory** — providers are the seam where a real backend will later plug in.

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
│   └── mock/             # In-memory mock data & image maps
├── features/             # Screens grouped by feature
│   ├── auth/  onboarding/  dashboard/  products/  orders/
│   ├── sales/  store/  notifications/  settings/  help/
│   └── splash/
└── shared/               # Reusable, feature-agnostic UI
    ├── layouts/          # MainLayout (sidebar, header, bottom dock)
    ├── widgets/          # Growbox* buttons, cards, states, dialogs
    └── utils/            # snackbar helper, store photo compression
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
| `SalesProvider` | transactions, summary and period filters — all derived from the orders |
| `StoreProvider` | store profile, open/close, opening hours and photos (`SharedPreferences`) |
| `NotificationsProvider` | notifications (read / delete / clear) |
| `ThemeProvider` | light / dark / system theme mode (`SharedPreferences`) |

## Routing

`app/router.dart` defines a single `GoRouter` (`appRouter`):

- **`/`** — splash: the logo animation, held for at least `kSplashMinimumDuration` (1 s). It leaves for `/login` once that minimum has elapsed **and** the app's startup work has finished, whichever is later; that work is opening `SharedPreferences`, so the theme and store reads that follow are served from an already-open store. Startup is capped at `kSplashStartupTimeout` (5 s) and failures are logged, so a hung or broken platform channel cannot strand the app on the splash.
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
- **No repository layer yet.** Providers hold the mock data themselves, or derive it: `SalesProvider` builds every number from `OrdersProvider`, so the Sales page and the dashboard cannot disagree. Providers are the seam where HTTP calls will later plug in, which keeps the change off the screens.
- **Persistence**: `SharedPreferences` holds everything that survives a restart: `theme_mode` (the System/Light/Dark index), the vendor's own `store_name` plus `store_operating_days` / `store_open_time` / `store_close_time`, and the two store photos as base64 data URLs under `store_logo_url` / `store_banner_url` (data URLs keep a pick working on web and desktop). `StoreProvider.loadFromPrefs()` reads them lazily, once; the splash awaits only opening the store, not these reads.

## Feature screens

- **Auth / onboarding** — full-screen flows with mock validation (e.g. password-length check) and a simulated network delay.
- **Dashboard** — summary cards plus an `fl_chart` line chart fed by mock sales.
- **Products** — searchable catalog grid with staggered animations, add/edit sheet, delete confirmation, and image picking via `image_picker`.
- **Orders** — filterable list with status chips and an order-details screen; status transitions call `OrdersProvider.updateOrderStatus`.
- **Sales** — summary, transaction history, `fl_chart` bar chart, and today / week / month / all filters via `SalesProvider.setPeriod`.
- **Store** — profile editing, logo/banner picking into fixed budgets (see *Store photos*), open/close toggle, and an operating-hours editor persisted to `SharedPreferences`.
- **Notifications / Settings / Help** — list + management UI, theme settings, static support screen.

## Shared UI

- `MainLayout` (`shared/layouts/`) implements the responsive chrome: collapsible glassmorphism sidebar (desktop), glass header with theme toggle and notification bell, mobile drawer, and a floating bottom dock with a sliding pill indicator. It owns back-navigation within the shell.
- `shared/widgets/` holds the reusable `Growbox*` components (buttons, cards, text fields, empty/error/loading states, dialogs, success modal, badges).
- `shared/utils/snackbar_helper.dart` centralizes snackbar feedback; `shared/utils/store_photo_compression.dart` is the single path for resizing and encoding the store photos.

## Store photos

Both store photos go through `shared/utils/store_photo_compression.dart`, so picking and re-saving share one code path:

- The picker is asked for a reduced image first (logo 1024 px, banner 2000 px, `imageQuality: 85`), so a full-size camera JPEG never reaches memory.
- `compressStorePhoto` then enforces the real budget: longest side ≤ 512 px (logo) / 1600 px (banner) and encoded size ≤ 400 KB / 800 KB, JPEG at quality 80 stepping down to 40. A transparent logo that already fits keeps its alpha; everything else becomes JPEG. The `image` package does the decode/resize/encode (`dart:ui` can only encode PNG).
- An image that still does not fit throws `ImageTooLargeException` and is refused with "This image is too large. Try a smaller one." rather than stored.
- The same helper re-compresses an already-saved data URL on every save, so an oversized photo from an older build shrinks the next time the sheet is saved.

`StoreProvider.updateStore` returns `false` when a write fails and rolls back the in-memory store **and** the stored values — a logo write that landed before a failed banner write is restored too — so a failed save never shows, or reloads, as saved. The Edit Store sheet reports the failure and keeps the previous image.

## Testing

- `test/widget_test.dart` boots the full app with the production `growboxProviders()` wiring (mocked `SharedPreferences`) and pins the splash contract: still showing at 900 ms, login on screen at the 1 s minimum, waiting for startup work that outlasts the minimum, and giving up at `kSplashStartupTimeout` when that work never finishes.
- `test/overflow_matrix_test.dart` renders every shell page and both detail pages at 1.0/1.5/2.0× text, 320/360/390/1440 px and both themes, then the Edit Store sheet, the single and bulk reject dialogs and the bulk bar, asserting `takeException()` stays null on every combination.
- `test/store_photo_pipeline_test.dart` covers the photo budgets, the refusal message, the sheet's error, and the rollback paths for the in-memory store and the stored values.
- `test/mock_images_assets_test.dart` guards asset integrity: every product, category and store image referenced by mock data must resolve to a bundled file.
- The rest of `test/` pins behaviour that has regressed before: dashboard charts and orders table, order transitions, workflow and row states, sales consistency, vendor identity and name sources, navigation coverage, sidebar collapse, shared components and the responsive grid.
- `test/screenshot_capture.dart` is the screenshot harness — no `_test` suffix, so `flutter test` skips it; `flutter test --update-goldens test/screenshot_capture.dart` regenerates `screenshots/`.

## Future backend integration

The intended seams, in order of work:

1. Add a `data/repositories/` layer and give each provider a repository.
2. Replace `data/mock/*` seeds with repository calls backed by HTTP.
3. Add `fromJson` / `toJson` to models (or add API-payload models).
4. Move `AuthProvider` onto a real auth service and gate shell routes with go_router redirects once auth is real.

## Conventions

- Feature-first folders: put a screen in `features/<feature>/`, not in a flat screens folder.
- Register any new app-wide provider in `growboxProviders()` in `main.dart`.
- Design tokens belong in `core/constants`, not inline in widgets.
- Reuse `shared/widgets` before writing a new one-off widget.