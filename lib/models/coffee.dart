class Helmet {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final double rating;
  final String? address;

  Helmet({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.rating,
    this.address,
  });

  factory Helmet.fromJson(Map<String, dynamic> json) {
    return Helmet(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
      category: json['category'] ?? '',
      rating: (json['rating'] ?? 4.5).toDouble(),
      address: json['address'],
    );
  }
}
