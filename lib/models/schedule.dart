import 'package:cloud_firestore/cloud_firestore.dart';

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
      scheduleDays: (map['schedule_days'] as List<dynamic>)
          .map((dayMap) => ScheduleDay.fromMap(dayMap as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'group_name': groupName,
      'schedule_days': scheduleDays.map((day) => day.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return 'Schedule{id: $id, groupId: $groupId, groupName: $groupName, scheduleDays: $scheduleDays}';
  }
}

class ScheduleDay {
  final DateTime date;
  final List<LessonEntry> lessons;

  ScheduleDay({
    required this.date,
    required this.lessons,
  });

  factory ScheduleDay.fromMap(Map<String, dynamic> map) {
    final timestamp = map['date'] as Timestamp?;
    final dateTime = timestamp?.toDate() ?? DateTime.now();

    return ScheduleDay(
      date: dateTime,
      lessons: (map['lessons'] as List<dynamic>)
          .map((lessonMap) => LessonEntry.fromMap(lessonMap as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'lessons': lessons.map((lesson) => lesson.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return 'ScheduleDay{date: $date, lessons: $lessons}';
  }
}

class LessonEntry {
  final String subjectId;
  final String teacherId;
  final String startTime;
  final String endTime;
  final String room;

  LessonEntry({
    required this.subjectId,
    required this.teacherId,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  factory LessonEntry.fromMap(Map<String, dynamic> map) {
    return LessonEntry(
      subjectId: map['subject_id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      room: map['room'] ?? '',
    );
  }
  @override
  String toString() {
    return 'vladcushpan{subjectId: $subjectId, teacherId: $teacherId, startTime: $startTime, endTime: $endTime, room: $room}';
  }
  Map<String, dynamic> toMap() {
    return {
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
    };
  }


}
