// lib/models/schedule.dart

class Schedule {
  final String id;
  final String groupId;
  final String groupName;
  final List<ScheduleDay> scheduleDays;

  Schedule({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.scheduleDays,
  });

  factory Schedule.fromMap(String id, Map<String, dynamic> map) {
    return Schedule(
      id: id,
      groupId: map['group_id'] ?? '',
      groupName: map['group_name'] ?? '',
      scheduleDays: (map['schedule_days'] as List<dynamic>? ?? [])
          .map((day) => ScheduleDay.fromMap(day))
          .toList(),
    );
  }
}

class ScheduleDay {
  final String dayOfWeek;
  final List<LessonEntry> lessons;

  ScheduleDay({
    required this.dayOfWeek,
    required this.lessons,
  });

  factory ScheduleDay.fromMap(Map<String, dynamic> map) {
    return ScheduleDay(
      dayOfWeek: map['day_of_week'] ?? '',
      lessons: (map['lessons'] as List<dynamic>? ?? [])
          .map((lesson) => LessonEntry.fromMap(lesson))
          .toList(),
    );
  }
}

class LessonEntry {
  final String startTime;
  final String endTime;
  final String subjectId;
  final String teacherId;
  final String room;
  final String details;

  LessonEntry({
    required this.startTime,
    required this.endTime,
    required this.subjectId,
    required this.teacherId,
    required this.room,
    required this.details,
  });

  factory LessonEntry.fromMap(Map<String, dynamic> map) {
    return LessonEntry(
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      subjectId: map['subject_id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      room: map['room'] ?? '',
      details: map['details'] ?? '',
    );
  }
}
