// lib/admin/schedule_list.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'schedule_editor.dart';

class ScheduleList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки расписаний: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final schedules = snapshot.data!.docs;

        if (schedules.isEmpty) {
          return Center(child: Text('Нет расписаний.'));
        }

        return ListView.builder(
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            final groupName = schedule['group_name'] ?? 'Без названия группы';

            return ListTile(
              title: Text(groupName),
              trailing: Icon(Icons.edit),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleEditor(scheduleId: schedule.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
