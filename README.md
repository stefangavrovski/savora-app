# Savora — Local Food Waste Reduction App

**Course:** Capstone Project  
**Faculty:** CST, SEE University  
**Semester:** 8th Semester (2025/2026)

---

## Table of Contents

- [About the Project](#about-the-project)
- [Author](#author)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Configuration](#configuration)
    - [Running the App](#running-the-app)
- [User Roles & Permissions](#user-roles--permissions)
- [Architecture](#architecture)
- [Backend Services (Supabase)](#backend-services-supabase)
- [Known Limitations](#known-limitations)

---

## About the Project

Savora is a Flutter mobile application built as a capstone project at SEE University. It addresses a concrete, observable problem: bakeries, restaurants, and small food vendors in Tetovo routinely discard unsold but perfectly edible food at the end of the business day because there is no organised digital channel through which they can offer it before closing. Savora fills that gap.

The platform connects verified local food businesses with nearby customers through a location-aware, real-time interface. Businesses post "surprise bags" — fixed-price bundles of surplus food with a defined pickup window and a limited quantity. Customers discover these on an interactive map, reserve a bag in a single tap, and collect it using a unique pickup code. The system guarantees strict first-come, first-served (FCFS) behaviour even under simultaneous reservation attempts, using PostgreSQL row-level locking at the database layer.

The backend is built on Supabase, using PostgreSQL with the PostGIS extension, Supabase Auth, Supabase Storage, and a set of Edge Functions and scheduled cron jobs. The mobile client is built in Flutter with Riverpod for state management and GoRouter for role-based navigation. The current build targets Android; iOS could not be compiled or tested due to hardware constraints during development, and this is documented as a known limitation.

---

## Author

| Name | ID |
|------|----|
| Stefan Gavrovski | 130841 |

---

## Features

- User registration and login with Supabase Auth and mandatory email verification
- Three distinct user roles with separate navigation flows: Customer, Business Owner, Admin
- Interactive map powered by MapLibre GL with custom card-style markers and real-time listing data
- Location-based listing discovery using a PostGIS spatial RPC (`fn_listings_near_point`) within a configurable radius
- Atomic, race-condition-safe reservation system using `SELECT ... FOR UPDATE` in PL/pgSQL — no bag can ever be double-booked
- Business onboarding with a multi-step form: business details, coordinates (GPS-assisted or geocoded from address), and EDB/EMBS document uploads
- Admin panel for reviewing pending business applications with document previews and approve/reject actions
- Pickup counter screen where businesses enter or receive an 8-character pickup code to mark a reservation as completed
- Real-time reservation status updates via Supabase Realtime stream
- In-app notification centre with unread badges, grouped by type, and tap-to-navigate deep linking
- Foreground push notifications fired when new listings appear from followed businesses or when a user is geofenced near an active business
- Geofencing service that streams device position and logs entry/exit events for each active business within 400 m / 600 m hysteresis thresholds
- Business follow/unfollow to receive notifications when a followed business posts a new bag
- Star ratings and text reviews for completed reservations, visible on the listing detail screen
- Business analytics dashboard: bags sold, bags wasted, food rescued (kg), total listings, average rating, follower count
- Customer impact stats on the profile screen: bags rescued, food saved (kg), money saved (MKD)
- Shimmer skeleton loaders on every screen while data is fetching
- Consistent design system: DM Sans typography, brand green palette, and Material 3 theming throughout

---

## Tech Stack

- **Framework:** Flutter (Dart SDK ^3.7.2)
- **State Management:** Flutter Riverpod 2.6.1
- **Navigation:** GoRouter 14.6.2
- **Backend:** Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **Database:** PostgreSQL 15 with PostGIS extension, hosted on Supabase
- **Map:** MapLibre GL 0.22.0 with MapTiler Streets v2 tile layer
- **Location:** Geolocator 13.0.2 + Permission Handler 11.3.1
- **Notifications:** flutter_local_notifications 17.2.4
- **Image Handling:** image_picker 1.1.2, cached_network_image 3.4.1
- **File Picking:** file_picker 8.1.7
- **Utilities:** intl, uuid, http, timeago, flutter_dotenv
- **UI:** shimmer, google_fonts, lottie, flutter_svg, url_launcher
- **Platform Target:** Android (API level per Flutter defaults)

---

## Project Structure

```
savora_app/
├── android/                         # Android platform configuration
│   └── app/
│       ├── src/main/AndroidManifest.xml
│       └── src/build.gradle.kts
├── lib/
│   ├── main.dart                    # Entry point: Supabase init, dotenv load, notification setup
│   ├── core/
│   │   ├── constants.dart           # Map defaults, geofence radii, MKD formatter, pickup code helpers
│   │   ├── geofencing_service.dart  # Singleton: streams device position, logs geofence enter/exit events
│   │   ├── notification_service.dart # flutter_local_notifications setup and display helper
│   │   ├── router.dart              # GoRouter config with role-aware redirect logic
│   │   ├── supabase_client.dart     # Convenience accessor for Supabase.instance.client
│   │   ├── theme.dart               # AppColors, AppTextStyles, AppSpacing, AppRadius, buildAppTheme()
│   │   └── widgets/
│   │       └── shimmer_widgets.dart # Skeleton loaders: listing, reservation, notification, dashboard
│   ├── features/
│   │   ├── admin/
│   │   │   ├── providers/
│   │   │   │   └── admin_provider.dart   # businessDetailProvider, businessDocumentsProvider, allUsersProvider, AdminActionsNotifier
│   │   │   └── screens/
│   │   │       ├── admin_panel_screen.dart    # Tabbed: pending applications with badge count, all users list
│   │   │       └── business_review_screen.dart # Business info card, signed document links, approve/reject buttons
│   │   ├── auth/
│   │   │   ├── models/
│   │   │   │   └── profile.dart        # Profile model with role helpers (isCustomer, isBusinessOwner, isAdmin)
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart  # authStateProvider, currentSessionProvider, geofencingLifecycleProvider
│   │   │   └── screens/
│   │   │       ├── login_screen.dart
│   │   │       ├── register_screen.dart     # Role selection cards: Customer / Business Owner
│   │   │       ├── splash_screen.dart
│   │   │       └── verify_email_screen.dart # Resend link, sign-out option
│   │   ├── business/
│   │   │   ├── models/
│   │   │   │   └── business.dart       # Business model with verification status helpers
│   │   │   ├── providers/
│   │   │   │   ├── business_provider.dart  # myBusinessProvider, pendingBusinessesProvider, BusinessOnboardingNotifier, LogoUploadNotifier, businessAnalyticsProvider
│   │   │   │   └── follow_provider.dart    # isFollowingProvider, FollowNotifier
│   │   │   └── screens/
│   │   │       ├── business_analytics_screen.dart  # Stats grid: bags sold/wasted, food rescued, reviews, followers
│   │   │       ├── business_dashboard_screen.dart  # Pending/rejected state views + active dashboard with action tiles
│   │   │       ├── business_onboarding_screen.dart # 2-step paged form: business info → EDB/EMBS docs → confirmation
│   │   │       ├── business_reservations_screen.dart
│   │   │       ├── create_listing_screen.dart   # Image upload, price/quantity fields, date-time picker for pickup window
│   │   │       ├── my_listings_screen.dart      # Active / past listing cards with cancel action
│   │   │       └── pickup_counter_screen.dart   # 8-char code input → completeByPickupCode RPC → success card
│   │   ├── listings/
│   │   │   ├── models/
│   │   │   │   └── bag_listing.dart     # BagListing model with status helpers and discount/distance computed fields
│   │   │   ├── providers/
│   │   │   │   └── listing_provider.dart  # nearbyListingsProvider (RPC), listingStreamProvider (realtime), listingByIdProvider, myListingsProvider, CreateListingNotifier
│   │   │   └── screens/
│   │   │       ├── explore_screen.dart       # Search bar overlay, filtered list from nearbyListingsProvider
│   │   │       └── listing_detail_screen.dart # Hero image, price card, pickup window, follow button, RatingBadge, BusinessReviewsSection, reserve CTA
│   │   ├── map/
│   │   │   ├── screens/
│   │   │   │   └── map_screen.dart   # MapLibre GL map, custom card-style markers rendered via Canvas, listing bottom sheet on tap
│   │   │   └── widgets/
│   │   │       └── listing_bottom_sheet.dart
│   │   ├── notifications/
│   │   │   ├── models/
│   │   │   │   └── notification_model.dart
│   │   │   ├── providers/
│   │   │   │   ├── notification_provider.dart   # notificationsStreamProvider (Realtime), unreadNotifCountProvider, NotificationNotifier
│   │   │   │   └── push_listener_provider.dart  # Watches stream, fires local notification for newest unread
│   │   │   └── screens/
│   │   │       └── notifications_screen.dart    # Type-aware icons, unread dot, tap deep-links, mark-all-read
│   │   ├── profile/
│   │   │   ├── providers/
│   │   │   │   └── profile_provider.dart   # currentProfileProvider, ProfileNotifier
│   │   │   └── screens/
│   │   │       └── profile_screen.dart     # Avatar upload, customer impact stats, quick-access nav, edit dialog
│   │   └── reservations/
│   │       ├── models/
│   │       │   ├── reservation.dart   # Reservation model with joined listing/business fields
│   │       │   └── review.dart
│   │       ├── providers/
│   │       │   └── reservation_provider.dart  # myReservationsProvider, reservationByIdProvider, businessReservationsProvider, ReservationNotifier
│   │       ├── screens/
│   │       │   ├── my_reservations_screen.dart
│   │       │   └── reservation_detail_screen.dart  # Pickup code display, cancel action, post-completion review form
│   │       └── widgets/
│   │           └── business_reviews_section.dart   # BusinessReviewsSection and RatingBadge — shown on listing detail screen
│   └── shell/
│       └── app_shell.dart   # StatefulShellRoute bottom navigation for customer: Map, Reservations, Notifications, Profile
├── .env                     # Environment variables — not committed to version control
└── pubspec.yaml
```

---

## Getting Started

### Prerequisites

Make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK ^3.7.2)
- Android Studio or VS Code with the Flutter and Dart plugins
- An Android device or emulator
- A [Supabase](https://supabase.com) project with the database schema applied (see the schema SQL file included in the repository)
- A [MapTiler](https://maptiler.com) account and API key (free tier is sufficient)

### Configuration

Create a `.env` file in the root of the project:

```
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
MAPTILER_KEY=your-maptiler-api-key
```

The `.env` file is declared as a Flutter asset in `pubspec.yaml` and loaded at startup via `flutter_dotenv`. Do not commit it to version control.

You will also need to configure the following inside your Supabase project dashboard:

- Apply the full database schema (tables, enums, triggers, RLS policies, RPC functions, analytics views)
- Enable the **PostGIS** extension under Database → Extensions
- Create the four storage buckets: `listing-images`, `business-logos`, `avatars`, `business-documents`
- Deploy the Edge Functions: `on-new-listing`, `on-reservation-confirmed`, `on-business-verified`, `send-push-notification`, `send-pickup-reminders`
- Configure the three database webhooks pointing to their respective Edge Functions
- Set up the five scheduled cron jobs: `expire-listings`, `mark-no-shows`, `prune-push-tokens`, `prune-geofence-events`, `pickup-reminders`

### Running the App

```bash
# Clone the repository
git clone https://github.com/stefangavrovski/savora-app.git
cd savora_app

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

On first launch the app loads environment variables, initialises the Supabase client, sets up the local notification plugin, and routes to the splash screen while the auth state resolves.

---

## User Roles & Permissions

The platform has three roles, each with a completely separate navigation flow and set of capabilities.

**Customer** — the end user of the platform. Customers can browse nearby surplus food listings on the interactive map and in a searchable list view, reserve available bags with a single tap, view their reservation history along with the pickup code for each confirmed reservation, cancel a reservation they no longer need, and leave a star rating and written review after a reservation is completed. They also have a personal impact dashboard on their profile screen showing total bags rescued, food saved in kilograms, and money saved in MKD. Customers can follow businesses to receive notifications when new listings are posted.

**Business Owner** — a verified food vendor. Before gaining access to any business features, a new business owner must complete a two-step onboarding form that collects the business's name, category, address and coordinates, opening hours, EDB (Unique Tax Number), EMBS (Unique Business ID), and uploads of the corresponding certificates. The application sits in a pending state until an admin approves it. Once approved, the business owner accesses a dashboard from which they can create new surprise bag listings (with title, description, price, original value, quantity, estimated weight, optional photo, and pickup window), view and cancel their active listings, manage incoming reservations, complete pickups via the pickup counter screen, and review their performance analytics.

**Admin** — the platform operator. Admins see only the admin panel, which shows all pending business applications with a live unread count badge, allows them to open each application to review the business's details and submitted documents (via signed Supabase Storage URLs), and to approve or reject the application with a confirmation dialog. Admins can also view the full user list.

---

## Architecture

The Flutter client follows a feature-first folder structure. Each feature is self-contained with its own models, Riverpod providers, and screens, keeping cross-feature dependencies minimal and explicit.

**State management** is handled entirely with Riverpod. `FutureProvider` and `StreamProvider` cover data fetching and real-time subscriptions respectively; `AsyncNotifier` covers any mutation that needs to trigger a refetch. The `authStateProvider` is a `StreamProvider` wrapping Supabase's `onAuthStateChange` stream, and `currentProfileProvider` derives from it, so role-based navigation updates reactively whenever the session or profile changes.

**Navigation** uses GoRouter with a `_RouterNotifier` that listens to auth state, profile state, and a pending-email-verification flag, and redirects accordingly. Unauthenticated users land on login. Unverified users are held on the verify-email screen. Authenticated customers get the `StatefulShellRoute` with the bottom navigation bar; business owners go directly to the dashboard; admins go to the admin panel. Attempts to access routes outside a user's role are silently redirected to their home route.

**Real-time updates** are handled in two places. Listing quantity on the detail screen is subscribed via Supabase Realtime (`listingStreamProvider`), so if another user reserves the last bag while this user is looking at the detail screen, the button disables without any manual refresh. Notifications are similarly streamed in real time; the `pushListenerProvider` watches the stream and fires a `flutter_local_notifications` local notification whenever a new unread notification arrives.

**Geofencing** runs as a singleton service started on login and stopped on logout. It keeps an in-memory map of which businesses the user is currently inside, polling device position every 50 metres via `Geolocator.getPositionStream`. Enter events (within 400 m) and exit events (beyond 600 m) are written to the `geofence_events` table; the `on-new-listing` Edge Function reads recent geofence enter events when fanning out notifications for a new listing.

**Concurrent reservation safety** is handled entirely at the database layer. The `make_reservation` PL/pgSQL function acquires a `SELECT ... FOR UPDATE` row-level lock on the `bag_listings` row before checking `quantity_available` and decrementing it. Any concurrent call on the same listing row blocks until the first transaction commits or rolls back, which serialises concurrent reservation attempts and guarantees strict FCFS behaviour with no application-layer coordination needed.

---

## Backend Services (Supabase)

**Database** — PostgreSQL 15 with PostGIS. Core tables: `profiles`, `businesses`, `business_documents`, `bag_listings`, `reservations`, `reservation_logs`, `business_follows`, `reviews`, `notifications`, `push_tokens`, `geofence_events`, `admin_actions`. Key RPCs called from Flutter: `make_reservation`, `cancel_reservation`, `complete_reservation`, `get_reservation_by_pickup_code`, `approve_business`, `reject_business`, `fn_listings_near_point`, `get_customer_stats`. Analytics exposed as regular SQL views: `v_customer_analytics`, `v_business_analytics`. Row-level security is enabled on all tables.

**Auth** — Supabase Auth with email-and-password sign-up. A `trg_on_auth_user_created` trigger creates a `profiles` row automatically on every new signup. Email confirmation is required before the router allows access to any protected route.

**Storage** — four buckets: `listing-images` (business-scoped upload policy), `business-logos` (business-scoped), `avatars` (user-scoped), `business-documents` (authenticated read; signed URLs generated server-side for admin review).

**Edge Functions** — five Deno functions deployed to Supabase: `send-push-notification` (inserts a notification row and forwards to Expo Push API if push tokens are registered), `on-new-listing` (fans out to followers and recent geofence entrants on listing insert), `on-reservation-confirmed` (sends pickup code notification on reservation insert), `on-business-verified` (sends approval/rejection notification on business status update), `send-pickup-reminders` (called by cron; sends reminders for reservations with pickup windows closing within 30–40 minutes).

**Cron Jobs** — five scheduled jobs: `expire-listings` and `mark-no-shows` run every 15 minutes to transition stale listings and missed reservations; `pickup-reminders` runs every 10 minutes; `prune-push-tokens` and `prune-geofence-events` run daily to keep the database clean.

---

## Known Limitations

**Android only.** The project compiles cleanly as a cross-platform Flutter app, but the iOS target was never built or tested. This was a hardware constraint during development — macOS and Xcode were not available — rather than a design decision. iOS should be functional modulo any platform-specific permission handling, but it has not been validated.

**Foreground notifications only.** In-app notifications are delivered via a Supabase Realtime subscription rendered as a `flutter_local_notifications` local notification. This works reliably while the app is open. Background push delivery would require FCM (Android) and APNs (iOS) integration, which was out of scope for this prototype.

**Manual pickup code entry.** The pickup counter screen accepts the 8-character code by typing. QR code or barcode scanning was planned but not implemented; the infrastructure for it is in place (the pickup code is already a short, high-contrast alphanumeric string).

**Portability.** The app defaults to Tetovo, North Macedonia as its map centre and uses MKD (Macedonian Denar) as its currency throughout. Adapting to another city or currency requires changes to `AppConstants` and the currency formatter.

---

## License

This project was created for educational purposes as part of university coursework.