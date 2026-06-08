import 'package:flutter/material.dart';
import 'package:mi_ruta/features/notifications/domain/entities/notification_entity.dart';

class NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback? onActionTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
    this.onActionTap,
  });

  Color _categoryColor(String category) {
    switch (category) {
      case 'wallet':
        return Colors.green.shade700;
      case 'gift':
        return Colors.pink.shade700;
      case 'driver':
        return Colors.orange.shade700;
      case 'ia_prediction':
        return Colors.indigo.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'gift':
        return Icons.card_giftcard;
      case 'driver':
        return Icons.directions_bus;
      case 'ia_prediction':
        return Icons.support_agent;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _categoryColor(notification.category),
                      child: Icon(
                        _categoryIcon(notification.category),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: notification.isRead
                                  ? Colors.black87
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _categoryColor(notification.category).withOpacity(0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: notification.isRead ? Colors.transparent : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.content,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    if (notification.actionLabel != null)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _categoryColor(notification.category),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onActionTap,
                        child: Text(
                          notification.actionLabel!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
