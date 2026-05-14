import 'package:flutter/material.dart';

void main() {
  runApp(const MiRutaApp());
}

class MiRutaApp extends StatelessWidget {
  const MiRutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MiRuta Mockup',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto', // Puedes cambiarlo por la fuente que uses
      ),
      home: const ProgramarViajeScreen(),
    );
  }
}

class ProgramarViajeScreen extends StatelessWidget {
  const ProgramarViajeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos simulados para las rutas (Mock data)
    final List<Map<String, dynamic>> rutas = [
      {'time': '18min', 'distance': '10 Km', 'buses': ['H'], 'price': '3', 'departure': 'Calle max paredes'},
      {'time': '10min', 'distance': '4.9 Km', 'buses': ['U', 'M'], 'price': '6', 'departure': 'Calle max paredes'},
      {'time': '18min', 'distance': '2Km', 'buses': ['K'], 'price': '3', 'departure': 'Calle max paredes'},
      {'time': '18min', 'distance': '1 Km', 'buses': ['P'], 'price': '3', 'departure': 'Calle max paredes'},
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Cabecera principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo MiRuta y Menú
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MiRuta',
                        style: TextStyle(
                          color: Color(0xFFFFCA28), // Amarillo similar al diseño
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu, size: 30),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Título Programar Viaje
                  Row(
                    children: [
                      const Icon(Icons.arrow_back, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Programar Viaje',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Barra de búsqueda
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // Fondo amarillo muy claro
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.black45),
                        SizedBox(width: 10),
                        Text(
                          '¿A dónde vamos, Alex?',
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Sombra sutil debajo del header (opcional según el diseño)
            Container(
              height: 2,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),

            // Lista de Rutas
            Expanded(
              child: Container(
                color: const Color(0xFFF5F5F5), // Fondo gris claro de la lista
                child: ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: rutas.length,
                  itemBuilder: (context, index) {
                    final ruta = rutas[index];
                    return _buildRouteCard(ruta);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para construir cada tarjeta de ruta
  Widget _buildRouteCard(Map<String, dynamic> ruta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: const Color(0xFFFFCA28), // Borde amarillo
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila superior: Tiempo y Distancia
          Center(
            child: Text(
              '${ruta['time']}   (${ruta['distance']})',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Fila media: Buses y Precio/Botón
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lista horizontal de buses
              Expanded(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: (ruta['buses'] as List<String>).map((bus) {
                    return _buildBusBadge(bus);
                  }).toList(),
                ),
              ),
              
              // Precio y Botón Elegir
              Column(
                children: [
                  Text(
                    'Bs   ${ruta['price']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF212121), // Negro
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Text(
                        'Elegir',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fila inferior: Punto de partida
          Text(
            'Sale desde la ${ruta['departure']}',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para el indicador amarillo de cada bus
  Widget _buildBusBadge(String letter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCA28), // Fondo amarillo
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_bus, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            letter,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}