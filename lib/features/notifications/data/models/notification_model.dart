import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.category,
    required super.title,
    required super.content,
    required super.isRead,
    required super.createdAt,
    super.deepLinkModule,
    super.actionLabel,
  });

  factory NotificationModel.fromJson(
    String id,
    Map<String, dynamic> json,
  ) {
    final createdAtRaw = json['created_at'];
    DateTime createdAt;

    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return NotificationModel(
      id: id,
      userId: json['user_id'] as String? ?? '',
      category: json['category'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: createdAt,
      deepLinkModule: json['deep_link_module'] as String?,
      actionLabel: json['action_label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category': category,
      'title': title,
      'content': content,
      'is_read': isRead,
      'created_at': Timestamp.fromDate(createdAt),
      'deep_link_module': deepLinkModule,
      'action_label': actionLabel,
    };
  }
}
