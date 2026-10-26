import 'package:mi_ruta/features/admin/data/datasources/operational_report_datasource.dart';
import 'package:mi_ruta/features/admin/domain/entities/operational_report.dart';

class OperationalReportService {
  final OperationalReportDatasource _datasource;

  OperationalReportService({
    required OperationalReportDatasource datasource,
  }) : _datasource = datasource;

  Future<OperationalReport> getReport({
    DateTime? from,
    DateTime? to,
  }) {
    return _datasource.getReport(
      from: from,
      to: to,
    );
  }
}