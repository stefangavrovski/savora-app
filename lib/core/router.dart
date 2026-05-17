import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/features/auth/providers/auth_provider.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      if (authState.isLoading) return AppRoutes.splash;

      final session = authState.value?.session;
      final isLoggedIn = session != null;
      final isEmailVerified = session?.user.emailConfirmedAt != null;
      final loc = state.matchedLocation;

      final authRoutes = [AppRoutes.login, AppRoutes.register];

      if (!isLoggedIn && !authRoutes.contains(loc) && loc != AppRoutes.splash) {
        return AppRoutes.login;
      }

      if (isLoggedIn && !isEmailVerified && loc != AppRoutes.verifyEmail) {
        return AppRoutes.verifyEmail;
      }

      if (isLoggedIn && isEmailVerified && authRoutes.contains(loc)) {
        return AppRoutes.map;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, __) => const VerifyEmailScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.map,
            builder: (_, __) => const MapScreen(),
          ),
          GoRoute(
            path: AppRoutes.explore,
            builder: (_, __) => const ExploreScreen(),
          ),
          GoRoute(
            path: AppRoutes.myReservations,
            builder: (_, __) => const MyReservationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.listingDetail,
        builder: (_, state) => ListingDetailScreen(
          listingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.reservationDetail,
        builder: (_, state) => ReservationDetailScreen(
          reservationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.businessOnboarding,
        builder: (_, __) => const BusinessOnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.businessDashboard,
        builder: (_, __) => const BusinessDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.createListing,
        builder: (_, __) => const CreateListingScreen(),
      ),
      GoRoute(
        path: AppRoutes.myListings,
        builder: (_, __) => const MyListingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.businessReservations,
        builder: (_, __) => const BusinessReservationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.pickupCounter,
        builder: (_, __) => const PickupCounterScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPanel,
        builder: (_, __) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminReview,
        builder: (_, state) => BusinessReviewScreen(
          businessId: state.pathParameters['businessId']!,
        ),
      ),
    ],
  );
});