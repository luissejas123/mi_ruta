import 'package:flutter/material.dart';

class HistorialConductorPage extends StatelessWidget {
  const HistorialConductorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),

        title: const Text(
          'Historial del Pasajero',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,

        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),

        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
        ),

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Billetera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Rutas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),

            child: Column(
              children: [

                // CARD SUPERIOR
                Container(
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EDF5),
                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(
                      color: Colors.black12,
                    ),
                  ),

                  child: Row(
                    children: [

                      // FOTO
                     Container(
                      width: 66,
                      height: 66,

                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.person,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                      const SizedBox(width: 14),

                      // INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            const Align(
                              alignment: Alignment.topRight,

                              child: Text(
                                'Hoy- Lunes 12 abril',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            const SizedBox(height: 2),

                            const Text(
                              'Juan Perez',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Row(
                              children: const [

                                Icon(
                                  Icons.directions_bus,
                                  color: Color(0xFFFFC107),
                                  size: 28,
                                ),

                                SizedBox(width: 8),

                                Text(
                                  'Unidada: 103',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // CONTENEDOR VIAJES
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E1D8),
                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Column(
                    children: [

                      // TITULO
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children:[

                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Viajes ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'desde hoy',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),

                      // ITEMS
                      const ViajeItem(),
                      const ViajeItem(),
                      const ViajeItem(),
                      const ViajeItem(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ViajeItem extends StatelessWidget {
  const ViajeItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),

      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFD0CBC1),
            width: 1,
          ),
        ),
      ),

      child: Column(
        children: [

          // PARTE SUPERIOR
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // NUMERO
              Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(8),
                ),

                child: const Center(
                  child: Text(
                    '10',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // TEXTO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Terminal → Plaza Central',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [

                        Container(
                          width: 20,
                          height: 20,

                          decoration: const BoxDecoration(
                            color: Color(0xFF39B54A),
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.access_time,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 6),

                        const Text(
                          '08:30 am - 09:20 am',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ESTRELLAS
          Row(
            children: [

              const Text(
                '😡',
                style: TextStyle(fontSize: 28),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      size: 18,
                      color: index == 0
                          ? const Color(0xFFFFC107)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star,
                      size: 18,
                      color: Color(0xFFFFC107),
                    ),
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