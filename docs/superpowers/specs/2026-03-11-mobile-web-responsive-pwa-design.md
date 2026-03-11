# Mobile Web Responsive + PWA — Design Spec
**Tickets:** EZE-143, EZE-144
**Date:** 2026-03-11

## Context

HeroOS is a Flutter web app accessed from mobile browsers (primarily iOS Safari). Currently, the app only has two layouts: native mobile (<900px) and desktop web (≥900px). When opened in a mobile browser, the native layout (AppBar + BottomNav) is used, but the browser's own UI chrome (URL bar top, toolbar bottom) overlaps the app content. The BottomNav is hidden behind Safari's bottom toolbar, and there's a visual clash between the white/gray browser chrome and the dark app theme.

The goal is to:
1. Make the browser chrome blend with the app using `theme-color` (EZE-143)
2. Create a proper mobile web layout without AppBar and with safe-area padding (EZE-143)
3. Complete the PWA so users can install it and get a full-screen experience without browser chrome (EZE-144)

## Design

### Breakpoints (responsive.dart)

`kIsWeb` is from `package:flutter/foundation.dart`, already re-exported by the existing `package:flutter/material.dart` import — no new import needed.

The current `isWeb` has no `kIsWeb` guard, which means on a wide native device (e.g. iPad landscape) it incorrectly triggers the web sidebar layout. Fix this as part of this ticket:

```dart
// Fix existing (was: screenWidth >= kWebBreakpoint — no kIsWeb guard)
bool get isWeb => kIsWeb && screenWidth >= kWebBreakpoint;

// New
bool get isMobileWeb => kIsWeb && screenWidth < kWebBreakpoint;
bool get isDesktopWeb => kIsWeb && screenWidth >= kWebBreakpoint;
```

All six existing `context.isWeb` call sites in screens are migrated to `context.isDesktopWeb` in the same step (they are equivalent after the fix, but explicit naming improves clarity).

### Web Files (index.html + manifest.json)

**index.html — add inside `<head>`, after the charset meta:**
```html
<meta name="theme-color" content="#0d0d1a">
```
This colors the Safari/Chrome URL bar to match the app background. Combined with the existing `viewport-fit=cover` and `apple-mobile-web-app-status-bar-style: black-translucent`, the browser chrome blends with the app.

**manifest.json — update:**
- `name`: `"HeroOS"` (was `"heroos"`)
- `short_name`: `"HeroOS"`
- `description`: `"Tu vida como RPG"`
- `theme_color`: `"#0d0d1a"` (match index.html, was `"#1a1a2e"`)
- `background_color`: `"#0d0d1a"` (match app scaffold, was `"#1a1a2e"` — avoids color flash on PWA launch)

### Mobile Web Layout (EZE-143)

When `context.isMobileWeb`:

**Dashboard:**
- No `AppBar`
- RpgHud replaced by a compact horizontal **strip** (~44px tall): `[Level badge] [XP bar / HP bar stacked] [XP total]`
- `BottomNavigationBar` wrapped in `SafeArea(bottom: true)` to respect browser home indicator
- Same `IndexedStack` content as native mobile

**All other screens (habits, tasks, finance, sleep, profile):**
- No `AppBar`
- Single-column layout (same as native mobile; split panels remain desktop-only)
- `SafeArea` bottom padding on scroll views / lists

**RpgHud widget — new `strip: true` parameter:**

The existing `compact: true` mode is a multi-row vertical layout designed for the 260px sidebar — it is not a horizontal strip. A new `strip: true` parameter and `_buildStrip()` method must be added to `rpg_hud.dart`:
- Layout: `Row` — level badge on left, XP+HP progress bars (stacked) in center, XP total on right
- Height: 44px, full width
- Background: `AppColors.surface` with bottom border `AppColors.divider`

### PWA (EZE-144)

**Service Worker:**
- Flutter generates `flutter_service_worker.js` automatically with `flutter build web --pwa-strategy offline-first`
- Update the GitHub Actions deploy workflow to use this flag
- Offline behavior is out of scope for this ticket — Supabase API calls will fail gracefully via existing error handling; the app shell will load from cache

**Install Banner (`install_banner.dart`):**

Shown only when all conditions are true:
1. `context.isMobileWeb`
2. Not already in standalone/installed mode — check via JS interop: `window.navigator.standalone == true` (iOS) or the PWA display mode media query
3. Not previously dismissed — check `SharedPreferences` key `pwa_banner_dismissed`

**Detection strategy (simplified — avoids complex `beforeinstallprompt` interop):**
- Show the banner on all mobile web sessions that pass the above conditions
- Let the browser (Android Chrome) show its own native install prompt separately — no need to intercept `beforeinstallprompt`
- On iOS Safari: tapping the banner shows a `SnackBar` / `Dialog` with instructions: "Toca el botón Compartir → Añadir a inicio"
- On Android Chrome: tapping the banner shows: "Abre el menú del navegador → Instalar app"

**Standalone check via JS interop:**
```dart
// In install_banner.dart
import 'package:web/web.dart' as web;

bool get _isStandalone =>
    web.window.matchMedia('(display-mode: standalone)').matches;
```
This works on both iOS and Android without platform-specific hacks.

**pubspec.yaml — add direct dependency:**
```yaml
dependencies:
  shared_preferences: ^2.3.0
  web: ^1.0.0  # promote from transitive to direct dependency
```

**Banner UI:**
- Subtle top banner below the RpgHud strip (or below AppBar on non-mobile-web)
- `AppColors.surface` background, `AppColors.textSecondary` text, dismiss `×` button
- Height: ~48px

## Files Modified

| File | Change |
|------|--------|
| `lib/core/utils/responsive.dart` | Fix `isWeb` + add `isMobileWeb`, `isDesktopWeb` |
| `lib/presentation/screens/dashboard_screen.dart` | `isWeb` → `isDesktopWeb`; `isMobileWeb` branch: strip + SafeArea BottomNav |
| `lib/presentation/screens/habits_screen.dart` | `isWeb` → `isDesktopWeb`; remove AppBar on `isMobileWeb`; SafeArea scroll |
| `lib/presentation/screens/tasks_screen.dart` | `isWeb` → `isDesktopWeb`; remove AppBar on `isMobileWeb`; SafeArea scroll |
| `lib/presentation/screens/finance_screen.dart` | `isWeb` → `isDesktopWeb`; remove AppBar on `isMobileWeb`; SafeArea scroll |
| `lib/presentation/screens/sleep_screen.dart` | `isWeb` → `isDesktopWeb`; remove AppBar on `isMobileWeb`; SafeArea scroll |
| `lib/presentation/screens/profile_screen.dart` | `isWeb` → `isDesktopWeb`; remove AppBar on `isMobileWeb`; SafeArea scroll |
| `lib/presentation/widgets/rpg_hud.dart` | Add `strip: true` param + `_buildStrip()` method (44px horizontal) |
| `lib/presentation/widgets/install_banner.dart` | New widget (standalone check + SharedPreferences + platform instructions) |
| `web/index.html` | Add `<meta name="theme-color" content="#0d0d1a">` |
| `web/manifest.json` | Fix name, description, theme_color, background_color |
| `pubspec.yaml` | Add `shared_preferences`, verify `web` package |
| `.github/workflows/deploy.yml` | Add `--pwa-strategy offline-first` to build command |

## Verification

1. `flutter run -d chrome` → resize to <900px → verify: compact strip visible, no AppBar, BottomNav not clipped by browser toolbar
2. On a **real Android Chrome** session (or Chrome remote debugging): verify URL bar turns dark (`#0d0d1a`). DevTools mobile emulation does NOT reflect `theme-color` — must use real device or remote debugging.
3. Build with `--pwa-strategy offline-first` → verify `flutter_service_worker.js` present in `build/web/`
4. Android Chrome: visit app → browser shows native install prompt → install → open as PWA → verify no browser chrome, standalone mode
5. iOS Safari: visit app → install banner visible → tap → instructions shown → "Añadir a inicio" → open from home screen → verify no Safari bar (standalone mode)
6. iOS Safari installed PWA: verify install banner does NOT appear (standalone check working)
