import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/supabase_client.dart';

class GeofencingService {
  GeofencingService._();
  static final GeofencingService instance = GeofencingService._();

  StreamSubscription<Position>? _positionSub;

  /// businessId → true if the user is currently inside that geofence
  final Map<String, bool> _insideState = {};

  /// Cached list of businesses: [{id, latitude, longitude}]
  List<Map<String, dynamic>> _businesses = [];

  bool get isRunning => _positionSub != null;

  /// Call after the user logs in and location permission is granted.
  Future<void> start() async {
    if (isRunning) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('[Geofencing] Location permission not granted — skipping.');
      return;
    }

    await _refreshBusinesses();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50,
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPosition,
      onError: (e) => debugPrint('[Geofencing] Stream error: $e'),
    );

    debugPrint('[Geofencing] Started. Watching ${_businesses.length} businesses.');
  }

  /// Call when the user logs out or the app is disposed.
  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _insideState.clear();
    debugPrint('[Geofencing] Stopped.');
  }

  /// Re-fetch the business list (call when new businesses are approved or
  /// the user's session refreshes).
  Future<void> refreshBusinesses() async => _refreshBusinesses();

  Future<void> _refreshBusinesses() async {
    try {
      final data = await supabase
          .from('businesses')
          .select('id, latitude, longitude')
          .eq('verification_status', 'approved')
          .eq('is_active', true);

      _businesses = (data as List)
          .map((b) => Map<String, dynamic>.from(b as Map))
          .toList();

      debugPrint('[Geofencing] Loaded ${_businesses.length} businesses.');
    } catch (e) {
      debugPrint('[Geofencing] Failed to load businesses: $e');
    }
  }

  void _onPosition(Position position) {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    for (final business in _businesses) {
      final businessId = business['id'] as String;
      final lat = (business['latitude'] as num).toDouble();
      final lng = (business['longitude'] as num).toDouble();

      final distanceMetres = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat,
        lng,
      );

      final wasInside = _insideState[businessId] ?? false;

      if (!wasInside && distanceMetres <= AppConstants.geofenceEnterRadius) {
        _insideState[businessId] = true;
        _logEvent(
          userId: userId,
          businessId: businessId,
          eventType: 'enter',
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else if (wasInside && distanceMetres > AppConstants.geofenceExitRadius) {
        _insideState[businessId] = false;
        _logEvent(
          userId: userId,
          businessId: businessId,
          eventType: 'exit',
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    }
  }

  Future<void> _logEvent({
    required String userId,
    required String businessId,
    required String eventType,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await supabase.from('geofence_events').insert({
        'user_id': userId,
        'business_id': businessId,
        'event_type': eventType,
        'latitude': latitude,
        'longitude': longitude,
      });
      debugPrint('[Geofencing] Logged $eventType for business $businessId');
    } catch (e) {
      debugPrint('[Geofencing] Failed to log $eventType: $e');
    }
  }
}