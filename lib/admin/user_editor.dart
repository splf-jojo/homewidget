import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserEditor extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? existingData;

  UserEditor({this.userId, this.existingData});

  @override
  _UserEditorState createState() => _UserEditorState();
}

class _UserEditorState extends State<UserEditor> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Поля формы
  String _fullName = '';
  String _phoneNumber = '';
  String _role = 'student';
  String _email = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _fullName = widget.existingData!['full_name'] ?? '';
      _phoneNumber = widget.existingData!['phone_number'] ?? '';
      _role = widget.existingData!['role'] ?? 'student';
      _email = widget.existingData!['email'] ?? '';
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

      if (widget.userId != null) {
        // Обновление существующего пользователя
        await usersCollection.doc(widget.userId).update({
          'full_name': _fullName,
          'phone_number': _phoneNumber,
          'role': _role,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пользователь обновлён.')),
        );
      } else {
        // Создание нового пользователя
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: _email, password: _password);

        await usersCollection.doc(userCredential.user!.uid).set({
          'email': _email,
          'full_name': _fullName,
          'phone_number': _phoneNumber,
          'role': _role,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пользователь создан.')),
        );
      }

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      String message = 'Произошла ошибка';
      if (e.code == 'weak-password') {
        message = 'Пароль слишком слабый.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Аккаунт с этим email уже существует.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              initialValue: _fullName,
              decoration: InputDecoration(labelText: 'Полное Имя'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Пожалуйста, введите полное имя';
                }
                return null;
              },
              onSaved: (value) {
                _fullName = value!.trim();
              },
            ),
            TextFormField(
              initialValue: _phoneNumber,
              decoration: InputDecoration(labelText: 'Телефон'),
              keyboardType: TextInputType.phone,
              onSaved: (value) {
                _phoneNumber = value!.trim();
              },
            ),
            // Поля email и пароль отображаются только при создании нового пользователя
            if (widget.userId == null) ...[
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Пожалуйста, введите валидный email';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value!.trim();
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Пароль'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Пароль должен быть не менее 6 символов';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value!.trim();
                },
              ),
            ],
            DropdownButtonFormField(
              value: _role,
              items: ['student', 'teacher', 'admin'].map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _role = value as String;
                });
              },
              decoration: InputDecoration(labelText: 'Роль'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveUser,
              child: _isLoading
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.userId != null ? 'Редактировать Пользователя' : 'Создать Пользователя';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: _buildForm(),
    );
  }
}
