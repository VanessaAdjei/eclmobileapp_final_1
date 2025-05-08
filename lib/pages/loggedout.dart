import 'package:eclapp/pages/signinpage.dart';
import 'package:flutter/material.dart';

class LoggedOutScreen extends StatelessWidget {
  const LoggedOutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/png.png',
                  height: 100,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sign in to start shopping',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to sign-in screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignInScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureRow(Icons.local_shipping, 'Free Delivery', 'Orders Over GHS120', 80.0), // Increased icon size
                        _buildFeatureRow(Icons.replay, 'Get Refund', 'Within 30 Days Returns', 80.0),
                        _buildFeatureRow(Icons.lock, 'Safe Payment', '100% Secure Payment', 80.0),
                        _buildFeatureRow(Icons.headset_mic, '24/7 Support', 'Feel Free To Call', 80.0),
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

  Widget _buildFeatureRow(IconData icon, String title, String subtitle, double iconSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Center the row horizontally
      children: [
        Icon(icon, color: Colors.green, size: iconSize), // Increased icon size
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey), softWrap: true,),
            ],
          ),
        ),
      ],
    );
  }
}