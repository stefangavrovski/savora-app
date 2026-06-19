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
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

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
  final Map<String, ui.Image> _thumbnailCache = {};
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

  Future<ui.Image?> _decodeNetworkImage(String url) async {
    final cached = _thumbnailCache[url];
    if (cached != null) return cached;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      final codec = await ui.instantiateImageCodec(
        response.bodyBytes,
        targetWidth: 96,
        targetHeight: 96,
      );
      final frame = await codec.getNextFrame();
      _thumbnailCache[url] = frame.image;
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _buildMarkerCardImage({
    required String priceLabel,
    required String subLabel,
    required bool available,
    ui.Image? thumbnail,
  }) async {
    const cardWidth = 168.0;
    const cardHeight = 64.0;
    const tailHeight = 14.0;
    const canvasHeight = cardHeight + tailHeight + 8;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, cardWidth, canvasHeight));

    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(4, 4, cardWidth - 8, cardHeight),
      const Radius.circular(16),
    );

    canvas.drawRRect(
      cardRect.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(cardRect, Paint()..color = Colors.white);

    final tailPath = Path()
      ..moveTo(cardWidth / 2 - 8, cardHeight + 2)
      ..lineTo(cardWidth / 2 + 8, cardHeight + 2)
      ..lineTo(cardWidth / 2, cardHeight + tailHeight)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = Colors.white);

    final accentColor = available ? const Color(0xFF2D6A4F) : const Color(0xFF9CA3AF);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(4, 4, 6, cardHeight),
        topLeft: const Radius.circular(16),
        bottomLeft: const Radius.circular(16),
      ),
      Paint()..color = accentColor,
    );

    const thumbCenter = Offset(40, 4 + cardHeight / 2);
    const thumbRadius = 22.0;
    if (thumbnail != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: thumbCenter, radius: thumbRadius)));
      canvas.drawImageRect(
        thumbnail,
        Rect.fromLTWH(0, 0, thumbnail.width.toDouble(), thumbnail.height.toDouble()),
        Rect.fromCircle(center: thumbCenter, radius: thumbRadius),
        Paint(),
      );
      canvas.restore();
    } else {
      canvas.drawCircle(thumbCenter, thumbRadius, Paint()..color = accentColor.withValues(alpha: 0.15));
      final iconPainter = TextPainter(
        text: const TextSpan(text: '🛍', style: TextStyle(fontSize: 20)),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(canvas, thumbCenter - Offset(iconPainter.width / 2, iconPainter.height / 2));
    }

    TextPainter(
      text: TextSpan(
        text: priceLabel,
        style: const TextStyle(color: Color(0xFF1B1B1B), fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, const Offset(70, 4 + cardHeight / 2 - 18));

    TextPainter(
      text: TextSpan(
        text: subLabel,
        style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, const Offset(70, 4 + cardHeight / 2 + 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(cardWidth.toInt(), canvasHeight.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  bool _isLoadingListings = false;

  Future<void> _loadListings() async {
    if (_isLoadingListings) return;
    _isLoadingListings = true;

    try {
      ref.invalidate(_locationProvider);
      final location = await ref.read(_locationProvider.future);
      final lat = location?.latitude ?? AppConstants.defaultLat;
      final lng = location?.longitude ?? AppConstants.defaultLng;

      final key = (lat: lat, lng: lng);
      ref.invalidate(nearbyListingsProvider(key));
      final listings = await ref.read(nearbyListingsProvider(key).future);

      if (!mounted || _mapController == null) return;

      await _mapController!.clearSymbols();
      _markerListings.clear();

      for (final listing in listings) {
        if (listing.businessLat == null || listing.businessLng == null) continue;

        final thumbnail = listing.imageUrl != null
            ? await _decodeNetworkImage(listing.imageUrl!)
            : null;

        final iconId = 'card-${listing.id}-${listing.isAvailable}';
        final iconBytes = await _buildMarkerCardImage(
          priceLabel: AppConstants.formatMKD(listing.price),
          subLabel: listing.isAvailable ? '${listing.quantityAvailable} left' : 'Sold out',
          available: listing.isAvailable,
          thumbnail: thumbnail,
        );
        await _mapController!.addImage(iconId, iconBytes);

        final symbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(listing.businessLat!, listing.businessLng!),
            iconImage: iconId,
            iconSize: 1.0,
            iconAnchor: 'bottom',
          ),
        );
        _markerListings[symbol.id] = listing;
      }
    } finally {
      _isLoadingListings = false;
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
                        color: Colors.black.withValues(alpha: 0.1),
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