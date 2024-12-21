// lib/main.dart

import 'package:flutter/material.dart';
import 'package:home/pages/home_page.dart';
import 'package:home/pages/profile_page.dart';
import 'package:home/pages/news_page.dart';
import 'package:home/pages/college_page.dart';
import 'package:home/admin/admin_panel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Импорт локализаций

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
      home: AuthGate(),
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

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return LoginPage();
        }
        return MainPage();
      },
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    ProfilePage(),
    NewsPage(),
    CollegePage(),
    AdminPanel(),
  ];

  final List<String> _titles = [
    'Главная',
    'Профиль',
    'Новости',
    'Колледж',
    'Админ Панель',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // После выхода из системы вы будете перенаправлены на страницу входа благодаря StreamBuilder в AuthGate
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выходе: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Выход',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Новости'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Колледж'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Админ'),
        ],
      ),
    );
  }
}
