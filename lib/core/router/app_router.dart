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
import '../../features/admin/screens/admin_dashboard.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
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
    initialLocation: '/dashboard',
    refreshListenable: AuthHelper(),
    redirect: (context, state) {
      final auth = AuthHelper();
      final hasCompletedOnboarding = auth.onboardingCompleted;
      final isLoggedIn = auth.isLoggedIn;
      final isAdmin = auth.isAdmin;
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!hasCompletedOnboarding) {
        return isOnboarding ? null : '/onboarding';
      }

      if (isOnboarding) {
        return isLoggedIn
            ? (isAdmin ? '/admin/dashboard' : '/dashboard')
            : '/login';
      }

      if (!isLoggedIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return isAdmin ? '/admin/dashboard' : '/dashboard';
      }
      if (isAdmin && !state.matchedLocation.startsWith('/admin')) {
        return '/admin/dashboard';
      }
      if (!isAdmin && state.matchedLocation.startsWith('/admin')) {
        return '/dashboard';
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
        path: '/admin/dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
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
            path: '/dashboard',
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
        path: '/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/prescriptions/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddPrescriptionScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
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

  static const _routes = [
    '/dashboard',
    '/vitals',
    '/medicines',
    '/prescriptions',
    '/symptom-analyzer',
    '/profile',
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    // Sync index with current location
    final location = GoRouterState.of(context).uri.toString();
    final idx = _routes.indexWhere((r) => location.startsWith(r));
    if (idx >= 0 && idx != _currentIndex) {
      _currentIndex = idx;
    }

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
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart_rounded),
            label: 'Vitals',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Medicines',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Prescriptions',
          ),
          NavigationDestination(
            icon: Icon(Icons.sick_outlined),
            selectedIcon: Icon(Icons.sick_rounded),
            label: 'Symptoms',
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
