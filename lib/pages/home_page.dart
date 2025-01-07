// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Модели
import 'package:home/models/schedule.dart';
import 'package:home/models/subject.dart';

// Сервисы
import 'package:home/services/schedule_service.dart';
import 'package:home/services/home_widget_service.dart';
import 'package:home/services/homework_service.dart';

// Виджеты
import 'package:home/widgets/day_selector.dart';
import 'package:home/widgets/lesson_list.dart';

class HomePage extends StatefulWidget {
  final String groupId;

  const HomePage({Key? key, required this.groupId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Schedule? schedule;
  bool isLoading = true;
  String errorMessage = '';

  /// Выбранная дата
  DateTime? selectedDate;

  // Словари с предметами и учителями
  Map<String, Subject> subjectsMap = {};
  Map<String, Map<String, dynamic>> teachersMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Загружаем расписание, предметы, учителей
  Future<void> _loadData() async {
    try {
      if (widget.groupId == '-1') {
        setState(() {
          errorMessage = 'У вас нет привязки к определённой группе.';
          isLoading = false;
        });
        return;
      }
      // 1. Получаем расписание
      final fetchedSchedule = await ScheduleService.fetchSchedule(widget.groupId);
      if (fetchedSchedule == null) {
        setState(() {
          errorMessage = 'Расписание для этой группы не найдено.';
          isLoading = false;
        });
        return;
      }

      // 2. Предметы
      final fetchedSubjects = await ScheduleService.fetchSubjects();

      // 3. Учителя
      final fetchedTeachers = await ScheduleService.fetchTeachers();

      // Сортируем дни по возрастанию даты
      fetchedSchedule.scheduleDays.sort((a, b) => a.date.compareTo(b.date));

      // Ищем «сегодня» или ближайший день
      final today = DateTime.now();
      final todayDay = fetchedSchedule.scheduleDays.firstWhere(
            (day) =>
        day.date.year == today.year &&
            day.date.month == today.month &&
            day.date.day == today.day,
        orElse: () {
          if (fetchedSchedule.scheduleDays.isNotEmpty) {
            // Возвращаем первый день из списка, если сегодня нет в расписании
            return fetchedSchedule.scheduleDays[0];
          } else {
            // Если расписание пустое, создаём дефолтный день с сегодняшней датой и пустыми уроками
            return ScheduleDay(date: today, lessons: []);
          }
        },
      );

      setState(() {
        schedule = fetchedSchedule;
        subjectsMap = fetchedSubjects;
        teachersMap = fetchedTeachers;
        selectedDate = todayDay.date;
        isLoading = false;
      });

      // Обновляем домашний виджет (например, для «сегодня»)
      if (todayDay.lessons.isNotEmpty) {
        await HomeWidgetService.updateHomeWidgetSchedule(
          todayDay.lessons,
          fetchedSubjects,
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка при загрузке данных: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(errorMessage)),
      );
    }
    if (schedule == null) {
      return const Scaffold(
        body: Center(child: Text('Нет данных для отображения.')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Горизонтальный список дат
          DaySelector(
            scheduleDays: schedule!.scheduleDays,
            selectedDate: selectedDate,
            onDateSelected: (date) {
              setState(() => selectedDate = date);
            },
          ),
          const Divider(),
          // Список уроков
          Expanded(
            child: _buildLessonsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList() {
    if (selectedDate == null) {
      return const Center(child: Text('Дата не выбрана'));
    }

    // Ищем расписание для выбранной даты
    final day = schedule!.scheduleDays.firstWhere(
          (d) =>
      d.date.year == selectedDate!.year &&
          d.date.month == selectedDate!.month &&
          d.date.day == selectedDate!.day,
      orElse: () => ScheduleDay(date: selectedDate!, lessons: []),
    );

    // Передаём groupId, чтобы внутри LessonList загрузить домашку
    return LessonList(
      scheduleDay: day,
      subjectsMap: subjectsMap,
      teachersMap: teachersMap,
      groupId: widget.groupId,
    );
  }
}
