// lib/admin/subjects_list.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_editor.dart';

class SubjectsList extends StatelessWidget {
  final CollectionReference subjectsCollection =
  FirebaseFirestore.instance.collection('subjects');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: subjectsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final subjects = snapshot.data!.docs;

          if (subjects.isEmpty) {
            return Center(child: Text('Предметы отсутствуют.'));
          }

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final data = subject.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Без названия'),
                subtitle: Text('ID: ${subject.id}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // Открываем редактор предмета
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectEditor(
                              subjectId: subject.id,
                              existingData: data,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Подтверждение удаления
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Удалить предмет'),
                            content: Text(
                                'Вы уверены, что хотите удалить предмет "${data['name']}"?'),
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
                            await subjectsCollection.doc(subject.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Предмет удалён.')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                  Text('Ошибка при удалении: ${e.toString()}')),
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
          // Открываем редактор для создания нового предмета
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectEditor(),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Добавить предмет',
      ),
    );
  }
}
