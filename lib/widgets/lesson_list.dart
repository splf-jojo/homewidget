// lib/widgets/lesson_list.dart
import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../models/subject.dart';
import '../services/homework_service.dart';
import '../models/homework.dart';

class LessonList extends StatelessWidget {
  final ScheduleDay scheduleDay;
  final Map<String, Subject> subjectsMap;
  final Map<String, Map<String, dynamic>> teachersMap;
  final String groupId;

  const LessonList({
    Key? key,
    required this.scheduleDay,
    required this.subjectsMap,
    required this.teachersMap,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (scheduleDay.lessons.isEmpty) {
      return const Center(child: Text('На этот день уроков нет.'));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      itemCount: scheduleDay.lessons.length,
      itemBuilder: (context, index) {
        final lesson = scheduleDay.lessons[index];
        final subjectName = subjectsMap[lesson.subjectId]?.name ?? 'Без названия';
        final teacherName =
            teachersMap[lesson.teacherId]?['full_name'] ?? 'Неизвестный учитель';

        // Лёгкое изменение цвета карточки под тему
        final baseColor = theme.cardColor;
        final cardColor = isDark
            ? baseColor.withOpacity(0.9)
            : theme.colorScheme.secondary.withOpacity(0.5);

        return GestureDetector(
          onTap: () => _showHomeworkDialog(context, lesson.subjectId),
          child: Card(
            color: cardColor,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Левая часть
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
                      ],
                    ),
                  ),
                  // Правая часть
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
                        const SizedBox(height: 4),
                        Text(
                          "${lesson.startTime} - ${lesson.endTime}",
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          teacherName,
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
          ),
        );
      },
    );
  }

  /// При нажатии на урок — показываем домашку
  Future<void> _showHomeworkDialog(BuildContext context, String subjectId) async {
    // Загружаем домашки на дату scheduleDay.date
    final homeworks = await HomeworkService.fetchHomeworks(
      groupId: groupId,
      date: scheduleDay.date,
    );

    // Фильтруем по предмету
    final hwForSubject =
    homeworks.where((hw) => hw.subjectId == subjectId).toList();

    if (hwForSubject.isEmpty) {
      // Нет заданий для этого предмета
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Домашнее задание'),
          content: const Text('Для этого предмета нет домашнего задания.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ОК'),
            ),
          ],
        ),
      );
      return;
    }

    // Если домашек несколько, можно либо объединить их тексты, либо
    // отобразить список. Пока что возьмём первую:
    final homework = hwForSubject.first;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Домашнее задание'),
        content: Text(homework.assignment),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }
}
