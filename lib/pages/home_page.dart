// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  final String startTime;
  final String endTime;
  final String subject;
  final String room;
  final String details;

  Lesson(this.startTime, this.endTime, this.subject, this.room, this.details);

  bool isCurrent() {
    final now = DateTime.now();
    final formatter = DateFormat("HH:mm");
    final start = formatter.parse(startTime);
    final end = formatter.parse(endTime);

    final todayStart = DateTime(now.year, now.month, now.day, start.hour, start.minute);
    final todayEnd = DateTime(now.year, now.month, now.day, end.hour, end.minute);

    return now.isAfter(todayStart) && now.isBefore(todayEnd);
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Lesson> lessons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLessonsFromFirebase();
  }

  Future<void> fetchLessonsFromFirebase() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('lessons').get();
      print("Fetched ${snapshot.docs.length} lessons from Firestore");

      final tempLessons = <Lesson>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final startTime = data['startTime'] as String? ?? "00:00";
        final endTime = data['endTime'] as String? ?? "00:00";
        final subject = data['subject'] as String? ?? "Unnamed";
        final room = data['room'] as String? ?? "NoRoom";
        final details = data['details'] as String? ?? "No details";
        tempLessons.add(Lesson(startTime, endTime, subject, room, details));
        print("Added lesson: $subject in room $room from $startTime to $endTime");
      }

      setState(() {
        lessons = tempLessons;
        isLoading = false;
      });

      await updateHomeWidgetSchedule();
    } catch (e) {
      print("Error fetching lessons: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateHomeWidgetSchedule() async {
    final lessonStrings = lessons.map((l) {
      return "${l.startTime}-${l.endTime} ${l.subject} ${l.room}";
    }).join(";");

    await HomeWidget.saveWidgetData<String>('widgetText', lessonStrings);
    await HomeWidget.updateWidget(
      name: 'AppWidgetProvider',
      iOSName: 'HomeWidgetExtension',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (lessons.isEmpty) {
      return Center(child: Text('No lessons available.'));
    }

    int currentLessonIndex = lessons.indexWhere((lesson) => lesson.isCurrent());

    return ListView.builder(
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final isCurrent = index == currentLessonIndex;
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.subject,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${lesson.startTime}-${lesson.endTime}",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Text(
                    lesson.room,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            initiallyExpanded: isCurrent,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  lesson.details,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[700],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
