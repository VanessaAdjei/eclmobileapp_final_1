import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/expresspay_service.dart';
import 'auth_service.dart';
import 'bottomnav.dart';
import 'cartprovider.dart';
import 'homepage.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedPaymentMethod = 'Mobile Money';
  bool savePaymentMethod = false;
  late ExpressPayApi expressPayApi;
  bool _isProcessingPayment = false;
  String _userName = "User";
  String _userEmail = "No email available";
  String _phoneNumber = "";
  String? _paymentError;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'name': 'Mobile Money',
      'icon': Icons.phone_android,
      'description': 'Pay with MTN, Vodafone, or AirtelTigo',
    },
    {
      'name': 'Card',
      'icon': Icons.credit_card,
      'description': 'Pay with a debit/credit card',
    },
    {
      'name': 'Cash on Delivery',
      'icon': Icons.money,
      'description': 'Pay when you receive your order',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print("Starting user data loading...");
      await _loadUserData();
      await _fetchUserDataFromAuthService();
      print("User data loading complete");
      print("Final values:");
      print("Name: $_userName");
      print("Email: $_userEmail");
      print("Phone: $_phoneNumber");
    });
    expressPayApi = ExpressPayApi(
      context,
      "https://sandbox.expresspaygh.com/api/sdk/php/server.php",
    );
    expressPayApi.setPaymentCompletionListener(onExpressPayPaymentFinished);
  }

  void onExpressPayPaymentFinished(bool paymentCompleted, String message) {
    setState(() {
      _isProcessingPayment = false;
    });

    if (paymentCompleted) {
      // Payment was completed
      String? token = expressPayApi.getToken();
      if (token != null) {
        queryPayment(token);
      }
    } else {
      // Payment failed
      debugPrint('expressPayDemo: $message');
      setState(() {
        _paymentError = 'Payment was not completed. $message';
      });
      _showPaymentFailureDialog(message);
    }
  }

  void _showPaymentFailureDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text('Your payment could not be processed. $message'),
              const SizedBox(height: 8),
              const Text('Please try again or select a different payment method.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                // Reset payment error state
                setState(() {
                  _paymentError = null;
                });
                // Get the cart provider
                final cart = Provider.of<CartProvider>(context, listen: false);
                // Try the payment again
                processPayment(cart);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadUserData() async {
    final secureStorage = const FlutterSecureStorage();

    try {
      String? name = await secureStorage.read(key: 'userName') ??
          await secureStorage.read(key: 'userName');  // Try both possible keys

      String? email = await secureStorage.read(key: 'userEmail') ??
          await secureStorage.read(key: 'userEmail');

      String? phoneNumber = await secureStorage.read(key: 'userPhoneNumber') ??
          await secureStorage.read(key: 'userPhoneNumber') ??
          await secureStorage.read(key: 'userPhone');

      // Debug the values
      print("Retrieved userName: ${name ?? 'null'}");
      print("Retrieved userEmail: ${email ?? 'null'}");
      print("Retrieved userPhone: ${phoneNumber ?? 'null'}");

      // Use AuthService to get current user as a backup method
      if (name == null || email == null || phoneNumber == null) {
        final userData = await AuthService.getCurrentUser();
        if (userData != null) {
          name = userData['name'] ?? name;
          email = userData['email'] ?? email;
          phoneNumber = userData['phone'] ?? phoneNumber;

          print("Backup retrieval - name: ${name ?? 'null'}");
          print("Backup retrieval - email: ${email ?? 'null'}");
          print("Backup retrieval - phone: ${phoneNumber ?? 'null'}");
        }
      }

      setState(() {
        _userName = name ?? "User";
        _userEmail = email ?? "No email available";
        _phoneNumber = phoneNumber ?? "";
      });
    } catch (e) {
      print("Error loading user data: $e");
      // Set defaults in case of error
      setState(() {
        _userName = "User";
        _userEmail = "No email available";
        _phoneNumber = "";
      });
    }
  }

  Future<void> _fetchUserDataFromAuthService() async {
    try {
      final userData = await AuthService.getCurrentUser();
      if (userData != null) {
        setState(() {
          _userName = userData['name'] ?? "User";
          _userEmail = userData['email'] ?? "No email available";
          _phoneNumber = userData['phone'] ?? "";
        });

        print("AuthService data - name: $_userName");
        print("AuthService data - email: $_userEmail");
        print("AuthService data - phone: $_phoneNumber");
      }
    } catch (e) {
      print("Error fetching from AuthService: $e");
    }
  }

  void queryPayment(String token) {
    expressPayApi.setQueryCompletionListener((paymentSuccessful, jsonObject, message) {
      if (paymentSuccessful) {
        debugPrint('Payment Successful: Navigating to Order Confirmation');
        Provider.of<CartProvider>(context, listen: false).clearCart();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const OrderConfirmationPage(),
          ),
              (route) => false,
        );
      } else {
        debugPrint('expressPayDemo: $message');
        setState(() {
          _paymentError = 'Payment verification failed: $message';
        });
        _showPaymentFailureDialog('Payment verification failed: $message');
      }
    });
    expressPayApi.query(token);
  }

  Future<void> processPayment(CartProvider cart) async {
    // Clear any previous errors
    setState(() {
      _paymentError = null;
      _isProcessingPayment = true;
    });

    // Check if phone number is available for Mobile Money payment
    if (selectedPaymentMethod == 'Mobile Money' && (_phoneNumber.isEmpty || _phoneNumber.length < 10)) {
      setState(() {
        _isProcessingPayment = false;
        _paymentError = 'Please provide a valid phone number for Mobile Money payments';
      });
      _showPaymentFailureDialog('Please provide a valid phone number for Mobile Money payments');
      return;
    }

    // Calculate cart total
    final subtotal = cart.calculateSubtotal();
    final deliveryFee = 5.00;
    final total = subtotal + deliveryFee;

    // Description of cart items
    String orderDesc = cart.cartItems.map((item) =>
    '${item.quantity}x ${item.name}'
    ).join(', ');

    if (orderDesc.length > 100) {
      orderDesc = '${orderDesc.substring(0, 97)}...';
    }

    // Split full name to first and last name
    final nameParts = _userName.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final params = {
      'request': 'submit',
      'order_id': 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
      'currency': 'GHS',
      'amount': total.toStringAsFixed(2),
      'order_desc': orderDesc,
      'user_name': _userEmail,
      'first_name': firstName,
      'last_name': lastName.isEmpty ? 'Customer' : lastName,
      'email': _userEmail,
      'phone_number': _phoneNumber,
      'account_number': _phoneNumber,
      'payment_method': selectedPaymentMethod == 'Card' ? 'card' :
      selectedPaymentMethod == 'Mobile Money' ? 'momo' : 'cod',
    };

    try {
      final response = await http.post(
        Uri.parse("https://sandbox.expresspaygh.com/api/sdk/php/server.php"),
        body: params,
      );

      print("ExpressPay Request: $params");
      print("API Response: ${response.body}");

      final jsonResponse = jsonDecode(response.body);
      final redirectUrl = jsonResponse['redirect-url'];

      if (redirectUrl != null) {
        await _launchCheckoutUrl(redirectUrl);
      } else {
        final errorMsg = jsonResponse['message'] ?? 'Payment failed (no redirect URL)';
        setState(() {
          _paymentError = 'Error: $errorMsg';
        });
        _showPaymentFailureDialog(errorMsg);
      }
    } catch (e) {
      setState(() {
        _paymentError = 'Payment Error: ${e.toString()}';
      });
      _showPaymentFailureDialog(e.toString());
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _launchCheckoutUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      setState(() {
        _paymentError = 'Could not launch payment page';
      });
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: kToolbarHeight + topPadding,
                child: AppBar(
                  backgroundColor: Colors.green.shade700,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  automaticallyImplyLeading: false,
                ),
              ),
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPaymentMethods(),
                          const SizedBox(height: 20),
                          _buildSavePaymentToggle(),
                          if (_paymentError != null) _buildErrorBanner(),
                          const SizedBox(height: 20),
                          _buildOrderSummary(cart),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: _isProcessingPayment ? null : () => processPayment(cart),
                              child: _isProcessingPayment
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                'CONTINUE TO PAYMENT',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            child: _buildProgressIndicator(),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _paymentError ?? 'An error occurred with your payment',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProgressStep("Delivery", isActive: false, onTap: () {
            // Navigate back to delivery page if it exists in your flow
            Navigator.pop(context);
          }),
          _buildArrow(),
          _buildProgressStep("Payment", isActive: true),
          _buildArrow(),
          _buildProgressStep("Confirmation", isActive: false, onTap: () {
            // Only allow navigation if payment is complete
            if (!_isProcessingPayment) {
              // This would typically be enabled after payment is complete
              // For now, just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Complete payment first')),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String text, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 50,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Icon(
        Icons.label_outline,
        color: Colors.grey[400],
        size: 20,
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT METHOD',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...paymentMethods.map((method) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: RadioListTile<String>(
              title: Row(
                children: [
                  Icon(method['icon'], color: Colors.green),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        method['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              value: method['name'],
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value!;
                  // Clear error when payment method changes
                  _paymentError = null;
                });
              },
              activeColor: Colors.green,
            ),
          );
        }),
        if (selectedPaymentMethod == 'Mobile Money' && _phoneNumber.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Text(
              'A valid phone number is required for Mobile Money payments',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSavePaymentToggle() {
    return Row(
      children: [
        Checkbox(
          value: savePaymentMethod,
          onChanged: (value) {
            setState(() {
              savePaymentMethod = value!;
            });
          },
          activeColor: Colors.green,
        ),
        const Text('Save this payment method '),
      ],
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    final subtotal = cart.calculateSubtotal();
    final deliveryFee = 5.00;
    final total = subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDER SUMMARY',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal', subtotal),
          _buildSummaryRow('Delivery Fee', deliveryFee),
          const Divider(),
          _buildSummaryRow('TOTAL', total, isHighlighted: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'GH₵${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Navigating to OrderConfirmationPage');
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Order Placed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your order has been placed successfully',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  HomePage(),
                  ),
                      (route) => false,
                );
              },
              child: const Text('Back to Home',style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}