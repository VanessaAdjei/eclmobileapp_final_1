// pages/itemdetail.dart
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eclapp/pages/signinpage.dart';
import 'AppBackButton.dart';
import 'package:eclapp/pages/homepage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

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

  Future<void> addToCartWithAuth(BuildContext context, Product product) async {
    if (await AuthService.isLoggedIn()) {
      _addToCart(context, product);
    } else {}
  }

  void _addToCart(BuildContext context, Product product) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final tempId = '${product.id}_${DateTime.now().millisecondsSinceEpoch}';
    final cartItem = CartItem(
      id: tempId,
      productId: product.id.toString(),
      name: product.name,
      price: double.tryParse(product.price) ?? 0.0,
      image: product.thumbnail,
      quantity: quantity,
      // modifiedDate: DateTime.now(),
    );
    cartProvider.addToCart(cartItem);
    print('Attempting to add to cart: '
        'id: ${product.id}, name: ${product.name}, price: ${product.price}, quantity: ${quantity}');
    final backendResponse = await AuthService.addToCartCheckAuth(
      productID: product.id,
      quantity: quantity,
      batchNo: product.batch_no,
    );
    print('Add to cart response: $backendResponse');
    // Update provider with backend items
    if (backendResponse['items'] != null) {
      final items = (backendResponse['items'] as List)
          .map((item) => CartItem(
                id: item['id']?.toString() ?? '', // This is the cart ID
                productId: item['product_id']?.toString() ?? '', // This is the product ID
                name: item['product_name'] ?? item['name'] ?? '',
                price: (item['price'] is int || item['price'] is double)
                    ? item['price'].toDouble()
                    : double.tryParse(item['price'].toString()) ?? 0.0,
                image: item['product_img'] ?? item['thumbnail'] ?? '',
                quantity: item['qty'] ?? item['quantity'] ?? 1,
              ))
          .toList();
      cartProvider.setCartItems(items);
    }
    showTopSnackBar(context, '${product.name} added to cart');
  }

  Future<Product> fetchProductDetails(String urlName) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://eclcommerce.ernestchemists.com.gh/api/product-details/$urlName'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('data')) {
          final productData = data['data']['product'] ?? {};
          final inventoryData = data['data']['inventory'] ?? {};

          List<String> tags = [];
          if (productData['tags'] != null && productData['tags'] is List) {
            tags = List<String>.from(
                productData['tags'].map((tag) => tag.toString()));
          }

          return Product.fromJson({
            'id': inventoryData['id'] ?? 0,
            'name': inventoryData['url_name']
                    ?.toString()
                    .replaceAll('-', ' ')
                    .split(' ')
                    .map((word) => word.isNotEmpty
                        ? word[0].toUpperCase() + word.substring(1)
                        : '')
                    .join(' ') ??
                'Unknown Product',
            'description': productData['description'] ?? '',
            'url_name': inventoryData['url_name'] ?? '',
            'status': inventoryData['status'] ?? '',
            'price': inventoryData['price']?.toString() ?? '0.00',
            'thumbnail': (productData['images'] != null &&
                    productData['images'].isNotEmpty)
                ? productData['images'][0]['url'] ?? ''
                : '',
            'tags': tags,
            'quantity': inventoryData['quantity']?.toString() ?? '',
            'category': (productData['categories'] != null &&
                    productData['categories'].isNotEmpty)
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

  Future<List<Product>> fetchRelatedProducts(String urlName) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://eclcommerce.ernestchemists.com.gh/api/related-products/$urlName'),
      );
      print('Related products API response: \\${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('data') && data['data'] is List) {
          return (data['data'] as List).map((item) {
            print('Related product item: ' + jsonEncode(item));
            return Product(
              id: item['product_id'] ?? item['id'] ?? 0,
              name: item['name'] ??
                  item['product_name'] ??
                  (item['product'] != null
                      ? item['product']['name'] ?? ''
                      : ''),
              description: item['description'] ??
                  (item['product'] != null
                      ? item['product']['description'] ?? ''
                      : ''),
              urlName: item['url_name'] ??
                  (item['product'] != null
                      ? item['product']['url_name'] ?? ''
                      : ''),
              status: item['status'] ??
                  (item['product'] != null
                      ? item['product']['status'] ?? ''
                      : ''),
              batch_no: item['batch_no'] ?? '',
              price: item['price']?.toString() ?? '0.00',
              thumbnail: item['thumbnail'] ??
                  item['product_img'] ??
                  (item['product'] != null
                      ? item['product']['thumbnail'] ??
                          item['product']['product_img'] ??
                          ''
                      : ''),
              quantity: item['qty_in_stock']?.toString() ??
                  item['quantity']?.toString() ??
                  '',
              category: item['category'] ?? '',
              route: '',
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching related products: $e');
      return [];
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double fontSize =
            screenWidth < 400 ? 13 : (screenWidth < 600 ? 15 : 17);
        double imageHeight =
            screenWidth < 400 ? 180 : (screenWidth < 600 ? 220 : 300);
        double cardPadding =
            screenWidth < 400 ? 10 : (screenWidth < 600 ? 16 : 24);

        return Scaffold(
          appBar: AppBar(
            backgroundColor:
                theme.appBarTheme.backgroundColor ?? Colors.green.shade700,
            elevation: theme.appBarTheme.elevation ?? 0,
            centerTitle: theme.appBarTheme.centerTitle ?? true,
            leading: AppBackButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                }
              },
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.appBarTheme.backgroundColor ??
                      Colors.green.shade700,
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load product details.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _productFuture =
                                fetchProductDetails(widget.urlName);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: Text('No product data available'));
              }

              final product = snapshot.data!;
              final price = double.tryParse(product.price) ?? 0.0;
              final totalPrice = price * quantity;

              return SingleChildScrollView(
                padding: const EdgeInsets.only(
                    left: 10, right: 10, top: 1, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product Image with Hero animation
                    Hero(
                      tag: 'product-image-${product.id}',
                      child: Animate(
                        effects: [
                          FadeEffect(duration: 400.ms),
                          SlideEffect(
                              duration: 400.ms,
                              begin: Offset(0, 0.1),
                              end: Offset(0, 0))
                        ],
                        child: Container(
                          height: imageHeight,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: product.thumbnail.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: product.thumbnail,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.medical_services,
                                            size: 80),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.medical_services,
                                          size: 80),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    // Glassmorphic Product Info Card
                    Animate(
                      effects: [
                        FadeEffect(duration: 400.ms, delay: 100.ms),
                        SlideEffect(
                            duration: 400.ms,
                            begin: Offset(0, 0.1),
                            end: Offset(0, 0),
                            delay: 100.ms)
                      ],
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 340),
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (product.category.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Chip(
                                          label: Text(
                                            product.category,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 10),
                                          ),
                                          backgroundColor: theme.primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 0),
                                        ),
                                      ),
                                    Text(
                                      product.name,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              fontSize: fontSize),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'GHS ${price.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: fontSize),
                                    ),
                                    const SizedBox(height: 7),
                                    ProductDescription(
                                        description: product.description),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Floating Quantity Selector
                    Animate(
                      effects: [
                        FadeEffect(duration: 400.ms, delay: 200.ms),
                        SlideEffect(
                            duration: 400.ms,
                            begin: Offset(0, 0.1),
                            end: Offset(0, 0),
                            delay: 200.ms)
                      ],
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.transparent,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove,
                                    color: Colors.black, size: 13),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 22, minHeight: 22),
                                onPressed: () {
                                  setState(() {
                                    if (quantity > 1) {
                                      quantity--;
                                    } else {
                                      showTopSnackBar(context,
                                          'Quantity cannot be less than 1');
                                    }
                                  });
                                },
                              ),
                              Text(quantity.toString(),
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add,
                                    color: Colors.black, size: 13),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 22, minHeight: 22),
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
                    // Add to Cart Button
                    Animate(
                      effects: [
                        FadeEffect(duration: 400.ms, delay: 300.ms),
                        SlideEffect(
                            duration: 400.ms,
                            begin: Offset(0, 0.1),
                            end: Offset(0, 0),
                            delay: 300.ms)
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade600,
                                  Colors.green.shade800
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.shade200.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.shopping_cart,
                                  size: 22, color: Colors.white),
                              label: Text(
                                'Add to Cart  •  GHS ${totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              onPressed: () async {
                                if (!await AuthService.isLoggedIn()) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SignInScreen(
                                          returnTo: ModalRoute.of(context)
                                              ?.settings
                                              .name),
                                    ),
                                  );
                                  if (await AuthService.isLoggedIn()) {
                                    _addToCart(context, product);
                                  }
                                } else {
                                  _addToCart(context, product);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Related Products Carousel
                    Animate(
                      effects: [
                        FadeEffect(duration: 400.ms, delay: 400.ms),
                        SlideEffect(
                            duration: 400.ms,
                            begin: Offset(0, 0.1),
                            end: Offset(0, 0),
                            delay: 400.ms)
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          FutureBuilder<List<Product>>(
                            future: fetchRelatedProducts(product.urlName),
                            builder: (context, relatedSnapshot) {
                              if (relatedSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox(
                                  height: 220,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 3,
                                    itemBuilder: (context, index) => Container(
                                      width: 170,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (relatedSnapshot.hasError) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Failed to load related products',
                                      style: TextStyle(color: Colors.red)),
                                );
                              }
                              final relatedProducts =
                                  relatedSnapshot.data ?? [];
                              if (relatedProducts.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.info_outline,
                                          color: Colors.grey, size: 20),
                                      SizedBox(width: 8),
                                      Text('No related products found.',
                                          style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              }
                              return SizedBox(
                                height: 220,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: relatedProducts.length,
                                  itemBuilder: (context, index) =>
                                      _buildRelatedProductCard(
                                          relatedProducts[index], context),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: const CustomBottomNav(),
        );
      },
    );
  }

  Widget _buildRelatedProductCard(Product product, BuildContext context) {
    final imageUrl = product.thumbnail.startsWith('http')
        ? product.thumbnail
        : 'https://adm-ecommerce.ernestchemists.com.gh/uploads/product/${product.thumbnail}';
    final inStock = (int.tryParse(product.quantity) ?? 0) > 0;
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ItemPage(urlName: product.urlName),
          ),
        );
      },
      child: Animate(
        effects: [
          ScaleEffect(
            duration: 120.ms,
            begin: const Offset(1, 1),
            end: const Offset(1.03, 1.03),
            curve: Curves.easeOut,
          ),
        ],
        child: SizedBox(
          height: 260,
          width: 180,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image section
                SizedBox(
                  height: 90,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22)),
                        child: product.thumbnail.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported,
                                      size: 40),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.medical_services,
                                    size: 40),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: inStock
                                ? Colors.green.withOpacity(0.85)
                                : Colors.red.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            inStock ? 'In Stock' : 'Out of Stock',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content section
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'GHS ${product.price}',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        leading:
            AppBackButton(backgroundColor: Colors.grey[400] ?? Colors.grey),
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
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 1, bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Image Skeleton
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white,
              ),

              Container(
                width: 100,
                height: 24,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Container(
                        width: double.infinity,
                        height: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),

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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: 150,
                  height: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

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

class ProductDescription extends StatefulWidget {
  final String description;

  const ProductDescription({
    super.key,
    required this.description,
  });

  @override
  State<ProductDescription> createState() => _ProductDescriptionState();
}

class _ProductDescriptionState extends State<ProductDescription> {
  bool isExpanded = false;
  late String _plainDescription;

  @override
  void initState() {
    super.initState();
    _plainDescription = _stripHtmlTags(widget.description);
  }

  String _stripHtmlTags(String html) {
    // Use the html parser to remove tags
    return parse(html).body?.text.trim() ?? html;
  }

  @override
  Widget build(BuildContext context) {
    final words = _plainDescription.split(' ');
    final displayContent = !isExpanded && words.length > 20
        ? '${words.take(20).join(' ')}...'
        : _plainDescription;

    if (_plainDescription.isEmpty) {
      return const Text(
        'No description available.',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 13,
          color: Colors.grey,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayContent,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        if (words.length > 20)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 30),
              ),
              onPressed: () => setState(() => isExpanded = !isExpanded),
              child: Text(
                isExpanded ? 'Read Less' : 'Read More',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CategoryAndTagsWidget extends StatelessWidget {
  final String category;
  final List<String> tags;

  const CategoryAndTagsWidget({
    super.key,
    required this.category,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category.isNotEmpty)
          Row(
            children: [
              const Text(
                "Category: ",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tags: ",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) => TagChip(tag: tag)).toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class TagChip extends StatelessWidget {
  final String tag;

  const TagChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
}
