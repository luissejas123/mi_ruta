import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String category;
  final String title;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final String? deepLinkModule;
  final String? actionLabel;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.deepLinkModule,
    this.actionLabel,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        title,
        content,
        isRead,
        createdAt,
        deepLinkModule,
        actionLabel,
      ];
}
