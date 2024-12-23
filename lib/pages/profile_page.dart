import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  String _errorMessage = '';
  File? _profileImage;

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
          .doc(_user!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _userData = userDoc.data()!;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // Здесь можно добавить код для загрузки фото в Firebase Storage
    }
  }

  Widget _buildProfilePhoto() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey),
        ),
        child: _profileImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            _profileImage!,
            fit: BoxFit.cover,
          ),
        )
            : Center(
          child: Icon(
            Icons.add_a_photo,
            color: Colors.grey,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    String role = _userData['role'] ?? 'unknown';

    return Column(
      children: [
        SizedBox(height: 20),
        _buildProfilePhoto(),
        SizedBox(height: 20),
        if (role == 'student') _buildStudentProfile(),
        if (role == 'teacher') _buildTeacherProfile(),
        if (role == 'admin') _buildAdminProfile(),
      ],
    );
  }

  Widget _buildStudentProfile() {
    return _buildProfileCard(
      title: 'Профиль Студента',
      items: [
        {'label': 'Полное имя', 'value': _userData['full_name'] ?? 'Не указано'},
        {'label': 'Email', 'value': _userData['email'] ?? 'Не указано'},
        {'label': 'Телефон', 'value': _userData['phone_number'] ?? 'Не указано'},
        {'label': 'ID группы', 'value': _userData['group_id'] ?? 'Не указано'},
      ],
    );
  }

  Widget _buildTeacherProfile() {
    return _buildProfileCard(
      title: 'Профиль Учителя',
      items: [
        {'label': 'Полное имя', 'value': _userData['full_name'] ?? 'Не указано'},
        {'label': 'Email', 'value': _userData['email'] ?? 'Не указано'},
        {'label': 'Телефон', 'value': _userData['phone_number'] ?? 'Не указано'},
        {'label': 'ID предмета', 'value': _userData['subject_id'] ?? 'Не указано'},
      ],
    );
  }

  Widget _buildAdminProfile() {
    return _buildProfileCard(
      title: 'Профиль Администратора',
      items: [
        {'label': 'Полное имя', 'value': _userData['full_name'] ?? 'Не указано'},
        {'label': 'Email', 'value': _userData['email'] ?? 'Не указано'},
        {'label': 'Телефон', 'value': _userData['phone_number'] ?? 'Не указано'},
      ],
    );
  }

  Widget _buildProfileCard({required String title, required List<Map<String, String>> items}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Divider(),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['label']!,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(item['value']!),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
      ),
      body: SingleChildScrollView(child: _buildProfileContent()),
    );
  }
}
