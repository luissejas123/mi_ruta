import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mi_ruta/features/routes/domain/services/route_data_sync_service.dart';

class RouteUpdateBanner extends StatelessWidget {
  final ValueListenable<RouteSyncStatus> status;
  final Widget child;

  const RouteUpdateBanner({
    super.key,
    required this.status,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RouteSyncStatus>(
      valueListenable: status,
      child: child,
      builder: (context, syncStatus, child) {
        final visible = syncStatus != RouteSyncStatus.idle;
        final updating = syncStatus == RouteSyncStatus.syncing;
        return Stack(
          children: [
            Positioned.fill(child: child!),
            SafeArea(
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(0, -1),
                duration: const Duration(milliseconds: 220),
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !visible,
                    // Banner de estado transitorio, no contenido crítico —
                    // se fija la escala de texto en vez de heredar la del
                    // sistema para que siga viéndose como un toast chico
                    // incluso con letra grande de accesibilidad activada
                    // (si no, el texto/ícono podían inflar el banner a un
                    // tamaño enorme, tapando media pantalla).
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: const TextScaler.linear(1.0)),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: updating
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (updating)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                updating
                                    ? 'Actualizando rutas...'
                                    : 'Rutas actualizadas',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
