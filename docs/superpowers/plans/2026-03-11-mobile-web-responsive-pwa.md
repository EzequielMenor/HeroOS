# Mobile Web Responsive + PWA Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make HeroOS look and work correctly in mobile browsers (iOS Safari / Android Chrome) and enable installation as a PWA.

**Architecture:** Add a third `isMobileWeb` breakpoint (kIsWeb + <900px) alongside the existing native and desktop-web layouts. Fix the browser chrome color mismatch with `theme-color`. Add a compact RpgHud strip replacing the AppBar in mobile web. Create an `InstallBanner` widget that detects standalone mode and guides PWA installation.

**Tech Stack:** Flutter web, `package:web` (JS interop for standalone detection), `shared_preferences`, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-03-11-mobile-web-responsive-pwa-design.md`

---

## Chunk 1: Foundation — responsive utils, web files, RpgHud strip

### Task 1: Fix `responsive.dart` — add `isMobileWeb` and `isDesktopWeb`

**Files:**
- Modify: `lib/core/utils/responsive.dart`

- [ ] **Step 1: Replace file contents**

  Current file has:
  ```dart
  import 'package:flutter/material.dart';

  const double kWebBreakpoint = 900.0;

  extension ResponsiveContext on BuildContext {
    double get screenWidth => MediaQuery.of(this).size.width;
    bool get isWeb => screenWidth >= kWebBreakpoint;
  }
  ```

  Replace with:
  ```dart
  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'package:flutter/material.dart';

  const double kWebBreakpoint = 900.0;

  extension ResponsiveContext on BuildContext {
    double get screenWidth => MediaQuery.of(this).size.width;

    /// Desktop web: running in a browser at ≥900px wide.
    /// Fixed: now includes kIsWeb guard (previously missing — wide iPads triggered web layout).
    bool get isWeb => kIsWeb && screenWidth >= kWebBreakpoint;

    /// Mobile web: running in a browser at <900px (phone/tablet browser).
    bool get isMobileWeb => kIsWeb && screenWidth < kWebBreakpoint;

    /// Desktop web: explicit alias for clarity alongside isMobileWeb.
    bool get isDesktopWeb => kIsWeb && screenWidth >= kWebBreakpoint;
  }
  ```

  Note: `kIsWeb` is already available via `package:flutter/material.dart`, but the explicit `foundation` import documents the source.

- [ ] **Step 2: Verify no compile errors**

  ```bash
  cd heroos && flutter analyze lib/core/utils/responsive.dart
  ```
  Expected: `No issues found!`

- [ ] **Step 3: Commit**

  ```bash
  git add lib/core/utils/responsive.dart
  git commit -m "feat: add isMobileWeb/isDesktopWeb breakpoints, fix isWeb kIsWeb guard"
  ```

---

### Task 2: Update `web/index.html` and `web/manifest.json`

**Files:**
- Modify: `web/index.html`
- Modify: `web/manifest.json`

- [ ] **Step 1: Add `theme-color` meta tag to index.html**

  In `web/index.html`, insert after `<meta charset="UTF-8">` (the first meta in `<head>`):
  ```html
  <meta name="theme-color" content="#0d0d1a">
  ```

  The top of `<head>` should look like:
  ```html
  <meta charset="UTF-8">
  <meta name="theme-color" content="#0d0d1a">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A new Flutter project.">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  ```

- [ ] **Step 2: Update manifest.json**

  Replace the entire `web/manifest.json` with:
  ```json
  {
      "name": "HeroOS",
      "short_name": "HeroOS",
      "start_url": ".",
      "display": "standalone",
      "background_color": "#0d0d1a",
      "theme_color": "#0d0d1a",
      "description": "Tu vida como RPG",
      "orientation": "portrait-primary",
      "prefer_related_applications": false,
      "icons": [
          {
              "src": "icons/Icon-192.png",
              "sizes": "192x192",
              "type": "image/png"
          },
          {
              "src": "icons/Icon-512.png",
              "sizes": "512x512",
              "type": "image/png"
          },
          {
              "src": "icons/Icon-maskable-192.png",
              "sizes": "192x192",
              "type": "image/png",
              "purpose": "maskable"
          },
          {
              "src": "icons/Icon-maskable-512.png",
              "sizes": "512x512",
              "type": "image/png",
              "purpose": "maskable"
          }
      ]
  }
  ```

- [ ] **Step 3: Commit**

  ```bash
  git add web/index.html web/manifest.json
  git commit -m "feat: add theme-color meta, fix manifest name and colors for PWA"
  ```

---

### Task 3: Add `shared_preferences` and `web` to `pubspec.yaml`

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add dependencies**

  In `pubspec.yaml`, under `dependencies:`, add after `http: ^1.2.0`:
  ```yaml
  shared_preferences: ^2.3.0
  web: ^1.0.0  # promote from transitive to direct dependency; used for JS interop in InstallBanner
  ```

- [ ] **Step 2: Fetch packages**

  ```bash
  cd heroos && flutter pub get
  ```
  Expected: `Got dependencies!`

- [ ] **Step 3: Commit**

  ```bash
  git add pubspec.yaml pubspec.lock
  git commit -m "chore: add shared_preferences and web as direct dependencies"
  ```

---

### Task 4: Add `strip: true` mode to `RpgHud`

**Files:**
- Modify: `lib/presentation/widgets/rpg_hud.dart`

The existing widget has `compact: true` (a vertical multi-row layout for the 260px sidebar). We need a new `strip: true` mode: a single 44px-tall horizontal row to replace the AppBar in mobile web.

Apply all changes in this task as one edit to avoid a mid-task compile failure (Step 1 adds a `_buildStrip()` call in `build()`, Step 2 adds the method body — do both before analyzing).

- [ ] **Step 1: Add `strip` parameter to the class and update `build()`**

  Update the class declaration and `build()` method:

  ```dart
  class RpgHud extends StatelessWidget {
    final ProfileEntity profile;
    final bool compact;
    final bool strip;

    const RpgHud({
      super.key,
      required this.profile,
      this.compact = false,
      this.strip = false,
    });

    @override
    Widget build(BuildContext context) {
      if (strip) return _buildStrip();
      if (compact) return _buildCompact();
      return _buildFull();
    }
  ```

- [ ] **Step 2: Add `_buildStrip()` method after `_buildCompact()`**

  Insert this method between `_buildCompact()` and `_avatarChild()`:

  ```dart
  /// Strip mode for mobile web: 44px horizontal bar replacing the AppBar.
  /// Shows level badge | XP+HP bars stacked | XP total.
  Widget _buildStrip() {
    final hpColor = profile.currentHp < profile.maxHp * 0.3
        ? AppColors.danger
        : AppColors.habits;

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.rpg.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.rpg.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Lvl ${profile.level}',
              style: const TextStyle(
                color: AppColors.rpg,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // XP + HP bars stacked
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: profile.xpProgress,
                    backgroundColor: AppColors.divider.withValues(alpha: 0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.rpg),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: profile.hpProgress,
                    backgroundColor: AppColors.divider.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // XP total
          Text(
            '${profile.currentXp} XP',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  ```

- [ ] **Step 3: Verify no compile errors**

  ```bash
  cd heroos && flutter analyze lib/presentation/widgets/rpg_hud.dart
  ```
  Expected: `No issues found!`

- [ ] **Step 4: Commit**

  ```bash
  git add lib/presentation/widgets/rpg_hud.dart
  git commit -m "feat: add strip:true mode to RpgHud for mobile web AppBar replacement"
  ```

---

## Chunk 2: Screens + PWA

### Task 5: Update `DashboardScreen` for mobile web

**Files:**
- Modify: `lib/presentation/screens/dashboard_screen.dart`

Dashboard is the only screen with an AppBar in native mobile (`Scaffold(appBar: AppBar(...))`). All other screens do not have AppBars — see Task 6.

- [ ] **Step 1: Update `build()` — rename isWeb + add isMobileWeb branch**

  Replace the `build()` method (lines ~290-297):
  ```dart
  @override
  Widget build(BuildContext context) {
    final statsVm = context.watch<StatsViewModel>();

    if (context.isDesktopWeb) {
      return _buildWebLayout(statsVm);
    }
    if (context.isMobileWeb) {
      return _buildMobileWebLayout(statsVm);
    }
    return _buildMobileLayout(statsVm);
  }
  ```

- [ ] **Step 3: Add `_buildMobileWebLayout()` method**

  Insert **before** the class closing brace — i.e., after `_buildMobileLayout()`'s closing `}` (line ~365) but before the `_DashboardScreenState` class closing `}` (line ~366). Inserting after line 366 would place the method outside the class and cause a compile error.

  ```dart
  // ── MOBILE WEB LAYOUT ────────────────────────────────────────────────────────

  Widget _buildMobileWebLayout(StatsViewModel statsVm) {
    return Scaffold(
      body: SafeArea(
        bottom: false, // BottomNav has its own SafeArea
        child: Column(
          children: [
            // Compact strip replaces AppBar (hidden on Profile tab)
            if (_currentIndex != 4)
              if (statsVm.isLoading)
                const LinearProgressIndicator(
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.rpg),
                )
              else if (statsVm.profile != null)
                RpgHud(profile: statsVm.profile!, strip: true),

            // PWA install hint (self-hides when not applicable)
            const InstallBanner(),

            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          items: _tabs
              .map(
                (t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  label: t.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
  ```

- [ ] **Step 4: Verify no compile errors**

  ```bash
  cd heroos && flutter analyze lib/presentation/screens/dashboard_screen.dart
  ```
  Expected: `No issues found!` (The `install_banner.dart` import is added in Task 7 Step 1, before this analyze passes cleanly)

- [ ] **Step 5: Visual check in Chrome**

  ```bash
  flutter run -d chrome
  ```
  - Resize to 600px → verify: compact strip visible, no AppBar, BottomNav present and not clipped
  - Resize to 1200px → verify: sidebar layout unchanged
  - Native mobile simulator → verify: original AppBar still present

- [ ] **Step 6: Commit**

  ```bash
  git add lib/presentation/screens/dashboard_screen.dart
  git commit -m "feat: add isMobileWeb layout to DashboardScreen (strip + SafeArea BottomNav)"
  ```

---

### Task 6: Rename `context.isWeb` → `context.isDesktopWeb` in remaining 5 screens

**Files:**
- Modify: `lib/presentation/screens/habits_screen.dart`
- Modify: `lib/presentation/screens/tasks_screen.dart`
- Modify: `lib/presentation/screens/finance_screen.dart`
- Modify: `lib/presentation/screens/sleep_screen.dart`
- Modify: `lib/presentation/screens/profile_screen.dart`

**Important context:** None of these 5 screens have an AppBar in their mobile/mobile-web Scaffold — Dashboard is the only screen with one. The change here is purely renaming `context.isWeb` to `context.isDesktopWeb` so the desktop split-panel layout only activates on desktop, not on a narrow browser window.

Screen-by-screen notes:
- **habits_screen.dart**: `context.isWeb` at line 38 (layout branch). Rename only.
- **tasks_screen.dart**: `context.isWeb` at lines 62 (layout branch) AND 403 (`(context.isWeb || _showCalendar) ? _selectedDay : null`). The line 403 usage correctly pre-assigns `_selectedDay` when the split-panel calendar is always visible — rename to `isDesktopWeb` preserves this intent.
- **finance_screen.dart**: `context.isWeb` at line 75 (inside `_buildContent`, controls Row vs single-column). Rename only.
- **sleep_screen.dart**: `context.isWeb` at line 1374 (controls PieChart + BarChart side-by-side vs stacked). Rename only.
- **profile_screen.dart**: `context.isWeb` at line 131 (layout branch). Rename only. Also update bottom padding in `_buildMobileLayout()` to respect safe area — change `EdgeInsets.fromLTRB(16, 8, 16, 24)` to `EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewPadding.bottom + 16)` (or wrap `SingleChildScrollView` in `SafeArea(top: false)`).

- [ ] **Step 1: Update `habits_screen.dart`**

  Search and replace: `context.isWeb` → `context.isDesktopWeb` (1 occurrence, line 38).

  Verify:
  ```bash
  flutter analyze lib/presentation/screens/habits_screen.dart
  ```
  Expected: `No issues found!`

- [ ] **Step 2: Update `tasks_screen.dart`**

  Search and replace: `context.isWeb` → `context.isDesktopWeb` (2 occurrences: lines 62 and 403).

  Verify:
  ```bash
  flutter analyze lib/presentation/screens/tasks_screen.dart
  ```
  Expected: `No issues found!`

- [ ] **Step 3: Update `finance_screen.dart`**

  Search and replace: `context.isWeb` → `context.isDesktopWeb` (1 occurrence, line 75).

  Verify:
  ```bash
  flutter analyze lib/presentation/screens/finance_screen.dart
  ```
  Expected: `No issues found!`

- [ ] **Step 4: Update `sleep_screen.dart`**

  Search and replace: `context.isWeb` → `context.isDesktopWeb` (1 occurrence, line 1374).

  Verify:
  ```bash
  flutter analyze lib/presentation/screens/sleep_screen.dart
  ```
  Expected: `No issues found!`

- [ ] **Step 5: Update `profile_screen.dart`**

  a) Search and replace: `context.isWeb` → `context.isDesktopWeb` (1 occurrence, line 131).

  b) In `_buildMobileLayout()`, wrap `SingleChildScrollView` in `SafeArea(top: false)` to respect browser home indicator:
  ```dart
  // Before:
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    ...
  );

  // After:
  return SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      ...
    ),
  );
  ```

  Verify:
  ```bash
  flutter analyze lib/presentation/screens/profile_screen.dart
  ```
  Expected: `No issues found!`

- [ ] **Step 6: Full analyze + visual check**

  ```bash
  cd heroos && flutter analyze lib/
  ```
  Expected: `No issues found!`

  ```bash
  flutter run -d chrome
  ```
  Resize to 600px. Navigate through all 5 tabs and verify:
  - No unintended layout changes at <900px (should look same as native mobile, no split panels)
  - Desktop split panels still work at 1200px

- [ ] **Step 7: Commit**

  ```bash
  git add lib/presentation/screens/habits_screen.dart \
          lib/presentation/screens/tasks_screen.dart \
          lib/presentation/screens/finance_screen.dart \
          lib/presentation/screens/sleep_screen.dart \
          lib/presentation/screens/profile_screen.dart
  git commit -m "refactor: rename context.isWeb → isDesktopWeb in all content screens"
  ```

---

### Task 7: Create `InstallBanner` widget

**Files:**
- Create: `lib/presentation/widgets/install_banner.dart`

- [ ] **Step 1: Add import to `dashboard_screen.dart` and create widget file**

  First, add this import at the top of `lib/presentation/screens/dashboard_screen.dart`:
  ```dart
  import '../widgets/install_banner.dart';
  ```

  Then create `lib/presentation/widgets/install_banner.dart` with this content:

  ```dart
  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'package:flutter/material.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:web/web.dart' as web;

  import '../../core/theme/app_colors.dart';

  /// Banner that prompts the user to install HeroOS as a PWA.
  ///
  /// Shown only when:
  /// - Running on mobile web (kIsWeb + width < 900)
  /// - Not already in standalone/installed mode
  /// - Not previously dismissed by the user
  class InstallBanner extends StatefulWidget {
    const InstallBanner({super.key});

    @override
    State<InstallBanner> createState() => _InstallBannerState();
  }

  class _InstallBannerState extends State<InstallBanner> {
    bool _visible = false;
    static const _prefKey = 'pwa_banner_dismissed';

    @override
    void initState() {
      super.initState();
      if (kIsWeb) _checkShouldShow();
    }

    Future<void> _checkShouldShow() async {
      // Don't show if already running as installed PWA
      final isStandalone =
          web.window.matchMedia('(display-mode: standalone)').matches;
      if (isStandalone) return;

      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_prefKey) ?? false;
      if (!dismissed && mounted) {
        setState(() => _visible = true);
      }
    }

    Future<void> _dismiss() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
      if (mounted) setState(() => _visible = false);
    }

    void _showInstallInstructions() {
      final ua = web.window.navigator.userAgent.toLowerCase();
      final isIos = ua.contains('iphone') || ua.contains('ipad');

      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Instalar HeroOS',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            isIos
                ? 'Toca el botón Compartir (□↑) en Safari\n→ "Añadir a inicio"\n\nAbrirá sin barras del navegador.'
                : 'Abre el menú del navegador (⋮)\n→ "Instalar app" o "Añadir a inicio"\n\nAbrirá sin barras del navegador.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(color: AppColors.rpg),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _dismiss();
              },
              child: const Text(
                'No mostrar más',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      if (!_visible) return const SizedBox.shrink();

      return Container(
        height: 40,
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(
              Icons.install_mobile_outlined,
              color: AppColors.rpg,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _showInstallInstructions,
                child: const Text(
                  'Instala HeroOS para la experiencia completa →',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            GestureDetector(
              onTap: _dismiss,
              child: const Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 2: Verify no compile errors**

  ```bash
  cd heroos && flutter analyze lib/presentation/widgets/install_banner.dart
  ```
  Expected: `No issues found!`

- [ ] **Step 3: Full analyze**

  ```bash
  flutter analyze lib/
  ```
  Expected: `No issues found!` (dashboard_screen.dart import of InstallBanner now resolves)

- [ ] **Step 4: Visual check in Chrome at <900px**

  ```bash
  flutter run -d chrome
  ```
  At <900px: banner should appear below the RpgHud strip. Click the banner text → dialog appears with instructions. Click "No mostrar más" → banner disappears. Refresh → banner stays hidden (SharedPreferences persisted).

- [ ] **Step 5: Commit**

  ```bash
  git add lib/presentation/widgets/install_banner.dart \
          lib/presentation/screens/dashboard_screen.dart
  git commit -m "feat: add InstallBanner with standalone check, wire into mobile web layout"
  ```

---

### Task 8: Update `deploy.yml` with `--pwa-strategy offline-first`

**Files:**
- Modify: `.github/workflows/deploy.yml`

- [ ] **Step 1: Update the build command**

  In `.github/workflows/deploy.yml` line 28, change:
  ```yaml
  run: flutter build web --release --base-href /HeroOS/ --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }}
  ```
  To:
  ```yaml
  run: flutter build web --release --pwa-strategy offline-first --base-href /HeroOS/ --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }}
  ```

- [ ] **Step 2: Verify service worker is generated locally**

  Run a local build (the missing `--dart-define` will use an empty string for `GROQ_API_KEY`, which is fine for verifying the service worker output):
  ```bash
  cd heroos && flutter build web --release --pwa-strategy offline-first --base-href /HeroOS/
  ls build/web/flutter_service_worker.js
  ```
  Expected: file exists. If missing, check Flutter version supports `--pwa-strategy` (requires Flutter 2.10+).

- [ ] **Step 3: Commit**

  ```bash
  git add .github/workflows/deploy.yml
  git commit -m "feat: enable offline-first PWA service worker in GitHub Pages deploy"
  ```

---

## Verification Checklist

- [ ] `flutter analyze lib/` → `No issues found!`
- [ ] Chrome DevTools at 600px: compact RpgHud strip + no AppBar + BottomNav visible and not clipped
- [ ] Chrome at 1200px: sidebar layout identical to before (no regression)
- [ ] Native mobile simulator: AppBar still present in Dashboard, no regressions
- [ ] `build/web/flutter_service_worker.js` exists after `flutter build web --pwa-strategy offline-first`
- [ ] Real Android Chrome: URL bar turns dark (`#0d0d1a`) — verify on real device or via Chrome remote debugging (DevTools emulation does NOT reflect `theme-color`)
- [ ] iOS Safari (real device): URL bar turns dark, install banner visible, tap → instructions dialog appears
- [ ] iOS Safari: install PWA → open from home screen → no Safari bar, install banner does NOT appear
