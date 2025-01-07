// lib/pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationsQuery = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true);

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
