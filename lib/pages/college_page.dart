import 'dart:async'; // Для использования Timer
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home/services/schedule_service.dart';
import 'package:home/models/schedule.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CollegePage extends StatefulWidget {
  final String groupId;

  const CollegePage({Key? key, required this.groupId}) : super(key: key);

  @override
  _CollegePageState createState() => _CollegePageState();
}

class _CollegePageState extends State<CollegePage> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  List<NotificationData> _notifications = []; // Список уведомлений
  Schedule? schedule;
  late Timer _timer; // Переменная для таймера

  @override
  void initState() {
    super.initState();
    _initializeTimeZone();
    _initializeNotifications();
    _loadTodaySchedule();
    _startPeriodicCheck(); // Запуск периодической проверки
  }

  // Инициализация часовых поясов
  void _initializeTimeZone() {
    tz.initializeTimeZones();
  }

  // Инициализация уведомлений
  void _initializeNotifications() {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    _notificationsPlugin.initialize(settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          setState(() {
            _notifications.add(NotificationData(
              time: DateTime.now(),
              text: response.payload ?? 'Пара закончилась',
            ));
          });
        });
  }

  // Отправка уведомления о завершении пары
  Future<void> _sendNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Основной канал',
      importance: Importance.high,
      priority: Priority.high,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Пара закончилась',
      'Следующая пара начнётся скоро!',
      details,
      payload: 'Пара завершена',
    );

    // Добавляем уведомление в список
    setState(() {
      _notifications.add(NotificationData(
        time: DateTime.now(),
        text: 'Пара закончилась. Следующая пара начнётся скоро!',
      ));
    });
  }
  // Проверка, совпадает ли время окончания пары с текущим временем
  void _checkForLessonEndTime() {
    if (schedule == null) return;

    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    final todayDay = schedule!.scheduleDays.firstWhere(
          (day) =>
      day.date.year == now.year &&
          day.date.month == now.month &&
          day.date.day == now.day,
      orElse: () => ScheduleDay(date: now, lessons: []),
    );

    for (var lesson in todayDay.lessons) {
      final formatter = DateFormat("HH:mm");
      DateTime endTimeDT = formatter.parse(lesson.endTime);
      final lessonTime = TimeOfDay(hour: endTimeDT.hour, minute: endTimeDT.minute);

      print('Сейчас ${currentTime.format(context)}');
      print('Конец в ${lessonTime.format(context)}');

      // Сравнение времени без учета года и дня
      if (currentTime.hour == lessonTime.hour && currentTime.minute == lessonTime.minute) {
        print('Время совпало');
        _sendNotification();
      } else {
        print('Время не совпало');
      }
    }
  }

  // Загрузка расписания
  Future<void> _loadTodaySchedule() async {
    try {
      if (widget.groupId == '-1') {
        print('Группа не привязана');
        return;
      }

      print("Загрузка расписания для группы ${widget.groupId}");
      final fetchedSchedule = await ScheduleService.fetchSchedule(widget.groupId);
      if (fetchedSchedule == null) {
        print('Расписание не найдено');
        return;
      }

      setState(() {
        schedule = fetchedSchedule;
      });
    } catch (e) {
      print('Ошибка при загрузке расписания: $e');
    }
  }

  // Запуск периодической проверки каждую минуту
  void _startPeriodicCheck() {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkForLessonEndTime(); // Проверяем каждую минуту
    });
  }

  // Остановка таймера при уничтожении виджета
  @override
  void dispose() {
    _timer.cancel(); // Останавливаем таймер
    super.dispose();
  }

  // ЭКРАН
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notification Page')),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return ListTile(

            title: Text(notification.text),
            subtitle: Text(DateFormat('HH:mm').format(notification.time)),
          );
        },
      ),
    );
  }
}

// Класс для хранения данных об уведомлении
class NotificationData {
  final DateTime time;
  final String text;

  NotificationData({required this.time, required this.text});
}
