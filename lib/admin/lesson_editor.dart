import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LessonEditor extends StatefulWidget {
  final String? lessonId;

  LessonEditor({this.lessonId});

  @override
  _LessonEditorState createState() => _LessonEditorState();
}

class _LessonEditorState extends State<LessonEditor> {
  final _formKey = GlobalKey<FormState>();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _subjectController = TextEditingController();
  final _roomController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.lessonId != null) {
      FirebaseFirestore.instance
          .collection('lessons')
          .doc(widget.lessonId)
          .get()
          .then((snapshot) {
        final data = snapshot.data()!;
        _startTimeController.text = data['startTime'];
        _endTimeController.text = data['endTime'];
        _subjectController.text = data['subject'];
        _roomController.text = data['room'];
        _detailsController.text = data['details'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonId == null ? 'New Lesson' : 'Edit Lesson'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _startTimeController,
                decoration: InputDecoration(labelText: 'Start Time (HH:MM)'),
              ),
              TextFormField(
                controller: _endTimeController,
                decoration: InputDecoration(labelText: 'End Time (HH:MM)'),
              ),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(labelText: 'Subject'),
              ),
              TextFormField(
                controller: _roomController,
                decoration: InputDecoration(labelText: 'Room'),
              ),
              TextFormField(
                controller: _detailsController,
                decoration: InputDecoration(labelText: 'Details'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveLesson,
                child: Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _saveLesson() async {
    final data = {
      'startTime': _startTimeController.text,
      'endTime': _endTimeController.text,
      'subject': _subjectController.text,
      'room': _roomController.text,
      'details': _detailsController.text,
    };

    if (widget.lessonId == null) {
      await FirebaseFirestore.instance.collection('lessons').add(data);
    } else {
      await FirebaseFirestore.instance
          .collection('lessons')
          .doc(widget.lessonId)
          .update(data);
    }

    Navigator.pop(context);
  }
}
