import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/notes_screen.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/finance_viewmodel.dart';
import 'presentation/viewmodels/habits_viewmodel.dart';
import 'presentation/viewmodels/tasks_viewmodel.dart';
import 'presentation/viewmodels/sleep_viewmodel.dart';
import 'presentation/viewmodels/goals_viewmodel.dart';
import 'presentation/viewmodels/profile_viewmodel.dart';
import 'presentation/viewmodels/notes_viewmodel.dart';
import 'presentation/viewmodels/quick_capture_viewmodel.dart';


/// — Configuración del router —
/// redirect: redirige a /login si no hay sesión, a /dashboard si la hay.
GoRouter _buildRouter(AuthViewModel authVm) => GoRouter(
  initialLocation: AppStrings.routeSplash,
  // Se re-evalúa cada vez que authVm notifica cambios
  refreshListenable: authVm,
  redirect: (context, state) {
    final isLoggedIn = authVm.isAuthenticated;
    final isOnLogin = state.matchedLocation == AppStrings.routeLogin;
    final isOnSplash = state.matchedLocation == AppStrings.routeSplash;

    // Si no está logueado y no está en login → mandar a login
    if (!isLoggedIn && !isOnLogin) return AppStrings.routeLogin;
    // Si está logueado y sigue en login o splash → mandar a dashboard
    if (isLoggedIn && (isOnLogin || isOnSplash)) {
      return AppStrings.routeDashboard;
    }
    return null; // no redirect
  },
  routes: [
    GoRoute(
      path: AppStrings.routeSplash,
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: AppStrings.routeLogin,
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: AppStrings.routeDashboard,
      builder: (context, state) => DashboardScreen(),
    ),
    GoRoute(
      path: AppStrings.routeNotes,
      builder: (context, state) => NotesScreen(),
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es');

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(HeroOSApp());
}

class HeroOSApp extends StatefulWidget {
  const HeroOSApp({super.key});

  @override
  State<HeroOSApp> createState() => _HeroOSAppState();
}

class _HeroOSAppState extends State<HeroOSApp> {
  final _authVm = AuthViewModel();
  final _goalsVm = GoalsViewModel();
  final _profileVm = ProfileViewModel();
  late final NotesViewModel _notesVm;
  late final HabitsViewModel _habitsVm;
  late final TasksViewModel _tasksVm;
  late final FinanceViewModel _financeVm;
  late final SleepViewModel _sleepVm;
  late final QuickCaptureViewModel _quickCaptureVm;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _notesVm = NotesViewModel();
    _habitsVm = HabitsViewModel();
    _tasksVm = TasksViewModel();
    _financeVm = FinanceViewModel();
    _sleepVm = SleepViewModel();
    _quickCaptureVm = QuickCaptureViewModel();
    _router = _buildRouter(_authVm);
  }

  @override
  void dispose() {
    _authVm.dispose();
    _habitsVm.dispose();
    _tasksVm.dispose();
    _financeVm.dispose();
    _sleepVm.dispose();
    _goalsVm.dispose();
    _profileVm.dispose();
    _notesVm.dispose();
    _quickCaptureVm.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authVm),
        ChangeNotifierProvider.value(value: _habitsVm),
        ChangeNotifierProvider.value(value: _tasksVm),
        ChangeNotifierProvider.value(value: _financeVm),
        ChangeNotifierProvider.value(value: _sleepVm),
        ChangeNotifierProvider.value(value: _goalsVm),
        ChangeNotifierProvider.value(value: _profileVm),
        ChangeNotifierProvider.value(value: _notesVm),
        ChangeNotifierProvider.value(value: _quickCaptureVm),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppColors.themeMode,
        builder: (context, mode, child) {
          return MaterialApp.router(
            scrollBehavior: AppScrollBehavior(),
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

/// Enables mouse and trackpad drag gestures for scrollable widgets on web/desktop.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
