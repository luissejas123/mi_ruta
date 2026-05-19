import 'dart:io';

import 'package:flutter/material.dart';

/// Sección de carga de documentos para [SolicitudBeneficioPage].
/// Incluye el área de toque para añadir archivos y la lista de documentos
/// seleccionados.
class DocumentUploadSection extends StatelessWidget {
  final bool isSubmitting;
  final List<File> documents;
  final VoidCallback onAddDocument;
  final void Function(int index) onRemoveDocument;

  const DocumentUploadSection({
    super.key,
    required this.isSubmitting,
    required this.documents,
    required this.onAddDocument,
    required this.onRemoveDocument,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: isSubmitting ? null : onAddDocument,
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  'Toca para agregar documentos',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Puedes agregar múltiples fotos o documentos',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (documents.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DocumentItemTile(
                    fileName: fileName,
                    fileSizeKb: (file.lengthSync() / 1024).toStringAsFixed(2),
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
  final VoidCallback onRemove;

  const _DocumentItemTile({
    required this.fileName,
    required this.fileSizeKb,
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
          Icon(Icons.description, size: 20, color: Colors.blue.shade600),
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
                  '$fileSizeKb KB',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 18,
            color: Colors.red,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
