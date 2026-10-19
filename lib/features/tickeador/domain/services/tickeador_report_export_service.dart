import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/tickeador_payments_report.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Genera PDF/Excel del reporte de auditoría del tickeador — mismo patrón
/// (sin dependencias extra, xlsx a mano) que
/// `OperationalReportExportService` del admin, ver ese archivo.
class TickeadorReportExportService {
  Future<Uint8List> buildPdf(TickeadorPaymentsReportEntity report) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'Mi Ruta - Reporte de cobros (Tickeador)',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Período: ${_formatDate(report.from)} - ${_formatDate(report.to)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.Text(
            'Unidades vistas en la estación: ${report.vehicleIds.join(', ')}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total cobrado: Bs. ${report.totalAmount.toStringAsFixed(2)}'),
              pw.Text('Viajes pagados: ${report.totalTrips}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('Por unidad', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Unidad', 'Línea', 'Viajes', 'Monto (Bs.)'],
            data: report.byVehicle
                .map((v) => [v.vehicleId, v.routeName, v.trips.toString(), v.amount.toStringAsFixed(2)])
                .toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFC12F)),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Por día', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          for (final day in report.byDay) ...[
            pw.Text(_formatDay(day.day),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const ['Pasajero', 'Unidad', 'Monto (Bs.)'],
              data: day.entries
                  .map((e) => [e.passengerName, e.vehicleId, e.amount.toStringAsFixed(2)])
                  .toList(),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFC12F)),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 4),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Total del día: Bs. ${day.amount.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    return document.save();
  }

  Uint8List buildExcel(TickeadorPaymentsReportEntity report) {
    final rows = <List<Object>>[
      ['Mi Ruta - Reporte de cobros (Tickeador)'],
      ['Período', '${_formatDate(report.from)} - ${_formatDate(report.to)}'],
      ['Unidades vistas en la estación', report.vehicleIds.join(', ')],
      [],
      ['Total cobrado (Bs.)', report.totalAmount],
      ['Viajes pagados', report.totalTrips],
      [],
      ['Unidad', 'Línea', 'Viajes', 'Monto (Bs.)'],
      ...report.byVehicle.map((v) => <Object>[v.vehicleId, v.routeName, v.trips, v.amount]),
      [],
      ['Desglose diario'],
      for (final day in report.byDay) ...[
        [_formatDay(day.day)],
        ['Pasajero', 'Unidad', 'Monto (Bs.)'],
        ...day.entries.map((e) => <Object>[e.passengerName, e.vehicleId, e.amount]),
        ['Total del día', '', day.amount],
        [],
      ],
    ];

    final sheetRows = <String>[];
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final cells = <String>[];
      for (var columnIndex = 0; columnIndex < rows[rowIndex].length; columnIndex++) {
        final value = rows[rowIndex][columnIndex];
        final reference = '${_columnName(columnIndex)}${rowIndex + 1}';
        if (value is num) {
          cells.add('<c r="$reference"><v>$value</v></c>');
        } else {
          cells.add('<c r="$reference" t="inlineStr"><is><t>${_xml(value.toString())}</t></is></c>');
        }
      }
      sheetRows.add('<row r="${rowIndex + 1}">${cells.join()}</row>');
    }

    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes))
      ..addFile(ArchiveFile.string('_rels/.rels', _rootRelationships))
      ..addFile(ArchiveFile.string('xl/workbook.xml', _workbook))
      ..addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', _workbookRelationships))
      ..addFile(
        ArchiveFile.string(
          'xl/worksheets/sheet1.xml',
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
              '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
              '<cols><col min="1" max="1" width="18" customWidth="1"/>'
              '<col min="2" max="3" width="16" customWidth="1"/></cols>'
              '<sheetData>${sheetRows.join()}</sheetData>'
              '</worksheet>',
        ),
      );

    return ZipEncoder().encodeBytes(archive);
  }

  Future<File> savePdf(TickeadorPaymentsReportEntity report) async {
    final bytes = await buildPdf(report);
    return _save(bytes, extension: 'pdf');
  }

  Future<File> saveExcel(TickeadorPaymentsReportEntity report) {
    return _save(buildExcel(report), extension: 'xlsx');
  }

  Future<void> share(File file, {required String subject}) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: subject));
  }

  Future<File> _save(Uint8List bytes, {required String extension}) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/reporte_tickeador_$timestamp.$extension');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  String _formatDay(DateTime date) => _formatDate(date);

  String _columnName(int index) {
    var value = index + 1;
    var name = '';
    while (value > 0) {
      value--;
      name = String.fromCharCode(65 + value % 26) + name;
      value ~/= 26;
    }
    return name;
  }

  String _xml(String value) => const HtmlEscape(HtmlEscapeMode.element).convert(value);

  static const _contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '</Types>';

  static const _rootRelationships =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>';

  static const _workbook =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets><sheet name="Reporte tickeador" sheetId="1" r:id="rId1"/></sheets>'
      '</workbook>';

  static const _workbookRelationships =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '</Relationships>';
}
