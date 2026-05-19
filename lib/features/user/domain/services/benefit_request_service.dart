import 'dart:io';
import 'package:mi_ruta/features/user/data/datasources/benefit_request_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/benefit_request.dart';
import 'package:mi_ruta/features/user/domain/services/storage_service.dart';

/// Servicio de dominio para operaciones de solicitudes de beneficio
class BenefitRequestService {
  final BenefitRequestDatasource _datasource;
  final StorageService _storageService;

  BenefitRequestService({
    required BenefitRequestDatasource datasource,
    required StorageService storageService,
  }) : _datasource = datasource,
       _storageService = storageService;

  /// Crea una solicitud de beneficio con documentos
  /// Sube los archivos a Firebase Storage y retorna el ID de la solicitud
  Future<String> submitBenefitRequest({
    required String userId,
    required String benefitType,
    required String description,
    required List<File> documentFiles,
  }) async {
    if (benefitType.isEmpty) {
      throw ArgumentError('El tipo de beneficio no puede estar vacío');
    }

    if (description.isEmpty) {
      throw ArgumentError('La descripción no puede estar vacía');
    }

    if (documentFiles.isEmpty) {
      throw ArgumentError('Debe incluir al menos un documento');
    }

    // Validar que todos los archivos existan
    for (final file in documentFiles) {
      if (!file.existsSync()) {
        throw ArgumentError('Uno o más archivos no existen');
      }
    }

    // Crear ID temporal para la solicitud
    final tempRequestId =
        'benefit_${userId}_${DateTime.now().millisecondsSinceEpoch}';

    // Subir todos los documentos a Firebase Storage
    final documentUrls = <String>[];
    for (int i = 0; i < documentFiles.length; i++) {
      final file = documentFiles[i];

      try {
        final url = await _storageService.uploadBenefitDocument(
          userId: userId,
          requestId: tempRequestId,
          documentFile: file,
          documentIndex: i,
        );
        documentUrls.add(url);
      } catch (e) {
        throw Exception('Error al subir documento: $e');
      }
    }

    // Crear solicitud de beneficio con URLs de Storage
    final requestId = await _datasource.createBenefitRequest(
      userId: userId,
      benefitType: benefitType,
      description: description,
      documentUrls: documentUrls,
    );

    return requestId;
  }

  /// Obtiene una solicitud de beneficio por ID
  Future<BenefitRequest?> getBenefitRequest(String requestId) async {
    return _datasource.getBenefitRequestById(requestId);
  }

  /// Obtiene el historial de solicitudes del usuario
  Future<List<BenefitRequest>> getBenefitRequestHistory(String userId) async {
    return _datasource.getBenefitRequestsByUserId(userId);
  }

  /// Aprueba una solicitud de beneficio
  Future<void> approveBenefitRequest(
    String requestId,
    String adminNotes,
  ) async {
    return _datasource.approveBenefitRequest(requestId, adminNotes);
  }

  /// Rechaza una solicitud de beneficio
  Future<void> rejectBenefitRequest(String requestId, String adminNotes) async {
    return _datasource.rejectBenefitRequest(requestId, adminNotes);
  }
}
