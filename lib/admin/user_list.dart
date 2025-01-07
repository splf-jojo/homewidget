import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_editor.dart';

class UserList extends StatelessWidget {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: usersCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return Center(child: Text('Пользователи отсутствуют.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final data = userDoc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['full_name'] ?? 'Без имени'),
                subtitle: Text('${data['email']} (${data['role']})'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // Открываем редактор пользователя
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserEditor(
                              userId: userDoc.id,
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
                            title: Text('Удалить пользователя'),
                            content: Text(
                                'Вы уверены, что хотите удалить пользователя "${data['full_name']}"?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text('Удалить'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await usersCollection.doc(userDoc.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Пользователь удалён.')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Ошибка при удалении: ${e.toString()}')),
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
          // Открываем редактор для создания нового пользователя
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserEditor(),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Добавить пользователя',
      ),
    );
  }
}
