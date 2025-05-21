class Product {
  final int id;
  final String name;
  final String description;
  final String urlName;
  final String status;
  final String price;
  final String thumbnail;
  final String quantity;
  final String category;
  final String? route;
  final List<String> tags;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.urlName,
    required this.status,
    required this.price,
    required this.thumbnail,
    required this.quantity,
    required this.category,
    required this.route,
    this.tags = const [],
  });


  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      urlName: json['url_name'],
      status: json['status'],
      price: json['price']?.toString() ?? '0.00',
      thumbnail: json['thumbnail'] ?? '',
      quantity: json['quantity'] ?? '',
      category: json['category'] ?? '',
      route: json['route'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
    );
  }
}