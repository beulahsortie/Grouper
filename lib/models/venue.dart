class Venue {
  final int id;
  final String name;
  final double price;
  final String imageUrl;

  Venue({required this.id, required this.name, required this.price, required this.imageUrl});

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
        id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
        name: json['name'] ?? '',
        price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse('${json['price']}') ?? 0.0,
        imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      );
}
