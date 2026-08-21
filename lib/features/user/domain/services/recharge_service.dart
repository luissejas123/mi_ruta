import 'dart:io';
import 'package:mi_ruta/features/user/data/datasources/recharge_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/recharge.dart';
import 'package:mi_ruta/features/user/domain/services/wallet_service.dart';
import 'package:mi_ruta/features/user/domain/services/storage_service.dart';

/// Servicio de dominio para operaciones de recarga
class RechargeService {
  final RecargeDatasource _datasource;
  final StorageService _storageService;

  RechargeService({
    required RecargeDatasource datasource,
    required WalletService walletService,
    required StorageService storageService,
  }) : _datasource = datasource,
       _storageService = storageService;

  /// Crea una solicitud de recarga con comprobante
  /// Sube la imagen a Firebase Storage y retorna el ID de la recarga
  Future<String> submitRechargeRequest({
    required String userId,
    required double amount,
    required String currency,
    required File proofImageFile,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('El monto debe ser mayor a 0');
    }

    if (!proofImageFile.existsSync()) {
      throw ArgumentError('El archivo de comprobante no existe');
    }

    // Crear ID temporal para la recarga
    final tempRechargeId =
        'recharge_${userId}_${DateTime.now().millisecondsSinceEpoch}';

    // Subir imagen a Firebase Storage
    final proofImageUrl = await _storageService.uploadRechargeProof(
      userId: userId,
      rechargeId: tempRechargeId,
      imageFile: proofImageFile,
    );

    // Crear solicitud de recarga con URL de Storage
    final rechargeId = await _datasource.createRecharge(
      userId: userId,
      amount: amount,
      currency: currency,
      proofImageUrl: proofImageUrl,
    );

    return rechargeId;
  }

  /// Obtiene una recarga por ID
  Future<Recharge?> getRecharge(String rechargeId) async {
    return _datasource.getRechargeById(rechargeId);
  }

  /// Obtiene el historial de recargas del usuario
  Future<List<Recharge>> getRechargeHistory(String userId) async {
    return _datasource.getRechargesByUserId(userId);
  }

  /// Aprueba una recarga (automático o manual)
  /// Abona el saldo a la billetera
  Future<void> approveRecharge(String rechargeId, String userId) async {
    final recharge = await _datasource.getRechargeById(rechargeId);

    if (recharge == null) {
      throw Exception('Recarga no encontrada');
    }

    if (recharge.status != 'pending') {
      throw Exception('Solo se pueden aprobar recargas pendientes');
    }

    // Aprobar en Firestore
    await _datasource.approveRecharge(rechargeId, userId);

    // Opcional: Aquí podrías notificar al usuario
  }

  /// Obtiene recargas pendientes (para admin)
  Future<List<Recharge>> getPendingRecharges(String userId) async {
    final recharges = await _datasource.getRechargesByUserId(userId);
    return recharges.where((r) => r.status == 'pending').toList();
  }

  /// Obtiene la URL de generación del código QR
  /// Retorna una URL que puede ser usada por un generador de QR
  String getQRCodeUrl({
    required String bankAccount,
    required double amount,
    required String reference,
  }) {
    // Puedes usar un servicio como qr-server para generar QR dinámicos
    // O retornar datos para que un generador local lo haga
    return 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=BANCO|$bankAccount|$amount|$reference';
  }
}
