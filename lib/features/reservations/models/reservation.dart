class Reservation {
  final String id;
  final String customerId;
  final String listingId;
  final String pickupCode;
  final String status; // 'confirmed' | 'completed' | 'cancelled' | 'no_show'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields (from query with bag_listings + businesses)
  final String? listingTitle;
  final String? businessName;
  final String? businessAddress;
  final double? price;
  final DateTime? pickupStart;
  final DateTime? pickupEnd;
  final String? listingImageUrl;

  const Reservation({
    required this.id,
    required this.customerId,
    required this.listingId,
    required this.pickupCode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.listingTitle,
    this.businessName,
    this.businessAddress,
    this.price,
    this.pickupStart,
    this.pickupEnd,
    this.listingImageUrl,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    // Handle nested join: bag_listings -> businesses
    final listing = json['bag_listings'] as Map<String, dynamic>?;
    final business = listing?['businesses'] as Map<String, dynamic>?;

    return Reservation(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      listingId: json['listing_id'] as String,
      pickupCode: json['pickup_code'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      listingTitle: listing?['title'] as String?,
      businessName: business?['name'] as String?,
      businessAddress: business?['address'] as String?,
      price: listing?['price'] != null
          ? double.parse(listing!['price'].toString())
          : null,
      pickupStart: listing?['pickup_start'] != null
          ? DateTime.parse(listing!['pickup_start'] as String)
          : null,
      pickupEnd: listing?['pickup_end'] != null
          ? DateTime.parse(listing!['pickup_end'] as String)
          : null,
      listingImageUrl: listing?['image_url'] as String?,
    );
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isNoShow => status == 'no_show';
  bool get canCancel => isConfirmed;
  bool get canReview => isCompleted;
}