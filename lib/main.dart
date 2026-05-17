/*
//4.2 planificasion inteligente de rutas
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

*/


// tamaño estandar modo oscuro

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
      title: 'MiRuta - Selección de Ubicación',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: const SelectLocationPage(),
    );
  }
}

// =========================================================================
// PÁGINA PRINCIPAL (SelectLocationPage)
// =========================================================================
class SelectLocationPage extends StatelessWidget {
  const SelectLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<LocationItemData> sugerencias = [
      LocationItemData(
        title: 'Plaza 14 de septiembre',
        icon: Icons.location_on,
      ),
      LocationItemData(
        title: 'Migraciones Cochabamba',
        icon: Icons.location_on,
      ),
      LocationItemData(
        title: 'Calle las Buganvillas',
        icon: Icons.access_time,
      ),
      LocationItemData(
        title: 'Pedro de Toledo',
        icon: Icons.access_time,
      ),
      LocationItemData(
        title: 'Parque de dinosaurios',
        icon: Icons.access_time,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Fondo estilo mapa
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFFE5E3DF),
              child: CustomPaint(
                painter: MapPlaceholderPainter(),
              ),
            ),

            // Contenido principal
            Column(
              children: [
                // Header
                Container(
                  color: Colors.white.withOpacity(0.95),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MiRuta',
                        style: TextStyle(
                          color: Color(0xFFFFCA28),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          size: 30,
                          color: Colors.black87,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Card superior
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: LocationInputCard(),
                ),

                const Spacer(),

                // Lista inferior amarilla
                Container(
                  height: MediaQuery.of(context).size.height * 0.42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFCA28),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      bottom: 60.0,
                    ),
                    itemCount: sugerencias.length,
                    itemBuilder: (context, index) {
                      return LocationListItem(
                        item: sugerencias[index],
                        onTap: () {},
                      );
                    },
                  ),
                ),
              ],
            ),

            // Botón flotante
            Positioned(
              bottom: 25,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCA28),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 54,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Programar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFF8F9FA),
        selectedItemColor: const Color(0xFF212121),
        unselectedItemColor: Colors.black38,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(
                Icons.home_outlined,
                size: 28,
              ),
            ),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 28,
              ),
            ),
            label: 'Billetera',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(
                Icons.map,
                size: 28,
              ),
            ),
            label: 'Rutas',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(
                Icons.person_outline,
                size: 28,
              ),
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// CARD SUPERIOR
// =========================================================================
class LocationInputCard extends StatelessWidget {
  const LocationInputCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 18.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCA28),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ubicación actual
          Row(
            children: [
              const Icon(
                Icons.radio_button_checked,
                color: Color(0xFF1565C0),
                size: 22,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  'Tu ubicación',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.only(
              left: 38.0,
              top: 10.0,
              bottom: 10.0,
            ),
            child: Divider(
              color: Colors.black38,
              thickness: 1.2,
              height: 1,
            ),
          ),

          // Destino
          const Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.black87,
                size: 26,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Plaza 14 de septiembre',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// ITEM DE LISTA
// =========================================================================
class LocationListItem extends StatelessWidget {
  final LocationItemData item;
  final VoidCallback onTap;

  const LocationListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white30,
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 4.0,
        ),
        leading: Icon(
          item.icon,
          color: Colors.black87,
          size: 26,
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black87,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }
}

// =========================================================================
// MODELO DE DATOS
// =========================================================================
class LocationItemData {
  final String title;
  final IconData icon;

  LocationItemData({
    required this.title,
    required this.icon,
  });
}

// =========================================================================
// MAPA PLACEHOLDER
// =========================================================================
class MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height * 0.2),
      Offset(size.width, size.height * 0.3),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.4, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width, size.height * 0.5),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.6, size.height),
      paint,
    );

    final paintCircle = Paint()
      ..color = Colors.green.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.4),
      60,
      paintCircle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}