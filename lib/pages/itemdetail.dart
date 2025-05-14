import 'package:eclapp/pages/signinpage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'Cart.dart';
import 'CartItem.dart';
import 'ProductModel.dart';
import 'auth_service.dart';
import 'bottomnav.dart';
import 'cartprovider.dart';
import 'package:html/parser.dart' show parse;
import 'package:shimmer/shimmer.dart';

class ItemPage extends StatefulWidget {
  final String urlName;

  const ItemPage({super.key, required this.urlName});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  late Future<Product> _productFuture;
  int quantity = 1;
  final uuid = Uuid();
  bool isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _productFuture = fetchProductDetails(widget.urlName);
  }

  String _cleanHtml(String html) {
    try {
      final document = parse(html);
      return document.body?.text ?? html;
    } catch (e) {
      return html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    }
  }

  Future<void> addToCartWithAuth(BuildContext context, Product product) async {
    if (await AuthService.isLoggedIn()) {
      _addToCart(context, product);
    } else {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => SignInScreen(
            returnTo: ModalRoute.of(context)?.settings.name,
            onSuccess: () => _addToCart(context, product),
          ),
        ),
      );
    }
  }

  void _addToCart(BuildContext context, Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCart(
      CartItem(
        id: product.id.toString(),
        name: product.name,
        price: double.tryParse(product.price) ?? 0.0,
        image: product.thumbnail,
        quantity: quantity,
      ),
    );
    showTopSnackBar(context, '${product.name} added to cart');
  }


  Widget _buildDescriptionSection(String? description) {
    final cleanText = description != null
        ? _cleanHtml(description).trim()
        : 'No description available';

    if (cleanText.isEmpty) return _buildNoDescription();

    final isLong = cleanText.length > 100;
    final displayText = isDescriptionExpanded
        ? cleanText
        : isLong ? '${cleanText.substring(0, 100)}...' : cleanText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isDescriptionExpanded = !isDescriptionExpanded;
            });
          },
          child: Text(
            displayText,
            style: _descriptionTextStyle(),
          ),
        ),
        if (isLong) _buildReadMoreButton(),
      ],
    );
  }


  Widget _buildReadMoreButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(40, 30),
        ),
        onPressed: () => setState(() => isDescriptionExpanded = !isDescriptionExpanded),
        child: Text(
          isDescriptionExpanded ? 'Read Less' : 'Read More',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNoDescription() {
    return const Text(
      'No description available.',
      style: TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: 13,
        color: Colors.grey,
      ),
    );
  }

  TextStyle _descriptionTextStyle() {
    return const TextStyle(
      fontSize: 13,
      color: Colors.black54,
      height: 1.4,
    );
  }

  Future<Product> fetchProductDetails(String urlName) async {
    try {
      final response = await http.get(
        Uri.parse('https://eclcommerce.ernestchemists.com.gh/api/product-details/$urlName'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('data')) {
          final productData = data['data']['product'] ?? {};
          final inventoryData = data['data']['inventory'] ?? {};

          return Product.fromJson({
            'id': inventoryData['id'] ?? 0,
            'name': inventoryData['url_name']?.toString().replaceAll('-', ' ').split(' ')
                .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
                .join(' ') ?? 'Unknown Product',
            'description': productData['description'] ?? '',
            'url_name': inventoryData['url_name'] ?? '',
            'status': inventoryData['status'] ?? '',
            'price': inventoryData['price']?.toString() ?? '0.00',
            'thumbnail': (productData['images'] != null && productData['images'].isNotEmpty)
                ? productData['images'][0]['url'] ?? ''
                : '',
            'quantity': inventoryData['quantity']?.toString() ?? '',
            'category': (productData['categories'] != null && productData['categories'].isNotEmpty)
                ? productData['categories'][0]['description'] ?? ''
                : '',
          });
        }
      }
      throw Exception('Failed to load product details');
    } catch (e) {
      print('Error fetching product details: $e');
      throw Exception('Could not load product: $e');
    }
  }

  List<Product> getRelatedProducts() {
    return [
      Product(
        id: 1,
        name: "Paracetamol 500mg Tablets",
        description: "Pain relief medicine",
        urlName: "paracetamol-500mg-tablets",
        status: "active",
        price: "5.99",
        route: '',
        thumbnail: "https://eclcommerce.ernestchemists.com.gh/storage/paracetamol.jpg",
        quantity: "100",
        category: "Pain Relief",
      ),
      Product(
        id: 2,
        name: "Ibuprofen 200mg Capsules",
        description: "Anti-inflammatory medicine",
        urlName: "ibuprofen-200mg-capsules",
        status: "active",
        price: "7.50",
        thumbnail: "https://eclcommerce.ernestchemists.com.gh/storage/ibuprofen.jpg",
        quantity: "80",
        category: "Pain Relief",
        route: '',
      ),
      Product(
        id: 3,
        name: "Vitamin C 1000mg Tablets",
        description: "Immune system booster",
        urlName: "vitamin-c-1000mg-tablets",
        status: "active",
        price: "12.99",
        thumbnail: "https://eclcommerce.ernestchemists.com.gh/storage/vitamin-c.jpg",
        quantity: "50",
        category: "Vitamins",
        route: '',
      ),
    ];
  }

  void showTopSnackBar(BuildContext context, String message, {Duration? duration}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          padding: EdgeInsets.zero, // Remove default padding
          icon: Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green[400],
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green[700],
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Cart()),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No product data available'));
          }

          final product = snapshot.data!;
          final price = double.tryParse(product.price) ?? 0.0;
          final totalPrice = price * quantity;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 1, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 200,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: product.thumbnail.isNotEmpty
                        ? Image.network(
                      product.thumbnail,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.medical_services, size: 80),
                          ),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.medical_services, size: 80),
                      ),
                    ),
                  ),
                ),

                // if (product.category.isNotEmpty)
                //   Padding(
                //     padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                //     child: Chip(
                //       label: Text(
                //         product.category,
                //         style: const TextStyle(color: Colors.white),
                //       ),
                //       backgroundColor: Colors.green.shade700,
                //     ),
                //   ),

                Center(
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.black, size: 16),
                            onPressed: () {
                              setState(() {
                                if (quantity > 1) {
                                  quantity--;
                                } else {
                                  showTopSnackBar(context, 'Quantity cannot be less than 1');
                                }
                              });
                            },
                          ),
                          Text(quantity.toString(),
                              style: const TextStyle(color: Colors.black, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.black, size: 16),
                            onPressed: () {
                              setState(() {
                                quantity++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  product.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),

                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'GHS ${price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),

                          Center(
                            child: Text(
                              'Product Details',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Divider(height: 16, thickness: 1),
                          const SizedBox(height: 4),

                          _buildDescriptionSection(product.description),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Center(
                            child: Text(
                              'Total: GHS ${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            await addToCartWithAuth(context, product);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                'Add to Cart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Related Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: getRelatedProducts().length,
                    itemBuilder: (context, index) {
                      final relatedProduct = getRelatedProducts()[index];
                      return Container(
                        width: 150,
                        margin: const EdgeInsets.only(left: 10, right: 10),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemPage(
                                    urlName: relatedProduct.urlName,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(10)),
                                    child: relatedProduct.thumbnail.startsWith('http')
                                        ? Image.network(
                                      relatedProduct.thumbnail,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported),
                                      ),
                                    )
                                        : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.medical_services),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        relatedProduct.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'GHS ${relatedProduct.price}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}


class ItemPageSkeleton extends StatelessWidget {
  const ItemPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[400],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {},
          ),
        ),
        title: Container(
          width: 200,
          height: 24,
          color: Colors.white,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[400],
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 1, bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Image Skeleton
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white,
              ),

              // Category Chip Skeleton
              Container(
                width: 100,
                height: 24,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              // Quantity Selector Skeleton
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              // Product Details Card Skeleton
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name Skeleton
                      Container(
                        width: double.infinity,
                        height: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),

                      // Price Skeleton
                      Center(
                        child: Container(
                          width: 100,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Product Details Title Skeleton
                      Center(
                        child: Container(
                          width: 120,
                          height: 20,
                          color: Colors.white,
                        ),
                      ),
                      const Divider(height: 24, thickness: 1),
                      const SizedBox(height: 8),

                      // Description Skeleton
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          5,
                              (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: index == 4 ? 100 : double.infinity,
                              height: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Total and Add to Cart Buttons Skeleton
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Related Products Title Skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: 150,
                  height: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Related Products List Skeleton
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(left: 10, right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 80,
                            height: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 60,
        color: Colors.white,
      ),
    );
  }
}