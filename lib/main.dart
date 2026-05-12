import 'package:flutter/material.dart';
import 'escanear_foto_page.dart';
import 'enviar_imagen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Pantalla inicial
      home: const EscanearFotoPage(),
    );
  }
}

/// =======================================
/// PANTALLA SUBIR FOTOGRAFIA
/// =======================================
class EscanearFotoPage extends StatelessWidget {
  const EscanearFotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Flecha atrás
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {},
              ),

              const SizedBox(height: 30),

              // Título
              const Center(
                child: Text(
                  'SUBIR FOTOGRAFIA',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Cuadro para imagen
              Center(
                child: Container(
                  width: 220,
                  height: 220,

                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              const SizedBox(height: 80),

              // Botón enviar
              Center(
                child: SizedBox(
                  width: 200,
                  height: 45,

                  child: ElevatedButton(
                    onPressed: () {

                      // Ir a pantalla de éxito
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const EnviarImagenPage(),
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 6,
                    ),

                    child: const Text(
                      'Subir Imagen',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================================
/// PANTALLA RECARGA EXITOSA
/// =======================================
class RecargaExitosaPage extends StatelessWidget {
  const RecargaExitosaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Círculo verde
              Container(
                width: 120,
                height: 120,

                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 70,
                ),
              ),

              const SizedBox(height: 40),

              // Texto
              const Text(
                '¡Abonaste saldo\nde manera\nexitosa!',
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}