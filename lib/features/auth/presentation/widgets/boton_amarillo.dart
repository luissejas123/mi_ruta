import 'package:flutter/material.dart';

class BotonAmarillo extends StatelessWidget {
  final String texto;
  final VoidCallback alPresionar;

  const BotonAmarillo({
    super.key,
    required this.texto,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: alPresionar,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC12F),
        minimumSize: const Size(280, 65),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
