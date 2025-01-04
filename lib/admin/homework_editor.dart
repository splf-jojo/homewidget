// lib/admin/homework_editor.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Модель
import 'package:home/models/homework.dart';

class HomeworkEditor extends StatefulWidget {
  final String? homeworkId;

  const HomeworkEditor({Key? key, this.homeworkId}) : super(key: key);

  @override
  State<HomeworkEditor> createState() => _HomeworkEditorState();
}

class _HomeworkEditorState extends State<HomeworkEditor> {
  String? _groupId;
  String? _subjectId;
  DateTime _date = DateTime.now();
  String _assignment = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.homeworkId != null) {
      _loadHomework();
    }
  }

  Future<void> _loadHomework() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('homeworks')
          .doc(widget.homeworkId)
          .get();
      if (!doc.exists) {
        throw 'Документ не найден';
      }
      final hw = Homework.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      setState(() {
        _groupId = hw.groupId;
        _subjectId = hw.subjectId;
        _date = hw.date;
        _assignment = hw.assignment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке: $e')),
      );
    }
  }

  Future<void> _saveHomework() async {
    if (_groupId == null || _subjectId == null || _assignment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    final hwData = {
      'group_id': _groupId!,
      'subject_id': _subjectId!,
      'date': Timestamp.fromDate(_date),
      'assignment': _assignment,
    };

    try {
      if (widget.homeworkId == null) {
        // Создаём новое
        await FirebaseFirestore.instance
            .collection('homeworks')
            .add(hwData);
      } else {
        // Обновляем существующее
        await FirebaseFirestore.instance
            .collection('homeworks')
            .doc(widget.homeworkId)
            .update(hwData);
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Домашнее задание сохранено')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (result != null) {
      setState(() => _date = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy', 'ru').format(_date);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.homeworkId == null
              ? 'Добавить домашнее задание'
              : 'Редактировать домашнее задание',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Выбор группы
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }
                  final groups = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _groupId,
                    items: groups.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Без названия'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _groupId = value),
                    decoration: const InputDecoration(labelText: 'Группа'),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Выбор предмета
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('subjects')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }
                  final subjects = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _subjectId,
                    items: subjects.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Без названия'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _subjectId = value),
                    decoration: const InputDecoration(labelText: 'Предмет'),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Выбор даты
              Row(
                children: [
                  Text('Дата: $formattedDate'),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Текст задания
              TextField(
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Задание',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _assignment = value,
                controller: TextEditingController(text: _assignment),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveHomework,
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
