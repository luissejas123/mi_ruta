import 'package:flutter/material.dart';

void main() {
  runApp(const MiRutaRegistroApp());
}

class MiRutaRegistroApp extends StatelessWidget {
  const MiRutaRegistroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiRuta Registro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFC12F)),
        useMaterial3: true,
      ),
      home: const RegisterTripPage(),
    );
  }
}

class RegisterTripPage extends StatefulWidget {
  const RegisterTripPage({super.key});

  @override
  State<RegisterTripPage> createState() => _RegisterTripPageState();
}

class _RegisterTripPageState extends State<RegisterTripPage> {
  final List<RouteOption> _routeOptions = const [
    RouteOption(
      line: 'H',
      routeBadge: 'H',
      duration: '18 min',
      distance: '10 km',
      price: '3',
      subtitle: 'Sale desde la Calle max paredes',
    ),
    RouteOption(
      line: 'U → M',
      routeBadge: 'U',
      duration: '10 min',
      distance: '4.9 km',
      price: '6',
      subtitle: 'Sale desde la Calle max paredes',
    ),
    RouteOption(
      line: 'K',
      routeBadge: 'K',
      duration: '18 min',
      distance: '2 km',
      price: '3',
      subtitle: 'Sale desde la Calle max paredes',
    ),
    RouteOption(
      line: 'P',
      routeBadge: 'P',
      duration: '18 min',
      distance: '1 km',
      price: '3',
      subtitle: 'Sale desde la Calle max paredes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildPageHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(child: _buildRouteList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE59A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Programar Viaje',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2CC),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Color(0xFF7D7D7D)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '¿A dónde vamos, Alex?',
              style: TextStyle(color: Color(0xFF7D7D7D), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'MiRuta',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFC12F),
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.menu, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildRouteList() {
    return ListView.separated(
      itemCount: _routeOptions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _routeOptions[index];
        return RouteOptionCard(
          routeOption: item,
          onSelect: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Seleccionaste la ruta ${item.line}'),
              ),
            );
          },
        );
      },
    );
  }
}

class RouteOption {
  final String line;
  final String routeBadge;
  final String duration;
  final String distance;
  final String price;
  final String subtitle;

  const RouteOption({
    required this.line,
    required this.routeBadge,
    required this.duration,
    required this.distance,
    required this.price,
    required this.subtitle,
  });
}

class RouteOptionCard extends StatelessWidget {
  final RouteOption routeOption;
  final VoidCallback onSelect;

  const RouteOptionCard({
    super.key,
    required this.routeOption,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD36B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC12F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_bus, size: 18, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC12F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    routeOption.routeBadge,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    routeOption.line,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Bs ${routeOption.price}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: onSelect,
                      child: const Text('Elegir'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              routeOption.subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${routeOption.duration} • ${routeOption.distance}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
