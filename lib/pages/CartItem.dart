class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String image;
  final DateTime? purchaseDate;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    required this.image,
    this.purchaseDate,
  });

  double get totalPrice => price * quantity;

  void updateQuantity(int newQuantity) {
    quantity = newQuantity;
  }


  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'image': image,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'],
    name: json['name'],
    price: json['price'],
    quantity: json['quantity'],
    image: json['image'],
  );
}