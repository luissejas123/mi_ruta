import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mi_ruta/features/routes/domain/entities/planned_trip.dart';

/// Builds the "Historial de viajes cancelados" PDF document as raw bytes.
///
/// Kept dependency-free of Flutter (only the pure-Dart `pdf` package) so it
/// stays testable like the rest of the domain layer — the presentation
/// layer is responsible for handing the resulting bytes to `printing` for
/// preview/share/save.
class CancelledTripsPdfService {
  static const _accent = PdfColor.fromInt(0xFFFFC12F);

  Future<Uint8List> build(List<PlannedTrip> trips) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Mi Ruta',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _accent,
                  ),
                ),
                pw.Text(
                  'Generado: ${_formatDateTime(DateTime.now())}',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Historial de viajes cancelados',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Total de viajes cancelados: ${trips.length}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          if (trips.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 16),
              child: pw.Text(
                'No hay viajes cancelados registrados.',
                style: const pw.TextStyle(color: PdfColors.grey600),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                  fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: _accent),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 24,
              headers: const [
                'Ruta',
                'Origen',
                'Destino',
                'Cancelado el',
                'Costo (Bs)',
              ],
              data: [
                for (final t in trips)
                  [
                    t.routesSummary.isEmpty ? '—' : t.routesSummary,
                    t.originName,
                    t.destinationName,
                    _formatDateTime(t.cancelledAt ?? t.createdAt),
                    t.totalCostBs.toStringAsFixed(2),
                  ],
              ],
            ),
        ],
      ),
    );

    return doc.save();
  }

  String _formatDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
