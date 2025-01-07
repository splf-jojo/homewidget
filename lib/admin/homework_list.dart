import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'homework_editor.dart';
import 'package:home/models/homework.dart';

class HomeworkList extends StatelessWidget {
  final CollectionReference homeworksCollection =
  FirebaseFirestore.instance.collection('homeworks');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: homeworksCollection.orderBy('date', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text('Домашних заданий нет.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final hw = Homework.fromMap(doc.id, doc.data() as Map<String, dynamic>);
              final dateStr = DateFormat('dd MMM yyyy', 'ru').format(hw.date);

              return ListTile(
                title: Text(
                  hw.assignment.isNotEmpty
                      ? hw.assignment.split('\n').first
                      : 'Без описания',
                ),
                subtitle: Text("Группа: ${hw.groupId} | Предмет: ${hw.subjectId}\nДата: $dateStr"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeworkEditor(homeworkId: hw.id),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Удалить домашнее задание'),
                            content: Text('Вы уверены, что хотите удалить это домашнее задание?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text('Удалить'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await homeworksCollection.doc(hw.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Домашнее задание удалено.')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ошибка при удалении: ${e.toString()}')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Открываем редактор для создания нового домашнего задания
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomeworkEditor()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Добавить домашнее задание',
      ),
    );
  }
}
