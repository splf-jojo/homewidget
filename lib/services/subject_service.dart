import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectService {
  /// Возвращает Map<subjectId, subjectName>
  static Future<Map<String, String>> fetchSubjectsMap() async {
    final snapshot = await FirebaseFirestore.instance.collection('subjects').get();

    if (snapshot.docs.isEmpty) return {};

    final Map<String, String> subjectsMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'] ?? 'Без названия';
      subjectsMap[doc.id] = name;
    }
    return subjectsMap;
  }
}
