import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({required FirebaseStorage storage}) : _storage = storage;

  /// Sube una imagen de comprobante a Firebase Storage
  /// Retorna la URL pública de la imagen
  Future<String> uploadRechargeProof({
    required String userId,
    required String rechargeId,
    required File imageFile,
  }) async {
    try {
      // Ruta: recharges/{userId}/{rechargeId}/proof.jpg
      final ref = _storage.ref().child(
        'recharges/$userId/$rechargeId/proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Subir archivo
      await ref.putFile(imageFile);

      // Obtener URL de descarga
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir comprobante: $e');
    }
  }

  /// Elimina un comprobante del storage
  Future<void> deleteRechargeProof(String proofUrl) async {
    try {
      final ref = _storage.refFromURL(proofUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Error al eliminar comprobante: $e');
    }
  }

  /// Sube un documento de solicitud de beneficio
  /// Retorna la URL pública del documento
  Future<String> uploadBenefitDocument({
    required String userId,
    required String requestId,
    required File documentFile,
    required int documentIndex,
  }) async {
    try {
      // Ruta: benefits/{userId}/{requestId}/document_{index}.*
      final fileName = documentFile.path.split('/').last;
      final fileExtension = fileName.split('.').last;

      final ref = _storage.ref().child(
        'benefits/$userId/$requestId/document_$documentIndex.$fileExtension',
      );

      // Subir archivo
      await ref.putFile(documentFile);

      // Obtener URL de descarga
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir documento: $e');
    }
  }

  /// Elimina un documento de beneficio
  Future<void> deleteBenefitDocument(String documentUrl) async {
    try {
      final ref = _storage.refFromURL(documentUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Error al eliminar documento: $e');
    }
  }
}
