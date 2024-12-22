  // lib/user_creation_page.dart

  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';

  class UserCreationPage extends StatefulWidget {
    @override
    _UserCreationPageState createState() => _UserCreationPageState();
  }

  class _UserCreationPageState extends State<UserCreationPage> {
    final _formKey = GlobalKey<FormState>();
    String _email = '';
    String _password = '';
    String _role = 'student';
    String _fullName = '';
    String _phoneNumber = '';

    Future<void> _createUser() async {
      final isValid = _formKey.currentState?.validate();
      if (!isValid!) return;

      _formKey.currentState?.save();

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: _email, password: _password);

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': _email,
          'full_name': _fullName,
          'phone_number': _phoneNumber,
          'role': _role,
        });

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Аккаунт успешно создан')),
        );
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
          SnackBar(content: Text('Произошла ошибка: $e')),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Создать Новый Аккаунт'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Полное Имя'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите полное имя';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _fullName = value!.trim();
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Телефон'),
                    keyboardType: TextInputType.phone,
                    onSaved: (value) {
                      _phoneNumber = value!.trim();
                    },
                  ),
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
                    onPressed: _createUser,
                    child: Text('Создать Аккаунт'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
