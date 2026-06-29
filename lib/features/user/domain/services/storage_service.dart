import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({required FirebaseStorage storage}) : _storage = storage;

  /// Sube foto de perfil del usuario
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // ✅ Ruta: profiles/{userId}/profile.jpg
      final ref = _storage.ref().child(
        'profiles/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir foto de perfil: $e');
    }
  }

  /// Sube una imagen de comprobante a Firebase Storage
  Future<String> uploadRechargeProof({
    required String userId,
    required String rechargeId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child(
        'recharges/$userId/$rechargeId/proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(imageFile);
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
  Future<String> uploadBenefitDocument({
    required String userId,
    required String requestId,
    required File documentFile,
    required int documentIndex,
  }) async {
    try {
      final fileName = documentFile.path.split('/').last;
      final fileExtension = fileName.split('.').last;
      final ref = _storage.ref().child(
        'benefits/$userId/$requestId/document_$documentIndex.$fileExtension',
      );
      await ref.putFile(documentFile);
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