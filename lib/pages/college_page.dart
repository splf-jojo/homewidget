import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:home/models/lesson.dart'; // Подключаем модель урока

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class CollegePage extends StatefulWidget {
  @override
  _CollegePageState createState() => _CollegePageState();
}

class _CollegePageState extends State<CollegePage> {
  List<String> notifications = []; // Список уведомлений
  late Timer _timer; // Таймер для проверки времени

  List<Lesson> lessons = []; // Пустой список, который будет заполнен из Firebase

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _startTimeCheck();
    _fetchLessons(); // Получаем уроки из базы данных
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      notifications.length, // ID
      title,
      body,
      notificationDetails,
    );

    setState(() {
      notifications.add(title);
    });
  }

  void _startTimeCheck() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      print('Текущее время: ${now.hour}:${now.minute}:${now.second}');
      print(lessons);
      for (var lesson in lessons) {
        if (lesson.isLessonEnding()) {
          print('Урок "${lesson.subject}" закончился!');
          _showNotification(
              'Урок окончен!',
              'Закончился урок "${lesson.subject}" в кабинете ${lesson.room}');
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Получаем уроки из Firebase
  Future<void> _fetchLessons() async {
    try {
      QuerySnapshot lessonSnapshot = await FirebaseFirestore.instance
          .collection('lessons') // Коллекция уроков
          .get();

      List<Lesson> fetchedLessons = lessonSnapshot.docs.map((doc) {
        return Lesson(
          doc['start_time'],
          doc['end_time'],
          doc['subject'],
          doc['room'],
          doc['details'],
        );
      }).toList();

      setState(() {
        lessons = fetchedLessons;
      });
    } catch (e) {
      print("Ошибка при получении уроков: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Расписание уроков')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _showNotification("Тестовое уведомление", "Это проверка"),
            child: Text("Отправить тестовое уведомление"),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(notifications[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
