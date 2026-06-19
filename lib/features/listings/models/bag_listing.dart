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
  final String status;
  final DateTime createdAt;
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
    final logoUrl =
        (json['business_logo_url'] ?? json['logo_url']) as String?;

    final businessId =
        (json['business_id'] ?? '') as String;

    final quantityTotal = json['quantity_total'];
    final quantityAvailable = json['quantity_available'];

    return BagListing(
      id: json['id'] as String,
      businessId: businessId,
      businessName: json['business_name'] as String?,
      businessLogoUrl: logoUrl,
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
      // Guard nulls that caused the "type 'Null' is not a subtype of 'String'" crash
      quantityTotal: quantityTotal != null ? (quantityTotal as num).toInt() : 0,
      quantityAvailable: quantityAvailable != null
          ? (quantityAvailable as num).toInt()
          : 0,
      estWeightGrams: json['est_weight_grams'] != null
          ? (json['est_weight_grams'] as num).toInt()
          : null,
      pickupStart: DateTime.parse(json['pickup_start'] as String),
      pickupEnd: DateTime.parse(json['pickup_end'] as String),
      status: (json['status'] as String?) ?? 'active',
      createdAt: DateTime.parse(
        (json['created_at'] as String?) ?? DateTime.now().toIso8601String(),
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
    if (distanceMetres! < 1000) return '${distanceMetres!.round()} m';
    return '${(distanceMetres! / 1000).toStringAsFixed(1)} km';
  }
}