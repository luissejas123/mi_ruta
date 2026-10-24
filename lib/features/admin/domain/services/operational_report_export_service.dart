import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:mi_ruta/features/admin/domain/entities/operational_report.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class OperationalReportExportService {
  Future<Uint8List> buildPdf(
    OperationalReport report, {
    DateTime? generatedAt,
  }) async {
    final date = generatedAt ?? DateTime.now();
    final document = pw.Document();
    final drivers = _orderedDrivers(report);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'Mi Ruta - Reporte operativo',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado: ${_formatDate(date)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total: ${report.totalDrivers}'),
              pw.Text('Suspendidos: ${report.suspendedDrivers.length}'),
              pw.Text('Destacados: ${report.featuredDrivers.length}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Estado',
              'Chofer',
              'Linea',
              'Viajes',
              'Calificacion',
            ],
            data: drivers
                .map(
                  (driver) => [
                    driver.isSuspended ? 'Suspendido' : 'Activo',
                    driver.name,
                    driver.line.isEmpty ? 'Sin linea' : driver.line,
                    driver.completedTrips.toString(),
                    driver.rating.toStringAsFixed(1),
                  ],
                )
                .toList(),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFC12F),
            ),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    return document.save();
  }

  Uint8List buildExcel(OperationalReport report, {DateTime? generatedAt}) {
    final date = generatedAt ?? DateTime.now();
    final rows = <List<Object>>[
      ['Mi Ruta - Reporte operativo'],
      ['Generado', _formatDate(date)],
      [],
      ['Estado', 'Chofer', 'Linea', 'Viajes', 'Calificacion'],
      ..._orderedDrivers(report).map(
        (driver) => <Object>[
          driver.isSuspended ? 'Suspendido' : 'Activo',
          driver.name,
          driver.line.isEmpty ? 'Sin linea' : driver.line,
          driver.completedTrips,
          driver.rating,
        ],
      ),
      [],
      ['Total', report.totalDrivers],
      ['Suspendidos', report.suspendedDrivers.length],
      ['Destacados', report.featuredDrivers.length],
    ];

    final sheetRows = <String>[];
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final cells = <String>[];
      for (
        var columnIndex = 0;
        columnIndex < rows[rowIndex].length;
        columnIndex++
      ) {
        final value = rows[rowIndex][columnIndex];
        final reference = '${_columnName(columnIndex)}${rowIndex + 1}';
        final style = rowIndex == 3 ? ' s="1"' : '';
        if (value is num) {
          cells.add('<c r="$reference"$style><v>$value</v></c>');
        } else {
          cells.add(
            '<c r="$reference" t="inlineStr"$style><is><t>${_xml(value.toString())}</t></is></c>',
          );
        }
      }
      sheetRows.add('<row r="${rowIndex + 1}">${cells.join()}</row>');
    }

    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes))
      ..addFile(ArchiveFile.string('_rels/.rels', _rootRelationships))
      ..addFile(ArchiveFile.string('xl/workbook.xml', _workbook))
      ..addFile(
        ArchiveFile.string(
          'xl/_rels/workbook.xml.rels',
          _workbookRelationships,
        ),
      )
      ..addFile(ArchiveFile.string('xl/styles.xml', _styles))
      ..addFile(
        ArchiveFile.string(
          'xl/worksheets/sheet1.xml',
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
              '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
              '<cols><col min="1" max="1" width="14" customWidth="1"/>'
              '<col min="2" max="2" width="30" customWidth="1"/>'
              '<col min="3" max="5" width="16" customWidth="1"/></cols>'
              '<sheetData>${sheetRows.join()}</sheetData>'
              '</worksheet>',
        ),
      );

    return ZipEncoder().encodeBytes(archive);
  }

  Future<File> savePdf(OperationalReport report) async {
    final bytes = await buildPdf(report);
    return _save(bytes, extension: 'pdf');
  }

  Future<File> saveExcel(OperationalReport report) {
    return _save(buildExcel(report), extension: 'xlsx');
  }

  Future<void> share(File file, {required String subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject),
    );
  }

  Future<File> _save(Uint8List bytes, {required String extension}) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${directory.path}/reporte_operativo_$timestamp.$extension',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  List<DriverOperationalStatus> _orderedDrivers(OperationalReport report) {
    return [...report.drivers]..sort((a, b) {
      final byStatus = (a.isSuspended ? 0 : 1).compareTo(b.isSuspended ? 0 : 1);
      return byStatus != 0 ? byStatus : a.name.compareTo(b.name);
    });
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

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

  String _xml(String value) =>
      const HtmlEscape(HtmlEscapeMode.element).convert(value);

  static const _contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
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
      '<sheets><sheet name="Reporte operativo" sheetId="1" r:id="rId1"/></sheets>'
      '</workbook>';

  static const _workbookRelationships =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';

  static const _styles =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="2"><font/><font><b/></font></fonts>'
      '<fills count="2"><fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FFFFC12F"/><bgColor indexed="64"/></patternFill></fill></fills>'
      '<borders count="1"><border/></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="0" fontId="1" fillId="1" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs>'
      '</styleSheet>';
}
