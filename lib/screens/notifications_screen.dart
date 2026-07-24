import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';

  NotificationsScreen({super.key});

  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benachrichtigungen'),
        actions: [
          if (user != null)
            IconButton(
              tooltip: 'Alle als gelesen markieren',
              onPressed: () async {
                await _notificationService.markAllAsRead(user.uid);

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Alle Benachrichtigungen wurden als gelesen markiert.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.done_all),
            ),
        ],
      ),
      body:
          user == null
              ? const Center(child: Text('Du bist nicht angemeldet.'))
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _notificationService.getNotifications(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Die Benachrichtigungen konnten nicht geladen werden.',
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notifications = snapshot.data?.docs ?? [];

                  if (notifications.isEmpty) {
                    return const _EmptyNotificationsView();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final data = notification.data();

                      return _NotificationCard(
                        notificationId: notification.id,
                        userId: user.uid,
                        data: data,
                        notificationService: _notificationService,
                      );
                    },
                  );
                },
              ),
    );
  }
}

class _EmptyNotificationsView extends StatelessWidget {
  const _EmptyNotificationsView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Noch keine Benachrichtigungen',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Sobald jemand mit deinem Beitrag interagiert, erscheint hier eine Benachrichtigung.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notificationId,
    required this.userId,
    required this.data,
    required this.notificationService,
  });

  final String notificationId;
  final String userId;
  final Map<String, dynamic> data;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    final senderName = data['senderName'] as String? ?? 'Jemand';
    final senderPhotoUrl = data['senderPhotoUrl'] as String?;
    final message =
        data['message'] as String? ?? '$senderName hat mit dir interagiert.';
    final isRead = data['isRead'] as bool? ?? false;
    final type = data['type'] as String? ?? '';

    final timestamp = data['createdAt'] as Timestamp?;
    final createdAt = timestamp?.toDate();

    return Card(
      elevation: isRead ? 0 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (!isRead) {
            await notificationService.markAsRead(
              userId: userId,
              notificationId: notificationId,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    senderPhotoUrl != null && senderPhotoUrl.isNotEmpty
                        ? NetworkImage(senderPhotoUrl)
                        : null,
                child:
                    senderPhotoUrl == null || senderPhotoUrl.isEmpty
                        ? Text(
                          senderName.isNotEmpty
                              ? senderName[0].toUpperCase()
                              : '?',
                        )
                        : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(_iconForType(type), size: 22),
              if (!isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'gerade eben';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'gerade eben';
    }

    if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Min.';
    }

    if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Std.';
    }

    if (difference.inDays == 1) {
      return 'gestern';
    }

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}
