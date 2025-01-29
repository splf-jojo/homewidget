import 'package:flutter_test/flutter_test.dart';
import 'package:home/models/subject.dart';
import 'package:home/models/lesson.dart';

void main() {
  group('Subject Tests', () {
    test('Subject is created correctly from map', () {
      // Arrange: создаем строго типизированную карту данных
      final Map<String, dynamic> subjectData = {'name': 'Mathematics'};

      // Act: создаем объект Subject из карты данных
      final subject = Subject.fromMap('subject123', subjectData);

      // Assert: проверяем поля объекта Subject
      expect(subject.id, 'subject123');
      expect(subject.name, 'Mathematics');
    });

    test('Subject name defaults to "Без названия" if missing', () {
      // Arrange: создаем пустую карту данных
      final Map<String, dynamic> subjectData = {};

      // Act: создаем объект Subject из карты данных
      final subject = Subject.fromMap('subject123', subjectData);

      // Assert: проверяем значение поля name по умолчанию
      expect(subject.name, 'Без названия');
    });
  });

  group('Lesson Tests', () {
    test('Lesson correctly determines current time status', () {
      // Arrange: создаем урок с текущим временем
      final now = DateTime.now();
      final startTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      final endTime = '${now.add(const Duration(minutes: 30)).hour}:${now.add(const Duration(minutes: 30)).minute.toString().padLeft(2, '0')}';

      final lesson = Lesson(startTime, endTime, 'Mathematics', '101', 'Test details');

      // Act: проверяем метод isCurrent
      final isCurrent = lesson.isCurrent();

      // Assert: метод должен вернуть true
      expect(isCurrent, true);
    });

    test('Lesson returns false if current time is outside the lesson time', () {
      // Arrange: создаем урок с прошедшим временем
      final pastLesson = Lesson('08:00', '09:00', 'History', '102', 'Test details');

      // Act: проверяем метод isCurrent
      final isCurrent = pastLesson.isCurrent();

      // Assert: метод должен вернуть false
      expect(isCurrent, false);
    });
  });
}
