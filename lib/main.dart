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
      title: 'MiRuta',
      theme: ThemeData(useMaterial3: true),
      home: const IniciarSesionFinal(), // Esta es la pantalla inicial
    );
  }
}

// --- PANTALLA 1: INICIAR SESIÓN FINAL ---
class IniciarSesionFinal extends StatelessWidget {
  const IniciarSesionFinal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'MiRuta',
              style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tu ruta, tu viaje,\ntu pago.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 50),
            // Botón Iniciar Sesión
            BotonAmarillo(
              texto: 'Iniciar sesión', 
              alPresionar: () {
                // Navegar a la segunda pantalla
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const InsertarCorreo())
                );
              }
            ),
            const SizedBox(height: 20),
            // Botón Registrarte
            BotonAmarillo(texto: 'Registrarte', alPresionar: () {}),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA 2: INSERTAR CORREO ---
class InsertarCorreo extends StatelessWidget {
  const InsertarCorreo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'MiRuta',
              style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            const InputConSombra(hint: '@ Correo electronico'),
            const InputConSombra(hint: 'Contraseña'),
            const SizedBox(height: 30),
            // Botón Negro
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(300, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 25),
            const Text('¿Olvidaste tu cuenta?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS REUTILIZABLES (Para mantener el código limpio) ---

class BotonAmarillo extends StatelessWidget {
  final String texto;
  final VoidCallback alPresionar;

  const BotonAmarillo({super.key, required this.texto, required this.alPresionar});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: alPresionar,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC12F), // El color amarillo de tu imagen
        minimumSize: const Size(280, 65),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        texto,
        style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class InputConSombra extends StatelessWidget {
  final String hint;
  const InputConSombra({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}