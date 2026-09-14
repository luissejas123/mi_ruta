import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mi_ruta/features/routes/domain/entities/planned_trip.dart';
import 'package:mi_ruta/features/routes/domain/services/tariff_service.dart';

/// Builds the "Historial de viajes cancelados" PDF document as raw bytes.
///
/// Layout uses only the pure-Dart `pdf` package (no Flutter widgets) — the
/// presentation layer hands the resulting bytes to `printing` for
/// preview/share/save. Depends on `TariffService` (Firestore-backed) to
/// resolve real per-trip costs — same pattern already used elsewhere for
/// cross-feature domain services (e.g. `DriverService`).
class CancelledTripsPdfService {
  static const _accent = PdfColor.fromInt(0xFFFFC12F);

  final TariffService _tariffService;

  CancelledTripsPdfService({required TariffService tariffService})
      : _tariffService = tariffService;

  Future<Uint8List> build(List<PlannedTrip> trips) async {
    // Costo real por tarifa/distancia configurada, no el monto plano
    // `busLegs.length * 2.5` que se imprimía antes sin mirar la línea real
    // — es lo que Padre marcó como la exposición más seria de este bug
    // (docs/PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 2, paso 3): un PDF de
    // "recibo" mostrando un monto inventado. Si falla la consulta (sin
    // conexión), cae al estimado plano en vez de romper la descarga.
    final costs = <String, double>{};
    for (final t in trips) {
      try {
        costs[t.id] = await _tariffService.resolvePlannedTripFare(t);
      } catch (_) {
        costs[t.id] = t.totalCostBs;
      }
    }

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
                    (costs[t.id] ?? t.totalCostBs).toStringAsFixed(2),
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
