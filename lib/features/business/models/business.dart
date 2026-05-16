class Business {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String address;
  final double latitude;
  final double longitude;
  final String category; // 'bakery' | 'restaurant' | 'cafe' | 'market' | 'deli' | 'other'
  final String verificationStatus; // 'pending' | 'approved' | 'rejected' | 'suspended'
  final String edb;
  final String embs;
  final String? phone;
  final String? logoUrl;
  final String? openingTime;
  final String? closingTime;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.verificationStatus,
    required this.edb,
    required this.embs,
    this.phone,
    this.logoUrl,
    this.openingTime,
    this.closingTime,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      category: json['category'] as String,
      verificationStatus: json['verification_status'] as String,
      edb: json['edb'] as String,
      embs: json['embs'] as String,
      phone: json['phone'] as String?,
      logoUrl: json['logo_url'] as String?,
      openingTime: json['opening_time'] as String?,
      closingTime: json['closing_time'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get isPending => verificationStatus == 'pending';
  bool get isApproved => verificationStatus == 'approved';
  bool get isRejected => verificationStatus == 'rejected';
  bool get isSuspended => verificationStatus == 'suspended';
  bool get canListBags => isApproved && isActive;

  String get categoryLabel {
    switch (category) {
      case 'bakery': return 'Bakery';
      case 'restaurant': return 'Restaurant';
      case 'cafe': return 'Café';
      case 'market': return 'Market';
      case 'deli': return 'Deli';
      default: return 'Other';
    }
  }
}