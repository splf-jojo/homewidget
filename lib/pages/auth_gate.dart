import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home/pages/login_page.dart';
import 'package:home/pages/main_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Пока состояние аутентификации загружается
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Если пользователь не аутентифицирован
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // Пользователь аутентифицирован, получаем его данные
        final User user = snapshot.data!;

        // Получаем данные пользователя из коллекции 'users'
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(child: Text('Данные пользователя не найдены.')),
              );
            }

            // Получаем роль пользователя
            final role = userSnapshot.data!['role'] ?? 'student';

            // Устанавливаем groupId в зависимости от роли
            if (role == 'teacher' || role == 'admin') {
              const groupId = '-1';
              return MainPage(groupId: groupId, role: role);
            } else {
              // Если пользователь студент, получаем его groupId
              return FutureBuilder<String?>(
                future: _getGroupIdForStudent(user.uid),
                builder: (context, groupSnapshot) {
                  if (groupSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!groupSnapshot.hasData || groupSnapshot.data == null) {
                    return const Scaffold(
                      body: Center(child: Text('Группа не найдена.')),
                    );
                  }
                  final groupId = groupSnapshot.data!;
                  return MainPage(groupId: groupId, role: role);
                },
              );
            }
          },
        );
      },
    );
  }

  /// Получаем groupId для студента
  Future<String?> _getGroupIdForStudent(String uid) async {
    final groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('students', arrayContains: uid)
        .get();

    if (groupSnapshot.docs.isNotEmpty) {
      return groupSnapshot.docs.first.id;
    }
    return null;
  }
}
