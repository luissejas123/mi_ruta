import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/admin/domain/entities/operational_report.dart';
import 'package:mi_ruta/features/admin/domain/services/operational_report_export_service.dart';

void main() {
  const report = OperationalReport(
    drivers: [
      DriverOperationalStatus(
        id: '1',
        name: 'Ana & Asociados',
        line: '101',
        completedTrips: 8,
        rating: 4.8,
        isSuspended: false,
      ),
      DriverOperationalStatus(
        id: '2',
        name: 'Bruno',
        line: '',
        completedTrips: 2,
        rating: 3.2,
        isSuspended: true,
      ),
    ],
  );
  final service = OperationalReportExportService();
  final generatedAt = DateTime(2026, 9, 18, 9, 30);

  test('genera un PDF válido con contenido', () async {
    final bytes = await service.buildPdf(report, generatedAt: generatedAt);

    expect(bytes.length, greaterThan(100));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });

  test('genera un XLSX válido con todos los choferes', () {
    final bytes = service.buildExcel(report, generatedAt: generatedAt);
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((file) => file.name).toSet();

    expect(names, contains('xl/workbook.xml'));
    expect(names, contains('xl/worksheets/sheet1.xml'));

    final sheet = archive.findFile('xl/worksheets/sheet1.xml')!;
    final xml = utf8.decode(sheet.readBytes()!);
    expect(xml, contains('Ana &amp; Asociados'));
    expect(xml, contains('Bruno'));
    expect(xml, contains('Suspendido'));
  });
}
