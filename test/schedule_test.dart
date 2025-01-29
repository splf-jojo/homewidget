import 'package:flutter_test/flutter_test.dart';
import 'package:home/models/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  test('Schedule is created correctly from map and converts back to map', () {
    // Arrange: создаем карту данных, имитирующую данные из Firestore
    final scheduleData = {
      'group_id': 'group123',
      'group_name': 'Test Group',
      'schedule_days': [
        {
          'date': Timestamp.fromDate(DateTime(2023, 2, 1)),
          'lessons': [
            {
              'subject_id': 'math101',
              'teacher_id': 'teacher1',
              'start_time': '09:00',
              'end_time': '10:00',
              'room': '101',
            },
            {
              'subject_id': 'eng102',
              'teacher_id': 'teacher2',
              'start_time': '10:00',
              'end_time': '11:00',
              'room': '102',
            },
          ],
        },
      ],
    };

    // Act: создаем объект Schedule из карты данных
    final schedule = Schedule.fromMap('schedule1', scheduleData);

    // Assert: проверяем поля объекта Schedule
    expect(schedule.id, 'schedule1');
    expect(schedule.groupId, 'group123');
    expect(schedule.groupName, 'Test Group');
    expect(schedule.scheduleDays.length, 1);

    final day = schedule.scheduleDays.first;
    expect(day.date, DateTime(2023, 2, 1));
    expect(day.lessons.length, 2);

    final lesson1 = day.lessons[0];
    expect(lesson1.subjectId, 'math101');
    expect(lesson1.teacherId, 'teacher1');
    expect(lesson1.startTime, '09:00');
    expect(lesson1.endTime, '10:00');
    expect(lesson1.room, '101');

    final lesson2 = day.lessons[1];
    expect(lesson2.subjectId, 'eng102');
    expect(lesson2.teacherId, 'teacher2');
    expect(lesson2.startTime, '10:00');
    expect(lesson2.endTime, '11:00');
    expect(lesson2.room, '102');

    // Act: преобразуем объект обратно в карту данных
    final convertedMap = schedule.toMap();

    // Assert: проверяем, что карта данных соответствует исходным данным
    expect(convertedMap['group_id'], 'group123');
    expect(convertedMap['group_name'], 'Test Group');

    final convertedDay = (convertedMap['schedule_days'] as List).first as Map<String, dynamic>;
    expect((convertedDay['date'] as Timestamp).toDate(), DateTime(2023, 2, 1));

    final convertedLessons = convertedDay['lessons'] as List;
    final convertedLesson1 = convertedLessons[0] as Map<String, dynamic>;
    expect(convertedLesson1['subject_id'], 'math101');
    expect(convertedLesson1['teacher_id'], 'teacher1');
    expect(convertedLesson1['start_time'], '09:00');
    expect(convertedLesson1['end_time'], '10:00');
    expect(convertedLesson1['room'], '101');

    final convertedLesson2 = convertedLessons[1] as Map<String, dynamic>;
    expect(convertedLesson2['subject_id'], 'eng102');
    expect(convertedLesson2['teacher_id'], 'teacher2');
    expect(convertedLesson2['start_time'], '10:00');
    expect(convertedLesson2['end_time'], '11:00');
    expect(convertedLesson2['room'], '102');
  });
}
