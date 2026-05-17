import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/router.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/listings/models/bag_listing.dart';
import 'package:savora_app/features/listings/providers/listing_provider.dart';
import 'package:savora_app/features/map/widgets/listing_bottom_sheet.dart';

final _locationProvider = FutureProvider<Position?>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  if (permission == LocationPermission.deniedForever) return null;

  return await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    ),
  );
});

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? _mapController;
  final Map<String, BagListing> _markerListings = {};
  bool _mapReady = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    controller.onSymbolTapped.add(_onSymbolTapped);
    setState(() => _mapReady = true);
    _loadListings();
  }

  void _onSymbolTapped(Symbol symbol) {
    final listing = _markerListings[symbol.id];
    if (listing == null) return;
    _showListingSheet(listing);
  }

  Future<void> _loadListings() async {
    final location = ref.read(_locationProvider).value;
    final lat = location?.latitude ?? AppConstants.defaultLat;
    final lng = location?.longitude ?? AppConstants.defaultLng;

    final listings = await ref.read(
      nearbyListingsProvider((lat: lat, lng: lng)).future,
    );

    if (!mounted || _mapController == null) return;

    await _mapController!.clearSymbols();
    _markerListings.clear();

    for (final listing in listings) {
      if (listing.businessLat == null || listing.businessLng == null) continue;

      final symbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(listing.businessLat!, listing.businessLng!),
          iconImage: 'marker-15',
          iconColor: listing.isAvailable ? '#2D6A4F' : '#9CA3AF',
          iconSize: 1.8,
          textField: 'MKD ${listing.price.toStringAsFixed(0)}',
          textOffset: const Offset(0, 1.8),
          textSize: 11,
          textColor: listing.isAvailable ? '#2D6A4F' : '#9CA3AF',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 1,
        ),
      );
      _markerListings[symbol.id] = listing;
    }
  }

  void _showListingSheet(BagListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ListingBottomSheet(listing: listing),
    );
  }

  Future<void> _goToMyLocation() async {
    final location = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        15,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(_locationProvider);

    // Once location resolves, animate camera to user's actual position
    ref.listen<AsyncValue<Position?>>(_locationProvider, (_, next) {
      next.whenData((position) {
        if (position != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              15,
            ),
          );
          _loadListings();
        }
      });
    });

    final initialLat = locationAsync.value?.latitude ?? AppConstants.defaultLat;
    final initialLng = locationAsync.value?.longitude ?? AppConstants.defaultLng;

    final styleUrl =
        'https://api.maptiler.com/maps/streets-v2/style.json?key=${dotenv.env['MAPTILER_KEY'] ?? ''}';

    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: styleUrl,
            initialCameraPosition: CameraPosition(
              target: LatLng(initialLat, initialLng),
              zoom: AppConstants.defaultZoom,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            compassEnabled: false,
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.explore),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Search bags near you...',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textDisabled),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'refresh',
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 2,
                  onPressed: _loadListings,
                  child: const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(height: AppSpacing.sm),
                FloatingActionButton.small(
                  heroTag: 'location',
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 2,
                  onPressed: _goToMyLocation,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),

          if (!_mapReady)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}