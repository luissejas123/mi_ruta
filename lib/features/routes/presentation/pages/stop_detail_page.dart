import 'package:mi_ruta/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_stop_info.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_info_card.dart';

class StopDetailPage extends StatelessWidget {
  final RouteStopInfo stopInfo;

  const StopDetailPage({super.key, required this.stopInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Consulta de parada',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RouteInfoCard(
                routeName: stopInfo.stopName,
                destination: 'Destino estimado',
                stopName: stopInfo.stopName,
                routeLines: stopInfo.routeLines,
                distance: stopInfo.distance,
                trafficStatus: stopInfo.trafficStatus,
                status: stopInfo.status,
                eta: stopInfo.estimatedArrival,
                estimatedArrival: stopInfo.estimatedArrival,
              ),
              const SizedBox(height: 24),
              Text(
                'Parada: ${stopInfo.stopName}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Líneas disponibles: ${stopInfo.routeLines.join(', ')}',
                style: TextStyle(fontSize: 13, color: AppColors.of(context).textSecondary),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
