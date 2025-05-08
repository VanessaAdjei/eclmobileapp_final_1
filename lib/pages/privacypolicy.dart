import 'package:flutter/material.dart';

import 'Cart.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
         'Privacy Policy',
          style: TextStyle(
            fontSize: 20,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text( // Use const
              'Privacy Policy',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green, // Green title
              ),
            ),
            const SizedBox(height: 24), // Increased spacing




            const Text( // Use const
              'We value your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and disclose information about you when you use our services.',
              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5), // Added height for better readability
            ),
            const SizedBox(height: 16), // Consistent spacing
            const Text( // Use const
              'Data Collection: We collect personal information such as your name, email address, and payment details when you register with us or use our services.',
              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5), // Added height
            ),
            const SizedBox(height: 16), // Consistent spacing
            const Text( // Use const
              'Data Use: The data we collect is used to provide you with our services, improve our offerings, and communicate with you.',
              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5), // Added height
            ),
            const SizedBox(height: 16), // Consistent spacing
            const Text( // Use const
              'Third-Party Sharing: We do not share your personal information with third parties without your consent, except as required by law.',
              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5), // Added height
            ),

            const SizedBox(height: 24), // Increased spacing
            // Add more sections as needed...
          ],
        ),
      ),
    );
  }
}
