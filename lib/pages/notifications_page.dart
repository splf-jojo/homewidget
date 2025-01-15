// lib/pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final notificationsQuery = FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('timestamp', descending: true);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  late final NotificationDetails platformChannelSpecifics;

  @override
  void initState() {
    super.initState();

    // Инициализация локальных уведомлений
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'notifications_channel_id', // уникальный ID канала
      'Уведомления',             // название канала
      channelDescription: 'Канал для уведомлений приложения',
      importance: Importance.max,
      priority: Priority.high,
    );

    platformChannelSpecifics =
    const NotificationDetails(android: androidPlatformChannelSpecifics);
  }

  void _showLocalNotification(String title, String body) {
    flutterLocalNotificationsPlugin.show(
      0, // ID уведомления
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Уведомлений нет.'));
          }

          // Простейший пример: показываем локальное уведомление для первого уведомления в списке
          final firstData = docs[0].data() as Map<String, dynamic>;
          final title = firstData['title'] ?? 'Без заголовка';
          final body = firstData['body'] ?? '';
          _showLocalNotification(title, body);

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Без заголовка';
              final body = data['body'] ?? '';
              return ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(title),
                subtitle: Text(body),
              );
            },
          );
        },
      ),
    );
  }
}
