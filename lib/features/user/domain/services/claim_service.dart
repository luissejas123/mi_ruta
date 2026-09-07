import 'package:mi_ruta/features/user/data/datasources/claim_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/claim_entity.dart';

class ClaimService {
  final ClaimDatasource _datasource;

  ClaimService({required ClaimDatasource datasource}) : _datasource = datasource;

  Future<String> createClaim({
    required String reporterId,
    String? targetId,
    required String lineId,
    required String claimType,
    required String title,
    required String description,
  }) =>
      _datasource.createClaim(
        reporterId: reporterId,
        targetId: targetId,
        lineId: lineId,
        claimType: claimType,
        title: title,
        description: description,
      );

  Future<List<ClaimEntity>> getClaimsByReporter(String reporterId) =>
      _datasource.getClaimsByReporter(reporterId);

  Future<List<ClaimEntity>> getClaims({List<String> lineIds = const []}) =>
      _datasource.getClaims(lineIds: lineIds);

  Future<void> resolveClaim(String claimId, {required String resolvedBy, String? resolutionNote}) =>
      _datasource.resolveClaim(claimId, resolvedBy: resolvedBy, resolutionNote: resolutionNote);
}
