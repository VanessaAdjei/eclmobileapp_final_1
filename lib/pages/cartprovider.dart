// pages/cartprovider.dart
import 'package:flutter/foundation.dart';
import 'CartItem.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;

class CartProvider with ChangeNotifier {
  // Map to store carts for different users
  Map<String, List<CartItem>> _userCarts = {};
  // Current user's cart items
  List<CartItem> _cartItems = [];
  List<CartItem> _purchasedItems = [];
  String? _currentUserId;

  List<CartItem> get cartItems => _cartItems;
  List<CartItem> get purchasedItems => _purchasedItems;

  CartProvider() {
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    await _loadUserCarts();
    await _checkCurrentUser();
    // If logged in, always sync with server
    if (_currentUserId != null) {
      await syncWithApi();
    }
  }

  Future<void> _checkCurrentUser() async {
    bool isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      String userId = (await AuthService.getCurrentUserID()) as String;
      _currentUserId = userId;
      _loadCurrentUserCart();
    } else {
      _currentUserId = null;
      _cartItems = [];
    }
    notifyListeners();
  }

  Future<void> _loadUserCarts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('user_carts');
      if (cartJson != null) {
        final Map<String, dynamic> userCartsMap = jsonDecode(cartJson);
        _userCarts = {};

        userCartsMap.forEach((userId, cartData) {
          final cartList = (cartData as List).cast<Map<String, dynamic>>();
          _userCarts[userId] =
              cartList.map((item) => CartItem.fromJson(item)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading user carts: $e');
    }
  }

  void _loadCurrentUserCart() {
    if (_currentUserId != null && _userCarts.containsKey(_currentUserId)) {
      _cartItems = _userCarts[_currentUserId]!;
    } else {
      _cartItems = [];
    }

    // Load purchased items for current user
    _loadPurchasedItems();
  }

  Future<void> _saveUserCarts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update current user's cart in the map if logged in
      if (_currentUserId != null) {
        _userCarts[_currentUserId!] = _cartItems;
      }

      // Convert user carts to JSON
      final Map<String, dynamic> userCartsJson = {};
      _userCarts.forEach((userId, cartItems) {
        userCartsJson[userId] = cartItems.map((item) => item.toJson()).toList();
      });

      await prefs.setString('user_carts', jsonEncode(userCartsJson));
    } catch (e) {
      debugPrint('Error saving user carts: $e');
    }
  }

  void addToCart(CartItem item) async {
    if (!await AuthService.isLoggedIn()) {
      debugPrint('User must be logged in to add items to cart');
      return;
    }

    _currentUserId ??= await AuthService.getCurrentUserID();

    int index =
        _cartItems.indexWhere((existingItem) => existingItem.id == item.id);
    if (index != -1) {
      _cartItems[index]
          .updateQuantity(_cartItems[index].quantity + item.quantity);
    } else {
      _cartItems.add(item);
    }

    await _saveUserCarts();
    notifyListeners();

    final hashedLink = await AuthService.getHashedLink();
    final token = await AuthService.getToken();
    if (hashedLink == null) {
      debugPrint(
          'No hashed_link found for user. Cannot add to cart on server.');
      return;
    }

    final url =
        'https://eclcommerce.ernestchemists.com.gh/api/check-out/$hashedLink';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final payload = {
      'product_id': item.id,
      'quantity': item.quantity,
      'price': item.price,
      'name': item.name,
      'image': item.image,
    };

    debugPrint('POST $url');
    debugPrint('Headers: $headers');
    debugPrint('Body: ${jsonEncode(payload)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );
      debugPrint('Add to cart API response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['items'] != null) {
          final serverItems = (responseData['items'] as List)
              .map((item) => CartItem(
                    id: item['product_id']?.toString() ??
                        item['id']?.toString() ??
                        '',
                    name: item['product_name'] ?? item['name'] ?? '',
                    price: (item['price'] is int || item['price'] is double)
                        ? item['price'].toDouble()
                        : double.tryParse(item['price'].toString()) ?? 0.0,
                    image: item['product_img'] ?? item['image'] ?? '',
                    quantity: item['qty'] ?? item['quantity'] ?? 1,
                  ))
              .toList();
          _cartItems = serverItems;
          await _saveUserCarts();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Add to cart error: $e');
    }
  }

  void purchaseItems() async {
    if (_currentUserId == null) return;

    _purchasedItems.addAll(_cartItems);
    _cartItems.clear();

    await _saveUserCarts();
    await _savePurchasedItems();
    await _pushCartToServer();
    notifyListeners();
  }

  void removeFromCart(int index) async {
    if (_currentUserId == null) return;

    final removedItem = _cartItems[index];
    _cartItems.removeAt(index);
    await _saveUserCarts();
    notifyListeners();

    // Get hashed link for API endpoint
    final hashedLink = await AuthService.getHashedLink();
    final token = await AuthService.getToken();
    if (hashedLink == null) {
      debugPrint(
          'No hashed_link found for user. Cannot remove from cart on server.');
      return;
    }

    final url = Uri.parse(
            'https://eclcommerce.ernestchemists.com.gh/api/check-out/$hashedLink')
        .replace(queryParameters: {'product_id': removedItem.id});
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.delete(
        url,
        headers: headers,
      );
      debugPrint(
          'Remove from cart API response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == 'success' &&
              responseData['items'] != null) {
            final serverItems = (responseData['items'] as List)
                .map((item) => CartItem(
                      id: item['product_id']?.toString() ??
                          item['id']?.toString() ??
                          '',
                      name: item['product_name'] ?? item['name'] ?? '',
                      price: (item['price'] is int || item['price'] is double)
                          ? item['price'].toDouble()
                          : double.tryParse(item['price'].toString()) ?? 0.0,
                      image: item['product_img'] ?? item['image'] ?? '',
                      quantity: item['qty'] ?? item['quantity'] ?? 1,
                    ))
                .toList();
            _cartItems = serverItems;
            await _saveUserCarts();
            notifyListeners();
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  void updateQuantity(int index, int newQuantity) async {
    if (_currentUserId == null) return;

    if (newQuantity > 0) {
      _cartItems[index].updateQuantity(newQuantity);
      await _saveUserCarts();
      await _pushCartToServer();
      notifyListeners();
    }
  }

  void clearCart() async {
    if (_currentUserId == null) return;

    _cartItems.clear();
    await _saveUserCarts();
    await _pushCartToServer();
    notifyListeners();
  }

  double calculateTotal() {
    return _cartItems.fold(
        0, (total, item) => total + (item.price * item.quantity));
  }

  double calculateSubtotal() {
    return _cartItems.fold(
        0, (subtotal, item) => subtotal + (item.price * item.quantity));
  }

  Future<void> _savePurchasedItems() async {
    if (_currentUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'purchasedItems_$_currentUserId';
    final purchasedJson =
        jsonEncode(_purchasedItems.map((item) => item.toJson()).toList());
    await prefs.setString(key, purchasedJson);
  }

  Future<void> _loadPurchasedItems() async {
    if (_currentUserId == null) {
      _purchasedItems = [];
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = 'purchasedItems_$_currentUserId';
    final purchasedJson = prefs.getString(key);

    if (purchasedJson != null) {
      final purchasedList = jsonDecode(purchasedJson) as List;
      _purchasedItems = purchasedList
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      _purchasedItems = [];
    }
  }

  Future<void> syncWithApi() async {
    print('syncWithApi called');
    if (_currentUserId == null) {
      print('No current user ID');
      return;
    }

    final authResult = await AuthService.checkAuthWithCart();
    print('syncWithApi backend response: $authResult');
    if (authResult == null) {
      print('authResult is null');
      return;
    }
    if (authResult['authenticated'] == true ||
        authResult['status'] == 'success') {
      final apiItems = authResult['items'] as List?;
      print('apiItems: $apiItems');
      if (apiItems == null) {
        print('apiItems is null');
        return;
      }
      final serverCart = apiItems
          .map((item) => CartItem(
                id: item['product_id']?.toString() ??
                    item['id']?.toString() ??
                    '',
                name: item['product_name'] ?? item['name'] ?? '',
                price: (item['price'] is int || item['price'] is double)
                    ? item['price'].toDouble()
                    : double.tryParse(item['price'].toString()) ?? 0.0,
                image: item['product_img'] ?? item['thumbnail'] ?? '',
                quantity: item['qty'] ?? item['quantity'] ?? 1,
              ))
          .toList();

      // Merge local and server carts by summing quantities for same id
      final Map<String, CartItem> merged = {};
      for (final item in _cartItems) {
        merged[item.id] = item;
      }
      for (final item in serverCart) {
        if (merged.containsKey(item.id)) {
          merged[item.id] = merged[item.id]!.copyWith(
            quantity: merged[item.id]!.quantity + item.quantity,
          );
        } else {
          merged[item.id] = item;
        }
      }
      _cartItems = merged.values.toList();
      await _saveUserCarts();
      await _pushCartToServer(); // Optionally push merged cart to server
      notifyListeners();
    } else {
      print('authResult did not pass the if condition');
    }
  }

  Future<void> handleUserLogin(String userId) async {
    _currentUserId = userId;

    // Load this user's cart if it exists
    if (_userCarts.containsKey(userId)) {
      _cartItems = _userCarts[userId]!;
    } else {
      _cartItems = [];
      _userCarts[userId] = _cartItems;
    }

    // Load purchased items for this user
    await _loadPurchasedItems();
    // Always sync with server on login
    await syncWithApi();
    notifyListeners();
  }

  Future<void> handleUserLogout() async {
    // Save current cart before logout if user is logged in
    if (_currentUserId != null) {
      _userCarts[_currentUserId!] = _cartItems;
      await _saveUserCarts();
    }

    _currentUserId = null;
    _cartItems = [];
    _purchasedItems = [];
    notifyListeners();
  }

  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  Future<void> _pushCartToServer() async {
    if (_currentUserId == null) return;
    final items = _cartItems.map((item) => item.toJson()).toList();
    await AuthService.updateServerCart(items);
  }

  void setCartItems(List<CartItem> items) {
    // Merge items with the same id by summing their quantities
    final Map<String, CartItem> merged = {};
    for (final item in items) {
      if (merged.containsKey(item.id)) {
        merged[item.id] = merged[item.id]!.copyWith(
          quantity: merged[item.id]!.quantity + item.quantity,
        );
      } else {
        merged[item.id] = item;
      }
    }
    _cartItems = merged.values.toList();
    notifyListeners();
  }
}
