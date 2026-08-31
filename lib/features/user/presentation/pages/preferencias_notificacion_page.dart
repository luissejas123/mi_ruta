import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/notification_preferences_cubit.dart';
import 'package:mi_ruta/features/user/presentation/widgets/switch_title.dart';

class PreferenciasNotificacionPage extends StatelessWidget {
  const PreferenciasNotificacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Preferencias de notificación',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocConsumer<NotificationPreferencesCubit, NotificationPreferences>(
        listenWhen: (previous, current) =>
            previous.isHydrated && current != previous,
        listener: (context, prefs) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Preferencias guardadas'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFFFFC12F),
              ),
            );
        },
        builder: (context, prefs) {
          final cubit = context.read<NotificationPreferencesCubit>();
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              SwitchTile(
                title: 'Activar notificaciones',
                icon: Icons.notifications_active_outlined,
                value: prefs.masterEnabled,
                onChanged: cubit.setMasterEnabled,
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CATEGORÍAS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              AbsorbPointer(
                absorbing: !prefs.masterEnabled,
                child: Opacity(
                  opacity: prefs.masterEnabled ? 1 : 0.4,
                  child: Column(
                    children: [
                      SwitchTile(
                        title: 'Notificaciones de viajes',
                        icon: Icons.directions_bus_outlined,
                        value: prefs.tripsEnabled,
                        onChanged: cubit.setTripsEnabled,
                      ),
                      SwitchTile(
                        title: 'Notificaciones de recargas',
                        icon: Icons.account_balance_wallet_outlined,
                        value: prefs.rechargesEnabled,
                        onChanged: cubit.setRechargesEnabled,
                      ),
                      SwitchTile(
                        title: 'Regalos y beneficios',
                        icon: Icons.card_giftcard_outlined,
                        value: prefs.giftsEnabled,
                        onChanged: cubit.setGiftsEnabled,
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Text(
                  'Cuando desactivas una categoría, dejarás de ver sus notificaciones '
                  'en la lista y en el contador de no leídas.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
