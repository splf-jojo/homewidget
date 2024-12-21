// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _user = FirebaseAuth.instance.currentUser;

    if (_user == null) {
      setState(() {
        _errorMessage = 'Пользователь не аутентифицирован.';
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid) // Используем UID пользователя для извлечения данных
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Данные пользователя не найдены.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при загрузке данных: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    if (_userData == null) {
      return Center(child: Text('Данные пользователя не доступны.'));
    }

    String role = _userData!['role'] ?? 'unknown';

    switch (role) {
      case 'student':
        return _buildStudentProfile();
      case 'teacher':
        return _buildTeacherProfile();
      case 'admin':
        return _buildAdminProfile();
      default:
        return Center(child: Text('Неизвестная роль пользователя.'));
    }
  }

  Widget _buildStudentProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Профиль Студента',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('Полное имя: ${_userData?['full_name'] ?? 'Не указано'}'),
          Text('Email: ${_userData?['email'] ?? 'Не указано'}'),
          Text('Телефон: ${_userData?['phone_number'] ?? 'Не указано'}'),
          Text('ID группы: ${_userData?['group_id'] ?? 'Не указано'}'),
        ],
      ),
    );
  }

  Widget _buildTeacherProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Профиль Учителя',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('Полное имя: ${_userData?['full_name'] ?? 'Не указано'}'),
          Text('Email: ${_userData?['email'] ?? 'Не указано'}'),
          Text('Телефон: ${_userData?['phone_number'] ?? 'Не указано'}'),
          Text('ID предмета: ${_userData?['subject_id'] ?? 'Не указано'}'),
        ],
      ),
    );
  }

  Widget _buildAdminProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Профиль Администратора',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('Полное имя: ${_userData?['full_name'] ?? 'Не указано'}'),
          Text('Email: ${_userData?['email'] ?? 'Не указано'}'),
          Text('Телефон: ${_userData?['phone_number'] ?? 'Не указано'}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildProfileContent();
  }
}
