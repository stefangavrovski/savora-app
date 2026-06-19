import 'package:intl/intl.dart';

class AppConstants {
  // Map default center — Tetovo, North Macedonia
  static const double defaultLat = 41.9981;
  static const double defaultLng = 20.9600;
  static const double defaultZoom = 14.0;

  // Geofencing thresholds (metres)
  static const double geofenceEnterRadius = 400.0;
  static const double geofenceExitRadius = 600.0;

  // Listings query radius (metres)
  static const double listingsRadius = 5000.0;

  // MKD currency formatter
  static String formatMKD(double amount) {
    final formatted = NumberFormat('#,##0.##', 'mk_MK').format(amount);
    return 'MKD $formatted';
  }

  // Pickup code display: "A3F9C21B" → "A3F9 C21B"
  static String formatPickupCode(String code) {
    if (code.length != 8) return code;
    return '${code.substring(0, 4)} ${code.substring(4)}';
  }

  // Pickup window display
  static String formatPickupWindow(DateTime start, DateTime end) {
    final localStart = start.toLocal();
    final localEnd = end.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(localStart.year, localStart.month, localStart.day);
    final timeFormat = DateFormat('h:mm a');

    String prefix;
    if (startDay == today) {
      prefix = 'Today';
    } else if (startDay == today.add(const Duration(days: 1))) {
      prefix = 'Tomorrow';
    } else {
      prefix = DateFormat('MMM d').format(localStart);
    }

    return '$prefix, ${timeFormat.format(localStart)} – ${timeFormat.format(localEnd)}';
  }
}