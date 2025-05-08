import 'package:flutter/foundation.dart';
import 'CartItem.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];
  List<CartItem> _purchasedItems = [];

  List<CartItem> get cartItems => _cartItems;
  List<CartItem> get purchasedItems => _purchasedItems;

  CartProvider() {
    _loadCart();
    _loadPurchasedItems();
  }

  void addToCart(CartItem item) {
    int index = _cartItems.indexWhere((existingItem) => existingItem.id == item.id);
    if (index != -1) {
      _cartItems[index].updateQuantity(_cartItems[index].quantity + item.quantity);
    } else {
      _cartItems.add(item);
    }
    _saveCart();
    notifyListeners();
  }

  void purchaseItems() {
    _purchasedItems.addAll(_cartItems);
    _cartItems.clear();
    _saveCart();
    _savePurchasedItems();
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cartItems.removeAt(index);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      _cartItems[index].updateQuantity(newQuantity);
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _saveCart();
    notifyListeners();
  }

  double calculateTotal() {
    return _cartItems.fold(0, (total, item) => total + (item.price * item.quantity));
  }

  double calculateSubtotal() {
    return _cartItems.fold(0, (subtotal, item) => subtotal + (item.price * item.quantity));
  }

  // Save cart to SharedPreferences
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(_cartItems.map((item) => item.toJson()).toList());
    await prefs.setString('cart', cartJson);
  }

  // Load cart from SharedPreferences
  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('cart');
    if (cartJson != null) {
      final cartList = jsonDecode(cartJson) as List;
      _cartItems = cartList.map((item) => CartItem.fromJson(item)).toList();
    }
    notifyListeners();
  }


  Future<void> _savePurchasedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final purchasedJson = jsonEncode(_purchasedItems.map((item) => item.toJson()).toList());
    await prefs.setString('purchasedItems', purchasedJson);
  }

  Future<void> _loadPurchasedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final purchasedJson = prefs.getString('purchasedItems');
    if (purchasedJson != null) {
      final purchasedList = jsonDecode(purchasedJson) as List;
      _purchasedItems = purchasedList.map((item) => CartItem.fromJson(item)).toList();
    }
    notifyListeners();
  }



  // In your CartProvider
  Future<void> syncWithApi() async {
    final authResult = await AuthService.checkAuthWithCart();
    if (authResult['authenticated'] == true) {
      final apiItems = authResult['cartItems'] as List;
      // Convert API items to your CartItem format
      final items = apiItems.map((item) => CartItem(
        id: item['product_id'].toString(),
        name: item['product_name'],
        price: item['price'].toDouble(),
        image: item['product_img'],
        quantity: item['qty'],
      )).toList();

      // Update local cart with API data
      _cartItems = items;
      notifyListeners();
    }
  }


  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);


}
