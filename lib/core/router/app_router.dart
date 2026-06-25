// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/vitals/screens/vitals_screen.dart';
import '../../features/vitals/screens/add_vital_screen.dart';
import '../../features/medicines/screens/medicines_screen.dart';
import '../../features/medicines/screens/add_medicine_screen.dart';
import '../../features/symptoms/screens/symptoms_screen.dart';
import '../../features/symptoms/screens/smart_symptom_screen.dart';
import '../../features/symptoms/screens/add_symptom_screen.dart';
import '../../features/doctor_visits/screens/doctor_visits_screen.dart';
import '../../features/doctor_visits/screens/add_visit_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/emergency/screens/emergency_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/getting_started_screen.dart';
import '../../features/ai_insights/screens/ai_insights_screen.dart';
import '../../features/ai_assistant/screens/ai_assistant_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/prescriptions/screens/prescriptions_screen.dart';
import '../../features/prescriptions/screens/add_prescription_screen.dart';
import '../../shared/utils/auth_helper.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: AuthHelper(),
    redirect: (context, state) {
      final auth = AuthHelper();
      final hasCompletedOnboarding = auth.onboardingCompleted;
      final acceptedPrecautions = auth.acceptedPrecautions;
      final isLoggedIn = auth.isLoggedIn;
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isGettingStarted = state.matchedLocation == '/getting-started';

      if (!hasCompletedOnboarding) {
        return isOnboarding ? null : '/onboarding';
      }

      if (isOnboarding) {
        return isLoggedIn
            ? '/'
            : (acceptedPrecautions ? '/login' : '/getting-started');
      }

      if (!acceptedPrecautions) {
        return isGettingStarted ? null : '/getting-started';
      }

      if (!isLoggedIn) {
        return (isLoggingIn || isGettingStarted) ? null : '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/getting-started',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GettingStartedScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/vitals',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VitalsScreen(),
            ),
          ),
          GoRoute(
            path: '/medicines',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MedicinesScreen(),
            ),
          ),
          GoRoute(
            path: '/prescriptions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PrescriptionsScreen(),
            ),
          ),
          GoRoute(
            path: '/symptoms',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SymptomsScreen(),
            ),
          ),
          GoRoute(
            path: '/symptom-analyzer',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SmartSymptomScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
      // Full-screen routes (outside shell)
      GoRoute(
        path: '/vitals/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddVitalScreen(),
      ),
      GoRoute(
        path: '/medicines/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddMedicineScreen(),
      ),
      GoRoute(
        path: '/symptoms/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddSymptomScreen(),
      ),
      GoRoute(
        path: '/symptoms/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SymptomsScreen(),
      ),
      GoRoute(
        path: '/visits',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DoctorVisitsScreen(),
      ),
      GoRoute(
        path: '/visits/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddVisitScreen(),
      ),
      GoRoute(
        path: '/emergency',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EmergencyScreen(),
      ),
      GoRoute(
        path: '/ai-assistant',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/ai-insights',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiInsightsScreen(),
      ),
      GoRoute(
        path: '/prescriptions/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddPrescriptionScreen(),
      ),
    ],
  );
}

class _AppShell extends StatefulWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;

  int _locationToIndex(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/vitals')) return 1;
    if (location.startsWith('/medicines')) return 2;
    if (location.startsWith('/prescriptions')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/vitals');
        break;
      case 2:
        context.go('/medicines');
        break;
      case 3:
        context.go('/prescriptions');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    _currentIndex = _locationToIndex(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1D9E75).withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Vitals',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Medicines',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Prescriptions',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
