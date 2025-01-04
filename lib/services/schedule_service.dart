import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';
import '../models/subject.dart';

class ScheduleService {
  /// Получаем расписание для конкретной группы
  static Future<Schedule?> fetchSchedule(String groupId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schedules')
        .where('group_id', isEqualTo: groupId)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return Schedule.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Получаем список всех предметов
  static Future<Map<String, Subject>> fetchSubjects() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('subjects').get();
    final Map<String, Subject> subjectsMap = {};

    for (var doc in snapshot.docs) {
      final subject = Subject.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      subjectsMap[subject.id] = subject;
    }
    return subjectsMap;
  }

  /// Получаем список всех учителей
  static Future<Map<String, Map<String, dynamic>>> fetchTeachers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .get();
    final Map<String, Map<String, dynamic>> teachersMap = {};

    for (var doc in snapshot.docs) {
      teachersMap[doc.id] = doc.data() as Map<String, dynamic>;
    }
    return teachersMap;
  }
}
