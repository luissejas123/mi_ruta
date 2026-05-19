import 'package:flutter/material.dart';

/// Diálogo para mostrar progreso de descarga de rutas.
class CacheDownloadDialog extends StatelessWidget {
  final ValueNotifier<int> progressNotifier;
  final ValueNotifier<int> totalNotifier;

  const CacheDownloadDialog({
    super.key,
    required this.progressNotifier,
    required this.totalNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'Descargando rutas...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: progressNotifier,
                builder: (context, progress, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: totalNotifier,
                    builder: (context, total, _) {
                      final percentage = total > 0
                          ? ((progress / total) * 100).toStringAsFixed(1)
                          : '0.0';
                      return Text(
                        '$progress / $total rutas ($percentage%)',
                        style: Theme.of(context).textTheme.labelSmall,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
