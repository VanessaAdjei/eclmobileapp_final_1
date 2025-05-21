// pages/cart.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eclapp/pages/homepage.dart';
import 'bottomnav.dart';
import 'cartprovider.dart';
import 'delivery_page.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  String deliveryOption = 'Delivery';

  String? selectedRegion;
  String? selectedCity;
  String? selectedTown;
  double deliveryFee = 0.00;

  TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void showTopSnackBar(BuildContext context, String message,
      {Duration? duration}) {
    final overlay = Overlay.of(context);

    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green[900],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration ?? const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Map<String, Map<String, Map<String, double>>> locationFees = {
    'Greater Accra': {
      'Accra': {'Madina': 5.00, 'Osu': 6.50},
      'Tema': {'Community 1': 6.00, 'Community 2': 7.00},
    },
    'Ashanti': {
      'Kumasi': {'Adum': 4.50, 'Asokwa': 5.50, 'Ahodwo': 6.00},
      'Ejisu': {'Ejisu Town': 5.00, 'Besease': 5.50},
    },
    'Western': {
      'Takoradi': {'Market Circle': 4.00, 'Anaji': 5.00, 'Effia': 6.00},
    },
  };

  List<String> regions = ['Greater Accra', 'Ashanti', 'Western'];
  Map<String, List<String>> cities = {
    'Greater Accra': ['Accra', 'Tema'],
    'Ashanti': ['Kumasi'],
    'Western': ['Takoradi'],
  };

  Map<String, List<String>> towns = {
    'Accra': ['Madina', 'Osu'],
    'Tema': ['Community 1', 'Community 2'],
    'Kumasi': ['Adum', 'Asokwa'],
    'Takoradi': ['Market Circle', 'Anaji'],
  };

  List<String> pickupLocations = [
    'Madina Mall',
    'Accra Mall',
    'Kumasi City Mall',
    'Takoradi Mall'
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: topPadding),
                    color: Colors.green.shade700,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                debugPrint("Back tapped");
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                child:
                                    Icon(Icons.arrow_back, color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Row(
                                  children: [
                                    _buildProgressStep("Cart",
                                        isActive: true,
                                        isCompleted: true,
                                        step: 1),
                                    _buildProgressLine(isActive: false),
                                    _buildProgressStep("Delivery",
                                        isActive: false,
                                        isCompleted: false,
                                        step: 2),
                                    _buildProgressLine(isActive: false),
                                    _buildProgressStep("Payment",
                                        isActive: false,
                                        isCompleted: false,
                                        step: 3),
                                    _buildProgressLine(isActive: false),
                                    _buildProgressStep("Confirmation",
                                        isActive: false,
                                        isCompleted: false,
                                        step: 4),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: cart.cartItems.isEmpty
                        ? _buildEmptyCart()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: cart.cartItems.length,
                            itemBuilder: (context, index) =>
                                _buildCartItem(cart, index),
                          ),
                  ),
                  _buildStickyCheckoutBar(cart),
                ],
              ),
            ],
          ),
          bottomNavigationBar: const CustomBottomNav(),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProgressStep("Cart",
              isActive: true, isCompleted: true, step: 1),
          _buildProgressLine(isActive: false),
          _buildProgressStep("Delivery",
              isActive: false, isCompleted: false, step: 2),
          _buildProgressLine(isActive: false),
          _buildProgressStep("Payment",
              isActive: false, isCompleted: false, step: 3),
          _buildProgressLine(isActive: false),
          _buildProgressStep("Confirmation",
              isActive: false, isCompleted: false, step: 4),
        ],
      ),
    );
  }

  Widget _buildProgressLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 1,
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _buildProgressStep(String text,
      {required bool isActive, required bool isCompleted, required int step}) {
    final color = isCompleted
        ? Colors.white
        : isActive
            ? Colors.white
            : Colors.white.withOpacity(0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? Colors.white.withOpacity(0.2)
                : Colors.transparent,
            border: Border.all(
              color: color,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight:
                isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () {
              // Navigate to sign-in screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(),
                ),
              );
            },
            child: const Text(
              'Continue Shopping',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartProvider cart, int index) {
    final item = cart.cartItems[index];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: NetworkImage(item.image.startsWith('http')
                    ? item.image
                    : 'https://eclcommerce.ernestchemists.com.gh/storage/${item.image}'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GH${item.price.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  cart.updateQuantity(index, item.quantity - 1);
                                }
                              },
                            ),
                            Text(item.quantity.toString()),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () =>
                                  cart.updateQuantity(index, item.quantity + 1),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => cart.removeFromCart(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCheckoutBar(CartProvider cart) {
    final bool isCartEmpty = cart.cartItems.isEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
                child: const Text('APPLY'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Delivery Options
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
          ),
          const SizedBox(height: 8),

          if (!isCartEmpty) _buildOrderSummary(cart),
          if (!isCartEmpty) const SizedBox(height: 8),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                disabledBackgroundColor: Colors.green.withOpacity(0.5),
                disabledForegroundColor: Colors.white.withOpacity(0.7),
              ),
              onPressed: isCartEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DeliveryPage()),
                      );
                    },
              child: const Text('PROCEED TO CHECKOUT',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    final subtotal = cart.calculateSubtotal();
    final total = subtotal + (deliveryOption == 'Delivery' ? deliveryFee : 0);

    return Column(
      children: [
        _buildSummaryRow('Subtotal', subtotal),
        _buildSummaryRow(
          'Delivery Fee',
          deliveryOption == 'Delivery' ? deliveryFee : 0,
          isHighlighted: false,
        ),
        const Divider(),
        _buildSummaryRow('TOTAL', total, isHighlighted: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value,
      {bool isHighlighted = false}) {
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
            'GH ${value.toStringAsFixed(2)}',
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
