// lib/admin/schedule_editor.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Если ваша модель лежит в другом месте, импортируйте её
import 'package:home/models/schedule.dart';

/// Виджет редактирования/создания расписания
class ScheduleEditor extends StatefulWidget {
  final String? scheduleId;

  const ScheduleEditor({Key? key, this.scheduleId}) : super(key: key);

  @override
  State<ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  final _formKey = GlobalKey<FormState>();
  String? _groupId;
  String? _groupName;

  /// Список дней расписания
  List<ScheduleDay> _scheduleDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.scheduleId != null) {
      _loadSchedule();
    } else {
      // Если создаём новое расписание, начинаем с пустого списка.
      _scheduleDays = [];
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Загрузить расписание из Firestore (если редактируем)
  Future<void> _loadSchedule() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('schedules')
          .doc(widget.scheduleId)
          .get();
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        _groupId = data['group_id'];
        _groupName = data['group_name'];
        _scheduleDays = (data['schedule_days'] as List<dynamic>)
            .map((day) => ScheduleDay.fromMap(day as Map<String, dynamic>))
            .toList();
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

  /// Сохранить расписание в Firestore (создать/обновить)
  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите группу')),
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
        // Редактирование (update)
        await FirebaseFirestore.instance
            .collection('schedules')
            .doc(widget.scheduleId)
            .update(scheduleData);
      } else {
        // Новое расписание (add)
        await FirebaseFirestore.instance
            .collection('schedules')
            .add(scheduleData);
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Расписание сохранено успешно')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    }
  }

  /// Добавляем новый день в список
  void _addDay() {
    setState(() {
      _scheduleDays.add(
        ScheduleDay(
          // По умолчанию пусть дата будет "сегодня"
          date: DateTime.now(),
          lessons: [],
        ),
      );
    });
  }

  /// Удаляем день из списка
  void _removeDay(int index) {
    setState(() {
      _scheduleDays.removeAt(index);
    });
  }

  /// Обновляем день (при изменениях внутри DayWidget)
  void _updateDay(int index, ScheduleDay updated) {
    setState(() {
      _scheduleDays[index] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.scheduleId != null
              ? 'Редактировать Расписание'
              : 'Создать Расписание',
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Если scheduleId == null (новое расписание), предлагаем выбрать группу
                if (widget.scheduleId == null)
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('groups')
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final groups = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: _groupId,
                        items: groups.map((group) {
                          final data =
                          group.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: group.id,
                            child: Text(data['name'] ?? 'Без названия'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _groupId = value;
                            // Подставим имя
                            _groupName = groups
                                .firstWhere((g) => g.id == value)['name'];
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Выберите группу',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, выберите группу';
                          }
                          return null;
                        },
                      );
                    },
                  )
                else
                // Если уже редактируем существующее расписание, показываем имя группы «как есть»
                  TextFormField(
                    initialValue: _groupName,
                    decoration:
                    const InputDecoration(labelText: 'Группа'),
                    readOnly: true,
                  ),
                const SizedBox(height: 20),
                // Список дней
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _scheduleDays.length,
                  itemBuilder: (context, index) {
                    final day = _scheduleDays[index];
                    return ScheduleDayWidget(
                      day: day,
                      onChanged: (updatedDay) => _updateDay(index, updatedDay),
                      onDelete: () => _removeDay(index),
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Кнопка "Добавить день"
                ElevatedButton.icon(
                  onPressed: _addDay,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить день'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveSchedule,
                  child: const Text('Сохранить Расписание'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Виджет для редактирования одного дня (ScheduleDay)
class ScheduleDayWidget extends StatefulWidget {
  final ScheduleDay day;
  final ValueChanged<ScheduleDay> onChanged;
  final VoidCallback onDelete;

  const ScheduleDayWidget({
    Key? key,
    required this.day,
    required this.onChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<ScheduleDayWidget> createState() => _ScheduleDayWidgetState();
}

class _ScheduleDayWidgetState extends State<ScheduleDayWidget> {
  late DateTime _date;
  late List<LessonEntry> _lessons;

  @override
  void initState() {
    super.initState();
    // Локально сохраняем дату и уроки
    _date = widget.day.date;
    _lessons = widget.day.lessons;
  }

  /// Открывает диалог выбора даты (DatePicker)
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (newDate != null) {
      setState(() {
        _date = newDate;
      });
      _notifyChange();
    }
  }

  void _addLesson() {
    setState(() {
      _lessons.add(
        LessonEntry(
          subjectId: '',
          teacherId: '',
          startTime: '',
          endTime: '',
          room: '',
        ),
      );
    });
    _notifyChange();
  }

  void _removeLesson(int index) {
    setState(() {
      _lessons.removeAt(index);
    });
    _notifyChange();
  }

  void _updateLesson(int index, LessonEntry updatedLesson) {
    setState(() {
      _lessons[index] = updatedLesson;
    });
    _notifyChange();
  }

  /// Сообщаем «родителю», что данные в этом дне обновились
  void _notifyChange() {
    widget.onChanged(
      ScheduleDay(
        date: _date,
        lessons: _lessons,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Форматируем дату в человекочитаемый вид, например: "5 янв 2025"
    final formattedDate = DateFormat('d MMM yyyy', 'ru').format(_date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        // Заголовок = выбранная дата
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formattedDate),
            // Кнопка «Выбрать дату»
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickDate,
              tooltip: 'Выбрать дату',
            ),
          ],
        ),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lessons.length,
            itemBuilder: (context, index) {
              final lesson = _lessons[index];
              return LessonEntryWidget(
                lesson: lesson,
                onChanged: (updated) => _updateLesson(index, updated),
                onDelete: () => _removeLesson(index),
              );
            },
          ),
          TextButton.icon(
            onPressed: _addLesson,
            icon: const Icon(Icons.add),
            label: const Text('Добавить урок'),
          ),
          // Кнопка "Удалить день"
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Удалить день',
                style: TextStyle(color: Colors.red),
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// Виджет редактирования одного урока (LessonEntry)
class LessonEntryWidget extends StatefulWidget {
  final LessonEntry lesson;
  final ValueChanged<LessonEntry> onChanged;
  final VoidCallback onDelete;

  const LessonEntryWidget({
    Key? key,
    required this.lesson,
    required this.onChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<LessonEntryWidget> createState() => _LessonEntryWidgetState();
}

class _LessonEntryWidgetState extends State<LessonEntryWidget> {
  late String _subjectId;
  late String _teacherId;
  late String _startTime;
  late String _endTime;
  late String _room;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.lesson.subjectId;
    _teacherId = widget.lesson.teacherId;
    _startTime = widget.lesson.startTime;
    _endTime = widget.lesson.endTime;
    _room = widget.lesson.room;
  }

  void _onSubjectChanged(String? value) {
    setState(() {
      _subjectId = value ?? '';
    });
    _notifyChange();
  }

  void _onTeacherChanged(String? value) {
    setState(() {
      _teacherId = value ?? '';
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

  /// Уведомляем родителя, что урок поменялся
  void _notifyChange() {
    widget.onChanged(
      LessonEntry(
        subjectId: _subjectId,
        teacherId: _teacherId,
        startTime: _startTime,
        endTime: _endTime,
        room: _room,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Dropdown для предмета
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('subjects')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final subjects = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _subjectId.isNotEmpty ? _subjectId : null,
                  items: subjects.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name'] ?? 'Без названия'),
                    );
                  }).toList(),
                  onChanged: _onSubjectChanged,
                  decoration: const InputDecoration(labelText: 'Предмет'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, выберите предмет';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            // Dropdown для учителя
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'teacher')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final teachers = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _teacherId.isNotEmpty ? _teacherId : null,
                  items: teachers.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['full_name'] ?? 'Без имени'),
                    );
                  }).toList(),
                  onChanged: _onTeacherChanged,
                  decoration: const InputDecoration(labelText: 'Учитель'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, выберите учителя';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            // Поле для времени начала и конца
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _startTime,
                    decoration: const InputDecoration(
                      labelText: 'Начало (например, 08:00)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите время начала';
                      }
                      return null;
                    },
                    onChanged: _onStartTimeChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _endTime,
                    decoration: const InputDecoration(
                      labelText: 'Конец (например, 09:30)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите время окончания';
                      }
                      return null;
                    },
                    onChanged: _onEndTimeChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Поле для аудитории
            TextFormField(
              initialValue: _room,
              decoration: const InputDecoration(labelText: 'Аудитория'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите номер аудитории';
                }
                return null;
              },
              onChanged: _onRoomChanged,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
