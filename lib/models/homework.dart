// models/homework.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Homework {
  final String id;
  final String groupId;   // Для какой группы
  final String subjectId; // Для какого предмета
  final DateTime date;    // На какую дату (день)
  final String assignment; // Текст самого задания

  Homework({
    required this.id,
    required this.groupId,
    required this.subjectId,
    required this.date,
    required this.assignment,
  });

  factory Homework.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['date'] as Timestamp?;
    final dateTime = timestamp?.toDate() ?? DateTime.now();
    return Homework(
      id: id,
      groupId: map['group_id'] ?? '',
      subjectId: map['subject_id'] ?? '',
      date: dateTime,
      assignment: map['assignment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'subject_id': subjectId,
      'date': Timestamp.fromDate(date),
      'assignment': assignment,
    };
  }
}
