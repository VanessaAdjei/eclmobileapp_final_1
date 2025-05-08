import 'package:eclapp/pages/prescription.dart';
import 'package:flutter/material.dart';

class ClickableImageButton extends StatelessWidget {
  final String imageUrl = 'assets/images/prescription.png';

  @override
  Widget build(BuildContext context) {
    // return GestureDetector(
    //   onTap: () {
    //     // Navigate to the Prescription page
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(builder: (context) => PrescriptionUploadPage()),
    //     );
    //   },
    //   child: Container(
    //     height: 100, // Set the height of the button
    //     width: 420, // Set the width of the button
    //     margin: EdgeInsets.symmetric(horizontal: 8), // Add margin
    //     decoration: BoxDecoration(
    //       borderRadius: BorderRadius.circular(10), // Rounded corners
    //       boxShadow: [
    //         BoxShadow(
    //           color: Colors.black26,
    //           blurRadius: 4,
    //         ),
    //       ],
    //     ),
    //     child: ClipRRect(
    //       borderRadius: BorderRadius.circular(10), // Rounded corners for the image
    //       child: Image.asset(
    //         imageUrl,
    //         fit: BoxFit.cover, // Ensure the image covers the container
    //       ),
    //     ),
    //   ),
    // );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {

          Navigator.push(
              context,
             MaterialPageRoute(builder: (context) => PrescriptionUploadPage()),
         );
        },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SUBMIT YOUR PRESCRIPTION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),

            ),
          ),
        ),
      ),
    );


  }
}