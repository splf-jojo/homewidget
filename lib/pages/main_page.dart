import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Пример импорта ваших экранов
import 'package:home/pages/home_page.dart';
import 'package:home/pages/news_page.dart';
import 'package:home/pages/college_page.dart';
import 'package:home/admin/admin_panel.dart';
import 'package:home/widgets/profile_header.dart';

// Пример импорта страницы для назначения ДЗ (если нужно)

class MainPage extends StatefulWidget {
  final String groupId; // Переданный groupId
  final String role;    // Роль пользователя ('student', 'teacher', 'admin', ...)

  const MainPage({
    Key? key,
    required this.groupId,
    required this.role,
  }) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  late List<Widget> _pages;
  late List<String> _titles;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    // Базовые страницы
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
      _pages.add( AdminPanel());
      _titles.add('Админ Панель');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // После выхода вернётся в AuthGate / LoginPage (зависит от вашей логики)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выходе: $e')),
      );
    }
  }

  List<BottomNavigationBarItem> _getBottomNavigationBarItems() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
      const BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Новости'),
      const BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Колледж'),
    ];

    if (widget.role == 'admin') {
      items.add(
        const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Админ'),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          // Свайп вправо открывает Drawer
          if (details.delta.dx > 10) {
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Заголовок Drawer с профилем пользователя
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const ProfileHeader(),
              ),
              // Пункты меню
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Главная'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.article),
                title: const Text('Новости'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Колледж'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 2);
                },
              ),
              // Если нужна страница назанчения ДЗ для учителей

              // Если админ - пункт "Админ Панель"
              if (widget.role == 'admin') ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Админ Панель'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedIndex = _pages.length - 1;
                    });
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Выход'),
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
}
