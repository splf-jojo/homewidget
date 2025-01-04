import 'package:intl/intl.dart';

class Lesson {
  final String startTime;
  final String endTime;
  final String subject;
  final String room;
  final String details;

  Lesson(this.startTime, this.endTime, this.subject, this.room, this.details);

  bool isCurrent() {
    final now = DateTime.now();
    final formatter = DateFormat("HH:mm");
    final start = formatter.parse(startTime);
    final end = formatter.parse(endTime);

    final todayStart = DateTime(now.year, now.month, now.day, start.hour, start.minute);
    final todayEnd = DateTime(now.year, now.month, now.day, end.hour, end.minute);

    return now.isAfter(todayStart) && now.isBefore(todayEnd);
  }

  bool isLessonEnding() {
    final now = DateTime.now();
    final formatter = DateFormat("HH:mm");
    final end = formatter.parse(endTime);

    final todayEnd = DateTime(now.year, now.month, now.day, end.hour, end.minute);

    return now.hour == todayEnd.hour && now.minute == todayEnd.minute && now.second == 0;
  }
}
