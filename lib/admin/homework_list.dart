// lib/admin/homework_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Модель
import 'package:home/models/homework.dart';

// Экран редактора
import 'homework_editor.dart';

class HomeworkList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('homeworks')
          .orderBy('date', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Домашних заданий нет.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final hw = Homework.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            final dateStr = DateFormat('dd MMM yyyy', 'ru').format(hw.date);
            return ListTile(
              title: Text(hw.assignment.isNotEmpty
                  ? hw.assignment.split('\n').first
                  : 'Без описания'),
              subtitle: Text("Группа: ${hw.groupId} | Предмет: ${hw.subjectId}\nДата: $dateStr"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeworkEditor(homeworkId: hw.id)),
                );
              },
            );
          },
        );
      },
    );
  }
}
