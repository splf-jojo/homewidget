import 'package:flutter/material.dart';
import 'schedule_list.dart';
import 'user_editor.dart';
import 'group_list.dart';
import 'schedule_editor.dart';
import 'user_list.dart';
import 'group_creation_page.dart';
import 'subjects_list.dart';
import 'subject_editor.dart';
import 'homework_list.dart';
import 'homework_editor.dart';
import 'post_list.dart';     // Убедитесь, что имя файла соответствует фактическому
import 'post_editor.dart';
// Новые экраны для постов
import 'post_list.dart';
import 'post_editor.dart';

class AdminPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6, // Увеличили количество вкладок до 6
      child: Scaffold(
        appBar: TabBar(
          tabs: [
            Tab(text: 'Расписания'),
            Tab(text: 'Пользователи'),
            Tab(text: 'Группы'),
            Tab(text: 'Предметы'),
            Tab(text: 'Домашки'),
            Tab(text: 'Посты'), // Новая вкладка для постов
          ],
        ),
        body: TabBarView(
          children: [
            ScheduleList(),
            UserList(),
            GroupList(),
            SubjectsList(),
            HomeworkList(),
            PostList(), // Страница списка постов
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              heroTag: "adminFab",  // Уникальный тег для этого FAB
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
                      MaterialPageRoute(builder: (context) => UserEditor()),
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
                  case 4:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeworkEditor()),
                    );
                    break;
                  case 5: // Обработка вкладки «Посты»
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PostEditor()),
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
