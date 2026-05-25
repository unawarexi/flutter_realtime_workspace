# 14 — Mobile & Frontend Architecture
# TeamSpot Flutter App: State Management, Navigation, Design System & Offline Strategy

---

## 1. Flutter Architecture Overview

The TeamSpot Flutter app follows **Feature-First Clean Architecture** with Riverpod for state management. The structure separates concerns into clear layers that mirror the backend's domain organization.

```
lib/
├── main.dart                  # Bootstrap: Firebase, Hive, env, Sentry
├── app.dart                   # TeamSpotApp widget (MaterialApp.router)
├── firebase_options.dart      # FlutterFire platform config
├── injection_container.dart   # Dependency injection setup
│
├── app/
│   ├── features/              # 25+ feature modules (one per domain)
│   │   ├── {feature}/
│   │   │   ├── presentation/  # Screens + widgets (UI layer)
│   │   │   └── usecases/      # Business orchestration logic
│   ├── domain/
│   │   ├── models/            # 28 data models (Dart classes)
│   │   └── repositories/      # Repository interfaces (30 repos)
│   ├── screens/               # Cross-feature screens (home, onboarding, splash)
│   └── components/            # Reusable UI components (design system)
│
├── core/
│   ├── apis/endpoints.dart    # All API paths (centralized, matches backend)
│   ├── auth/                  # Google + GitHub + biometric auth services
│   ├── config/                # BaseURL + environment dotenv keys
│   ├── constants/             # Colors, icons, sizes, strings, responsive
│   ├── db/hive.dart           # Local cache (Hive + TTL management)
│   ├── errors/                # Exceptions + Failures (Either pattern)
│   ├── network/               # ApiClient (Dio), interceptors, connectivity
│   ├── services/              # Storage, WebSocket, notifications
│   └── utils/                 # Formatters, validators, file picker, permissions
│
├── router/app_router.dart     # GoRouter: all routes + auth guard + deep links
├── store/                     # Riverpod providers (one per feature domain)
└── theme/                     # Light + dark Material 3 themes
```

---

## 2. State Management: Riverpod 2.6

### Architecture Decision: Why Riverpod over Bloc/GetX/Provider

| Concern | Provider | Bloc | GetX | **Riverpod** |
|---------|----------|------|------|-------------|
| Type safety | Partial | Full | Partial | **Full** |
| Testability | Medium | High | Low | **High** |
| Compile-time safety | No | Partial | No | **Yes** |
| Auto-dispose | Manual | Manual | Manual | **Built-in** |
| Async state | Complex | Complex | Messy | **Elegant** |
| Dependency injection | External | External | Built-in | **Built-in** |

Riverpod's `ref.watch` / `ref.read` pattern provides reactive data flow with no widget tree coupling. Providers auto-dispose when no widget watches them, preventing memory leaks.

### Provider Pattern

> **See** [`Flutter_Realtime_Workspace/lib/store`](../Flutter_Realtime_Workspace/lib/store) — Riverpod providers — one `StateNotifier` per domain under `lib/store/`

### Repository Provider Pattern

> **See** [`Flutter_Realtime_Workspace/lib/store`](../Flutter_Realtime_Workspace/lib/store) — Riverpod providers — one `StateNotifier` per domain under `lib/store/`

---

## 3. Navigation: GoRouter 16.1

### Route Structure

> **See** [`Backend_Realtime_Workspace/modules/auth`](../Backend_Realtime_Workspace/modules/auth) — Auth module — social sign-in, refresh token, logout

### Auth Guard Logic

> **See** [`Backend_Realtime_Workspace/modules/auth`](../Backend_Realtime_Workspace/modules/auth) — Auth module — social sign-in, refresh token, logout

---

## 4. Network Layer: Dio + Interceptors

> **See** [`Backend_Realtime_Workspace/core/structures/index.js`](../Backend_Realtime_Workspace/core/structures/index.js) — `LRUCache`, `PriorityQueue`, `SlidingWindow`, `BloomFilter`, `Trie`, `CircuitBreaker`

### Auth Interceptor (Token Auto-Refresh)

> **See** [`Backend_Realtime_Workspace/modules/auth`](../Backend_Realtime_Workspace/modules/auth) — Auth module — social sign-in, refresh token, logout

---

## 5. Local Storage Architecture (Hive + TTL)

> **See** [`Backend_Realtime_Workspace/core/structures/index.js`](../Backend_Realtime_Workspace/core/structures/index.js) — `LRUCache`, `PriorityQueue`, `SlidingWindow`, `BloomFilter`, `Trie`, `CircuitBreaker`

---

## 6. Real-Time: Socket.IO Client

> **See** [`Backend_Realtime_Workspace/middlewares/validate.middleware.js`](../Backend_Realtime_Workspace/middlewares/validate.middleware.js) — `validateRequest()` — Joi schema validation middleware factory

---

## 7. Design System

### Color System (`core/constants/colors.dart`)
> **See** [`Flutter_Realtime_Workspace/lib/`](../Flutter_Realtime_Workspace/lib/) — Flutter source

### Typography: Poppins font family
- 300 Light, 400 Regular, 500 Medium (all weights loaded from `assets/fonts/`)
- Material 3 TextTheme mapped to Poppins via `google_fonts` package

### Responsive Layout
> **See** [`Flutter_Realtime_Workspace/lib/`](../Flutter_Realtime_Workspace/lib/) — Flutter source

---

## 8. Offline-First Strategy

```
Level 1 — Read cache (Hive TTL):
  - User profile: TTL 5 min → show stale on network error
  - Project list: TTL 2 min → show stale
  - Notifications: TTL 30s → show stale badge count

Level 2 — Connectivity interception:
  - ConnectivityService streams network state changes
  - ConnectivityToast shows "You're offline" banner automatically
  - API requests that require network show graceful error (not crash)

Level 3 — Queue pending writes (future):
  - Task status changes while offline → queued to Hive
  - On reconnect → replay queue to API
  - Uses idempotency key to prevent duplicate writes

What is NOT available offline:
  - AI assistant (requires API + LLM)
  - Video meetings (requires WebRTC)
  - Real-time channel messages
  - File uploads
```

---

## 9. Platform Strategy

TeamSpot Flutter targets: **iOS, Android, Web, macOS, Windows, Linux**

```
Platform-specific handling:
  iOS/macOS:
    - Biometric: Face ID / Touch ID via local_auth
    - Notifications: APNs (requires Apple developer account)
    - CallKit: incoming call UI native integration
    - Privacy: permission dialogs follow iOS guidelines

  Android:
    - Biometric: Fingerprint / Face unlock
    - Notifications: FCM push notifications (full support)
    - Background messaging: firebaseMessagingBackgroundHandler

  Web:
    - No biometric (browser API pending)
    - Service Worker for push notifications (future)
    - Responsive layout (SResponsive breakpoints)

  Desktop (macOS/Windows/Linux):
    - Side navigation (GlassSideBar) replaces bottom nav
    - Keyboard shortcuts
    - Multi-window support (future)
```

---

## 10. Security: Secrets & Token Handling

> **See** [`Backend_Realtime_Workspace/agent/knowledge/rag-pipeline.js`](../Backend_Realtime_Workspace/agent/knowledge/rag-pipeline.js) — `RagPipeline` — document chunking → embedding → Qdrant upsert → retrieval

Keys stored in `FlutterSecureStorage`:
- Backend JWT access token
- Firebase refresh credential cache
- 2FA secret (if TOTP enabled)

**Never** stored in `GetStorage` / `SharedPreferences`:
- Any token, password, or secret
- PII beyond display name (settings only)
