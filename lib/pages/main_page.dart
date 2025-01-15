import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Ваши экраны
import 'package:home/pages/home_page.dart';
import 'package:home/pages/news_page.dart';
import 'package:home/pages/notifications_page.dart'; // <-- NEW: Страница уведомлений
import 'package:home/admin/admin_panel.dart';
import 'package:home/widgets/profile_header.dart';

class MainPage extends StatefulWidget {
  final String groupId;
  final String role;

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
    // Базовые страницы (без "Колледж")
    _pages = [
      HomePage(groupId: widget.groupId),
      const NewsPage(),
    ];
    _titles = [
      'Главная',
      'Новости',
    ];

    // Если пользователь админ, добавляем AdminPanel
    if (widget.role == 'admin') {
      _pages.add(AdminPanel());
      _titles.add('Админ Панель');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выходе: $e')),
      );
    }
  }

  List<BottomNavigationBarItem> _getBottomNavigationBarItems() {

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
      const BottomNavigationBarItem(icon: Icon(Icons.article), label: ''),

    ];

    if (widget.role == 'admin') {
      items.add(
        const BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
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
        actions: [
          // Показываем иконку уведомлений, только если пользователь на HomePage (индекс 0)
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // NEW: Открываем экран уведомлений
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
              },
            ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
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
          selectedFontSize: 0,
        items: _getBottomNavigationBarItems(),
      ),
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const ProfileHeader(),
              ),
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
              // Если роль админ, добавляем пункт «Админ Панель»
              if (widget.role == 'admin') ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Админ Панель'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = _pages.length - 1);
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
