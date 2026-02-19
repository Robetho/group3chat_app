import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_service.dart';

class NotificationListenerWidget extends StatefulWidget {
  final Widget child;

  const NotificationListenerWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<NotificationListenerWidget> createState() =>
      _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState extends State<NotificationListenerWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationListener();
    });
  }

  void _setupNotificationListener() {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );

    notificationService.onNotification.listen((data) {
      try {
        _handleNotification(data);
      } catch (e, stack) {
        debugPrint("❌ Error handling notification: $e\n$stack");
      }
    });
  }

  void _handleNotification(Map<String, dynamic> data) {
    final type = data['type'] ?? 'unknown';
    debugPrint('📱 Notification handled: $type');

    switch (type) {
      case 'notification_clicked':
        _handleNotificationClick(data);
        break;
      case 'foreground_message':
        _showInAppNotification(data);
        break;
      case 'app_opened_from_background':
        _handleBackgroundNotification(data);
        break;
      case 'app_opened_from_terminated':
        _handleTerminatedNotification(data);
        break;
      default:
        debugPrint("⚠️ Unknown notification type: $type");
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    final payload = data['payload'];
    final messageId = _safeExtract(data, 'messageId');
    final senderId = _safeExtract(data, 'senderId');

    debugPrint('📱 User clicked notification with payload: $payload');

    if (messageId != null) {
      _navigateToChat(messageId, senderId);
    }
  }

  void _showInAppNotification(Map<String, dynamic> data) {
    final title = data['title'] ?? 'New Message';
    final body = data['body'] ?? '';

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $body'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleBackgroundNotification(Map<String, dynamic> data) {
    final messageId = _safeExtract(data, 'messageId');
    final senderId = _safeExtract(data, 'senderId');

    debugPrint('📱 App opened from background with data: ${data['data']}');

    if (messageId != null) {
      _navigateToChat(messageId, senderId);
    }
  }

  void _handleTerminatedNotification(Map<String, dynamic> data) {
    final messageId = _safeExtract(data, 'messageId');
    final senderId = _safeExtract(data, 'senderId');

    debugPrint('📱 App opened from terminated state with data: ${data['data']}');

    if (messageId != null) {
      _navigateToChat(messageId, senderId);
    }
  }

  /// Helper to safely extract nested values
  dynamic _safeExtract(Map<String, dynamic> data, String key) {
    final inner = data['data'];
    if (inner is Map<String, dynamic>) {
      return inner[key];
    }
    return null;
  }

  void _navigateToChat(String messageId, String? senderId) {
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'messageId': messageId,
        'senderId': senderId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
