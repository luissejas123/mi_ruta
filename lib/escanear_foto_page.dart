import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'enviar_imagen.dart';

class EscanearFotoPage extends StatefulWidget {
  const EscanearFotoPage({super.key});

  @override
  State<EscanearFotoPage> createState() =>
      _EscanearFotoPageState();
}

class _EscanearFotoPageState
    extends State<EscanearFotoPage> {

  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;

  Future<void> _pickImage() async {

    final XFile? result = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (result != null) {

      String path = result.path.toLowerCase();

      // Validar formatos
      if (!path.endsWith('.jpg') &&
          !path.endsWith('.jpeg') &&
          !path.endsWith('.png')) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solo se permiten imágenes JPG o PNG',
            ),
          ),
        );

        return;
      }

      final bytes = await result.readAsBytes();

      setState(() {
        _imageBytes = bytes;
      });
    }
  }

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
                  onPressed: () {},
                ),

                const SizedBox(height: 20),

                // Título
                const Center(
                  child: Text(
                    'SUBIR FOTOGRAFIA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Botón galería
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,

                    icon: const Icon(Icons.photo),

                    label: const Text(
                      'Subir desde galería',
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.grey.shade300,
                      foregroundColor: Colors.black,

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Imagen
                Center(
                  child: Container(
                    width: 240,
                    height: 240,

                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                      ),
                    ),

                    child: _imageBytes != null
                        ? Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Text(
                              'Imagen aquí',
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                // Texto ayuda
                Center(
                  child: Text(
                    'Solo imágenes JPG y PNG',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Botón subir imagen
                Center(
                  child: SizedBox(
                    width: 170,
                    height: 48,

                    child: ElevatedButton(
                      onPressed: () {

                        if (_imageBytes == null) {

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Debes seleccionar una imagen',
                              ),
                            ),
                          );
                          return;
                        }

                        if (_imageBytes!.lengthInBytes > 5 * 1024 * 1024) {

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                                content: Text(
                                  'La imagen no puede superar los 5MB',
                                ),
                              ),
                            );

                          return;
                          
                        }
                        //imagen solo en png o jpg
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                              content: Text(
                                'Imagen válida, subiendo...',
                              ),
                            ),
                          );
                          //mensaje si la imagen no es valida "La imagen debe ser JPG o PNG"
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                                content: Text(
                                  'La imagen debe ser JPG o PNG',
                                ),
                              ),
                            );

                          // si todo esta bien, ir a  pantalla de éxito
                            
                          
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EnviarImagenPage(
                              imageBytes: _imageBytes,
                            ),
                          ),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),

                      child: const Text(
                        'Subir Imagen',
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