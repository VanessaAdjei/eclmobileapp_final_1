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
    cartProvider.addToCart(
      CartItem(
        // Use the prefixed version
        id: product.id.toString(),
        name: product.name,
        price: double.tryParse(product.price) ?? 0.0,
        image: product.thumbnail,
        quantity: quantity, // Use the selected quantity
      ),
    );
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

  List<Product> getRelatedProducts() {
    return [
      Product(
        id: 1,
        name: "Paracetamol 500mg Tablets",
        description: "Pain relief medicine",
        urlName: "paracetamol-500mg-tablets",
        status: "active",
        batch_no: "1234567890",
        price: "5.99",
        route: '',
        thumbnail:
            "https://eclcommerce.ernestchemists.com.gh/storage/paracetamol.jpg",
        quantity: "100",
        category: "Pain Relief",
      ),
      Product(
        id: 2,
        name: "Ibuprofen 200mg Capsules",
        description: "Anti-inflammatory medicine",
        urlName: "ibuprofen-200mg-capsules",
        status: "active",
        batch_no: "1234567890",
        price: "7.50",
        thumbnail:
            "https://eclcommerce.ernestchemists.com.gh/storage/ibuprofen.jpg",
        quantity: "80",
        category: "Pain Relief",
        route: '',
      ),
      Product(
        id: 3,
        name: "Vitamin C 1000mg Tablets",
        description: "Immune system booster",
        batch_no: "1234567890",
        urlName: "vitamin-c-1000mg-tablets",
        status: "active",
        price: "12.99",
        thumbnail:
            "https://eclcommerce.ernestchemists.com.gh/storage/vitamin-c.jpg",
        quantity: "50",
        category: "Vitamins",
        route: '',
      ),
    ];
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
        leading: AppBackButton(),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load product details.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _productFuture = fetchProductDetails(widget.urlName);
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

          final relatedProducts = getRelatedProducts();

          return SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 1, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 200,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: product.thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.thumbnail,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.medical_services, size: 80),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.medical_services, size: 80),
                            ),
                          ),
                  ),
                ),
                // Product Info Card
                Center(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.category.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Chip(
                                label: Text(
                                  product.category,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11),
                                ),
                                backgroundColor: Colors.green.shade700,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 0),
                              ),
                            ),
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'GHS ${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 12, thickness: 1),
                          const SizedBox(height: 4),
                          const Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ProductDescription(description: product.description),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove,
                                color: Colors.black, size: 16),
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
                                  color: Colors.black, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add,
                                color: Colors.black, size: 16),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total: GHS ${totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart,
                            size: 20, color: Colors.white),
                        label: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        onPressed: () async {
                          if (!await AuthService.isLoggedIn()) {
                            // Redirect to sign in page
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignInScreen(
                                  returnTo:
                                      ModalRoute.of(context)?.settings.name,
                                ),
                              ),
                            );
                            // Optionally, after sign in, check again and add to cart if logged in
                            if (await AuthService.isLoggedIn()) {
                              _addToCart(context, product);
                            }
                          } else {
                            _addToCart(context, product);
                          }
                        },
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
                    itemCount: relatedProducts.length,
                    itemBuilder: (context, index) {
                      final relatedProduct = relatedProducts[index];
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
                                    child: relatedProduct.thumbnail
                                            .startsWith('http')
                                        ? CachedNetworkImage(
                                            imageUrl: relatedProduct.thumbnail,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Center(
                                                    child:
                                                        CircularProgressIndicator()),
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                  Icons.image_not_supported),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                                Icons.medical_services),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
  late List<Map<String, String>> _sections;

  @override
  void initState() {
    super.initState();
    _sections = _parseHtmlSections(widget.description);
  }

  List<Map<String, String>> _parseHtmlSections(String html) {
    if (html.isEmpty) return [];

    try {
      final document = parse(html);
      final List<Map<String, String>> sections = [];

      // Get all paragraph elements
      final paragraphs = document.body?.getElementsByTagName('p') ?? [];

      String currentTitle = '';
      String currentContent = '';

      for (var i = 0; i < paragraphs.length; i++) {
        final p = paragraphs[i];
        final text = p.text.trim();

        // Skip empty paragraphs
        if (text.isEmpty) continue;

        // Check if this is a section title (has bold text)
        final boldElements = p.getElementsByTagName('strong');
        if (boldElements.isNotEmpty) {
          // If we already have content from previous section, add it to sections
          if (currentTitle.isNotEmpty && currentContent.isNotEmpty) {
            sections.add({
              'title': currentTitle,
              'content': currentContent,
            });
            currentContent = '';
          }

          // Set new title
          currentTitle = boldElements.first.text.trim();

          // Check if there's additional text in the same paragraph that's not part of the title
          final remainingText = text.replaceAll(currentTitle, '').trim();
          if (remainingText.isNotEmpty) {
            currentContent = remainingText;
          }
        } else if (currentTitle.isNotEmpty) {
          // This is content for the current section
          if (currentContent.isNotEmpty) {
            currentContent += ' $text';
          } else {
            currentContent = text;
          }
        }
      }

      // Add the last section if there's one pending
      if (currentTitle.isNotEmpty && currentContent.isNotEmpty) {
        sections.add({
          'title': currentTitle,
          'content': currentContent,
        });
      }

      return sections;
    } catch (e) {
      print('Error parsing HTML: $e');
      return [
        {
          'title': 'Description',
          'content': html.replaceAll(RegExp(r'<[^>]*>'), ' ')
        }
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sections.isEmpty) {
      return _buildNoDescription();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...isExpanded ? _buildFullDescription() : _buildCollapsedDescription(),
        _buildReadMoreButton(),
      ],
    );
  }

  List<Widget> _buildFullDescription() {
    return _sections
        .map((section) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section['title'] != 'PRODUCT DETAILS')
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
                    child: Text(
                      section['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                Text(
                  section['content'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ))
        .toList();
  }

  List<Widget> _buildCollapsedDescription() {
    final firstSection = _sections.isNotEmpty ? _sections[0] : null;

    if (firstSection == null) return [];

    final content = firstSection['content'] ?? '';
    final words = content.split(' ');
    final displayContent =
        words.length > 20 ? '${words.take(20).join(' ')}...' : content;

    return [
      if (firstSection['title'] != 'PRODUCT DETAILS' &&
          firstSection['title']!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            firstSection['title'] ?? '',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      Text(
        displayContent,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black54,
          height: 1.4,
        ),
      ),
    ];
  }

  Widget _buildReadMoreButton() {
    // Hide the button if the first section's content is 20 words or fewer
    if (_sections.isEmpty) return const SizedBox.shrink();
    final firstSection = _sections[0];
    final content = firstSection['content'] ?? '';
    final words = content.split(' ');
    if (words.length <= 20) return const SizedBox.shrink();

    return Align(
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
