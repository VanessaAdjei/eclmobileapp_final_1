// pages/AppBackButton.dart
import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onPressed;

  const AppBackButton({
    Key? key,
    this.backgroundColor = const Color(0xFF43A047), // green[600]
    this.iconColor = Colors.white,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onPressed ??
            () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
        child: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
          ),
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.arrow_back, color: iconColor, size: 24),
        ),
      ),
    );
  }
}
