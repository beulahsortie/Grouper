class Category {
  final int id;
  final String title;
  final String imageUrl;

  Category({required this.id, required this.title, required this.imageUrl});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
        title: json['title'] ?? '',
        imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      );
}
