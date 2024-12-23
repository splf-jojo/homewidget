// lib/main.dart

import 'package:flutter/material.dart';
import 'package:home/pages/home_page.dart';
import 'package:home/pages/news_page.dart';
import 'package:home/pages/college_page.dart';
import 'package:home/admin/admin_panel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:home/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация данных локали для 'ru_RU'
  await initializeDateFormatting('ru_RU', null);
  Intl.defaultLocale = 'ru_RU';

  // Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Widget App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: AuthGate(), // Используем AuthGate как корневой виджет
      supportedLocales: [
        const Locale('ru', 'RU'),
        // Добавьте другие локали по мере необходимости
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Добавьте другие делегаты по мере необходимости
      ],
    );
  }
}

class MainPage extends StatefulWidget {
  final String groupId; // Переданный groupId
  final String role; // Роль пользователя

  MainPage({required this.groupId, required this.role});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages; // Инициализируем позднее
  late List<String> _titles; // Инициализируем позднее

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      HomePage(groupId: widget.groupId),
      NewsPage(),
      CollegePage(),
    ];

    _titles = [
      'Главная',
      'Новости',
      'Колледж',
    ];

    // Если пользователь админ, добавляем AdminPanel
    if (widget.role == 'admin') {
      _pages.add(AdminPanel());
      _titles.add('Админ Панель');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // После выхода из системы вы будете перенаправлены на страницу входа благодаря AuthGate
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выходе: $e')),
      );
    }
  }

  List<BottomNavigationBarItem> _getBottomNavigationBarItems() {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
      BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Новости'),
      BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Колледж'),
    ];

    if (widget.role == 'admin') {
      items.add(
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Админ'),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Присваиваем GlobalKey
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          // Определяем направление свайпа
          if (details.delta.dx > 10) { // Порог для определения свайпа вправо
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: _getBottomNavigationBarItems(),
      ),
      drawer: Drawer(
        child: SingleChildScrollView( // Оборачиваем в SingleChildScrollView для предотвращения переполнения
          child: Column(
            children: [
              // Заголовок Drawer с профилем пользователя
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: _buildProfileContent(),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Главная'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.article),
                title: Text('Новости'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.school),
                title: Text('Колледж'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              if (widget.role == 'admin') ...[
                Divider(),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Админ Панель'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedIndex = _pages.length - 1; // Индекс AdminPanel
                    });
                  },
                ),
              ],
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Выход'),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Функция для построения контента профиля внутри DrawerHeader
  Widget _buildProfileContent() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              'Данные профиля не найдены.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          child: Container(
            width: double.infinity, // Во всю ширину блока
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Отступы внутри
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    await _pickImage();
                    // Здесь можно добавить код для загрузки фото в Firebase Storage
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: userData['profile_image'] != null
                        ? NetworkImage(userData['profile_image'])
                        : null,
                    child: userData['profile_image'] == null
                        ? Icon(Icons.person, size: 40, color: Colors.grey[700])
                        : null,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  userData['full_name'] ?? 'Не указано',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Дополнительные поля, если нужно
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {

  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Пока состояние аутентификации загружается
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Если пользователь не аутентифицирован
        if (!snapshot.hasData) {
          return LoginPage();
        }

        // Пользователь аутентифицирован, получаем его данные
        User user = snapshot.data!;

        // Получаем данные пользователя из коллекции 'users'
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return Scaffold(
                body: Center(child: Text('Данные пользователя не найдены.')),
              );
            }

            // Получаем роль пользователя
            String role = userSnapshot.data!['role'] ?? 'student';

            // Устанавливаем groupId в зависимости от роли
            if (role == 'teacher' || role == 'admin') {
              String groupId = '-1';
              return MainPage(groupId: groupId, role: role);
            } else {
              // Если пользователь студент, получаем его groupId
              return FutureBuilder<String?>(
                future: FirebaseFirestore.instance
                    .collection('groups')
                    .where('students', arrayContains: user.uid)
                    .get()
                    .then((groupSnapshot) {
                  if (groupSnapshot.docs.isNotEmpty) {
                    return groupSnapshot.docs.first.id;
                  }
                  return null;
                }),
                builder: (context, groupSnapshot) {
                  if (groupSnapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!groupSnapshot.hasData || groupSnapshot.data == null) {
                    return Scaffold(
                      body: Center(child: Text('Группа не найдена.')),
                    );
                  }
                  String groupId = groupSnapshot.data!;
                  return MainPage(groupId: groupId, role: role);
                },
              );
            }
          },
        );
      },
    );
  }
}
