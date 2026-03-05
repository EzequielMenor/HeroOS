import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/finance_viewmodel.dart';
import 'presentation/viewmodels/habits_viewmodel.dart';
import 'presentation/viewmodels/stats_viewmodel.dart';
import 'presentation/viewmodels/tasks_viewmodel.dart';
import 'presentation/viewmodels/sleep_viewmodel.dart';
import 'presentation/viewmodels/goals_viewmodel.dart';

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
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppStrings.routeLogin,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppStrings.routeDashboard,
      builder: (context, state) => const DashboardScreen(),
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

  runApp(const HeroOSApp());
}

class HeroOSApp extends StatefulWidget {
  const HeroOSApp({super.key});

  @override
  State<HeroOSApp> createState() => _HeroOSAppState();
}

class _HeroOSAppState extends State<HeroOSApp> {
  final _authVm = AuthViewModel();
  final _statsVm = StatsViewModel();
  final _goalsVm = GoalsViewModel();
  late final HabitsViewModel _habitsVm;
  late final TasksViewModel _tasksVm;
  late final FinanceViewModel _financeVm;
  late final SleepViewModel _sleepVm;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _habitsVm = HabitsViewModel(_statsVm);
    _tasksVm = TasksViewModel(_statsVm);
    _financeVm = FinanceViewModel(_statsVm);
    _sleepVm = SleepViewModel(_statsVm);
    _router = _buildRouter(_authVm);
  }

  @override
  void dispose() {
    _authVm.dispose();
    _statsVm.dispose();
    _habitsVm.dispose();
    _tasksVm.dispose();
    _financeVm.dispose();
    _sleepVm.dispose();
    _goalsVm.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authVm),
        ChangeNotifierProvider.value(value: _statsVm),
        ChangeNotifierProvider.value(value: _habitsVm),
        ChangeNotifierProvider.value(value: _tasksVm),
        ChangeNotifierProvider.value(value: _financeVm),
        ChangeNotifierProvider.value(value: _sleepVm),
        ChangeNotifierProvider.value(value: _goalsVm),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: _router,
      ),
    );
  }
}
