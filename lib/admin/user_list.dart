// lib/user_list.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Если у вас есть страница для редактирования пользователей, импортируйте её здесь

class UserList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(), // Все пользователи в коллекции 'users'
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;

            return ListTile(
              title: Text(data['full_name'] ?? 'Без имени'),
              subtitle: Text('${data['email']} (${data['role']})'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  // Реализуйте редактирование пользователя, например, открытие UserEditPage
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => UserEditPage(userId: user.id)));
                },
              ),
            );
          },
        );
      },
    );
  }
}
