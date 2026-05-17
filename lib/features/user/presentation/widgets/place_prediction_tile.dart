import 'package:flutter/material.dart';

/// Ítem de la lista de sugerencias de búsqueda.
class PlacePredictionTile extends StatelessWidget {
  final Map<String, dynamic> prediction;
  final VoidCallback onTap;

  const PlacePredictionTile({
    super.key,
    required this.prediction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sf = prediction['structured_formatting'] as Map<String, dynamic>?;
    final mainText = (sf?['main_text'] as String?) ?? '';
    final secondaryText = (sf?['secondary_text'] as String?) ?? '';

    return ListTile(
      leading: const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFFFBC02D),
        child: Icon(Icons.location_on, color: Colors.black87, size: 18),
      ),
      title: Text(
        mainText,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        secondaryText,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
      onTap: onTap,
    );
  }
}
