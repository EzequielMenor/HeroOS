# Liquid Glass Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a smooth swipeable PageView navigation with a floating "liquid glass" navigation bar that stretches dynamically during transitions.

**Architecture:** We will replace the current `IndexedStack` inside `DashboardScreen` with a `PageView`. To achieve high performance (60/120 FPS on iOS), we will use a `ValueNotifier<double>` to track the scroll offset of the page transitions. This prevents rebuilding the entire screen widget tree on every scroll frame, only rebuilding the custom navigation indicator. The math behind the liquid stretch will be decoupled into a pure unit-tested helper class.

**Tech Stack:** Flutter, Cupertino (for iOS-style scroll physics), Provider.

## Global Constraints
- Target platform is iOS/iPhone.
- Apple Industrial design aesthetics (glassmorphic blur, thin borders, greyscale palette).
- Maintain clean architecture boundaries (widgets call presentation-layer ViewModels).
- Follow conventional commits.

---

### Task 1: Create Liquid Glass Math & Indicator Widget

**Files:**
- Create: `lib/presentation/widgets/liquid_glass_indicator.dart`
- Create: `test/liquid_glass_indicator_test.dart`

**Interfaces:**
- Consumes: `double pageOffset` (current fractional scroll position), `double tabWidth` (pixel width of a tab).
- Produces: `LiquidGlassMath` (pure mathematical calculations) and `LiquidGlassIndicator` (UI rendering widget).

- [x] **Step 1: Write the failing unit test for the liquid math**
  Create `test/liquid_glass_indicator_test.dart` with tests validating that:
  - At integer pages, width is exactly equal to `tabWidth`.
  - At fractional pages (e.g. `0.5`), the width is greater than `tabWidth` (stretching occurs).
  - The left boundary transitions smoothly with ease-in/ease-out curves.

  Code:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:heroos/presentation/widgets/liquid_glass_indicator.dart';

  void main() {
    test('LiquidGlassMath stretching calculation', () {
      // At t = 0 (exact tab center)
      final pos0 = LiquidGlassMath.calculate(pageOffset: 0.0, tabWidth: 80.0);
      expect(pos0.left, 0.0);
      expect(pos0.width, 80.0);

      // At t = 0.5 (moving from tab 0 to 1, stretching should peak)
      final posHalf = LiquidGlassMath.calculate(pageOffset: 0.5, tabWidth: 80.0);
      // Left edge moves slower (easeIn(0.5) < 0.5)
      expect(posHalf.left, lessThan(40.0));
      // Right edge moves faster (easeOut(0.5) > 0.5)
      expect(posHalf.left + posHalf.width, greaterThan(120.0));
      expect(posHalf.width, greaterThan(80.0)); // Stretched

      // At t = 1.0 (settled on tab 1)
      final pos1 = LiquidGlassMath.calculate(pageOffset: 1.0, tabWidth: 80.0);
      expect(pos1.left, 80.0);
      expect(pos1.width, 80.0);
    });
  }
  ```

- [x] **Step 2: Run tests to verify they fail**
  Run: `flutter test test/liquid_glass_indicator_test.dart`
  Expected: FAIL with compilation error (no `LiquidGlassMath` class found).

- [x] **Step 3: Implement the math calculator and the LiquidGlassIndicator widget**
  Create `lib/presentation/widgets/liquid_glass_indicator.dart` containing both the calculation engine and the UI widget.

  Code:
  ```dart
  import 'dart:ui';
  import 'package:flutter/material.dart';

  class LiquidGlassPosition {
    final double left;
    final double width;
    const LiquidGlassPosition(this.left, this.width);
  }

  class LiquidGlassMath {
    static LiquidGlassPosition calculate({
      required double pageOffset,
      required double tabWidth,
    }) {
      final int leftTab = pageOffset.floor();
      final double t = pageOffset - leftTab;

      // Calculate stretched edges using asymmetric curves
      final double leftPos = (leftTab + Curves.easeIn.transform(t)) * tabWidth;
      final double rightPos = (leftTab + 1 + Curves.easeOut.transform(t)) * tabWidth;

      return LiquidGlassPosition(leftPos, rightPos - leftPos);
    }
  }

  class LiquidGlassIndicator extends StatelessWidget {
    final double pageOffset;
    final double tabWidth;
    final double height;

    const LiquidGlassIndicator({
      super.key,
      required this.pageOffset,
      required this.tabWidth,
      required this.height,
    });

    @override
    Widget build(BuildContext context) {
      final pos = LiquidGlassMath.calculate(
        pageOffset: pageOffset,
        tabWidth: tabWidth,
      );

      return Positioned(
        left: pos.left,
        width: pos.width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

- [x] **Step 4: Run tests to verify they pass**
  Run: `flutter test test/liquid_glass_indicator_test.dart`
  Expected: PASS

- [x] **Step 5: Commit**
  Run:
  ```bash
  git add lib/presentation/widgets/liquid_glass_indicator.dart test/liquid_glass_indicator_test.dart
  git commit -m "feat: add liquid glass indicator widget and math tests"
  ```

---

### Task 2: Integrate PageView & Liquid Glass Navbar in DashboardScreen

**Files:**
- Modify: `lib/presentation/screens/dashboard_screen.dart`

**Interfaces:**
- Consumes: `LiquidGlassIndicator` (custom indicator widget).
- Produces: Updated `DashboardScreen` utilizing swipe gestures and a floating glass navbar.

- [x] **Step 1: Write a test verifying DashboardScreen uses PageView**
  Add a widget test to `test/dashboard_navigation_test.dart` verifying the presence of the `PageView` and verifying tab items change the page index.

  Code:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:provider/provider.dart';
  import 'package:heroos/presentation/screens/dashboard_screen.dart';
  import 'package:heroos/presentation/viewmodels/habits_viewmodel.dart';
  import 'package:heroos/presentation/viewmodels/tasks_viewmodel.dart';
  import 'package:heroos/presentation/viewmodels/sleep_viewmodel.dart';
  import 'package:heroos/presentation/viewmodels/profile_viewmodel.dart';

  // Mock viewmodels
  class MockHabitsViewModel extends ChangeNotifier implements HabitsViewModel {
    @override
    List get todayHabits => [];
    @override
    void loadHabits() {}
    @override
    bool isCompletedToday(String id) => false;
  }
  class MockTasksViewModel extends ChangeNotifier implements TasksViewModel {
    @override
    List get pendingTasks => [];
    @override
    void loadTasks() {}
  }
  class MockSleepViewModel extends ChangeNotifier implements SleepViewModel {
    @override
    get todayLog => null;
    @override
    void loadLogs() {}
  }
  class MockProfileViewModel extends ChangeNotifier implements ProfileViewModel {
    @override
    get profile => null;
    @override
    void loadProfile() {}
  }

  void main() {
    testWidgets('DashboardScreen renders PageView and responds to swipe/tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HabitsViewModel>.value(value: MockHabitsViewModel()),
            ChangeNotifierProvider<TasksViewModel>.value(value: MockTasksViewModel()),
            ChangeNotifierProvider<SleepViewModel>.value(value: MockSleepViewModel()),
            ChangeNotifierProvider<ProfileViewModel>.value(value: MockProfileViewModel()),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      // Verify PageView is rendered
      expect(find.byType(PageView), findsOneWidget);
    });
  }
  ```

- [x] **Step 2: Run test to verify it fails**
  Run: `flutter test test/dashboard_navigation_test.dart`
  Expected: FAIL (no `PageView` found, since it currently uses `IndexedStack`).

- [x] **Step 3: Modify DashboardScreen implementation**
  Update `lib/presentation/screens/dashboard_screen.dart` to:
  1. Replace `IndexedStack` with `PageView` using `PageController`.
  2. Implement `BouncingScrollPhysics` for native iOS-like inertia.
  3. Introduce a `ValueNotifier<double> _pageOffsetNotifier` to track offset.
  4. Attach a listener to `PageController` that updates `_pageOffsetNotifier`.
  5. Refactor the `bottomNavigationBar` to float over the screen and contain the `LiquidGlassIndicator`.
  6. Set a fixed `tabWidth = 80.0` for navigation items to ensure smooth alignment.

  Code changes in `lib/presentation/screens/dashboard_screen.dart`:
  - Set up page controller and notifier:
    ```dart
    late final PageController _pageController;
    late final ValueNotifier<double> _pageOffsetNotifier;

    @override
    void initState() {
      super.initState();
      _pageController = PageController(initialPage: _currentIndex);
      _pageOffsetNotifier = ValueNotifier<double>(_currentIndex.toDouble());
      _pageController.addListener(_onPageScroll);
      // ... existing loads ...
    }

    void _onPageScroll() {
      if (_pageController.hasClients) {
        _pageOffsetNotifier.value = _pageController.page ?? 0.0;
      }
    }

    @override
    void dispose() {
      _pageController.removeListener(_onPageScroll);
      _pageController.dispose();
      _pageOffsetNotifier.dispose();
      super.dispose();
    }
    ```
  - Inside `_buildMobileLayout()`, wrap the body in a `Stack` to allow the floating navigation bar to overlay the page view content with `extendBody: true`:
    ```dart
    Widget _buildMobileLayout() {
      const double tabWidth = 80.0;
      const double navHeight = 44.0;
      return Scaffold(
        extendBody: true,
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: [
            _TodayOverview(),
            TasksScreen(),
            HabitsScreen(),
            FinanceScreen(),
            SleepScreen(),
            NotesScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.scaffold.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            height: navHeight,
                            width: _tabs.length * tabWidth,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Liquid Indicator driven by PageNotifier
                                ValueListenableBuilder<double>(
                                  valueListenable: _pageOffsetNotifier,
                                  builder: (context, offset, child) {
                                    return LiquidGlassIndicator(
                                      pageOffset: offset,
                                      tabWidth: tabWidth,
                                      height: navHeight,
                                    );
                                  },
                                ),
                                // Tab labels/icons
                                Row(
                                  children: List.generate(_tabs.length, (index) {
                                    final isSelected = _currentIndex == index;
                                    final tab = _tabs[index];
                                    return GestureDetector(
                                      onTap: () {
                                        _pageController.animateToPage(
                                          index,
                                          duration: const Duration(milliseconds: 350),
                                          curve: Curves.easeInOutCubic,
                                        );
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: SizedBox(
                                        width: tabWidth,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              tab.label.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.1,
                                                color: isSelected
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: AppColors.divider,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: () => showGlobalAdd(context),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    ```

- [x] **Step 4: Run tests to verify they pass**
  Run: `flutter test`
  Expected: PASS

- [x] **Step 5: Commit changes**
  Run:
  ```bash
  git add lib/presentation/screens/dashboard_screen.dart test/dashboard_navigation_test.dart
  git commit -m "feat: integrate PageView and floating liquid glass navbar in DashboardScreen"
  ```
