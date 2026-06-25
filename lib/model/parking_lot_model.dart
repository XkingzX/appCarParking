// model/parking_lot_model.dart
class ParkingLotModel {
  final String id;
  final String? ownerId;
  final String? ownerName;
  final String name;
  final String? location;
  final double latitude;
  final double longitude;
  final double avgRating;
  final int totalReviews;
  final DateTime? createdAt;

  ParkingLotModel({
    required this.id,
    this.ownerId,
    this.ownerName,
    required this.name,
    this.location,
    required this.latitude,
    required this.longitude,
    this.avgRating = 0,
    this.totalReviews = 0,
    this.createdAt,
  });

  factory ParkingLotModel.fromJson(Map<String, dynamic> json) {
    return ParkingLotModel(
      id: json['id'] ?? '',
      ownerId: json['owner_id'],
      ownerName: json['profiles']?['full_name'], // Giả sử khi query có JOIN với profiles
      name: json['name'] ?? '',
      location: json['location'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
