import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/entities/app_notification.dart';
import 'package:mi_ruta/features/user/domain/services/notification_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/notification_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/notification_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/notification_state.dart';

class NotificacionesPage extends StatelessWidget {
  const NotificacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        final userId = authState is AuthLoaded ? authState.user.uid : '';
        return NotificationBloc(service: getIt<NotificationService>())
          ..add(LoadNotifications(userId));
      },
      child: const _NotificacionesView(),
    );
  }
}

class _NotificacionesView extends StatefulWidget {
  const _NotificacionesView();
  @override
  State<_NotificacionesView> createState() => _NotificacionesViewState();
}

class _NotificacionesViewState extends State<_NotificacionesView> {
  // null = category picker, 'trip'/'recharge'/'gift' = filtered list
  String? _activeCategory;

  String get _userId {
    final s = context.read<AuthBloc>().state;
    return s is AuthLoaded ? s.user.uid : '';
  }

  void _markAllRead() {
    context.read<NotificationBloc>().add(MarkAllNotificationsRead(_userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _activeCategory != null
              ? () => setState(() => _activeCategory = null)
              : () => Navigator.pop(context),
        ),
        title: Text(
          _activeCategory == null
              ? 'Notificaciones'
              : _activeCategory == 'trip'
                  ? 'Viajes'
                  : _activeCategory == 'recharge'
                      ? 'Recargas'
                      : 'Regalos',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          if (_activeCategory != null)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Marcar leídas',
                style: TextStyle(color: Color(0xFFFFC12F), fontSize: 12),
              ),
            ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }
          if (state is NotificationError) {
            return Center(child: Text(state.message));
          }
          if (state is NotificationLoaded) {
            if (_activeCategory == null) {
              return _CategoryPicker(
                tripCount: state.trips.length,
                rechargeCount: state.recharges.length,
                giftCount: state.gifts.length,
                tripUnread: state.trips.where((n) => !n.isRead).length,
                rechargeUnread: state.recharges.where((n) => !n.isRead).length,
                giftUnread: state.gifts.where((n) => !n.isRead).length,
                onTap: (cat) => setState(() => _activeCategory = cat),
              );
            }
            final items = _activeCategory == 'trip'
                ? state.trips
                : _activeCategory == 'recharge'
                    ? state.recharges
                    : state.gifts;
            return _NotificationList(
              items: items,
              userId: _userId,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final int tripCount, rechargeCount, giftCount;
  final int tripUnread, rechargeUnread, giftUnread;
  final void Function(String) onTap;

  const _CategoryPicker({
    required this.tripCount,
    required this.rechargeCount,
    required this.giftCount,
    required this.tripUnread,
    required this.rechargeUnread,
    required this.giftUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryCard(
            icon: Icons.directions_bus_outlined,
            label: 'Notificaciones de viajes',
            count: tripCount,
            unread: tripUnread,
            onTap: () => onTap('trip'),
          ),
          const SizedBox(height: 16),
          _CategoryCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Notificaciones de recargas',
            count: rechargeCount,
            unread: rechargeUnread,
            onTap: () => onTap('recharge'),
          ),
          const SizedBox(height: 16),
          _CategoryCard(
            icon: Icons.card_giftcard_outlined,
            label: 'Regalos obtenidos',
            count: giftCount,
            unread: giftUnread,
            onTap: () => onTap('gift'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final int unread;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFC12F),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Text(
                '$count',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
          ],
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<AppNotification> items;
  final String userId;

  const _NotificationList({required this.items, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin notificaciones',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (context, i) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _NotifTile(
        notif: items[i],
        userId: userId,
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final String userId;

  const _NotifTile({required this.notif, required this.userId});

  IconData get _icon {
    switch (notif.type) {
      case NotificationType.trip:
        return Icons.directions_bus_outlined;
      case NotificationType.recharge:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.gift:
        return Icons.card_giftcard_outlined;
    }
  }

  void _onTap(BuildContext context) {
    if (!notif.isRead) {
      context.read<NotificationBloc>().add(
            MarkNotificationRead(userId, notif.id),
          );
    }
    if (notif.type == NotificationType.gift) {
      _showGiftDetail(context);
    }
  }

  void _showGiftDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<NotificationBloc>(),
        child: _GiftDetail(notif: notif, userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnread = !notif.isRead;
    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? const Color(0xFFFFC12F).withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: isUnread
              ? Border.all(color: const Color(0xFFFFC12F).withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC12F),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFC12F),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(notif.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            if (notif.type == NotificationType.gift)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    const months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _GiftDetail extends StatelessWidget {
  final AppNotification notif;
  final String userId;

  const _GiftDetail({required this.notif, required this.userId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUsed = notif.isUsed ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('🎁', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            '¡Felicidades!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recibiste un ${notif.discountPercent}% de descuento\nen ${notif.businessName}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (notif.validUntil != null) ...[
            const SizedBox(height: 8),
            Text(
              'Válido hasta ${_fmt(notif.validUntil!)}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isUsed
                  ? null
                  : () {
                      context.read<NotificationBloc>().add(
                            MarkGiftUsed(userId, notif.id),
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Descuento aplicado! Muestra esta pantalla en el negocio.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC12F),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isUsed ? 'Ya utilizado' : 'Usar descuento',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${months[d.month - 1]}. ${d.year}';
  }
}
