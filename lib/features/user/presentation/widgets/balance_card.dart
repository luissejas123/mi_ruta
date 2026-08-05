import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final String currency;
  final String? cardNumber;

  const BalanceCard({
    super.key,
    required this.balance,
    this.currency = 'Bs.',
    this.cardNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // ✅ Color amarillo consistente con toda la app
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC12F), Color(0xFFE6A800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SALDO DISPONIBLE',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$currency ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (cardNumber != null) ...[
            const SizedBox(height: 16),
            Text(
              cardNumber!,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}