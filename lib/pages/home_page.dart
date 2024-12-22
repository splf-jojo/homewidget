// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/schedule.dart'; // Обновите путь согласно вашей структуре
import './profile_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Schedule? schedule;
  bool isLoading = true;
  String errorMessage = '';

  // Карты для соответствий
  Map<String, String> subjectMap = {};
  Map<String, String> teacherMap = {};

  @override
  void initState() {
    super.initState();
    fetchScheduleData();
  }

  Future<void> fetchScheduleData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'Пользователь не аутентифицирован.';
          isLoading = false;
        });
        return;
      }

      String userId = user.uid;

      // Извлекаем роль пользователя
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        setState(() {
          errorMessage = 'Данные пользователя не найдены.';
          isLoading = false;
        });
        return;
      }

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        setState(() {
          errorMessage = 'Данные пользователя пусты.';
          isLoading = false;
        });
        return;
      }

      String role = userData['role'] ?? 'unknown';

      String? groupId;
      String? teacherId;

      if (role == 'student') {
        // Для студента: найти группу, в которой содержится его UID
        QuerySnapshot groupSnapshot = await FirebaseFirestore.instance
            .collection('groups')
            .where('students', arrayContains: userId)
            .get();

        if (groupSnapshot.docs.isEmpty) {
          setState(() {
            errorMessage = 'Группа пользователя не найдена.';
            isLoading = false;
          });
          return;
        }

        // Предполагается, что студент принадлежит только к одной группе
        DocumentSnapshot groupDoc = groupSnapshot.docs.first;
        Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
        groupId = groupDoc.id;
      } else if (role == 'teacher') {
        // Для учителя: использовать его UID как teacherId
        teacherId = userId;
      } else if (role == 'admin') {
        // Для администратора: нет необходимости в groupId или teacherId
      } else {
        setState(() {
          errorMessage = 'Неизвестная роль пользователя.';
          isLoading = false;
          isLoading = false;
        });
        return;
      }

      // Загрузка предметов
      QuerySnapshot subjectsSnapshot =
      await FirebaseFirestore.instance.collection('subjects').get();

      for (var doc in subjectsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final subjectId = doc.id;
        final subjectName = data['name'] as String? ?? 'Без названия';
        subjectMap[subjectId] = subjectName;
      }

      // Загрузка учителей
      QuerySnapshot teachersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();

      for (var doc in teachersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final teacherId = doc.id;
        final teacherName = data['full_name'] as String? ?? 'Без имени';
        teacherMap[teacherId] = teacherName;
      }

      // Загрузка расписания
      QuerySnapshot schedulesSnapshot;

      if (role == 'student') {
        schedulesSnapshot = await FirebaseFirestore.instance
            .collection('schedules')
            .where('group_id', isEqualTo: groupId)
            .get();
      } else if (role == 'teacher') {
        // Firestore не поддерживает вложенные запросы, поэтому нужно загрузить все расписания и фильтровать на клиенте
        schedulesSnapshot =
        await FirebaseFirestore.instance.collection('schedules').get();
      } else if (role == 'admin') {
        schedulesSnapshot =
        await FirebaseFirestore.instance.collection('schedules').get();
      } else {
        schedulesSnapshot =
        await FirebaseFirestore.instance.collection('schedules').get();
      }

      if (schedulesSnapshot.docs.isEmpty) {
        setState(() {
          errorMessage = 'Расписание не найдено.';
          isLoading = false;
        });
        return;
      }

      List<Schedule> fetchedSchedules = [];

      for (var doc in schedulesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        Schedule scheduleData = Schedule.fromMap(doc.id, data);

        if (role == 'student') {
          fetchedSchedules.add(scheduleData);
        } else if (role == 'teacher') {
          // Проверяем, есть ли уроки с teacher_id == current teacherId
          bool hasTeacher = scheduleData.scheduleDays.any((day) =>
              day.lessons.any((lesson) => lesson.teacherId == teacherId));
          if (hasTeacher) {
            fetchedSchedules.add(scheduleData);
          }
        } else if (role == 'admin') {
          fetchedSchedules.add(scheduleData);
        }
      }

      if (fetchedSchedules.isEmpty) {
        setState(() {
          errorMessage = 'Расписание не найдено для вашей роли.';
          isLoading = false;
        });
        return;
      }

      // Для упрощения, используем первое расписание
      // Можно адаптировать для нескольких расписаний, если требуется
      Schedule fetchedSchedule = fetchedSchedules.first;

      setState(() {
        schedule = fetchedSchedule;
        isLoading = false;
      });

      await updateHomeWidgetSchedule();
    } catch (e) {
      print("Error fetching schedule data: $e");
      if (!mounted) return;

      setState(() {
        errorMessage = 'Ошибка при загрузке данных: $e';
        isLoading = false;
      });
    }
  }

  Future<void> updateHomeWidgetSchedule() async {
    if (schedule == null) return;

    // Формируем строку расписания для Home Widget
    // Например, только уроки на текущий день
    DateTime now = DateTime.now();
    String today = DateFormat('EEEE', 'ru_RU').format(now); // Получаем день недели на русском

    // Firestore может хранить дни недели на русском, поэтому сравниваем в нижнем регистре
    ScheduleDay? todaySchedule = schedule!.scheduleDays.firstWhere(
            (day) => day.dayOfWeek.toLowerCase() ==
            today.toLowerCase(), // Сравнение на основе перевода дня недели
        orElse: () => ScheduleDay(dayOfWeek: today, lessons: []));

    final lessonStrings = todaySchedule.lessons.map((lesson) {
      String subjectName = subjectMap[lesson.subjectId] ?? 'Без названия';
      String teacherName = teacherMap[lesson.teacherId] ?? 'Неизвестный учитель';
      return "${lesson.startTime}-${lesson.endTime} $subjectName($teacherName) ${lesson.room}";

      // return "${lesson.startTime}-${lesson.endTime} $subjectName ($teacherName)  аудитории ${lesson.room}в";
    }).join(";\n");

    await HomeWidget.saveWidgetData<String>('widgetText', lessonStrings);
    await HomeWidget.updateWidget(
      name: 'AppWidgetProvider',
      iOSName: 'HomeWidgetExtension',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (schedule == null) {
      return Center(child: Text('Расписание недоступно.'));
    }

    // Определяем текущий день недели
    DateTime now = DateTime.now();
    String today = DateFormat('EEEE', 'ru_RU').format(now); // Получаем день недели на русском

    ScheduleDay? todaySchedule = schedule!.scheduleDays.firstWhere(
            (day) => day.dayOfWeek.toLowerCase() ==
            today.toLowerCase(), // Сравнение на основе перевода дня недели
        orElse: () => ScheduleDay(dayOfWeek: today, lessons: []));

    if (todaySchedule.lessons.isEmpty) {
      return Center(child: Text('Сегодня нет уроков.'));
    }

    // Определяем текущий урок
    int currentLessonIndex = todaySchedule.lessons.indexWhere((lesson) {
      final nowTime = TimeOfDay.fromDateTime(now);
      final lessonStart = _parseTimeOfDay(lesson.startTime);
      final lessonEnd = _parseTimeOfDay(lesson.endTime);

      if (lessonStart == null || lessonEnd == null) return false;

      final nowMinutes = nowTime.hour * 60 + nowTime.minute;
      final startMinutes = lessonStart.hour * 60 + lessonStart.minute;
      final endMinutes = lessonEnd.hour * 60 + lessonEnd.minute;

      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    });

    return ListView.builder(
      itemCount: todaySchedule.lessons.length,
      itemBuilder: (context, index) {
        final lesson = todaySchedule.lessons[index];
        final isCurrent = index == currentLessonIndex;

        String subjectName = subjectMap[lesson.subjectId] ?? 'Без названия';
        String teacherName = teacherMap[lesson.teacherId] ?? 'Неизвестный учитель';

        return Card(
          margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          color: isCurrent
              ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
              : Theme.of(context).cardColor,
          child: ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        "${lesson.startTime}-${lesson.endTime}",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Text(
                    "Аудитория: ${lesson.room}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            initiallyExpanded: isCurrent,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Учитель: $teacherName',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Детали: ${lesson.details}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print("Error parsing time: $e");
      return null;
    }
  }
}
