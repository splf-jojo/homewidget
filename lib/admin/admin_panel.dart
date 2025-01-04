// lib/admin/admin_panel.dart

import 'package:flutter/material.dart';
import 'schedule_list.dart';
import 'user_list.dart';
import 'group_list.dart';
import 'schedule_editor.dart';
import 'user_creation_page.dart';
import 'group_creation_page.dart';
import 'subjects_list.dart';
import 'subject_editor.dart';

// Новые экраны для домашек
import 'homework_list.dart';       // список домашних заданий
import 'homework_editor.dart';     // редактор (добавление/редактирование)

class AdminPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Было 4, теперь 5
      child: Scaffold(
        appBar: TabBar(
          tabs: [
            Tab(text: 'Расписания'),
            Tab(text: 'Пользователи'),
            Tab(text: 'Группы'),
            Tab(text: 'Предметы'),
            Tab(text: 'Домашки'), // Новая вкладка
          ],
        ),
        body: TabBarView(
          children: [
            ScheduleList(),
            UserList(),
            GroupList(),
            SubjectsList(),
            HomeworkList(), // Экран со списком домашних заданий
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
                  case 4: // Домашки
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeworkEditor()),
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
