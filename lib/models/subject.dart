// lib/models/subject.dart

class Subject {
  final String id;
  final String name;

  Subject({
    required this.id,
    required this.name,
  });

  factory Subject.fromMap(String id, Map<String, dynamic> map) {
    return Subject(
      id: id,
      name: map['name'] ?? 'Без названия',
    );
  }
}
