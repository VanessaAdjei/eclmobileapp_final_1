// pages/CartItem.dart
class CartItem {
  final String id;
  final String name;
  final double price;
  final double? originalPrice; // Added for sale price tracking
  int quantity;
  final String image;
  final DateTime? purchaseDate;
  DateTime? lastModified; // Changed to nullable

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice, // Added optional original price
    this.quantity = 1,
    required this.image,
    this.purchaseDate,
    DateTime?
        modifiedDate, // Renamed parameter to avoid initialization conflict
  }) {
    // Initialize lastModified in the constructor body instead
    lastModified = modifiedDate ?? DateTime.now();
  }

  void updateQuantity(int newQuantity) {
    quantity = newQuantity;
    lastModified = DateTime.now();
  }

  double get totalPrice => price * quantity;

  // Enhanced toJson to be more robust
  Map<String, dynamic> toJson() {
    try {
      return {
        'id': id,
        'name': name,
        'price': price,
        if (originalPrice != null) 'originalPrice': originalPrice,
        'quantity': quantity,
        'image': image,
        // Handle potential null lastModified
        if (lastModified != null)
          'lastModified': lastModified!.toIso8601String(),
        if (purchaseDate != null)
          'purchaseDate': purchaseDate!.toIso8601String(),
      };
    } catch (e) {
      // Fallback if any serialization fails
      print('Error in CartItem.toJson(): $e');
      return {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'image': image,
        'lastModified': DateTime.now().toIso8601String(),
      };
    }
  }

  // Robust fromJson implementation
  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Ensure required fields have defaults
    final String itemId = json['id']?.toString() ?? '0';
    final String itemName = json['name']?.toString() ?? 'Unknown Item';

    // Handle price conversion safely
    double itemPrice = 0.0;
    double? itemOriginalPrice;
    try {
      final dynamic rawPrice = json['price'];
      if (rawPrice is double) {
        itemPrice = rawPrice;
      } else if (rawPrice is int) {
        itemPrice = rawPrice.toDouble();
      } else if (rawPrice is String) {
        itemPrice = double.tryParse(rawPrice) ?? 0.0;
      }

      // Handle original price if present
      final dynamic rawOriginalPrice = json['originalPrice'];
      if (rawOriginalPrice != null) {
        if (rawOriginalPrice is double) {
          itemOriginalPrice = rawOriginalPrice;
        } else if (rawOriginalPrice is int) {
          itemOriginalPrice = rawOriginalPrice.toDouble();
        } else if (rawOriginalPrice is String) {
          itemOriginalPrice = double.tryParse(rawOriginalPrice);
        }
      }
    } catch (_) {
      // Default to 0 if price parsing fails
    }

    // Parse quantity safely
    int itemQuantity = 1;
    try {
      final dynamic rawQuantity = json['quantity'];
      if (rawQuantity is int) {
        itemQuantity = rawQuantity;
      } else if (rawQuantity is String) {
        itemQuantity = int.tryParse(rawQuantity) ?? 1;
      }
      // Ensure quantity is at least 1
      if (itemQuantity < 1) itemQuantity = 1;
    } catch (_) {
      // Default to 1 if quantity parsing fails
    }

    // Handle image URL
    final String itemImage = json['image']?.toString() ?? '';

    // Parse lastModified with fallbacks
    DateTime? itemLastModified;
    try {
      final dynamic rawLastModified = json['lastModified'];
      if (rawLastModified is String && rawLastModified.isNotEmpty) {
        itemLastModified = DateTime.parse(rawLastModified);
      } else {
        // Only set current time if lastModified was not in the JSON
        itemLastModified = DateTime.now();
      }
    } catch (e) {
      print('Error parsing lastModified: $e');
      // Set current time on parsing failure
      itemLastModified = DateTime.now();
    }

    // Parse optional purchaseDate
    DateTime? itemPurchaseDate;
    try {
      final dynamic rawPurchaseDate = json['purchaseDate'];
      if (rawPurchaseDate is String && rawPurchaseDate.isNotEmpty) {
        itemPurchaseDate = DateTime.parse(rawPurchaseDate);
      }
    } catch (e) {
      print('Error parsing purchaseDate: $e');
      // Keep as null on parsing failure
    }

    return CartItem(
      id: itemId,
      name: itemName,
      price: itemPrice,
      originalPrice: itemOriginalPrice,
      quantity: itemQuantity,
      image: itemImage,
      modifiedDate:
          itemLastModified, // Changed from lastModified to modifiedDate
      purchaseDate: itemPurchaseDate,
    );
  }

  // Add support for comparing CartItems
  bool equals(CartItem other) {
    return id == other.id &&
        name == other.name &&
        price == other.price &&
        originalPrice == other.originalPrice &&
        image == other.image;
  }

  // Add a clone method to create a copy with potentially different values
  CartItem clone({
    String? id,
    String? name,
    double? price,
    double? originalPrice,
    int? quantity,
    String? image,
    DateTime? modifiedDate,
    DateTime? purchaseDate,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      modifiedDate: modifiedDate ?? lastModified,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }

  // Add a copyWith method for updating fields
  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    double? originalPrice,
    int? quantity,
    String? image,
    DateTime? modifiedDate,
    DateTime? purchaseDate,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      modifiedDate: modifiedDate ?? this.lastModified,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }
}
