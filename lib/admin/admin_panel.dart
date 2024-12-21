// lib/admin/admin_panel.dart

import 'package:flutter/material.dart';
import 'schedule_list.dart';
import 'user_list.dart';
import 'group_list.dart';
import 'schedule_editor.dart';
import 'user_creation_page.dart';
import 'group_creation_page.dart';
import 'subjects_list.dart'; // Добавляем импорт SubjectsList
import 'subject_editor.dart'; // Добавляем импорт SubjectEditor (если используется напрямую)

class AdminPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Увеличиваем количество вкладок до 4
      child: Scaffold(
        appBar: AppBar(
          title: Text('Админ Панель'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Расписания'),
              Tab(text: 'Пользователи'),
              Tab(text: 'Группы'),
              Tab(text: 'Предметы'), // Новая вкладка для предметов
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ScheduleList(),
            UserList(),
            GroupList(),
            SubjectsList(), // Добавляем SubjectsList в TabBarView
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                final TabController tabController =
                DefaultTabController.of(context)!;
                switch (tabController.index) {
                  case 0:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ScheduleEditor()),
                    );
                    break;
                  case 1:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserCreationPage()),
                    );
                    break;
                  case 2:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GroupCreationPage()),
                    );
                    break;
                  case 3:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SubjectEditor()),
                    );
                    break;
                }
              },
              child: Icon(Icons.add),
              tooltip: 'Добавить',
            );
          },
        ),
      ),
    );
  }
}
