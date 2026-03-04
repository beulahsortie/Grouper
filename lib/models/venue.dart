class Venue {
  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final double? distanceKm;
  final int? categoryId;

  Venue({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.distanceKm,
    this.categoryId,
  });

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
        id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
        name: json['name'] ?? '',
        price: (json['price'] is num)
            ? (json['price'] as num).toDouble()
            : double.tryParse('${json['price']}') ?? 0.0,
        imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
        latitude: json['latitude'] != null
            ? (json['latitude'] is num
                ? (json['latitude'] as num).toDouble()
                : double.tryParse('${json['latitude']}'))
            : null,
        longitude: json['longitude'] != null
            ? (json['longitude'] is num
                ? (json['longitude'] as num).toDouble()
                : double.tryParse('${json['longitude']}'))
            : null,
        address: json['address'],
        distanceKm: json['distance_km'] != null
            ? (json['distance_km'] is num
                ? (json['distance_km'] as num).toDouble()
                : double.tryParse('${json['distance_km']}'))
            : null,
        categoryId: json['category_id'] != null
            ? (json['category_id'] is int
                ? json['category_id']
                : int.tryParse('${json['category_id']}'))
            : null,
      );
}