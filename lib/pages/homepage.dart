// pages/homepage.dart
import 'dart:math';
import 'package:eclapp/pages/signinpage.dart';
import 'package:eclapp/pages/storelocation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ProductModel.dart';
import 'auth_service.dart';
import 'bottomnav.dart';
import 'cache.dart';
import 'clickableimage.dart';
import 'itemdetail.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'search_results_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool _isLoading = false;
  final RefreshController _refreshController = RefreshController();
  bool _allContentLoaded = false;
  final CacheService _cache = CacheService();
  static const String _productsCacheKey = 'home_products';
  TextEditingController searchController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  _launchPhoneDialer(String phoneNumber) async {
    final permissionStatus = await Permission.phone.request();
    if (permissionStatus.isGranted) {
      final String formattedPhoneNumber = 'tel:$phoneNumber';
      print("Dialing number: $formattedPhoneNumber");
      if (await canLaunch(formattedPhoneNumber)) {
        await launch(formattedPhoneNumber);
      } else {
        print("Error: Could not open the dialer.");
      }
    } else {
      print("Permission denied.");
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

  _launchWhatsApp(String phoneNumber, String message) async {
    if (phoneNumber.isEmpty || message.isEmpty) {
      print("Phone number or message is empty");
      return;
    }

    if (!phoneNumber.startsWith('+')) {
      print("Phone number must include the country code (e.g., +233*******)");
      return;
    }

    String whatsappUrl =
        'whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}';

    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      print("WhatsApp is not installed or cannot be launched.");
      showTopSnackBar(
          context, 'Could not open WhatsApp. Please ensure it is installed.');
    }
  }

  Future<void> _loadAllContent() async {
    if (_allContentLoaded && !_cache.shouldRefreshCache()) return;

    setState(() => _allContentLoaded = false);
    try {
      await Future.wait([
        loadProducts(),
        Future.delayed(Duration(milliseconds: 500)),
      ]);
    } catch (e) {
      final cachedProducts = _cache.getCachedData(_productsCacheKey);
      if (cachedProducts != null) {
        setState(() {
          products = cachedProducts;
          filteredProducts = cachedProducts;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _allContentLoaded = true);
      }
    }
  }

  Future<void> loadProducts() async {
    try {
      setState(() => _isLoading = true);
      if (!_cache.shouldRefreshCache()) {
        final cachedProducts = _cache.getCachedData(_productsCacheKey);
        if (cachedProducts != null) {
          setState(() {
            products = cachedProducts;
            filteredProducts = cachedProducts;
          });
          return;
        }
      }

      List<Product> loadedProducts = await AuthService().fetchProducts();
      _cache.cacheData(_productsCacheKey, loadedProducts);

      setState(() {
        products = loadedProducts;
        filteredProducts = loadedProducts;
      });
    } catch (e) {
      showTopSnackBar(context, 'Failed to load products');
    } finally {
      setState(() => _isLoading = false);
      _refreshController.refreshCompleted();
    }
  }

  void makePhoneCall(String phoneNumber) async {
    final Uri callUri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      throw "Could not launch $callUri";
    }
  }

  void _showContactOptions(String phoneNumber) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.call, color: Colors.green),
                title: Text('Call'),
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  _launchPhoneDialer(phoneNumber);
                  makePhoneCall(phoneNumber);
                },
              ),
              ListTile(
                leading:
                    FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
                title: Text('WhatsApp'),
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  _launchWhatsApp(
                      phoneNumber, "Hello, I'm interested in your products!");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAllContent();
    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_isScrolled) {
        setState(() {
          _isScrolled = true;
        });
      } else if (_scrollController.offset <= 100 && _isScrolled) {
        setState(() {
          _isScrolled = false;
        });
      }
    });
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
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TypeAheadField<Product>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search medicines, products...',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[100],
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchResultsPage(
                    query: value.trim(),
                    products: products,
                  ),
                ),
              );
            }
          },
        ),
        suggestionsCallback: (pattern) async {
          if (pattern.isEmpty) {
            return [];
          }
          try {
            final response = await http.get(
              Uri.parse(
                  'https://eclcommerce.ernestchemists.com.gh/api/search/' +
                      pattern),
            );
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              final List productsData = data['data'] ?? [];
              final products = productsData.map<Product>((item) {
                return Product(
                  id: item['id'] ?? 0,
                  name: item['name'] ?? 'No name',
                  description: item['tag_description'] ?? '',
                  urlName: item['url_name'] ?? '',
                  status: item['status'] ?? '',
                  batch_no: item['batch_no'] ?? '',
                  price:
                      (item['price'] ?? item['selling_price'] ?? 0).toString(),
                  thumbnail: item['thumbnail'] ?? item['image'] ?? '',
                  quantity: item['quantity']?.toString() ?? '',
                  category: item['category'] ?? '',
                  route: item['route'] ?? '',
                );
              }).toList();
              if (products.length > 1) {
                return [
                  Product(
                    id: -1,
                    name: '__VIEW_MORE__',
                    description: '',
                    urlName: '',
                    status: '',
                    price: '',
                    thumbnail: '',
                    quantity: '',
                    batch_no: '',
                    category: '',
                    route: '',
                  ),
                  ...products.take(6),
                ];
              }
              return products;
            }
            return [];
          } catch (e) {
            print('Search API error: $e');
            return [];
          }
        },
        itemBuilder: (context, Product suggestion) {
          if (suggestion.name == '__VIEW_MORE__') {
            return Container(
              color: Colors.green.withOpacity(0.08),
              child: ListTile(
                leading: Icon(Icons.list, color: Colors.green[700]),
                title: Text(
                  'View All Results',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
          // Try to find the product in the products list by id or name
          final matchingProduct = products.firstWhere(
            (p) => p.id == suggestion.id || p.name == suggestion.name,
            orElse: () => suggestion,
          );
          final imageUrl = getProductImageUrl(
              matchingProduct.thumbnail.isNotEmpty
                  ? matchingProduct.thumbnail
                  : suggestion.thumbnail);
          print(
              'Search suggestion: \\${suggestion.name}, thumbnail: \\${suggestion.thumbnail}, used thumbnail: \\${matchingProduct.thumbnail}, imageUrl: \\${imageUrl}');
          return ListTile(
            leading: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              placeholder: (context, url) => SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) => Icon(Icons.broken_image),
            ),
            title: Text(suggestion.name),
            subtitle: (suggestion.price.isNotEmpty && suggestion.price != '0')
                ? Text('GHS ${suggestion.price}')
                : null,
          );
        },
        onSuggestionSelected: (Product suggestion) {
          final matchingProduct = products.firstWhere(
            (p) => p.id == suggestion.id || p.name == suggestion.name,
            orElse: () => suggestion,
          );
          final urlName = matchingProduct.urlName.isNotEmpty
              ? matchingProduct.urlName
              : suggestion.urlName;
          print('Navigating to item page with urlName: $urlName');
          if (suggestion.name == '__VIEW_MORE__') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchResultsPage(
                  query: _searchController.text,
                  products: products,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemPage(urlName: urlName),
              ),
            );
          }
        },
        noItemsFoundBuilder: (context) => Padding(
          padding: const EdgeInsets.all(12.0),
          child:
              Text('No products found', style: TextStyle(color: Colors.grey)),
        ),
        hideOnEmpty: true,
        hideOnLoading: false,
        debounceDuration: Duration(milliseconds: 10),
        suggestionsBoxDecoration: SuggestionsBoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        suggestionsBoxVerticalOffset: 0,
        suggestionsBoxController: null,
      ),
    );
  }

  Widget _buildActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.people,
              title: "Meet Our Pharmacists",
              color: Colors.blue[600]!,
              onTap: () {},
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.location_on,
              title: "Store Locator",
              color: Colors.green[600]!,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => StoreSelectionPage()),
                );
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.contact_support_rounded,
              title: "Contact Us",
              color: Colors.orange[600]!,
              onTap: () => _showContactOptions("+233504518047"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: BoxConstraints(
          minWidth: 90,
          maxWidth: 100,
          minHeight: 100,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularProducts() {
    List<Map<String, String>> popularProducts = [
      {'name': 'Product', 'image': 'assets/images/prod2.png'},
      {'name': 'Product', 'image': 'assets/images/prod3.png'},
      {'name': 'Product', 'image': 'assets/images/prod4.png'},
      {'name': 'Product', 'image': 'assets/images/prod2.png'},
      {'name': 'Product', 'image': 'assets/images/prod5.png'},
      {'name': 'Product', 'image': 'assets/images/prod4.png'},
      {'name': 'Product', 'image': 'assets/images/prod2.png'},
      {'name': 'Product', 'image': 'assets/images/prod5.png'},
      {'name': 'Product', 'image': 'assets/images/prod4.png'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            'Popular Products',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: popularProducts.map((product) {
              return GestureDetector(
                onTap: () {
                  if (kDebugMode) {
                    print("Tapped on ${product['name']}");
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipOval(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          product['image']!,
                          fit: BoxFit.contain,
                          height: 90,
                          width: 80,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Divider(
          color: Colors.grey.shade300,
          thickness: 2.0,
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double cardWidth = screenWidth * (screenWidth < 600 ? 0.45 : 0.60);
    double cardHeight = screenHeight * (screenHeight < 800 ? 0.15 : 0.20);
    double imageHeight = cardHeight * (cardHeight < 800 ? 0.5 : 1);
    double fontSize = screenWidth * 0.032;
    double paddingValue = screenWidth * 0.02;

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: EdgeInsets.all(screenWidth * 0.019),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemPage(urlName: product.urlName),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: imageHeight,
              padding: EdgeInsets.all(paddingValue * 0.01),
              constraints: BoxConstraints(
                maxHeight: imageHeight,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: product.thumbnail,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.broken_image, size: 30),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: paddingValue * 0.8,
                vertical: paddingValue * 0.3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: cardHeight < 600 ? 30 : 50,
                    child: Text(
                      product.name,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: max(fontSize * 1.1, 12),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'GHS ${product.price}',
                    style: TextStyle(
                      fontSize: max(fontSize * 0.95, 11),
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _allContentLoaded ? _buildMainContent() : _buildOptimizedSkeleton(),
      bottomNavigationBar: _allContentLoaded ? const CustomBottomNav() : null,
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        SmartRefresher(
          controller: _refreshController,
          onRefresh: loadProducts,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 56.0,
                floating: false,
                automaticallyImplyLeading: false,
                pinned: true,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    return FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: EdgeInsets.only(left: 16, bottom: 10),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 56,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: Image.asset(
                                    'assets/images/png.png',
                                    height: 56,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 56,
                            child: IconButton(
                              icon: Icon(Icons.shopping_cart,
                                  color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Cart(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 10.0),
                  child: _buildSearchBar(),
                ),
              ),
              SliverToBoxAdapter(
                child: buildOrderMedicineCard(),
              ),
              SliverToBoxAdapter(
                child: _buildActionCards(),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Medicine',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.green[700],
                              letterSpacing: 1.2,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < 6) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 400 + index * 80),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: _buildProductCard(filteredProducts[index]),
                      );
                    }
                    return SizedBox.shrink();
                  },
                  childCount:
                      filteredProducts.length > 6 ? 6 : filteredProducts.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                  childAspectRatio: 1.2,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: ClickableImageButton(),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'First Aid',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.green[700],
                              letterSpacing: 1.2,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    int adjustedIndex = index + 6;
                    if (adjustedIndex < 12 &&
                        adjustedIndex < filteredProducts.length) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration:
                            Duration(milliseconds: 400 + (index + 6) * 80),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child:
                            _buildProductCard(filteredProducts[adjustedIndex]),
                      );
                    }
                    return SizedBox.shrink();
                  },
                  childCount: filteredProducts.length > 12
                      ? 6
                      : (filteredProducts.length > 6
                          ? filteredProducts.length - 6
                          : 0),
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                  childAspectRatio: 1.2,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 1.0),
                  child: _buildPopularProducts(),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Other Products',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.green[700],
                              letterSpacing: 1.2,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    int adjustedIndex = index + 12;
                    if (adjustedIndex < filteredProducts.length) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration:
                            Duration(milliseconds: 400 + (index + 12) * 80),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child:
                            _buildProductCard(filteredProducts[adjustedIndex]),
                      );
                    }
                    return SizedBox.shrink();
                  },
                  childCount: filteredProducts.length > 12
                      ? filteredProducts.length - 12
                      : 0,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                  childAspectRatio: 1.2,
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptimizedSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              color: Colors.white,
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Container(
              height: 150,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                    3,
                    (index) => Container(
                          width: (MediaQuery.of(context).size.width - 48) / 3,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )),
              ),
            ),
            GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) => _buildProductSkeleton(),
            ),
            Container(
              height: 120,
              margin: const EdgeInsets.all(16),
              color: Colors.white,
            ),
            GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) => _buildProductSkeleton(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: 150,
                height: 24,
                color: Colors.white,
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: 5,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) => _buildProductSkeleton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 100,
                  height: 14,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 50.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            // Search Bar Skeleton
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Banner Carousel Skeleton
            SliverToBoxAdapter(
              child: Container(
                height: 150,
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Action Cards Skeleton
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                      3,
                      (index) => Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          )),
                ),
              ),
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductCardSkeleton(),
                childCount: 4,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 120,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductCardSkeleton(),
                childCount: 4,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Container(
                  width: 150,
                  height: 24,
                  color: Colors.white,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 120,
                margin: EdgeInsets.only(left: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductCardSkeleton(),
                childCount: 4,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProductCardSkeleton() {
    return Container(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 16,
            color: Colors.white,
          ),
          SizedBox(height: 4),
          Container(
            width: 80,
            height: 14,
            color: Colors.white,
          ),
          SizedBox(height: 8),
          Container(
            width: 60,
            height: 16,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

Widget buildOrderMedicineCard() => _OrderMedicineCard();

class _OrderMedicineCard extends StatefulWidget {
  @override
  State<_OrderMedicineCard> createState() => _OrderMedicineCardState();
}

class _OrderMedicineCardState extends State<_OrderMedicineCard> {
  final List<String> imageUrls = [
    'assets/images/ban1.png',
    'assets/images/ban2.png',
    'assets/images/slide3.png',
    'assets/images/slide4.png',
  ];

  late final PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);

    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page?.round() ?? 0) + 1;
        if (nextPage >= imageUrls.length) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: EdgeInsets.symmetric(vertical: 10),
      child: PageView.builder(
        controller: _pageController,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imageUrls[index],
                fit: BoxFit.fill,
                cacheHeight: 300,
                cacheWidth: (MediaQuery.of(context).size.width * 0.85).round(),
              ),
            ),
          );
        },
      ),
    );
  }
}

String getProductImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return 'https://eclcommerce.ernestchemists.com.gh$url';
}
