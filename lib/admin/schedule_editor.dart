// lib/admin/schedule_editor.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleEditor extends StatefulWidget {
  final String? scheduleId;

  ScheduleEditor({this.scheduleId});

  @override
  _ScheduleEditorState createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  final _formKey = GlobalKey<FormState>();
  String? _groupId;
  String? _groupName;
  List<ScheduleDay> _scheduleDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.scheduleId != null) {
      _loadSchedule();
    } else {
      // Инициализируем дни недели с изменяемыми списками уроков
      _scheduleDays = List.generate(7, (index) => ScheduleDay(dayOfWeek: getDayName(index)));
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getDayName(int index) {
    const days = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    return days[index];
  }

  Future<void> _loadSchedule() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('schedules').doc(widget.scheduleId).get();
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _groupId = data['group_id'];
        _groupName = data['group_name'];
        _scheduleDays = (data['schedule_days'] as List).map((day) {
          return ScheduleDay.fromMap(day);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить расписание: $e')),
      );
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, выберите группу')),
      );
      return;
    }

    final scheduleData = {
      'group_id': _groupId,
      'group_name': _groupName,
      'schedule_days': _scheduleDays.map((day) => day.toMap()).toList(),
    };

    try {
      if (widget.scheduleId != null) {
        await FirebaseFirestore.instance.collection('schedules').doc(widget.scheduleId).update(scheduleData);
      } else {
        await FirebaseFirestore.instance.collection('schedules').add(scheduleData);
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Расписание сохранено успешно')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка при сохранении расписания: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scheduleId != null ? 'Редактировать Расписание' : 'Создать Расписание'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                widget.scheduleId == null
                    ? FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('groups').get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }
                    final groups = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: _groupId,
                      items: groups.map((group) {
                        final data = group.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: group.id,
                          child: Text(data['name'] ?? 'Без названия'),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setState(() {
                          _groupId = value;
                          _groupName = groups.firstWhere((group) => group.id == value)['name'];
                        });
                      },
                      decoration: InputDecoration(labelText: 'Выберите группу'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, выберите группу';
                        }
                        return null;
                      },
                    );
                  },
                )
                    : TextFormField(
                  initialValue: _groupName,
                  decoration: InputDecoration(labelText: 'Группа'),
                  readOnly: true,
                ),
                SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _scheduleDays.length,
                  itemBuilder: (context, index) {
                    return ScheduleDayWidget(
                      day: _scheduleDays[index],
                      onChanged: (updatedDay) {
                        setState(() {
                          _scheduleDays[index] = updatedDay;
                        });
                      },
                    );
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveSchedule,
                  child: Text('Сохранить Расписание'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleDay {
  String dayOfWeek;
  List<LessonEntry> lessons;

  ScheduleDay({required this.dayOfWeek, List<LessonEntry>? lessons})
      : this.lessons = lessons ?? [];

  factory ScheduleDay.fromMap(Map<String, dynamic> map) {
    return ScheduleDay(
      dayOfWeek: map['day_of_week'],
      lessons: (map['lessons'] as List).map((lesson) => LessonEntry.fromMap(lesson)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day_of_week': dayOfWeek,
      'lessons': lessons.map((lesson) => lesson.toMap()).toList(),
    };
  }
}

class LessonEntry {
  String subjectId;
  String teacherId;
  String startTime;
  String endTime;
  String room;

  LessonEntry({
    required this.subjectId,
    required this.teacherId,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  factory LessonEntry.fromMap(Map<String, dynamic> map) {
    return LessonEntry(
      subjectId: map['subject_id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      room: map['room'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
    };
  }
}

class ScheduleDayWidget extends StatefulWidget {
  final ScheduleDay day;
  final ValueChanged<ScheduleDay> onChanged;

  ScheduleDayWidget({required this.day, required this.onChanged});

  @override
  _ScheduleDayWidgetState createState() => _ScheduleDayWidgetState();
}

class _ScheduleDayWidgetState extends State<ScheduleDayWidget> {
  void _addLesson() {
    setState(() {
      widget.day.lessons.add(LessonEntry(
        subjectId: '',
        teacherId: '',
        startTime: '',
        endTime: '',
        room: '',
      ));
      widget.onChanged(widget.day);
    });
  }

  void _removeLesson(int index) {
    setState(() {
      widget.day.lessons.removeAt(index);
      widget.onChanged(widget.day);
    });
  }

  void _updateLesson(int index, LessonEntry lesson) {
    setState(() {
      widget.day.lessons[index] = lesson;
      widget.onChanged(widget.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: Text(widget.day.dayOfWeek),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.day.lessons.length,
            itemBuilder: (context, index) {
              final lesson = widget.day.lessons[index];
              return LessonEntryWidget(
                lesson: lesson,
                onChanged: (updatedLesson) => _updateLesson(index, updatedLesson),
                onDelete: () => _removeLesson(index),
              );
            },
          ),
          TextButton.icon(
            onPressed: _addLesson,
            icon: Icon(Icons.add),
            label: Text('Добавить Урок'),
          ),
        ],
      ),
    );
  }
}

class LessonEntryWidget extends StatefulWidget {
  final LessonEntry lesson;
  final ValueChanged<LessonEntry> onChanged;
  final VoidCallback onDelete;

  LessonEntryWidget({required this.lesson, required this.onChanged, required this.onDelete});

  @override
  _LessonEntryWidgetState createState() => _LessonEntryWidgetState();
}

class _LessonEntryWidgetState extends State<LessonEntryWidget> {
  String? _selectedSubjectId;
  String? _selectedTeacherId;
  String _startTime = '';
  String _endTime = '';
  String _room = '';

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.lesson.subjectId.isNotEmpty ? widget.lesson.subjectId : null;
    _selectedTeacherId = widget.lesson.teacherId.isNotEmpty ? widget.lesson.teacherId : null;
    _startTime = widget.lesson.startTime;
    _endTime = widget.lesson.endTime;
    _room = widget.lesson.room;
  }

  void _onSubjectChanged(String? value) {
    setState(() {
      _selectedSubjectId = value;
    });
    _notifyChange();
  }

  void _onTeacherChanged(String? value) {
    setState(() {
      _selectedTeacherId = value;
    });
    _notifyChange();
  }

  void _onStartTimeChanged(String value) {
    setState(() {
      _startTime = value;
    });
    _notifyChange();
  }

  void _onEndTimeChanged(String value) {
    setState(() {
      _endTime = value;
    });
    _notifyChange();
  }

  void _onRoomChanged(String value) {
    setState(() {
      _room = value;
    });
    _notifyChange();
  }

  void _notifyChange() {
    widget.onChanged(LessonEntry(
      subjectId: _selectedSubjectId ?? '',
      teacherId: _selectedTeacherId ?? '',
      startTime: _startTime,
      endTime: _endTime,
      room: _room,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Dropdown для предмета
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final subjects = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedSubjectId?.isNotEmpty == true ? _selectedSubjectId : null,
                  items: subjects.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name'] ?? 'Без названия'),
                    );
                  }).toList(),
                  onChanged: _onSubjectChanged,
                  decoration: InputDecoration(labelText: 'Предмет'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, выберите предмет';
                    }
                    return null;
                  },
                );
              },
            ),
            SizedBox(height: 10),
            // Dropdown для учителя
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final teachers = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedTeacherId?.isNotEmpty == true ? _selectedTeacherId : null,
                  items: teachers.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['full_name'] ?? 'Без имени'),
                    );
                  }).toList(),
                  onChanged: _onTeacherChanged,
                  decoration: InputDecoration(labelText: 'Учитель'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, выберите учителя';
                    }
                    return null;
                  },
                );
              },
            ),
            SizedBox(height: 10),
            // Поле для времени начала и конца
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _startTime,
                    decoration: InputDecoration(labelText: 'Начало (например, 08:00)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите время начала';
                      }
                      return null;
                    },
                    onChanged: _onStartTimeChanged,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _endTime,
                    decoration: InputDecoration(labelText: 'Конец (например, 09:30)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите время конца';
                      }
                      return null;
                    },
                    onChanged: _onEndTimeChanged,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Поле для аудитории
            TextFormField(
              initialValue: _room,
              decoration: InputDecoration(labelText: 'Аудитория'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, введите номер аудитории';
                }
                return null;
              },
              onChanged: _onRoomChanged,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
