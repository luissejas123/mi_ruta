import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FloatingNotification extends StatelessWidget {
  final String message;

  const FloatingNotification({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 87,
      decoration: BoxDecoration(
        color: const Color(0xFFFBC02D),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Container(
            width: 65,
            height: 59,
            decoration: const BoxDecoration(
              color: Color(0xFF0EBC60),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingGift extends StatelessWidget {
  final int count;

  const FloatingGift({this.count = 1, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 65,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Icon(
              Icons.card_giftcard,
              size: 82,
              color: Colors.red, // Asumiendo color, ajustar si necesario
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 34,
              height: 31,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}