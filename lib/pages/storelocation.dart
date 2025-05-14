
import 'package:flutter/material.dart';
import 'Cart.dart';
import 'bottomnav.dart';


class StoreSelectionPage extends StatefulWidget {
  const StoreSelectionPage({super.key});

  @override
  _StoreSelectionPageState createState() => _StoreSelectionPageState();
}

class _StoreSelectionPageState extends State<StoreSelectionPage> {

  final List<String> regions = ['Greater Accra', 'Volta', 'Ashanti', 'Northern'];
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
      child:  Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green.shade700,
          elevation: 0,
          centerTitle: true,
          leading: Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green[400],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: Text(
            'Store Locations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green[700],

              ),
              child:          IconButton(
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Region or City:',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Roboto',
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedRegion,
                      hint: Text('Select Region'),
                      isExpanded: true,
                      icon: Icon(Icons.arrow_downward, color: Colors.green),
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
                      ),
                      items: regions.map((String region) {
                        return DropdownMenuItem<String>(
                          value: region,
                          child: Text(region),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedCity,
                      hint: Text('Select City'),
                      isExpanded: true,
                      icon: Icon(Icons.arrow_downward, color: Colors.green),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCity = newValue;
                          selectedRegion = cities.firstWhere((city) => city.name == newValue).region;
                        });
                      },
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                      items: cities
                          .map((City city) => DropdownMenuItem<String>(
                        value: city.name,
                        child: Text(city.name),
                      ))
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: _getFilteredStores()
                      .map((store) => StoreListItem(store: store))
                      .toList(),
                ),
              ),
            ],
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

    return  Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 6,
      child: ListTile(
        title: Text(store.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(store.city),
        trailing: Icon(Icons.store, color: Colors.green),
      ),
    );
  }
}