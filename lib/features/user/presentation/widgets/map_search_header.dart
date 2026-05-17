import 'package:flutter/material.dart';

class MapSearchHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  final String? searchText;

  const MapSearchHeader({
    super.key,
    required this.onSearchTap,
    this.searchText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3F4),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'MiRuta',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFBC02D),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBC02D),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.black87),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      searchText ?? '¿A dónde vamos ...?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: searchText != null
                            ? Colors.black87
                            : Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (searchText != null)
                    const Icon(Icons.close, color: Colors.black54, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
