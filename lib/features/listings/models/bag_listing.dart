class BagListing {
  final String id;
  final String businessId;
  final String? businessName;
  final String? businessLogoUrl;
  final String? businessAddress;
  final double? businessLat;
  final double? businessLng;
  final String title;
  final String? description;
  final String? imageUrl;
  final double price;
  final double originalValue;
  final int quantityTotal;
  final int quantityAvailable;
  final int? estWeightGrams;
  final DateTime pickupStart;
  final DateTime pickupEnd;
  final String status; // 'active' | 'sold_out' | 'expired' | 'cancelled'
  final DateTime createdAt;

  // From fn_listings_near_point (may be null if fetched directly)
  final double? distanceMetres;

  const BagListing({
    required this.id,
    required this.businessId,
    this.businessName,
    this.businessLogoUrl,
    this.businessAddress,
    this.businessLat,
    this.businessLng,
    required this.title,
    this.description,
    this.imageUrl,
    required this.price,
    required this.originalValue,
    required this.quantityTotal,
    required this.quantityAvailable,
    this.estWeightGrams,
    required this.pickupStart,
    required this.pickupEnd,
    required this.status,
    required this.createdAt,
    this.distanceMetres,
  });

  factory BagListing.fromJson(Map<String, dynamic> json) {
    return BagListing(
      id: json['id'] as String,
      businessId: (json['business_id'] ?? json['bid'] ?? '') as String,
      businessName: json['business_name'] as String?,
      businessLogoUrl: json['logo_url'] as String?,
      businessAddress: json['address'] as String?,
      businessLat: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      businessLng: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      price: double.parse(json['price'].toString()),
      originalValue: double.parse(json['original_value'].toString()),
      quantityTotal: json['quantity_total'] as int,
      quantityAvailable: json['quantity_available'] as int,
      estWeightGrams: json['est_weight_grams'] as int?,
      pickupStart: DateTime.parse(json['pickup_start'] as String),
      pickupEnd: DateTime.parse(json['pickup_end'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(
        (json['created_at'] ?? DateTime.now().toIso8601String()) as String,
      ),
      distanceMetres: json['distance_metres'] != null
          ? double.parse(json['distance_metres'].toString())
          : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isSoldOut => status == 'sold_out';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';
  bool get isAvailable => isActive && quantityAvailable > 0;

  double get discountPercent =>
      ((originalValue - price) / originalValue * 100).roundToDouble();

  String get distanceLabel {
    if (distanceMetres == null) return '';
    if (distanceMetres! < 1000) {
      return '${distanceMetres!.round()} m';
    }
    return '${(distanceMetres! / 1000).toStringAsFixed(1)} km';
  }
}