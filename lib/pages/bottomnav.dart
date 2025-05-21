import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'cartprovider.dart';


class CustomBottomNav extends StatefulWidget {
  const CustomBottomNav({super.key});

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  bool _userLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    setState(() {
      _userLoggedIn = loggedIn;
    });
  }

  bool _isCurrentRoute(BuildContext context, String routeName) {
    return ModalRoute.of(context)?.settings.name == routeName;
  }

  void _onItemTapped(BuildContext context, String routeName) {
    if (_isCurrentRoute(context, routeName)) return;
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        elevation: 0,
        currentIndex: _getSelectedIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              _onItemTapped(context, '/');
              break;
            case 1:
              _onItemTapped(context, '/cart');
              break;
            case 2:
              _onItemTapped(context, '/categories');
              break;
            case 3:
              _onItemTapped(context, '/profile');
              break;
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart),
                if (_userLoggedIn && cart.totalItems > 0)
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.totalItems}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/home':
        return 0;
      case '/cart':
        return 1;
      case '/categories':
        return 2;
      case '/profile':
        return 3;
      default:
        return 0;
    }
  }
}