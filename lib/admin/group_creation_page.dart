// lib/group_creation_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupCreationPage extends StatefulWidget {
  @override
  _GroupCreationPageState createState() => _GroupCreationPageState();
}

class _GroupCreationPageState extends State<GroupCreationPage> {
  final _formKey = GlobalKey<FormState>();
  String _groupName = '';
  int _course = 1;
  List<String> _students = [];

  Future<void> _createGroup() async {
    final isValid = _formKey.currentState?.validate();
    if (!isValid!) return;

    _formKey.currentState?.save();

    try {
      await FirebaseFirestore.instance.collection('groups').add({
        'name': _groupName,
        'course': _course,
        'students': _students,
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Группа успешно создана')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $e')),
      );
    }
  }

  Future<void> _addStudent() async {
    String? selectedStudentId = await showDialog<String>(
      context: context,
      builder: (context) => AddStudentDialog(),
    );

    if (selectedStudentId != null && !_students.contains(selectedStudentId)) {
      setState(() {
        _students.add(selectedStudentId);
      });
    }
  }

  Future<void> _removeStudent(String studentId) async {
    setState(() {
      _students.remove(studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создать Группу'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Название группы'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название группы';
                  }
                  return null;
                },
                onSaved: (value) {
                  _groupName = value!.trim();
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Курс'),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите курс';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 1) {
                    return 'Курс должен быть положительным числом';
                  }
                  return null;
                },
                onSaved: (value) {
                  _course = int.parse(value!.trim());
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Студенты:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _addStudent,
                    icon: Icon(Icons.add),
                    label: Text('Добавить'),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    String studentId = _students[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return ListTile(title: Text('Загрузка...'));
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        return ListTile(
                          title: Text(data?['full_name'] ?? 'Без имени'),
                          subtitle: Text(data?['email'] ?? ''),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeStudent(studentId),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createGroup,
                child: Text('Создать Группу'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddStudentDialog extends StatefulWidget {
  @override
  _AddStudentDialogState createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  String? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Выберите студента'),
      content: Container(
        width: double.maxFinite,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Student').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();
            final students = snapshot.data!.docs;

            return DropdownButtonFormField<String>(
              items: students.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(data['full_name'] ?? 'Без имени'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStudentId = value;
                });
              },
              decoration: InputDecoration(labelText: 'Студент'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, выберите студента';
                }
                return null;
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedStudentId != null) {
              Navigator.of(context).pop(_selectedStudentId);
            }
          },
          child: Text('Добавить'),
        ),
      ],
    );
  }
}
