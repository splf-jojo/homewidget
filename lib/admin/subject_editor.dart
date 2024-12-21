// lib/admin/subject_editor.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectEditor extends StatefulWidget {
  final String? subjectId;
  final Map<String, dynamic>? existingData;

  SubjectEditor({this.subjectId, this.existingData});

  @override
  _SubjectEditorState createState() => _SubjectEditorState();
}

class _SubjectEditorState extends State<SubjectEditor> {
  final _formKey = GlobalKey<FormState>();
  String _subjectName = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _subjectName = widget.existingData!['name'] ?? '';
    }
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      CollectionReference subjects =
      FirebaseFirestore.instance.collection('subjects');

      if (widget.subjectId != null) {
        // Обновление существующего предмета
        await subjects.doc(widget.subjectId).update({'name': _subjectName});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Предмет обновлён.')),
        );
      } else {
        // Создание нового предмета
        await subjects.add({'name': _subjectName});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Предмет создан.')),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              initialValue: _subjectName,
              decoration: InputDecoration(labelText: 'Название предмета'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Пожалуйста, введите название предмета';
                }
                return null;
              },
              onSaved: (value) {
                _subjectName = value!.trim();
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSubject,
              child: _isLoading
                  ? CircularProgressIndicator(
                valueColor:
                AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title =
    widget.subjectId != null ? 'Редактировать Предмет' : 'Создать Предмет';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: _buildForm(),
    );
  }
}
