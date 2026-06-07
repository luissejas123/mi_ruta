import 'package:flutter/material.dart';

class RegisterButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const RegisterButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? const Color(0xFFF4BE2C) : Colors.grey[400],
          elevation: isEnabled ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

