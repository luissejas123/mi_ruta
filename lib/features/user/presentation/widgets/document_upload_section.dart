import 'dart:io';
import 'package:flutter/material.dart';

class DocumentUploadSection extends StatelessWidget {
  final bool isSubmitting;
  final List<File> documents;
  final VoidCallback onAddDocument;
  final void Function(int index) onRemoveDocument;

  // ✅ Constantes de validación
  static const _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const _allowedExtensions = ['jpg', 'jpeg', 'png'];

  const DocumentUploadSection({
    super.key,
    required this.isSubmitting,
    required this.documents,
    required this.onAddDocument,
    required this.onRemoveDocument,
  });

  // ✅ Validar archivo antes de agregar
  static String? validateFile(File file) {
    final fileName = file.path.split('/').last.toLowerCase();
    final extension = fileName.split('.').last;

    if (!_allowedExtensions.contains(extension)) {
      return 'Solo se permiten archivos JPG o PNG';
    }

    final fileSize = file.lengthSync();
    if (fileSize > _maxFileSizeBytes) {
      final sizeMB = (fileSize / 1024 / 1024).toStringAsFixed(1);
      return 'El archivo supera 5 MB (tamaño actual: $sizeMB MB)';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: documents.isNotEmpty
              ? const Color(0xFFFFC12F)
              : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ✅ Área de toque para agregar
          GestureDetector(
            onTap: isSubmitting ? null : onAddDocument,
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: documents.isNotEmpty
                      ? const Color(0xFFFFC12F)
                      : Colors.grey.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  'Toca para agregar documentos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solo JPG o PNG • Máximo 5 MB por archivo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // ✅ Lista de documentos seleccionados
          if (documents.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Documentos seleccionados (${documents.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final file = documents[index];
                final fileName = file.path.split('/').last;
                final fileSize = file.lengthSync();
                final isImage = fileName.toLowerCase().endsWith('.jpg') ||
                    fileName.toLowerCase().endsWith('.jpeg') ||
                    fileName.toLowerCase().endsWith('.png');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DocumentItemTile(
                    fileName: fileName,
                    fileSizeKb: fileSize < 1024 * 1024
                        ? '${(fileSize / 1024).toStringAsFixed(0)} KB'
                        : '${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                    isImage: isImage,
                    onRemove: () => onRemoveDocument(index),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentItemTile extends StatelessWidget {
  final String fileName;
  final String fileSizeKb;
  final bool isImage;
  final VoidCallback onRemove;

  const _DocumentItemTile({
    required this.fileName,
    required this.fileSizeKb,
    required this.isImage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // ✅ Ícono según tipo
          Icon(
            isImage ? Icons.image_outlined : Icons.description_outlined,
            size: 22,
            color: const Color(0xFFFFC12F),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileSizeKb,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 18,
            color: Colors.red.shade400,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}