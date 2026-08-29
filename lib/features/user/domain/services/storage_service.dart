import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mi_ruta/features/user/domain/entities/benefit_request.dart';

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

  /// Genera un comprobante PDF real a partir del documento asociado a un beneficio.
  /// Si el documento original es imagen, se convierte a PDF; si ya es PDF, se descarga tal cual.
  Future<File> generateBenefitPdf(BenefitRequest request) async {
    final docUrl = (request.documentUrls.isNotEmpty)
        ? request.documentUrls.first
        : throw Exception('La solicitud no tiene documento asociado');

    final response = await http.get(Uri.parse(docUrl));
    if (response.statusCode != 200) {
      throw Exception('No se pudo descargar el comprobante del beneficio');
    }

    final lowerUrl = docUrl.toLowerCase();
    final isPdf =
        lowerUrl.endsWith('.pdf') ||
        response.headers['content-type']?.toLowerCase().contains('pdf') == true;

    final downloadsDir =
        await getDownloadsDirectory() ?? await getTemporaryDirectory();
    final filePath =
        '${downloadsDir.path}/beneficio_${request.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfFile = File(filePath);

    if (isPdf) {
      await pdfFile.writeAsBytes(response.bodyBytes);
      return pdfFile;
    }

    final pdf = pw.Document();
    final imageBytes = response.bodyBytes;
    try {
      final image = pw.MemoryImage(imageBytes);
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Comprobante de beneficio',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Tipo: ${request.benefitType}'),
                pw.Text('Estado: ${request.status}'),
                pw.Text('Fecha: ${request.createdAt.toIso8601String()}'),
                pw.SizedBox(height: 20),
                pw.Image(image, fit: pw.BoxFit.contain),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            children: [
              pw.Text(
                'Comprobante de beneficio',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Tipo: ${request.benefitType}'),
              pw.Text('Estado: ${request.status}'),
              pw.Text('Fecha: ${request.createdAt.toIso8601String()}'),
              pw.SizedBox(height: 20),
              pw.Text(
                'El documento original no era compatible con PDF; se generó un comprobante a partir de los datos reales de la solicitud.',
              ),
            ],
          ),
        ),
      );
    }

    await pdfFile.writeAsBytes(await pdf.save());
    return pdfFile;
  }
}
