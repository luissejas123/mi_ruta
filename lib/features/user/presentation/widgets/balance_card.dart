import 'package:flutter/material.dart';

/// Tarjeta de saldo de wallet.
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF5C210), const Color(0xFFE6B000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Disponible',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '$currency ${balance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (cardNumber != null) ...[
            const SizedBox(height: 20),
            Text(
              cardNumber!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}
