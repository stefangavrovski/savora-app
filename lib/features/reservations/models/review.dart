class Review {
  final String id;
  final String reservationId;
  final String customerId;
  final String businessId;
  final int rating; // 1–5
  final String? comment;
  final DateTime createdAt;
  final String? reviewerName;

  const Review({
    required this.id,
    required this.reservationId,
    required this.customerId,
    required this.businessId,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.reviewerName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final reviewer = json['profiles'] as Map<String, dynamic>?;

    return Review(
      id: json['id'] as String,
      reservationId: json['reservation_id'] as String,
      customerId: json['customer_id'] as String,
      businessId: json['business_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewerName: reviewer?['full_name'] as String?,
    );
  }
}