import 'package:home_widget/home_widget.dart';
import '../models/schedule.dart';
import '../models/subject.dart';

class HomeWidgetService {
  /// Обновляем домашний виджет с расписанием (Android / iOS)
  static Future<void> updateHomeWidgetSchedule(
      List<LessonEntry> lessons,
      Map<String, Subject> subjectsMap,
      ) async {
    try {
      final lessonStrings = lessons.map((lesson) {
        final subjectName = subjectsMap[lesson.subjectId]?.name ?? 'Без названия';
        return "${lesson.startTime}-${lesson.endTime} $subjectName ${lesson.room}";
      }).join(";");

      await HomeWidget.saveWidgetData<String>('widgetText', lessonStrings);
      await HomeWidget.updateWidget(
        name: 'AppWidgetProvider', // Android
        iOSName: 'HomeWidgetExtension', // iOS
      );
    } catch (e) {
      print("Failed to update home widget: $e");
    }
  }
}
