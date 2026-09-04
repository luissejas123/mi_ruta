import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mi_ruta/features/user/data/datasources/trip_history_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/trip_history_entry.dart';

class TripHistoryService {
  final TripHistoryDatasource _datasource;

  TripHistoryService({required TripHistoryDatasource datasource})
    : _datasource = datasource;

  Future<void> saveTrip({
    required String userId,
    required String routeName,
    required String originName,
    required String destinationName,
    required Duration elapsed,
    double farePaid = 0.0,
  }) async {
    final entry = TripHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      routeName: routeName,
      originName: originName,
      destinationName: destinationName,
      elapsed: elapsed,
      date: DateTime.now(),
      farePaid: farePaid,
    );
    await _datasource.saveTrip(entry);
  }

  Future<List<TripHistoryEntry>> getTrips(String userId) =>
      _datasource.getTrips(userId);

  String _formatDuration(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    return '$day/$month/$year';
  }

  Future<List<int>> generateDriverTripHistoryPdf(String userId) async {
    final trips = await _datasource.getTrips(userId);
    if (trips.isEmpty) {
      return <int>[];
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final rows = <pw.TableRow>[
            pw.TableRow(
              children: [
                pw.Text(
                  'Ruta',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Origen',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Destino',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Duración',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Fecha',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            ...trips.map(
              (trip) => pw.TableRow(
                children: [
                  pw.Text(trip.routeName),
                  pw.Text(trip.originName),
                  pw.Text(trip.destinationName),
                  pw.Text(_formatDuration(trip.elapsed)),
                  pw.Text(_formatDate(trip.date)),
                ],
              ),
            ),
          ];

          return [
            pw.Text(
              'Historial de viajes',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(1.6),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.0),
                4: pw.FlexColumnWidth(1.0),
              },
              children: rows,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<String> downloadDriverTripHistory(String userId) async {
    final trips = await _datasource.getTrips(userId);
    if (trips.isEmpty) {
      return '';
    }

    final pdfBytes = await generateDriverTripHistoryPdf(userId);
    if (pdfBytes.isEmpty) {
      return '';
    }

    final downloadsDir =
        await getDownloadsDirectory() ?? await getTemporaryDirectory();
    final pdfFile = File(
      '${downloadsDir.path}/historial_viajes_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await pdfFile.writeAsBytes(pdfBytes, flush: true);
    return pdfFile.path;
  }
}
