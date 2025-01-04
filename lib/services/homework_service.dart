// services/homework_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homework.dart';

class HomeworkService {
  /// Получить список всех домашних заданий для [groupId] на конкретную [date].
  /// (Опционально можно фильтровать ещё и по subjectId).
  static Future<List<Homework>> fetchHomeworks({
    required String groupId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('homeworks')
        .where('group_id', isEqualTo: groupId)
    // Фильтруем по дате: date >= startOfDay и date <= endOfDay
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .get();

    return snapshot.docs
        .map((doc) => Homework.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }
}
