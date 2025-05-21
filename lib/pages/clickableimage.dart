import 'package:eclapp/pages/prescription.dart';
import 'package:flutter/material.dart';

class ClickableImageButton extends StatelessWidget {
  final String imageUrl = 'assets/images/prescription.png';

  const ClickableImageButton({super.key});

  @override
  Widget build(BuildContext context) {

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