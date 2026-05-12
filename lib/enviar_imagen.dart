import 'package:flutter/material.dart';
import 'dart:typed_data';

class EnviarImagenPage extends StatefulWidget {

  final Uint8List? imageBytes;

  const EnviarImagenPage({
    super.key,
    this.imageBytes,
  });

  @override
  State<EnviarImagenPage> createState() =>
      _EnviarImagenPageState();
}

class _EnviarImagenPageState
    extends State<EnviarImagenPage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // Flecha atrás
                IconButton(
                  icon: const Icon(Icons.arrow_back),

                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 20),

                // Título
                const Center(
                  child: Text(
                    'ENVIAR IMAGEN',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Imagen
                Center(
                  child: Container(
                    width: 240,
                    height: 240,

                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                      ),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),

                    child: widget.imageBytes != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8),

                            child: Image.memory(
                              widget.imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Center(
                            child: Text(
                              'Sin imagen',
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                Center(
                  child: Text(
                    'Imagen lista para enviar',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Botón enviar
                Center(
                  child: SizedBox(
                    width: 140,
                    height: 48,

                    child: ElevatedButton(
                      onPressed: () {

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Imagen enviada correctamente',
                            ),
                          ),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),

                      child: const Text(
                        'Enviar',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}