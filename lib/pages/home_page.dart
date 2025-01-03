// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home/models/schedule.dart';
import 'package:home/models/subject.dart';
import 'package:home_widget/home_widget.dart';

class HomePage extends StatefulWidget {
  final String groupId; // Переданный groupId

  HomePage({required this.groupId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Schedule? schedule;
  bool isLoading = true;
  String errorMessage = '';
  String selectedDay = 'Понедельник'; // По умолчанию первый день

  // Карты для соответствий
  Map<String, Subject> subjectsMap = {};
  Map<String, Map<String, dynamic>> teachersMap = {}; // teacherId -> teacherData

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  /// Вспомогательная функция для получения текущего дня недели на русском языке
  String getCurrentDayOfWeek() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'Понедельник';
      case DateTime.tuesday:
        return 'Вторник';
      case DateTime.wednesday:
        return 'Среда';
      case DateTime.thursday:
        return 'Четверг';
      case DateTime.friday:
        return 'Пятница';
      case DateTime.saturday:
        return 'Суббота';
      case DateTime.sunday:
        return 'Воскресенье';
      default:
        return '';
    }
  }

  /// Метод для загрузки данных расписания, предметов и учителей
  Future<void> fetchData() async {
    try {
      if (widget.groupId != '-1') {
        // 1. Загрузка расписания для данной группы
        QuerySnapshot scheduleSnapshot = await FirebaseFirestore.instance
            .collection('schedules')
            .where('group_id', isEqualTo: widget.groupId)
            .get();

        if (scheduleSnapshot.docs.isEmpty) {
          setState(() {
            errorMessage = 'Расписание для этой группы не найдено.';
            isLoading = false;
          });
          return;
        }

        DocumentSnapshot scheduleDoc = scheduleSnapshot.docs.first;
        Schedule fetchedSchedule =
        Schedule.fromMap(scheduleDoc.id, scheduleDoc.data() as Map<String, dynamic>);

        // 2. Загрузка всех предметов
        QuerySnapshot subjectsSnapshot =
        await FirebaseFirestore.instance.collection('subjects').get();
        for (var doc in subjectsSnapshot.docs) {
          Subject subject = Subject.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          subjectsMap[subject.id] = subject;
        }

        // 3. Загрузка всех учителей
        QuerySnapshot teachersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .get();
        for (var doc in teachersSnapshot.docs) {
          teachersMap[doc.id] = doc.data() as Map<String, dynamic>;
        }

        setState(() {
          schedule = fetchedSchedule;
          isLoading = false;
        });

        // Получаем название текущего дня недели
        String currentDay = getCurrentDayOfWeek();

        // Находим уроки для текущего дня
        ScheduleDay? currentScheduleDay = schedule!.scheduleDays.firstWhere(
              (day) => day.dayOfWeek == currentDay,
          orElse: () => ScheduleDay(dayOfWeek: currentDay, lessons: []),
        );

        // Обновляем домашний виджет только если есть уроки на текущий день
        if (currentScheduleDay.lessons.isNotEmpty) {
          updateHomeWidgetSchedule(currentScheduleDay.lessons);
        }
      } else {
        setState(() {
          schedule = null;
          isLoading = false;
          errorMessage = 'У вас нет привязки к определенной группе.';
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        errorMessage = 'Ошибка при загрузке данных: $e';
        isLoading = false;
      });
    }
  }

  /// Функция для обновления домашнего виджета с расписанием
  Future<void> updateHomeWidgetSchedule(List<LessonEntry> lessons) async {
    // Формируем строку из данных о расписании
    final lessonStrings = lessons.map((lesson) {
      return "${lesson.startTime}-${lesson.endTime} "
          "${subjectsMap[lesson.subjectId]?.name ?? 'Без названия'} "
          "${lesson.room}";
    }).join(";");

    try {
      await HomeWidget.saveWidgetData<String>('widgetText', lessonStrings);
      await HomeWidget.updateWidget(
        name: 'AppWidgetProvider', // Android
        iOSName: 'HomeWidgetExtension', // iOS
      );
      print("Home widget updated successfully.");
    } catch (e) {
      print("Failed to update home widget: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : widget.groupId != '-1'
          ? Column(
        children: [
          // Выбор дня недели
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: schedule!.scheduleDays.length,
              itemBuilder: (context, index) {
                String day = schedule!.scheduleDays[index].dayOfWeek;
                bool isSelected = day == selectedDay;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDay = day;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                          decoration: isSelected
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor:
                          Theme.of(context).colorScheme.primary,
                          decorationThickness: 2,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(),
          // Список уроков
          Expanded(
            child: _buildLessonsList(),
          ),
        ],
      )
          : Center(
        child: Text(
          'У вас нет привязки к определенной группе.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// Метод для построения списка уроков
  Widget _buildLessonsList() {
    if (schedule == null) {
      return Center(child: Text('Нет данных для отображения.'));
    }

    // Найти уроки для выбранного дня
    ScheduleDay? selectedScheduleDay = schedule!.scheduleDays.firstWhere(
          (day) => day.dayOfWeek == selectedDay,
      orElse: () => ScheduleDay(dayOfWeek: selectedDay, lessons: []),
    );

    if (selectedScheduleDay.lessons.isEmpty) {
      return Center(child: Text('На этот день уроков нет.'));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      itemCount: selectedScheduleDay.lessons.length,
      itemBuilder: (context, index) {
        LessonEntry lesson = selectedScheduleDay.lessons[index];
        String subjectName = subjectsMap[lesson.subjectId]?.name ?? 'Без названия';
        String teacherName = teachersMap[lesson.teacherId]?['full_name'] ?? 'Неизвестный учитель';

        // Цвет карточки в зависимости от темы
        Color baseColor = theme.cardColor;
        HSLColor hslColor = HSLColor.fromColor(baseColor);
        // Немного меняем светлоту для светлой/тёмной темы
        final cardColor = isDark
            ? hslColor.withLightness((hslColor.lightness + 0.05).clamp(0.0, 1.0)).toColor()
            : theme.colorScheme.secondary.withOpacity(0.05);

        return Card(
          color: cardColor,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0, // Убираем тень
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Левая часть карточки
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        lesson.details,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                // Правая часть карточки
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        lesson.room,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${lesson.startTime} - ${lesson.endTime}",
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        " $teacherName",
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
