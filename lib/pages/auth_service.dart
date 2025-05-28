// pages/auth_service.dart
import 'dart:async';
import 'package:eclapp/pages/signinpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'ProductModel.dart';

class AuthService {
  static const String baseUrl = "https://eclcommerce.ernestchemists.com.gh/api";
  static const String usersKey = "users";
  static const String loggedInUserKey = "loggedInUser";
  static const String isLoggedInKey = "isLoggedIn";
  static const String userNameKey = "userName";
  static const String userEmailKey = "userEmail";
  static const String userPhoneNumberKey = "userPhoneNumber";
  static const String authTokenKey = 'authToken';

  List<Product> products = [];
  List<Product> filteredProducts = [];
  static final FlutterSecureStorage secureStorage =
      const FlutterSecureStorage();
  static bool _isLoggedIn = false;
  static String? _authToken;
  static Timer? _tokenRefreshTimer;

  static Future<void> init() async {
    _authToken = await secureStorage.read(key: authTokenKey);
    _isLoggedIn = _authToken != null;
    if (_isLoggedIn) {
      _isLoggedIn = await _verifyToken();
      if (!_isLoggedIn) {
        await secureStorage.delete(key: authTokenKey);
        _authToken = null;
      }
    }
  }

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://eclcommerce.ernestchemists.com.gh/api/get-all-products'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> dataList = responseData['data'];

        final products = dataList.map<Product>((item) {
          final productData = item['product'] as Map<String, dynamic>;
          return Product(
            id: productData['id'] ?? 0,
            name: productData['name'] ?? 'No name',
            description: productData['description'] ?? '',
            urlName: productData['url_name'] ?? '',
            status: productData['status'] ?? '',
            batch_no: productData['batch_no'] ?? '',
            price: (item['price'] ?? 0).toString(),
            thumbnail: productData['thumbnail'] ?? '',
            quantity: productData['quantity'] ?? '',
            category: productData['category'] ?? '',
            route: productData['route'] ?? '',
          );
        }).toList();

        return products;
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  static Future<Product> fetchProductDetails(String urlName) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://eclcommerce.ernestchemists.com.gh/api/product-details/$urlName'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final productData = data['product'];

        return Product(
          id: productData['id'] ?? 0,
          name: productData['name'] ?? 'No name',
          description: productData['description'] ?? '',
          urlName: productData['url_name'] ?? '',
          status: productData['status'] ?? '',
          category: productData['category'] ?? '',
          route: productData['route'] ?? '',
          batch_no: productData['batch_no'] ?? '',
          price: (productData['price'] ?? 0).toString(),
          thumbnail: productData['thumbnail'] ?? '',
          quantity: productData['qty_in_stock']?.toString() ?? '',
        );
      } else {
        throw Exception('Failed to load product details');
      }
    } catch (e) {
      print('Error fetching product details: $e');
      throw Exception('Could not load product');
    }
  }

  // Sign up  user
  static Future<bool> signUp(
      String name, String email, String password, String phoneNumber) async {
    final url = Uri.parse('$baseUrl/register');

    final payload = {
      "name": name,
      "email": email,
      "password": password,
      "phone": phoneNumber,
    };
    print('SignUp request payload: ' + payload.toString());

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      print('SignUp response status: ' + response.statusCode.toString());
      print('SignUp response body: ' + response.body);

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Signup failed: " + response.body);
        return false;
      }
    } catch (error) {
      print("Error during signup: $error");
      return false;
    }
  }

  // OTP
  static Future<bool> verifyOTP(String email, String otp) async {
    final url = Uri.parse(
        'https://eclcommerce.ernestchemists.com.gh/api/otp-verification');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      );

      if (response.statusCode == 200) {
        print("OTP Verified Successfully!");
        print("API Raw Response: ${response.body}");

        return true;
      } else {
        print("OTP Verification Failed: ${response.body}");
        return false;
      }
    } catch (error) {
      print("Error during OTP verification: $error");
      return false;
    }
  }

  static Future<String?> getBearerToken() async {
    final token = await secureStorage.read(key: authTokenKey);
    return token != null ? 'Bearer $token' : null;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<void> saveToken(String token) async {
    await secureStorage.write(key: authTokenKey, value: token);
    print("Token saved: $token");
  }

  // Sign in a  user
  static Future<Map<String, dynamic>> signIn(
      String email, String password) async {
    try {
      final payload = {
        'email': email,
        'password': password,
      };
      print('SignIn request payload: ' + payload.toString());
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      print('SignIn response status: ' + response.statusCode.toString());
      print('SignIn response body: ' + response.body);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = responseData['access_token'];
        if (token == null) return {'success': false};

        // Update all state consistently
        await secureStorage.write(key: authTokenKey, value: token);
        if (responseData['user'] != null) {
          await storeUserData(responseData['user']);
        }

        _authToken = token;
        _isLoggedIn = true;
        _startTokenRefreshTimer();

        return {
          'success': true,
          'token': token,
          'user': responseData['user'],
        };
      }
      return {'success': false, 'message': responseData['message']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<bool> isLoggedIn() async {
    debugPrint('🔐 Checking auth state...');
    debugPrint('Memory state: $_isLoggedIn');
    debugPrint('Token exists: ${_authToken != null}');
    if (_isLoggedIn && _authToken != null) return true;

    final token = await secureStorage.read(key: authTokenKey);
    debugPrint('Storage token: ${token != null ? "exists" : "null"}');
    if (token == null) {
      _isLoggedIn = false;
      return false;
    }

    // Optional: Verify token with backend if needed
    final isValid = await _verifyToken();
    if (!isValid) {
      await logout();
      return false;
    }

    _authToken = token;
    _isLoggedIn = true;
    return true;
  }

  static Future<bool> _verifyToken() async {
    try {
      final token = await secureStorage.read(key: authTokenKey);
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/check-auth'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Token verification error: $e');
      return false;
    }
  }

  //  logout
  static Future<void> logout() async {
    try {
      if (_authToken != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {'Authorization': 'Bearer $_authToken'},
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _authToken = null;
      _isLoggedIn = false;
      await secureStorage.deleteAll();
      _tokenRefreshTimer?.cancel();
    }
  }

  static void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(Duration(minutes: 5), (_) async {
      if (await isLoggedIn()) {
        debugPrint("Token refresh check completed");
      }
    });
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getBearerToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': token ?? '',
    };
  }

  Future<void> saveUserDetails(String name, String email, String phone) async {
    await secureStorage.write(key: userNameKey, value: name);
    await secureStorage.write(key: userEmailKey, value: email);
    await secureStorage.write(key: userPhoneNumberKey, value: phone);
  }

  Future<String?> getUserName() async {
    try {
      String? userName = await secureStorage.read(key: userNameKey);
      print("Retrieved User Name: $userName");

      return userName?.isNotEmpty == true ? userName : "User";
    } catch (e) {
      print("Error retrieving user name: $e");
      return "User";
    }
  }

  Future<void> saveProfileImage(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image', imagePath);
  }

  static Future<String?> getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image');
  }

  static Future<void> storeUserData(Map<String, dynamic> user) async {
    try {
      await secureStorage.write(key: 'user_id', value: user['id'].toString());
      await secureStorage.write(key: userNameKey, value: user['name']);
      await secureStorage.write(key: userEmailKey, value: user['email']);
      if (user['phone'] != null) {
        await secureStorage.write(
            key: userPhoneNumberKey, value: user['phone']);
      }
      if (user['hashed_link'] != null) {
        await secureStorage.write(
            key: 'hashed_link', value: user['hashed_link']);
      }
      debugPrint("User data saved successfully");
    } catch (e) {
      debugPrint("Error saving user data: $e");
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final name = await secureStorage.read(key: 'userName');
      final email = await secureStorage.read(key: 'userEmail');
      final phone = await secureStorage.read(key: 'userphoneNumber');
      final id = await secureStorage.read(key: 'user_id');

      if (email == null) return null;

      return {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
      };
    } catch (e) {
      debugPrint("Error retrieving user data: $e");
      return null;
    }
  }

  static Future<String?> getCurrentUserID() async {
    try {
      final id = await secureStorage.read(key: 'user_id');
      if (id == null) {
        debugPrint('No user ID found in storage');
        return null;
      }
      debugPrint('Retrieved user ID: $id');
      return id;
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  //
  // static Future<void> saveToken(String token) async {
  //   await secureStorage.write(key: authTokenKey, value: token);
  //   print("Token saved: $token");
  // }

  static bool isValidJwt(String token) {
    final parts = token.split('.');
    return parts.length == 3;
  }

  static Future<bool> isUserSignedUp(String email) async {
    try {
      String? usersData = await secureStorage.read(key: usersKey);
      if (usersData == null) return false;

      Map<String, dynamic> rawUsers = json.decode(usersData);
      Map<String, Map<String, String>> users = rawUsers.map(
        (key, value) => MapEntry(key, Map<String, String>.from(value)),
      );

      return users.containsKey(email);
    } catch (e) {
      print("Error decoding users data: $e");
      return false;
    }
  }

  static Future<String?> getUserEmail() async {
    try {
      return await secureStorage.read(key: userEmailKey);
    } catch (e) {
      print("❌ Error retrieving user email: $e");
      return null;
    }
  }

  static Future<String?> getUserPhoneNumber() async {
    try {
      return await secureStorage.read(key: userPhoneNumberKey);
    } catch (e) {
      print("❌ Error retrieving phone number: $e");
      return null;
    }
  }

  static Future<void> debugPrintUserData() async {
    try {
      String? usersData = await secureStorage.read(key: usersKey);
      print("DEBUG: Users Data: $usersData");
    } catch (e) {
      print("Error retrieving user data for debugging: $e");
    }
  }

  static Future<bool> validateCurrentPassword(String password) async {
    try {
      String? userEmail = await secureStorage.read(key: loggedInUserKey);
      if (userEmail != null) {
        String? storedUserJson = await secureStorage.read(key: usersKey);
        if (storedUserJson != null) {
          Map<String, dynamic> users = jsonDecode(storedUserJson);

          if (users.containsKey(userEmail)) {
            String storedHash = users[userEmail]['password'];
            String inputHash = hashPassword(password);

            print("Entered Hashed Password: $inputHash");
            print("Stored Hashed Password: $storedHash");

            return storedHash == inputHash;
          }
        }
      }
      print("User not found or no password stored.");
      return false;
    } catch (e) {
      print("Error validating password: $e");
      return false;
    }
  }

  static Future<bool> updatePassword(
      String oldPassword, String newPassword) async {
    try {
      if (!(await validateCurrentPassword(oldPassword))) {
        print("Old password does not match.");
        return false;
      }

      String? userEmail = await secureStorage.read(key: loggedInUserKey);
      if (userEmail != null) {
        String? storedUserJson = await secureStorage.read(key: usersKey);
        if (storedUserJson != null) {
          Map<String, dynamic> users = jsonDecode(storedUserJson);
          users[userEmail]['password'] = hashPassword(newPassword);

          await secureStorage.write(key: usersKey, value: jsonEncode(users));
          print("Password updated successfully for $userEmail");
          return true;
        }
      }

      print("Password update failed.");
      return false;
    } catch (e) {
      print("Error updating password: $e");
      return false;
    }
  }

  static Future<void> saveUserName(String username) async {
    await secureStorage.write(key: userNameKey, value: username);
    print("Username saved: $username");
  }

  static Future<void> checkAuthAndRedirect(BuildContext context,
      {VoidCallback? onSuccess}) async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!isLoggedIn) {
      final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignInScreen(returnTo: currentRoute),
        ),
      );

      final stillLoggedIn = await AuthService.isLoggedIn();
      if (stillLoggedIn && onSuccess != null) {
        onSuccess();
      }
    } else if (onSuccess != null) {
      onSuccess();
    }
  }

  static Future<bool> checkAuthStatus() async {
    try {
      final token = await secureStorage.read(key: authTokenKey);
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/check-auth'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Auth check error: $e');
      return false;
    }
  }

  Future<bool> requireAuth(BuildContext context) async {
    if (await AuthService.isLoggedIn()) return true;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SignInScreen(
          returnTo: ModalRoute.of(context)?.settings.name,
        ),
      ),
    );

    return result ?? false;
  }

  static Future<Map<String, dynamic>> checkAuthWithCart() async {
    try {
      final token = await getToken();
      print('Token used for check-auth: $token');
      if (token == null) return {'authenticated': false};

      final response = await http.post(
        Uri.parse('$baseUrl/check-auth'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );
      print('Raw check-auth HTTP response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'authenticated': true,
          'items': data['items'] ?? [],
          'totalPrice': data['totalPrice'] ?? 0,
        };
      }
      return {};
    } catch (e) {
      debugPrint('Auth check error: $e');
      return {'authenticated': false};
    }
  }

  static Future<Map<String, dynamic>> getServerCart() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'cart': data['items'] ?? [],
          'lastUpdated': data['updated_at'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch cart: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  // Add this to your AuthService class
  static Future<String?> getToken() async {
    return await secureStorage.read(key: authTokenKey);
  }

  static Future<void> syncCartOnLogin(String userId) async {
    try {
      // 1. Get server cart first
      final serverCart = await getServerCart();

      if (serverCart['success']) {
        // 2. Merge with local cart if needed
        await mergeCarts(serverCart['cart']);
      }
    } catch (e) {
      debugPrint('Cart sync error: $e');
    }
  }

  static Future<void> mergeCarts(List<dynamic> serverItems) async {
    final prefs = await SharedPreferences.getInstance();
    final localCart = prefs.getString('local_cart');

    if (localCart != null) {
      // Implement your merge logic here
      // Compare timestamps or quantities to resolve conflicts
    }

    // Save the merged cart
    await prefs.setString('local_cart', jsonEncode(serverItems));
  }

  static Future<Map<String, dynamic>> updateServerCart(
      List<Map<String, dynamic>> items) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/cart/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'items': items,
          'last_updated': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': 'Failed to update cart: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> mergeServerCart(
      List<Map<String, dynamic>> items) async {
    try {
      final token = await getBearerToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/cart/merge'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'items': items}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'cart': json.decode(response.body),
        };
      }
      return {'success': false, 'message': 'Failed to merge cart'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addToCartCheckAuth({
    required int productID,
    required int quantity,
    required String batchNo,
  }) async {
    final token = await secureStorage.read(key: authTokenKey);
    final response = await http.post(
      Uri.parse('$baseUrl/check-auth'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'productID': productID,
        'quantity': quantity,
        'batch_no': batchNo,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<String?> getHashedLink() async {
    return await secureStorage.read(key: 'hashed_link');
  }

  static Future<Map<String, dynamic>> getOrders() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'status': 'error', 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Orders API response status: \\${response.statusCode}');
      debugPrint('Orders API response body: \\${response.body}');

      final data = jsonDecode(response.body);
      // Return the raw structure so the Purchases page can handle it
      return data is Map<String, dynamic>
          ? data
          : {'status': 'error', 'message': 'Invalid response'};
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return {
        'status': 'error',
        'message': 'Exception: $e',
      };
    }
  }
}

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!) {
          return SignInScreen(
            returnTo: ModalRoute.of(context)?.settings.name,
          );
        }

        return child;
      },
    );
  }
}

class AuthState extends InheritedWidget {
  final bool isLoggedIn;
  final Function() refreshAuthState;

  const AuthState({
    required this.isLoggedIn,
    required this.refreshAuthState,
    required super.child,
    super.key,
  });

  static AuthState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthState>();
  }

  @override
  bool updateShouldNotify(AuthState oldWidget) {
    return isLoggedIn != oldWidget.isLoggedIn;
  }
}
