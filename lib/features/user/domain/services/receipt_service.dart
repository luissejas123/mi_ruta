import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mi_ruta/features/user/domain/entities/trip_history_entry.dart';

/// Genera comprobantes/constancias en PDF y permite compartirlos o
/// descargarlos al almacenamiento del dispositivo.
class ReceiptService {
  static const _amarillo = PdfColor.fromInt(0xFFFFC12F);

  String _fmtDate(DateTime d) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $hour:$minute';
  }

  pw.Widget _header(String title, String folio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(color: _amarillo),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Mi Ruta',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(title, style: const pw.TextStyle(fontSize: 13)),
            ],
          ),
          pw.Text('Folio: $folio', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<File> _savePdf(pw.Document doc, String fileNamePrefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  /// Constancia de un viaje realizado (sin monto, el historial de viajes
  /// no registra el pago asociado).
  Future<File> buildTripCertificate(TripHistoryEntry entry) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header('Constancia de viaje', entry.id),
            pw.SizedBox(height: 20),
            _row('Línea / ruta', entry.routeName),
            _row('Origen', entry.originName),
            _row('Destino', entry.destinationName),
            _row('Fecha y hora', _fmtDate(entry.date)),
            _row('Duración', '${entry.elapsed.inMinutes} min'),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Costo del viaje', style: const pw.TextStyle(fontSize: 13)),
                  pw.Text(
                    'Bs. ${entry.farePaid.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.Text(
              'Documento generado por la app Mi Ruta como constancia de uso del servicio de transporte.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
    return _savePdf(doc, 'constancia_viaje');
  }

  /// Comprobante digital de un movimiento de billetera (recarga o pago de viaje).
  Future<File> buildTransactionReceipt(Map<String, dynamic> transaction) async {
    final doc = pw.Document();

    final amount = (transaction['amount'] ?? 0.0).toDouble();
    final isTopUp = amount > 0;
    final type = transaction['transaction_type']?.toString() ?? '';
    final description = transaction['description']?.toString() ?? 'Movimiento';
    final id = transaction['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    DateTime date;
    try {
      date = (transaction['timestamp'] as dynamic).toDate();
    } catch (_) {
      date = DateTime.now();
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header('Comprobante digital', id),
            pw.SizedBox(height: 20),
            _row('Concepto', description),
            _row('Tipo', isTopUp ? 'Recarga de saldo' : 'Pago de viaje'),
            _row('Fecha y hora', _fmtDate(date)),
            if (transaction['payment_method'] != null)
              _row('Método de pago', transaction['payment_method'].toString()),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Monto', style: const pw.TextStyle(fontSize: 13)),
                  pw.Text(
                    '${isTopUp ? '+' : '-'} Bs. ${amount.abs().toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: isTopUp ? PdfColors.green700 : PdfColors.orange900,
                    ),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.Text(
              type.isNotEmpty ? 'Ref: $type' : '',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Comprobante generado por la app Mi Ruta.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
    return _savePdf(doc, 'comprobante');
  }

  /// Comparte/permite descargar el PDF generado mediante el selector nativo
  /// del sistema operativo.
  Future<void> share(File file, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject),
    );
  }
}
