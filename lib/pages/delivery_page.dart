import 'dart:convert';

import 'package:eclapp/pages/payment_page.dart';
import 'package:eclapp/pages/savedaddresses.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottomnav.dart';
import 'cartprovider.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({Key? key}) : super(key: key);

  @override
  _DeliveryPageState createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  String deliveryOption = 'Delivery';
  GoogleMapController? mapController;
  LatLng? selectedLocation;
  String? selectedAddress;
  double deliveryFee = 0.00;
  final TextEditingController _typeAheadController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  Set<Marker> markers = {};
  bool isLoadingLocation = false;
  bool _isMapReady = false;
  Position? currentPosition;
  List<SavedAddress> savedAddresses = [];
  String? selectedRegion;
  String? selectedCity;
  List<String> availableStations = [];

  @override
  void dispose() {
    mapController?.dispose();
    _typeAheadController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    loadSavedAddresses();
  }

  double _calculateDeliveryFee(LatLng location) {
    if (selectedAddress?.toLowerCase().contains('accra') ?? false) {
      return 10.00;
    } else if (selectedAddress?.toLowerCase().contains('kumasi') ?? false) {
      return 15.00;
    } else {
      return 20.00;
    }
  }

  Future<void> _searchAddress(String address) async {
    if (!mounted) return;

    setState(() => isLoadingLocation = true);
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty && mounted) {
        Location location = locations.first;
        LatLng latLng = LatLng(location.latitude, location.longitude);

        setState(() {
          selectedLocation = latLng;
          selectedAddress = address;
          markers = {
            Marker(
              markerId: const MarkerId('deliveryLocation'),
              position: latLng,
              infoWindow: InfoWindow(title: address),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            )
          };
          deliveryFee = _calculateDeliveryFee(latLng);
        });

        if (_isMapReady) {
          mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(latLng, 15),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find location: $address')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingLocation = false);
      }
    }
  }

  Future<void> getCurrentLocation() async {
    if (!mounted) return;

    setState(() => isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')),
        );
        await openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      if (!mounted) return;
      setState(() => currentPosition = position);

      if (_isMapReady) {
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.administrativeArea
        ].where((s) => s?.isNotEmpty ?? false).join(', ');

        _typeAheadController.text = address;
        await _searchAddress(address);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the top padding (safe area)
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Main content body
          Column(
            children: [
              PreferredSize(
                preferredSize: Size.fromHeight(kToolbarHeight),
                child: AppBar(
                  backgroundColor: Colors.green.shade700,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    return Stack(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDeliveryOptions(),
                              const SizedBox(height: 16),
                              if (deliveryOption == 'Delivery') _buildMapSection(),
                              if (deliveryOption == 'Pickup') _buildPickupForm(),
                              _buildContactInfo(),
                              const SizedBox(height: 16),
                              _buildDeliveryNotes(),
                              const SizedBox(height: 20),
                              _buildOrderSummary(cart),
                              const SizedBox(height: 30),
                              _buildContinueButton(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        if (isLoadingLocation)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // Positioned Progress Indicator on top
          Positioned(
            top: topPadding , // Top padding + AppBar height
            left: 0,
            right: 0,
            child: _buildProgressIndicator(),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }






  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProgressStep("Delivery", isActive: true),
          _buildArrow(),
          _buildProgressStep("Payment", isActive: false),
          _buildArrow(),
          _buildProgressStep("Confirmation", isActive: false),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Icon(
        Icons.arrow_forward,
        color: Colors.grey[400],
        size: 20,
      ),
    );
  }


  Widget _buildProgressStep(String text, {bool isActive = false}) {
    return Column(
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
          color: isActive ? Colors.green : Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildDeliveryOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'DELIVERY METHOD',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Home Delivery'),
                  selected: deliveryOption == 'Delivery',
                  onSelected: (selected) => _handleDeliveryOptionChange('Delivery'),
                  selectedColor: Colors.green.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: deliveryOption == 'Delivery' ? Colors.green : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Pickup Station'),
                  selected: deliveryOption == 'Pickup',
                  onSelected: (selected) => _handleDeliveryOptionChange('Pickup'),
                  selectedColor: Colors.green.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: deliveryOption == 'Pickup' ? Colors.green : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (deliveryOption == 'Delivery')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              icon: const Icon(Icons.my_location, size: 20),
              label: const Text('Use Current Location'),
              onPressed: getCurrentLocation,
            ),
          ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ENTER YOUR DELIVERY ADDRESS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _typeAheadController,
            decoration: InputDecoration(
              hintText: 'Search for your address',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _typeAheadController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _typeAheadController.clear();
                  setState(() {
                    selectedLocation = null;
                    selectedAddress = null;
                    markers.clear();
                  });
                },
              )
                  : null,
            ),
            onSubmitted: (value) async {
              if (value.length > 2) {
                await _searchAddress(value);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        if (savedAddresses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<SavedAddress>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Use Saved Address",
                border: OutlineInputBorder(),
              ),
              items: savedAddresses.map((addr) {
                return DropdownMenuItem(
                  value: addr,
                  child: Text(addr.address),
                );
              }).toList(),
              onChanged: (selected) {
                if (selected != null) {
                  setState(() {
                    selectedLocation = selected.location;
                    selectedAddress = selected.address;
                    _typeAheadController.text = selected.address;
                    markers = {
                      Marker(
                        markerId: const MarkerId('deliveryLocation'),
                        position: selected.location,
                        infoWindow: InfoWindow(title: selected.address),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                      )
                    };
                    deliveryFee = _calculateDeliveryFee(selected.location);
                  });

                  if (_isMapReady) {
                    mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(selected.location, 15),
                    );
                  }
                }
              },
            ),
          ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 250,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: currentPosition != null
                        ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                        : const LatLng(5.6037, -0.1870),
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {
                    mapController = controller;
                    setState(() => _isMapReady = true);
                    if (currentPosition != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(
                            currentPosition!.latitude,
                            currentPosition!.longitude,
                          ),
                          15,
                        ),
                      );
                    }
                  },
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true, // Changed to true
                  zoomGesturesEnabled: true, // Added this
                  scrollGesturesEnabled: true, // Added this
                  tiltGesturesEnabled: true, // Added this
                  rotateGesturesEnabled: true, // Added this
                  onTap: (latLng) async {
                    try {
                      final placemarks = await placemarkFromCoordinates(
                        latLng.latitude,
                        latLng.longitude,
                      );

                      if (placemarks.isNotEmpty && mounted) {
                        final place = placemarks.first;
                        final address = [
                          place.street,
                          place.locality,
                          place.administrativeArea
                        ].where((s) => s?.isNotEmpty ?? false).join(', ');

                        setState(() {
                          _typeAheadController.text = address;
                          selectedLocation = latLng;
                          selectedAddress = address;
                          markers = {
                            Marker(
                              markerId: const MarkerId('selected_location'),
                              position: latLng,
                              infoWindow: InfoWindow(title: address),
                            )
                          };
                          deliveryFee = _calculateDeliveryFee(latLng);
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                ),
                if (!_isMapReady || isLoadingLocation)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (selectedAddress != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECTED ADDRESS:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  selectedAddress!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivery Fee: GH${deliveryFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPickupForm() {

    final Map<String, Map<String, List<String>>> pickupLocations = {
      'Greater Accra': {
        'Accra': ['Accra Mall', 'West Hills Mall', 'Achimota Retail Centre'],
        'Tema': ['Tema Mall', 'Community 25 Station']
      },
      'Ashanti': {
        'Kumasi': ['Kumasi City Mall', 'Adum Station', 'Asokwa Station']
      },
      'Western': {
        'Takoradi': ['Takoradi Mall', 'Airport Station']
      },
      'Eastern': {
        'Madina': ['Madina Mall'],
        'Koforidua': ['Koforidua Station']
      }
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PICKUP LOCATION',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Region Dropdown
          DropdownButtonFormField<String>(
            value: selectedRegion,
            decoration: const InputDecoration(
              labelText: 'Select Region',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: pickupLocations.keys.map((region) {
              return DropdownMenuItem(
                value: region,
                child: Text(region),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedRegion = value;
                selectedCity = null;
                selectedAddress = null;
              });
            },
          ),

          if (selectedRegion != null) ...[
            const SizedBox(height: 12),
            // City Dropdown
            DropdownButtonFormField<String>(
              value: selectedCity,
              decoration: const InputDecoration(
                labelText: 'Select City',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: pickupLocations[selectedRegion]!.keys.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCity = value;
                  selectedAddress = null;
                });
              },
            ),
          ],

          if (selectedCity != null) ...[
            const SizedBox(height: 12),
            // Station Dropdown
            DropdownButtonFormField<String>(
              value: selectedAddress,
              decoration: const InputDecoration(
                labelText: 'Select Pickup Station',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: pickupLocations[selectedRegion]![selectedCity]!.map((station) {
                return DropdownMenuItem(
                  value: station,
                  child: Text(station),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAddress = value;
                  deliveryFee = 0.00;
                });
              },
            ),
          ],

          const SizedBox(height: 12),
          const Text(
            'Pickup stations are open Monday-Saturday, 9am-6pm',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
  Widget _buildContactInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTACT INFORMATION',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixText: '+233 ',
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryNotes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DELIVERY NOTES (OPTIONAL)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Any special delivery instructions?',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    final subtotal = cart.calculateSubtotal();
    final total = subtotal + deliveryFee;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            '₵${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4), // Change this to 0 for square corners
            ),
          ),
          onPressed: () async {
            await saveCurrentAddress();
            if (deliveryOption == 'Delivery' && selectedAddress == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a delivery address')),
              );
              return;
            }

            if (deliveryOption == 'Pickup' && selectedAddress == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a pickup location')),
              );
              return;
            }

            if (_phoneController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter your phone number')),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentPage(),
              ),
            );
          },
          child: const Text('CONTINUE TO PAYMENT',     style: TextStyle(color: Colors.white),),
        ),
      ),
    );
  }


  void _handleDeliveryOptionChange(String option) {
    setState(() {
      deliveryOption = option;
      if (option == 'Pickup') {
        selectedLocation = null;
        _typeAheadController.clear();
        markers.clear();
        deliveryFee = 0.00;
      }
    });
  }

  Future<void> loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getStringList('saved_addresses') ?? [];

    setState(() {
      savedAddresses = savedData
          .map((jsonStr) => SavedAddress.fromJson(json.decode(jsonStr)))
          .toList();
    });
  }

  Future<void> saveCurrentAddress() async {
    if (selectedAddress == null || selectedLocation == null) return;

    final newAddress = SavedAddress(
      address: selectedAddress!,
      location: selectedLocation!,
    );

    // Check if address already exists
    bool addressExists = savedAddresses.any((addr) =>
    addr.address == newAddress.address ||
        (addr.location.latitude == newAddress.location.latitude &&
            addr.location.longitude == newAddress.location.longitude)
    );

    if (!addressExists) {
      setState(() {
        savedAddresses.add(newAddress);
      });

      final prefs = await SharedPreferences.getInstance();
      final savedData = savedAddresses.map((e) => json.encode(e.toJson())).toList();
      await prefs.setStringList('saved_addresses', savedData);
    }
  }

}