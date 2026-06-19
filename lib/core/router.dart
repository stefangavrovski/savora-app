import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/features/auth/providers/auth_provider.dart';
import 'package:savora_app/features/profile/providers/profile_provider.dart';
import 'package:savora_app/features/auth/screens/login_screen.dart';
import 'package:savora_app/features/auth/screens/register_screen.dart';
import 'package:savora_app/features/auth/screens/verify_email_screen.dart';
import 'package:savora_app/features/auth/screens/splash_screen.dart';
import 'package:savora_app/features/map/screens/map_screen.dart';
import 'package:savora_app/features/listings/screens/explore_screen.dart';
import 'package:savora_app/features/reservations/screens/my_reservations_screen.dart';
import 'package:savora_app/features/reservations/screens/reservation_detail_screen.dart';
import 'package:savora_app/features/profile/screens/profile_screen.dart';
import 'package:savora_app/features/notifications/screens/notifications_screen.dart';
import 'package:savora_app/features/business/screens/business_onboarding_screen.dart';
import 'package:savora_app/features/business/screens/business_dashboard_screen.dart';
import 'package:savora_app/features/business/screens/create_listing_screen.dart';
import 'package:savora_app/features/business/screens/my_listings_screen.dart';
import 'package:savora_app/features/business/screens/business_reservations_screen.dart';
import 'package:savora_app/features/business/screens/pickup_counter_screen.dart';
import 'package:savora_app/features/admin/screens/admin_panel_screen.dart';
import 'package:savora_app/features/admin/screens/business_review_screen.dart';
import 'package:savora_app/features/listings/screens/listing_detail_screen.dart';
import 'package:savora_app/shell/app_shell.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';

  // Customer
  static const map = '/map';
  static const explore = '/explore';
  static const listingDetail = '/listing/:id';
  static const myReservations = '/reservations';
  static const reservationDetail = '/reservations/:id';
  static const notifications = '/notifications';
  static const profile = '/profile';

  // Business
  static const businessOnboarding = '/business/onboarding';
  static const businessDashboard = '/business/dashboard';
  static const createListing = '/business/listings/create';
  static const myListings = '/business/listings';
  static const businessReservations = '/business/reservations';
  static const pickupCounter = '/business/pickup';

  // Admin
  static const adminPanel = '/admin';
  static const adminReview = '/admin/review/:businessId';
}

final pendingEmailVerificationProvider = StateProvider<bool>((ref) => false);
final pendingVerificationEmailProvider = StateProvider<String?>((ref) => null);

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(currentProfileProvider, (_, __) => notifyListeners());
    _ref.listen(pendingEmailVerificationProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      // TEMP DEBUG
      debugPrint(
        '[ROUTER] loc=$loc hasValue=${authAsync.hasValue} '
        'session=${authAsync.value?.session != null} '
        'pendingFlag=${ref.read(pendingEmailVerificationProvider)}',
      );

      if (!authAsync.hasValue) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final session = authAsync.value?.session;
      final isLoggedIn = session != null;
      final isEmailVerified = session?.user.emailConfirmedAt != null;

      final authRoutes = {AppRoutes.login, AppRoutes.register};

      if (!isLoggedIn) {
        if (ref.read(pendingEmailVerificationProvider) &&
            loc == AppRoutes.verifyEmail) {
          return null;
        }
        if (authRoutes.contains(loc)) return null;
        return AppRoutes.login;
      }

      if (ref.read(pendingEmailVerificationProvider)) {
        Future.microtask(() {
          ref.read(pendingEmailVerificationProvider.notifier).state = false;
        });
      }

      if (!isEmailVerified) {
        return loc == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
      }

      final profileAsync = ref.read(currentProfileProvider);

      if (!profileAsync.hasValue) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final profile = profileAsync.value;

      if (profile == null) {
        return authRoutes.contains(loc) ? null : AppRoutes.login;
      }

      final String homeRoute;
      if (profile.isAdmin) {
        homeRoute = AppRoutes.adminPanel;
      } else if (profile.isBusinessOwner) {
        homeRoute = AppRoutes.businessDashboard;
      } else {
        homeRoute = AppRoutes.map;
      }

      if (loc == AppRoutes.splash || authRoutes.contains(loc)) {
        return homeRoute;
      }

      const businessPrefixes = [
        '/business/onboarding',
        '/business/dashboard',
        '/business/listings',
        '/business/reservations',
        '/business/pickup',
      ];
      final isBusinessRoute = businessPrefixes.any((p) => loc.startsWith(p));
      if (isBusinessRoute && !profile.isBusinessOwner && !profile.isAdmin) {
        return AppRoutes.map;
      }

      if (loc.startsWith('/admin') && !profile.isAdmin) {
        return AppRoutes.map;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.verifyEmail, builder: (_, __) => const VerifyEmailScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.map, builder: (_, __) => const MapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.myReservations, builder: (_, __) => const MyReservationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),

      GoRoute(path: AppRoutes.explore, builder: (_, __) => const ExploreScreen()),

      GoRoute(
        path: AppRoutes.listingDetail,
        builder: (_, state) => ListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.reservationDetail,
        builder: (_, state) => ReservationDetailScreen(reservationId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.businessOnboarding, builder: (_, __) => const BusinessOnboardingScreen()),
      GoRoute(path: AppRoutes.businessDashboard, builder: (_, __) => const BusinessDashboardScreen()),
      GoRoute(path: AppRoutes.createListing, builder: (_, __) => const CreateListingScreen()),
      GoRoute(path: AppRoutes.myListings, builder: (_, __) => const MyListingsScreen()),
      GoRoute(path: AppRoutes.businessReservations, builder: (_, __) => const BusinessReservationsScreen()),
      GoRoute(path: AppRoutes.pickupCounter, builder: (_, __) => const PickupCounterScreen()),
      GoRoute(path: AppRoutes.adminPanel, builder: (_, __) => const AdminPanelScreen()),
      GoRoute(
        path: AppRoutes.adminReview,
        builder: (_, state) => BusinessReviewScreen(businessId: state.pathParameters['businessId']!),
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});