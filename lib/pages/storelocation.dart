// pages/storelocation.dart
import 'package:flutter/material.dart';
import 'Cart.dart';
import 'bottomnav.dart';
import 'AppBackButton.dart';
import 'HomePage.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreSelectionPage extends StatefulWidget {
  const StoreSelectionPage({super.key});

  @override
  _StoreSelectionPageState createState() => _StoreSelectionPageState();
}

class _StoreSelectionPageState extends State<StoreSelectionPage> {
  final List<String> regions = [
    'Greater Accra',
    'Volta',
    'Ashanti',
    'Northern'
  ];
  final List<City> cities = [
    City(name: 'City 1', region: 'Greater Accra'),
    City(name: 'City 2', region: 'Greater Accra'),
    City(name: 'City 3', region: 'Volta'),
    City(name: 'City 4', region: 'Ashanti'),
    City(name: 'City 5', region: 'Northern'),
    City(name: 'City 6', region: 'Ashanti'),
    City(name: 'City 7', region: 'Volta'),
  ];

  String? selectedRegion;
  String? selectedCity;

  List<Store> stores = [
    Store(name: 'Store A', city: 'City 1', region: 'Greater Accra'),
    Store(name: 'Store B', city: 'City 2', region: 'Greater Accra'),
    Store(name: 'Store C', city: 'City 3', region: 'Volta'),
    Store(name: 'Store D', city: 'City 4', region: 'Ashanti'),
    Store(name: 'Store E', city: 'City 5', region: 'Northern'),
    Store(name: 'Store F', city: 'City 6', region: 'Ashanti'),
    Store(name: 'Store G', city: 'City 7', region: 'Volta'),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return Future.value(false);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.green.shade700,
          elevation: 0,
          centerTitle: true,
          leading: AppBackButton(
            backgroundColor: Colors.green[600] ?? Colors.green,
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
          title: Text(
            'Store Locations',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green[700],
              ),
              child: IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.white),
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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade100,
                Colors.green.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Region or City:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  elevation: 6,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedRegion,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.map, color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              labelText: 'Region',
                              labelStyle: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15),
                              hintStyle: TextStyle(
                                  color: Colors.grey[600], fontSize: 15),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                            ),
                            hint:
                                Text(' Region', style: TextStyle(fontSize: 15)),
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down,
                                color: Colors.green),
                            menuMaxHeight: 250,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedRegion = newValue;
                                selectedCity = null;
                              });
                            },
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                            items: regions.map((String region) {
                              return DropdownMenuItem<String>(
                                value: region,
                                child: Text(region,
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 15)),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCity,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.location_city,
                                  color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              labelText: 'City',
                              labelStyle: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15),
                              hintStyle: TextStyle(
                                  color: Colors.grey[600], fontSize: 15),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                            ),
                            hint: Text(' City', style: TextStyle(fontSize: 15)),
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down,
                                color: Colors.green),
                            menuMaxHeight: 250,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCity = newValue;
                                selectedRegion = cities
                                    .firstWhere((city) => city.name == newValue)
                                    .region;
                              });
                            },
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                            items: cities
                                .map((City city) => DropdownMenuItem<String>(
                                      value: city.name,
                                      child: Text(city.name,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15)),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 350),
                    child: ListView(
                      key: ValueKey(
                          '${selectedRegion ?? ''}-${selectedCity ?? ''}'),
                      padding: EdgeInsets.zero,
                      children: _getFilteredStores()
                          .map((store) => StoreListItem(store: store))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(),
      ),
    );
  }

  List<Store> _getFilteredStores() {
    if (selectedRegion != null) {
      return stores.where((store) => store.region == selectedRegion).toList();
    } else if (selectedCity != null) {
      return stores.where((store) => store.city == selectedCity).toList();
    } else {
      return stores;
    }
  }
}

class City {
  final String name;
  final String region;

  City({required this.name, required this.region});
}

class Store {
  final String name;
  final String city;
  final String region;

  Store({required this.name, required this.city, required this.region});
}

class StoreListItem extends StatelessWidget {
  final Store store;

  const StoreListItem({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          radius: 26,
          child: Icon(Icons.store, color: Colors.green.shade700, size: 30),
        ),
        title: Text(
          store.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.green.shade900,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green.shade400, size: 18),
            SizedBox(width: 4),
            Text(
              store.city,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            color: Colors.green.shade400, size: 20),
        onTap: () async {
          final query = Uri.encodeComponent(store.city + ", " + store.region);
          final googleMapsUrl =
              'https://www.google.com/maps/search/?api=1&query=$query';
          if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
            await launchUrl(Uri.parse(googleMapsUrl),
                mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open the map.')),
            );
          }
        },
      ),
    );
  }
}
